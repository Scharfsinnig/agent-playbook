---
layout: default
title: 第 3 章　Agent 内部究竟保存什么：状态、上下文、知识和记忆
permalink: /chapters/part-01-runtime/chapter-03/
part_home: /chapters/part-01-runtime/
previous_page: /chapters/part-01-runtime/chapter-02/
next_page: /chapters/part-01-runtime/chapter-04/
---

# 第 3 章　Agent 内部究竟保存什么：状态、上下文、知识和记忆

## 3.1 不要把聊天历史误当作系统状态

当调研 Agent 读取合同、等待制裁筛查并起草意见时，很多系统只保存一串聊天消息。这样做短期方便，长期却会混淆三类含义：业务世界现在是什么、这次执行已经做到了哪里、模型此刻应该阅读什么。聊天历史既会被窗口截断，也缺少版本、权限、实体与事务语义；它不能可靠回答“这份合同是否仍为当前版本”“这个动作是否已经提交”“这个事实是否可跨会话复用”。

生产系统至少应分开六类数据。业务真相存在 CRM、合同库、审批系统等权威系统中；执行状态存在状态机、事件日志与检查点中；工作记忆是当前 run 需要的有限目标、待办、证据和计划；情景记忆保存已经验证过的历史案例；语义记忆保存可跨任务引用的稳定事实和政策；程序性记忆保存经过测试的工具用法、技能和提示模板。向量索引可以服务于语义检索，却不是这些责任的替代品。它本身不会处理对象身份、时效、访问控制、冲突或撤销。

## 3.2 核心状态字段及其不变量

建议把运行状态定义为可序列化的结构，而不是由模型隐式“记住”。以下字段不是所有系统都要原样实现，但体现了最低不变量：

```text
RunState {
  identity: {run_id, tenant_id, principal, purpose, trace_id},
  contract: {version, success_predicates, allowed_actions, deadline},
  control: {phase, state_version, cancellation_epoch, lease, budgets},
  plan: {plan_version, open_goals, assumptions, dependencies},
  evidence: {claims, source_refs, freshness, conflicts},
  actions: {issued, receipts, retries, idempotency_keys, compensations},
  context: {selected_items, redactions, token_budget, provenance},
  verification: {step_verdicts, final_verdict, outstanding_gaps}
}
```

其中 `state_version` 防止并发 worker 覆盖彼此的更新；`cancellation_epoch` 让晚到的回调不能在取消后重新激活 run；`idempotency_keys` 防止恢复时重复写入；`source_refs` 应至少保存来源标识、版本或抓取时间、访问决策和可信等级；`assumptions` 则让计划知道什么观察一旦变化就必须重规划。状态的每次变化应有明确事件，如 `ActionAuthorized`、`ToolDispatched`、`ReceiptObserved`、`VerificationFailed`，而不是直接覆盖一份 JSON 后丢掉因果链。

## 3.3 上下文是一次决策的受控投影

上下文编译（context compilation）解决的是“本次模型调用需要看什么”，而不是“历史上发生过什么”。在供应商案例中，规划模型可能需要任务契约摘要、当前未完成检查、相关政策版本、合同的授权片段、制裁筛查的最新状态以及可用工具的契约；它不需要所有旧草稿、其他供应商的记录或原始审计日志。把全部内容塞进窗口会增加成本，并让陈旧或不可信文本夺取注意力。上下文工程的关键也因此不是把窗口扩到最大，而是按当前动作选择恰当的信息与压缩边界。[Anthropic：Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

上下文选择应先通过访问控制与目的限制，再考虑相关性。每个注入模型的项目都应带有 `source`、`authority`、`valid_time`、`tenant_scope`、`trust_level` 和必要时的 `taint` 标签。网页、邮件、工具自由文本和用户上传文件是数据，不是能够修改系统目标的指令。AgentDojo 的研究说明，工具所读到的不可信数据可被用来劫持后续行动；因此，内容过滤有帮助，但敏感动作前的模型外策略门才是最后防线。[AgentDojo](https://arxiv.org/abs/2406.13352)

## 3.4 记忆写入比检索更需要治理

模型生成的摘要、用户的一句话和工具返回的文本不能自动成为长期事实。供应商 A 的“无负面记录”可能只是某次搜索暂未命中，若被写入共享记忆，后续任务会把缺失误认为事实。更稳妥的写入状态是 `proposed → quarantined → verified → active → superseded/tombstoned`：候选记忆先记录来源、实体、时间、权限与置信度；经规则、权威来源或人工验证后才可被默认检索；发生冲突或撤销时保留血缘并停止注入。

记忆冲突不应由“相似度最高”自动裁决。一个原子 claim 可表示为主体、谓词、客体、有效时间、来源和置信度；对同一供应商的相反 claim，要检查来源权威性、适用域和版本，而不是把新摘要覆盖旧摘要。用户偏好可以多值共存，业务状态却应回到权威系统。审计日志的保留规则也与可注入记忆不同：前者可能需要受控保留以便追责，后者需要支持过期、撤销和数据主体请求。

## 3.5 实现、指标与边界

运行时可采用检查点保存 thread/run 级工作状态，采用独立 store 保存跨 run 的长时信息。LangGraph 的文档也区分 thread checkpoint 与跨线程 store；这与上述分层一致。[LangGraph Persistence](https://langchain-ai.github.io/langgraph/concepts/time-travel/?h=time+travel) 但框架提供持久化不等于自动获得正确的记忆治理，实体解析、访问过滤、版本迁移和删除传播仍需业务实现。

应监测上下文 token 的组成、检索后被验证支持的 claim 比例、陈旧或冲突记忆的命中率、无来源记忆写入率、跨租户负向测试结果和撤销到索引/缓存生效的时延。对于快速变化的库存、价格、准入状态，正确做法通常是调用权威读取工具，而不是依赖向量库；对于无法可靠建立来源与撤销路径的数据，宁可不进入长期记忆。下一章将说明这些状态如何在每一步运行中被读取、改变和验证。
