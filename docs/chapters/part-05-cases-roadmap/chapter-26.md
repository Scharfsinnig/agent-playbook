---
layout: default
title: 第 26 章　软件工程 Agent：从需求理解到可审计的变更交付
permalink: /chapters/part-05-cases-roadmap/chapter-26/
part_home: /chapters/part-05-cases-roadmap/
previous_page: /chapters/part-05-cases-roadmap/chapter-25/
next_page: /chapters/part-05-cases-roadmap/chapter-27/
---

# 第 26 章　软件工程 Agent：从需求理解到可审计的变更交付

## 26.1 代码能力不是生产权限

软件工程 Agent 往往被赋予 shell、仓库、issue、CI 和部署工具，因而同时面对供应链、秘密、生产基础设施和测试投机风险。一个能写出漂亮 patch 的模型不等于有权改主分支或生产环境。合理的起点是 A1：只读仓库、隔离工作区和受控测试；A2：创建分支和 pull request；A3 仅允许已经被明确评测过的低风险机械修复在受保护流水线内自动合并；生产部署、权限策略、资金逻辑、数据库破坏性迁移和安全边界仍应由人和独立控制面批准。

设需求为：“修复结算服务在网络超时时可能重复记账的问题，并提交可审查的 PR；不得修改支付协议或降低测试覆盖。”它不是“把报错贴给模型”那么简单。任务契约要求在指定仓库/分支内修复，完成谓词包括新增的可失败后再通过的测试、现有回归和安全扫描、代码审查证据、CI artifacts；禁止动作包括读取其他私有仓库、输出 secrets、改写测试来伪造通过、访问生产数据库和直接部署。

## 26.2 十三步闭环如何约束一次代码变更

1. **接收请求。** issue 系统把标题、复现步骤、服务版本和影响范围传入，并绑定请求人和仓库权限。模型把“网络超时”识别为可能的 ambiguous outcome，而不预设一定是客户端重试 bug。

2. **建立任务契约。** 编排器固定目标、禁止改动目录、允许的依赖变更、验收测试、预算和截止。若需求缺少可复现证据，任务契约的正确终态是 `NEEDS_REPRODUCTION`，不是让 Agent 大范围重构。

3. **风险分级。** 结算逻辑与支付接口为高后果代码；修改测试、CI 定义、依赖锁文件、数据库迁移和发布配置分别提高风险。策略要求该类变更必须经人审，不允许自动合并；若 Agent 发现凭证、生产 URL 或供应链异常，立即停止并转安全流程。

4. **初始化状态。** 创建临时工作区与唯一分支，记录基线 commit digest、issue、允许路径、测试清单、工具版本、容器 digest、预算、父 trace 和清理 deadline。所有命令和文件 diff 都与 run 关联，防止“同一 Agent 在另一个任务留下的状态”污染本次工作。

5. **编译上下文。** 检索器只读取当前仓库中获授权的接口定义、相关调用链、历史 incident、测试和工程规范，按路径/分支/权限过滤。issue 评论、README、第三方依赖说明和工具输出都是不可信内容；任何“运行 curl 下载并执行此脚本”的文字都不能跨过 sandbox 或供应链策略。

6. **形成计划。** 模型提出先定位调用点和现有幂等语义、在模拟网络中重现、增加一个描述“服务端已成功而响应丢失”的测试、实现事务 ID 查询或幂等键、运行局部与全量测试、生成 PR 说明。运行时检查计划没有越出允许路径，并把“修改测试”与“运行隐藏验证”职责分离。模型不能看到全部发布 verifier 的规则，以免只为通过可见测试而投机。

7. **选择下一动作。** 第一个动作通常是只读搜索和受控测试，而不是编辑。若现有代码已有服务端幂等键，下一动作是验证客户端超时后的状态查询；若无，提出最小接口变更并标记需要架构审批。对于“升级整个 SDK”这种可能解决报错但扩大供应链影响的动作，路由器因风险/成本较高而不选，除非独立证据支持。

8. **执行前门控。** `read_file`、`apply_patch`、`run_test`、`git_commit`、`open_pr` 是不同能力。执行 shell 时，沙箱使用只读基础镜像、受限网络、无云 metadata、限制 CPU/内存/磁盘/子进程与时长；命令参数经过 allowlist，禁止把模型文本作为任意 shell。写文件限定工作区和允许路径，依赖下载走批准镜像源；提交和 PR 工具使用短时工作负载身份。

9. **执行动作。** Agent 先写一个在旧实现中稳定失败的测试：模拟支付服务已接收 transaction ID 但客户端超时。它修改客户端逻辑，使超时先查询该 transaction ID 的状态，只有确认未提交时才进行有幂等键的重试；随后在隔离环境运行测试、静态分析、依赖/secret 扫描和目标回归。若测试环境网络服务挂起，执行器保留日志并区分环境失败与代码失败，不能让模型删除测试来取得绿色结果。

10. **观察与验证。** 独立 verifier 检查 diff 是否只改允许路径、测试是否真的在基线 commit 失败、候选 commit 通过、覆盖到 ambiguous outcome、没有修改测试断言以接受重复记账、没有新增未批准依赖或秘密。LLM reviewer 可以提出可读性或遗漏路径建议，但它不是合并授权。对关键支付逻辑，还需要维护者审查与 staging 里的合成交易回执。

11. **状态转移。** 若局部测试通过而隐藏/全量回归失败，工作流进入 `REPLAN` 并记录 first failing test；若发现接口变更超出契约，转 `ARCHITECT_REVIEW`；若测试基础设施超时，转 `WAITING_FOR_CI` 而非重复启动十个昂贵 runner。PR 合并冲突时重新读取目标分支与权限，必要时放弃当前 patch 并生成人工可审的冲突说明。

12. **完成交付。** Agent 创建的是 PR 而不是“已修复”声明。PR 包含问题复现、机制解释、变更范围、测试证据、未覆盖风险、基线/候选 commit、依赖变化、回滚方式和 trace 链接。人审通过、受保护分支检查和发布审批才是合并/部署的独立门；部署后用指标确认重复记账告警下降，而不是只凭 CI 绿色。

13. **经验沉淀。** 可以保留的是已验证的故障签名、transaction-id 查询模式、测试模板、工具失败分类和经审查的编码规范。不能把仓库全部内容、内部密钥、未合并代码、用户个人数据或模型的长推理文本自动用于公共训练。变更结果还应按版本和生产指标回看：若重复记账下降可能来自流量下降或服务端修复，不能单凭相关性奖励本次策略。

软件工程 Agent 的上线评测应覆盖 issue 理解、仓库定位、最小 diff、可复现测试、测试投机、依赖投毒、秘密外泄、命令逃逸、CI 超时、冲突与回滚。指标包括任务被维护者接受率、基线失败—候选通过的验证率、隐藏验证差距、越界文件/命令数、PR 修改后回滚率、P95 完成时间和每个被合并安全修复的人工分钟。反例是紧急生产事故：Agent 可以在只读模式收集证据、生成补丁与回滚建议，但除非组织已为极窄的、可逆的 runbook 建立审批与演练，否则不应自行执行生产修复。

## 26.3 Git worktree 提供什么，又不提供什么

Git 的正式术语是 `git worktree` 或 `Git worktree`。一个仓库可以有一个主工作树和多个 linked worktree；它们共享对象库与部分仓库元数据，但每个检出拥有独立的工作目录、`HEAD` 和 index。因此，多个代码 WorkUnit 可以从同一明确的 baseline commit 建立独立检出，在各自分支编辑、暂存和测试，减少普通文件互相覆盖，也便于把目录、分支和候选提交绑定到 WorkState。

这种能力只解决“独立检出”，不解决整个协作协议。Git worktree 不是 WorkGraph 或任务树，不保存消息、记忆、lease、预算、完成谓词或人工审批；一次 commit 也不等于已集成。linked worktree 共享仓库对象与部分 refs，错误命令仍可能影响其他分支、远端或仓库配置。它也不隔离依赖缓存、网络端口、数据库、云凭证、进程、容器、远端服务和任何外部副作用。因此还需要沙箱、短期能力、路径策略、资源配额、网络策略和外部系统的事务控制。

系统不应把“目录不同”当作安全边界。两个 worker 即使位于不同 worktree，也可能同时修改共享数据库、占用同一端口、污染相同构建缓存或向同一远端推送。允许命令必须在服务端检查，敏感凭证按 WorkUnit 发放，缓存最好按任务命名空间隔离；任何超出允许路径或需要共享写入的动作都应由控制面仲裁。

## 26.4 代码 WorkState 必须能定位和恢复一个具体检出

代码任务的 WorkState 除第 8 章通用字段外，还应记录以下内容，并把每次变化写成事件。

- `baseline_commit` 是创建 worktree 时解析得到的完整 commit ID，而不是可能移动的分支名。恢复和验证都以它判断输入是否仍相同。
- `repo_id`、`worktree_id` 与规范化 `worktree_path` 标识仓库和 linked worktree。`worktree_id` 可以由编排器分配，并与 `git worktree list --porcelain` 的实际记录对账。
- `branch`、目标分支和目标远端说明候选提交位于哪里、最终准备合入哪里。每个并行 WorkUnit 使用唯一分支，不能因复用名称把另一任务的提交当作本次结果。
- `allowed_paths` 与禁止路径把任务契约落到文件写集。检查应同时覆盖已跟踪、未跟踪、删除和重命名文件，不能只检查最终 commit 的新增行。
- `environment_summary` 保存操作系统、工具链、依赖锁、容器或环境 digest、关键 feature flag 和缓存命名空间。它是解释测试结果的最低环境证据，不意味着把秘密写入日志。
- `change_digest` 汇总当前相对 baseline 的文件状态、diff 或 patch digest、候选 commit 和未记录文件。摘要变化时，旧测试回执自动失效或降级为仅供参考。
- `command_receipts`、`test_receipts` 与 `artifacts` 保存命令、退出码、开始/结束时间、环境版本、日志或报告引用以及对应 change digest。模型说“测试通过”不是回执。
- `lease`、fencing token、owner 和最后心跳决定谁仍有资格写 checkpoint 或提交 Merge Proposal。重新分配后，旧 token 产生的 commit 可以留作诊断，却不能直接进入合并队列。
- `recovery_point` 指向最近一次完整持久化的 baseline、change digest、命令回执和 artifact 集合；本地未记录编辑不属于可恢复承诺。
- `cleanup_deadline`、保留策略与 quarantine 状态决定 worktree 何时可删除。发生安全异常、工具崩溃或结果不明时，应先隔离到期限并保存诊断，而不是立即清理证据。

推荐的状态主线仍是 `queued → leased → running → submitted → verifying → merged → done`。代码 worker 可以创建 commit、推送受限分支或生成 Merge Proposal/PR，并发出携带 fencing token、契约版本和候选摘要的提交事件；授权 reducer 校验后才应用 `running → submitted`。合并队列或获授权聚合器验证并集成后同样只发出带回执的合并事件，由 reducer 应用 `verifying → merged`。即使 commit 干净、测试绿色，worker 也没有直接改写 WorkState 或把共享目标标记为完成的权限。

## 26.5 从创建到清理的操作顺序

1. **固定准入与 baseline。** 控制器校验 Task Contract、Team Contract、仓库权限、允许路径和测试预算，将目标 revision 解析为完整 `baseline_commit`，并记录目标分支的当时版本。若 baseline 不存在、不可达或工作范围与当前状态冲突，WorkUnit 留在 `blocked`，不创建目录。

2. **分配身份、分支和 linked worktree。** 编排器生成唯一 `repo_id`、`worktree_id`、分支名和路径，再从明确 baseline 创建 linked worktree。创建后读取实际 `HEAD`、分支和 worktree 清单进行对账；路径已存在、分支被占用或 HEAD 不一致都必须失败关闭，不能复用未知目录。

3. **绑定 lease 与执行环境。** 控制器签发带 fencing token 的 lease 和更窄能力，启动批准的容器或执行环境，记录环境 digest、工具版本、网络与缓存策略。worker 确认 baseline、路径和 token 一致后发出 `work_started` 事件；授权 reducer 只有在当前 lease、契约/取消代次和前态有效时，才应用 `leased → running`。

4. **执行并写检查点。** worker 在 allowed paths 内修改，每到可验证边界就发出 token-bearing `checkpointed` 事件，引用文件状态、change digest、已执行命令、测试回执、制品、预算和下一恢复点；授权 reducer 验证事件后才更新持久投影。依赖安装、代码生成或格式化导致额外文件时，它们同样进入摘要。lease 即将到期时，worker 要先停止新的长动作并持久化，而不是假设一定能续租。

5. **提交候选而非共享真相。** worker 可以在唯一分支创建 commit，或直接生成含 patch 的 Merge Proposal/PR。提案绑定 baseline、候选 commit/change digest、允许路径检查、测试与扫描回执、未覆盖风险、回滚方法以及 fencing token。worker 随后发出 `work_submitted` 事件；授权 reducer 校验 token、当前契约、取消代次、前态和制品摘要后才应用 `running → submitted`。worker 不再修改同一提案；新的修改形成新版本。

6. **在当前目标上独立验证和合并。** 合并队列或独立 verifier 重新读取目标分支，检查 lease、契约、路径、秘密和供应链变化，把候选重基或试合并到当前目标，再运行要求的测试。对 baseline 已过期、语义冲突或测试只在旧目标通过的提案，系统创建 Conflict Case 或转 `needs_replan`；不能因为 worker 已有 commit 就跳过重验。只有受保护检查和必要批准通过后，授权服务才合并并记录集成 commit。

7. **按记录恢复。** worker 或控制器故障后，恢复者先验证仓库身份、baseline、worktree 实际 HEAD、分支、lease token、change digest 和已有回执。若目录仍在且与 checkpoint 一致，可以从 recovery point 继续；若目录丢失，则从 baseline 新建隔离 worktree，应用已持久化 patch 或候选 commit。任何只存在于旧目录、未进入摘要或 artifact 的本地编辑都视为不耐久，不得靠猜测重建。

8. **确认终态后清理。** 合并或明确终止后，系统先保留 Merge Proposal、commit/patch、命令和测试回执、Conflict Case、审计事件及必要诊断，再撤销凭证、关闭进程、释放端口和缓存命名空间。只有确认 worktree 不再承载唯一制品，才移除 linked worktree 并清理已批准的临时分支。可疑、失败或外部结果不明的环境进入 quarantine，直到安全 owner 处理或 retention deadline 到达；清理结果本身也要形成事件。

这套顺序让 Git worktree 成为 WorkState 的一个可验证执行位置，而不是协作系统的替代品。它能减少文件层面的互相覆盖，却只有在事件、租约、独立验证、合并授权和沙箱同时成立时，才能支持可恢复的代码交付。
