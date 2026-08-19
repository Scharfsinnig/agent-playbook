---
layout: default
title: "第 4 章　Agent Loop 的逐步运行逻辑：观察、规划、行动、验证与状态转移"
permalink: /handbook/part-01-runtime/chapter-04/
part_home: /handbook/part-01-runtime/
previous_page: /handbook/part-01-runtime/chapter-03/
next_page: /handbook/part-01-runtime/chapter-05/
---

# 第 4 章　Agent Loop 的逐步运行逻辑：观察、规划、行动、验证与状态转移

## 4.1 Loop 不是无限的 while，而是一组受限状态迁移

最小的 Agent Loop 通常写成“调用模型—若有工具则执行—把结果塞回模型—重复”。它适合演示，却无法表达等待、授权、取消、补偿和恢复。生产运行时应把循环表示成有限状态机：`RECEIVED` 接收请求；`CONTEXT_READY` 完成权限过滤和上下文编译；`PLAN_PROPOSED` 产生候选；`ACTION_AUTHORIZED` 通过策略和必要审批；`DISPATCHED` 派发已记录意图的动作；`OBSERVED` 接收环境结果；随后根据证据进入 `REPLAN`、`VERIFY`、`WAIT`、`ASK_HUMAN`、`COMPENSATE` 或终态 `SUCCEEDED/BLOCKED/FAILED/CANCELED`。

状态机不要求每个任务都直线运行。它允许从 `OBSERVED` 回到 `PLAN_PROPOSED`，但这条边必须有原因码，如“资源版本变化”“证据冲突”“权限拒绝”或“局部验证失败”。状态迁移由 reducer 或工作流引擎执行，模型只输出结构化候选，不能凭一句“现在完成”把自己跳到成功终态。这样，运行记录不仅可调试，也能在发生安全事故时证明哪些控制本应阻止该动作。

## 4.2 一步的真实语义

以“读取合同条款”为例，一步开始于观察：当前合同引用过期，且尚未满足“数据跨境条款已核验”的子目标。模型根据经编译的上下文提出 `read_contract(version=current)`，同时说明预期效果是获得条款证据，不是直接宣布无风险。策略引擎检查资源是否在允许范围、请求主体是否有读取能力、预算是否足够；工具网关用 schema 验证参数、附加审计字段并生成 `action_id`。若该动作只读，它可能直接派发；若动作会产生外部写入，则还要检查幂等键、影响范围和审批。

派发之前持久化意图很重要：运行时先写 `ActionAuthorized` 与幂等键，再写或发送 `ToolDispatched`。工具返回后追加 `ReceiptObserved`，包括协议状态、结构化结果引用、工具版本、实际资源版本和错误类别。reducer 依据回执更新执行状态；验证器再判定条款是否真正支持所需 claim。若工具超时，状态不是简单 `failed`，而是 `unknown`：系统应使用 correlation ID 查询任务状态、等待签名回调或把它交给人工，而不是立刻重发一个可能已经执行的写请求。

## 4.3 进展与循环检测必须基于外部变化

模型说“再检索一次也许会更好”不是进展。进展应来自可观测的目标差距缩小，例如未完成验收项减少、获得新的独立证据、世界对象进入期望状态、关键计划前提被确认、风险被降低。对于调研任务，可以计算尚缺的证据类别、每项结论的引用覆盖和冲突数量；对于代码任务，可以观察测试、文件 diff 和构建结果；对于业务办理，则观察权威系统的状态转移。

循环守护器还要识别动作指纹和状态振荡。一个实用指纹是 `tool + 规范化参数 + 目标子集 + 世界版本`。同一指纹在世界版本不变时反复出现，或出现 A→B→A 的模式且没有新证据，表明当前策略已卡住。此时正确反应未必是立即失败：可以重规划、切换到更低风险的替代工具、要求澄清、等待外部事件或把最小证据包交给人。硬性的 Token、时间、工具调用和递归深度上限仍必须存在，但它们是防火墙，不是任务完成逻辑。

## 4.4 一个可恢复控制循环的伪代码

```text
state = load_or_create_run(contract, identity)
while state.phase is not terminal:
    enforce_deadline_and_cancellation(state)
    context = compile_context(state, acl, purpose, freshness)
    candidates = planner.propose(context) + [ASK_HUMAN, WAIT, REPLAN, STOP]
    candidates = policy_filter(candidates, state)
    action = choose_allowed_candidate(candidates, progress, cost, risk)

    if loop_guard.detect_stagnation(state, action):
        action = choose_recovery_action(state)
    if action.requires_external_effect:
        persist_intent_and_idempotency_key(action)
        require_commit_time_authorization(action)

    observation = dispatch_or_wait(action)
    append_event(observation)
    state = reduce(state, observation)
    verdict = verifier.evaluate(contract, state)

    if verdict.success: transition(SUCCEEDED)
    elif verdict.requires_compensation: transition(COMPENSATE)
    elif verdict.blocked: transition(BLOCKED or ASK_HUMAN)
```

这里的 `choose_allowed_candidate` 可以使用规则、模型评分或学习到的路由器，但永远在 `policy_filter` 之后。`verifier.evaluate` 也不应只调用与执行模型相同的提示去询问“对不对”；应优先使用规则、测试、权威读取和独立证据。模型自评可以成为低成本的线索，例如建议“此处可能缺合同附件”，但它不应单独触发成功、写入长期记忆或扩大权限。

## 4.5 运行质量如何评估

除最终成功率外，运行时应测量无进展循环率、重复动作率、从取消到静止的时延、恢复后重复副作用数、未知结果对账时延、状态迁移非法率和在预算耗尽前得到可行动终态的比例。对每个失败 run，还要记录 first divergence：第一个偏离契约、错误事实、权限拒绝或工具协议不满足的事件。仅看最后一个报错会把根因错归为“模型不够聪明”。

这种状态机的边界是，它不会自动判断复杂业务的价值，也无法从不完美观测中推出真相。它的作用是把不确定判断放在有回路、有证据、有恢复边界的地方。第五章讨论模型在该回路内怎样规划，而不把计划本身误当成执行事实。
