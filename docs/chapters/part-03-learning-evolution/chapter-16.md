---
layout: default
title: 第 16 章　UCB、上下文 Bandit 与 Agent Loop：选择下一臂，不定义任务结束
permalink: /chapters/part-03-learning-evolution/chapter-16/
part_home: /chapters/part-03-learning-evolution/
previous_page: /chapters/part-03-learning-evolution/chapter-15/
next_page: /chapters/part-03-learning-evolution/chapter-17/
---

# 第 16 章　UCB、上下文 Bandit 与 Agent Loop：选择下一臂，不定义任务结束

## 16.1 Bandit 在 Agent 中是一个局部选择器

多臂 Bandit 描述的是重复的“看到上下文、选择一个臂、观察所选臂 reward”的问题。上下文 Bandit（contextual bandit）把当前任务特征纳入选择，例如文档长度、语言、风险等级、历史检索置信度、预计成本和是否有强 verifier。UCB（Upper Confidence Bound）类算法通常将某个臂的估计回报与不确定性上界相加，让未充分尝试的臂获得探索机会；LinUCB 等模型进一步用特征预测不同上下文下的收益。其经典目标是平衡探索与利用、控制累计 regret，而不是生成计划或证明完成。[Auer, Cesa-Bianchi and Fischer, UCB](https://link.springer.com/article/10.1023/A:1013689704352)

采购 Agent 的一个合理 Bandit 点是“在已批准的三个模型配置中，哪一个负责将条款抽取成草稿”：小模型成本低，强模型质量高，专业模型对扫描 PDF 更稳。另一个是“选择哪个已验证的检索器/重排器”。每次选择的 reward 可以在一个约定窗口内由结构化抽取正确、人工改写量、成本和延迟组成。这里的臂不是“是否有权限修改合同”；权限必须先由策略系统决定。也不是“是否已完成任务”；完成需要独立的验收谓词。

## 16.2 为什么 UCB 不能成为循环停止器

UCB 回答的是“若还要再进行一次选择，哪个臂值得选”，它通常假定持续交互并累积奖励。Agent loop 的停止却是另一个决策：当前任务是否已经满足完成谓词，继续行动的预期价值是否低于成本和风险，是否应因阻塞、预算耗尽、循环或不确定性而交接。即使把 `stop` 做成一个臂，仍必须由运行时定义什么时候 stop 合法、如何验证完成、何时强制停止以及是否允许继续；否则 Bandit 可能为探索而继续调用工具，或过早因短期 reward 选择停止。

正确架构是先由状态机计算硬终态：成功的外部验收、策略拒绝、超时/预算硬熔断、取消、不可恢复错误或等待审批。仅在这些条件都未触发、且有多个安全的下一步候选时，Bandit 才为局部路由提供建议。运行时还应比较继续计算的机会成本、风险和延迟；对高风险或不可逆动作，候选集合本身就不应包含自由探索臂。若目标是以给定置信度从一批候选中识别最佳方案，应使用带显式停止规则的 best-arm identification，而不是把累计 regret 的 UCB 当作结束条件；Track-and-Stop 是此类问题的代表方法。[Garivier and Kaufmann, Track-and-Stop](https://proceedings.mlr.press/v49/garivier16a.html)

这一区分可落实到运行时 API：`select_arm(context, safe_candidates)` 只返回一个候选模型、检索器或已批准动作配置及其不确定性；`transition(state, observation)` 才根据完成谓词、策略、预算和验证器返回 `CONTINUE`、`WAIT_APPROVAL`、`HANDOFF`、`COMPENSATE` 或终态。前者不能把一个未经授权的写动作加入 candidate set，后者也不能因为 Bandit 估计某臂奖励更高就跳过完成核验。把两个接口、日志和 owner 分开，是避免“局部路由算法接管整个 Agent loop”的最直接工程手段。

## 16.3 实现前提：日志概率、反馈时钟与安全候选集

离线评估或后续学习 Bandit 时，日志必须记录：上下文特征及其版本、候选臂集合、所选臂、logging policy 给该臂的 propensity、选择时刻、reward 定义版本、reward 的观察时刻与缺失原因、模型/工具/环境版本、硬约束是否触发。没有 propensity，就无法可靠地用 inverse propensity scoring（IPS）或 doubly robust（DR）估计一个新策略本会怎样表现；没有候选集和时间戳，也难以判断 support 是否重叠。DR 和 IPS 不是“自动消偏”按钮，其有效性依赖行为策略覆盖、模型假设和足够有效样本量。[Dudík et al., Doubly Robust Policy Evaluation](https://arxiv.org/abs/1103.4601)

上线前应报告 overlap、importance weight 分布、effective sample size（ESS）、估计区间和对策略偏离的敏感性。新策略想选的臂若在历史相似上下文中几乎从未出现，OPE 的置信区间不可信；此处不能凭一个高估分发布，只能限制新策略、收集受控数据或回到规则/强模型。离线 RL 的相同困难常称为 distributional shift 或 support mismatch，保守方法如 CQL 的思想正是避免对数据支持外动作过度乐观。[Kumar et al., Conservative Q-Learning](https://arxiv.org/abs/2006.04779)

Bandit 还要求 reward 在可用窗口内足够可靠。若采购 Agent 以“用户点击通知”作 reward，可能偏好夸张通知而忽略变更是否真正落地；若两周后才知道项目延期是否减少，短期奖励会产生选择偏差。应定义观察窗口和缺失机制，保留长期 holdout 与业务结果校验；只有一次性或短期可归因选择适合 Bandit。涉及多步、长期延迟、状态会因早期动作而改变的问题，应采用明确的状态机、搜索、MDP/RL 或人工流程，而不是把每一步假装成独立臂。

## 16.4 非平稳与安全探索

模型、工具、文档、用户和业务目标会变，历史最优臂可能迅速失效。折扣统计、滑动窗口、变点检测和定期回归能帮助路由适应，但不能证明新候选安全。实际部署中，Bandit 只应从已经通过离线和安全评估的候选集合中选；高风险写动作、支付、删除、权限提升等不应作为探索臂。新模型或 prompt 先 shadow；若进入 canary，限定租户、预算、时长和最大 regret，并预注册停止与回滚规则。还要审计 context 特征是否包含敏感属性或造成某些群体长期被路由到低质量服务。

一个反例是“让 Bandit 自己决定何时从强模型降级到小模型，并以每次节省 token 为 reward”。这种系统会迅速偏向便宜臂，即使长尾合同被误读。更可靠的 reward 要以安全验收任务成功为主，成本只是在可行域内的次级目标；低置信、缺证据或高风险任务强制升级，不能由探索奖金抵消。
