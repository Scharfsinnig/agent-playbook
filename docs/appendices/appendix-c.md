---
layout: default
title: 附录 C：核心状态对象与指标字典
permalink: /appendices/appendix-c/
part_home: /appendices/
previous_page: /appendices/appendix-b/
next_page: /references/
---

# 附录 C：核心状态对象与指标字典

这一附录不是要求所有团队照搬同一套数据库表，而是给出一组必须在概念上分开的对象。很多 Agent 系统之所以难以调试，并不是缺少模型日志，而是把目标、状态、证据、模型消息、工具结果和长期记忆全都塞进同一个对话数组。对象边界一旦混乱，权限、重放、删除和学习归因都会随之混乱。

## C.1 任务契约 Task Contract

任务契约是自然语言请求与可执行系统之间的边界。它必须在 Agent 开始产生真实副作用前被建立，并在任务期间保持版本化。它不要求所有字段一开始都有值，但必须标出哪些字段缺失会阻止任务继续。

- `task_id`：全局唯一任务标识，用于关联状态、Trace、审批和业务回执。
- `requester` 与 `principal`：谁提出请求，系统实际代表谁行动。二者可能不同，例如员工代表公司账户提交申请。
- `purpose`：被批准的业务目的。用途不是一句宽泛的“帮助用户”，而应足以判断后续数据访问和动作是否越界。
- `resource_scope`：可读取或修改的租户、账户、目录、项目、时间范围和对象集合。
- `deliverables`：应交付的文档、答案、变更、回执或环境状态。
- `completion_predicates`：可以从外部证据验证的完成条件。例如“目标分支测试通过且生成指定提交”，而不是“模型认为代码已经改好”。
- `forbidden_effects`：无论模型如何判断都不得发生的动作，例如向未授权收件人发送、访问其他租户、删除原始数据。
- `required_evidence`：任务结束前必须取得的证据种类、来源数量、测试结果或人工签字。
- `autonomy_policy`：哪些动作可自动执行，哪些只能生成草稿，哪些需要绑定具体参数的审批。
- `budgets`：Token、模型费用、工具费用、步骤、墙钟时间、并发和风险暴露的上限及阶段保留额。
- `deadline`：绝对截止时间，而不只是每个调用各自的相对超时。
- `terminal_states`：明确区分成功、部分完成、失败、拒绝、取消、等待、阻塞和人工接管。
- `version`：任何目标、范围或权限变更都产生新版本，防止被工具内容或子 Agent 静默改写。

任务契约的关键指标不是“字段填得多不多”，而是当关键字段缺失、互相冲突或被后续输入尝试改写时，系统是否能稳定阻断并给出可理解的理由。

## C.2 运行状态 Run State

运行状态记录系统现在处于哪里，以及为什么能从一个状态进入另一个状态。建议至少区分 `received`、`clarifying`、`ready`、`planning`、`awaiting_authorization`、`executing`、`observing`、`verifying`、`waiting_external`、`compensating` 和多个终态。状态名可以不同，但不能让任意节点直接把任务改为“完成”。

运行状态通常包含当前契约版本、计划版本、待办步骤、已满足的完成谓词、未决假设、证据引用、预算余额、最近进展、重复签名、租约、截止时间、待审批动作、外部等待句柄及最后一个检查点。这里保存的是控制信息，不应复制整个业务数据库。订单是否支付、文件是否存在、工单是否关闭等业务真相仍应从权威系统读取；运行状态只保存其引用、版本和最近一次经过验证的观察。

每次状态转移都应写成追加事件，至少记录前态、动作、观察、策略理由码、后态、时间、执行者与制品版本。这样才能在事故后回答“第一个错误转移发生在哪里”，而不是只看到最终一段貌似合理的文字。

## C.3 计划步骤 Plan Step

计划不是自由文本待办清单，而是一组可验证的子目标。每个步骤至少需要：步骤 ID、要产生的结果、前置条件、依赖、允许使用的工具、风险等级、预算、局部验收谓词、失败分类、补偿方式和失效条件。环境观察推翻前提时，相关步骤必须被标记失效，不能继续沿旧计划执行。

计划应允许局部承诺。对稳定且低风险的部分，可以提前建立较长路径；对依赖外部搜索、用户输入或实时环境的部分，只计划到下一个可验证检查点。这样既避免“一次生成二十步然后盲目照做”，也避免每一步都从零规划造成的局部贪心和上下文浪费。

## C.4 动作提案 Action Proposal

模型输出的工具调用不应直接等同于获准执行。动作提案是二者之间的显式对象，通常包含动作类型、工具与版本、结构化参数、预期效果、目标资源、风险级别、所依据的证据、候选替代、预计成本、幂等键、所需权限和审批要求。

执行前门控读取动作提案，而不是解析一段自然语言。门控通过后生成不可变的执行请求；若参数、资源版本、金额或收件人发生变化，旧审批自动失效。这个边界能把“模型擅长提出做什么”与“系统有权决定能否做”分开。

## C.5 工具契约与动作回执 Tool Contract / Action Receipt

工具契约需要说明输入 schema、输出 schema、前置条件、后置条件、副作用类型、身份与权限、费用、超时、错误分类、幂等语义、并发语义、补偿动作以及输出可信度。名称和 description 只是帮助模型选择的提示，不能代替服务端访问控制。

动作回执则记录服务端真实执行结果，包括工具调用 ID、业务事务 ID、请求参数哈希、资源执行前后版本、时间、状态、错误类别、可否重试、产生的副作用、验证结果和补偿引用。网络超时时，回执状态应允许表示“结果未知”，系统先查询业务状态而不是盲目重试。否则一次看似普通的重试就可能变成重复扣款、重复发信或重复删除。

## C.6 证据记录与主张账本 Evidence Record / Claim Ledger

证据记录描述信息从哪里来、在什么时间和权限下取得、经过了什么转换，以及它支持或反驳哪些主张。最低字段包括来源 URI 或业务对象、来源类型、作者或系统、抓取时间、有效时间、版本、租户与 ACL、内容哈希、信任级别、转换链和引用定位。

主张账本把最终交付中的关键事实拆成 `claim → evidence → status → confidence`。`status` 至少区分已验证事实、基于证据的推断、未验证假设和建议。这样做的目的不是把所有推理过程永久保存，而是让关键结论能够被外部重建，并防止流畅的模型文字把推断伪装成事实。

## C.7 审批授权 Approval Grant

有效审批必须绑定具体任务、契约版本、动作类型、参数哈希、目标对象、最大影响、审批人、授权依据、创建时间和过期时间。只显示一句“是否确认”而不展示对象、金额、收件人、差异和风险，不构成有信息量的审批。

审批是一次有限能力授予，不是允许 Agent 随后改变参数的空白支票。恢复长任务时，系统还要检查审批是否过期、资源状态是否变化以及批准人当时看到的预览是否仍与实际动作一致。

## C.8 记忆记录 Memory Record

长期记忆至少需要区分事实、用户明确偏好、历史经历摘要和可执行技能。每条记忆应包含主体、租户、用途、来源、提议者、验证状态、置信度、适用范围、创建与最后验证时间、有效期、访问控制、支持事件、冲突关系、替代关系和删除标记。

建议采用 `proposed → quarantined → verified → active → superseded/expired/deleted` 的生命周期。模型总结、网页指令和单次对话内容不能直接进入 active。用户确认且只影响本人的可删除偏好可以较快生效；会改变跨用户行为的技能、记忆提取器或召回策略则属于产品制品变更，需要评测和分批发布。

## C.9 学习候选 Learning Candidate

学习候选不是原始 Trace 的别名。它应说明目标能力、任务分布、结果验证方式、候选输入与目标、所依据的轨迹片段、归因证据及置信度、数据用途与适用合法基础、敏感信息处理、策略/模型/工具版本、采样概率、奖励延迟、是否为合成数据、与评测集的污染检查以及质量审核状态。

只有这些信息齐全，团队才能判断某个失败应修工具、检索还是模型，也才能在训练后发现性能变化来自真正学习还是数据泄漏。观察日志通常只能提供相关性和归因线索；除非有随机化或可验证的干预，或针对特定策略价值满足明确的可识别假设（完整的可观测决策上下文、正确记录的 propensity、positivity/overlap、一致性及无未观测混杂等），否则不能把事后叙事当作因果标签。

## C.10 发布清单 Release Manifest

每次发布需要把会改变 Agent 行为的全部制品绑定成一个可回滚版本：基础模型、adapter、tokenizer、量化与推理配置、系统提示、工作流/状态机、工具目录与 schema、策略、检索索引、记忆 schema、路由、验证器、Judge、依赖和安全规则。只记录“模型版本”不足以复现一个 Agent。

发布清单还应关联训练数据版本、评测报告、适用用例、风险接受、shadow/canary 阈值、最大暴露、自动回退条件、人工停止人和计划失效日期。这样，当结果漂移时，团队能判断究竟是模型变化、索引更新、工具升级还是策略热改造成。

## C.11 结果指标

**经验证任务成功率（verified task success rate）**的分母是满足入组条件的任务，分子是完成谓词经外部验证全部满足的任务。它不同于模型自报完成率，也不应把被拒绝、等待和用户取消全部混为失败。报告时要同时给出终态分布和任务难度切片。

**错误完成率（false-complete rate）**衡量 Agent 宣布成功但环境未满足完成谓词的比例。这个指标对会产生真实动作的 Agent 特别关键，因为一段令人信服的回复可能掩盖根本没有下单、没有写入或测试未通过。

**安全可接受任务成本（cost per safe accepted task）**把模型、工具、检索、基础设施、人工审批、返工和预期错误损失纳入同一分母。只看每次模型调用费用会奖励那些调用便宜却制造大量下游清理工作的方案。

## C.12 轨迹与循环指标

**进展向量（progress vector）**不应压成单一模型分数。可以分别记录新增可信证据、未完成子目标减少、环境状态变化、关键不确定性下降、风险降低和验证覆盖提升。连续多轮所有分量均无变化，才是无进展的重要信号。

**循环率（loop rate）**需要按语义重复、状态重复、周期振荡和同错重试分类。只统计连续相同字符串会漏掉“换一种说法做同一件事”；只统计总步数又会误伤确实需要长程执行的任务。

**重规划有效率**应衡量触发重规划后任务是否重新取得进展，而不是只统计重规划次数。频繁重规划可能意味着适应性强，也可能说明计划质量差、环境观察不可靠或前提从未被显式管理。

**停止决策质量**需要同时看正确早停、过早停止和过晚停止。降低平均步骤数不是单独目标；如果因此增加漏做验证或未完成任务，就只是把成本从计算转移到了业务错误。

## C.13 工具与执行指标

**动作有效率**衡量提案通过 schema、权限、资源版本和业务规则后被安全执行的比例。应把模型参数错误、策略拒绝、资源冲突、工具故障和结果未知分开，否则无法定位改善责任。

**重复副作用率**统计同一业务意图产生多次不可预期写入的比例。目标可以是在给定覆盖和观察窗口内零事件，但必须同时报告样本量、故障注入范围和对账方法，不能把“未观察到”写成绝对不会发生。

**模糊结果恢复率**衡量网络超时或客户端失联后，系统通过幂等键、事务 ID、状态查询和对账恢复真实结果的能力。这比“API 重试成功率”更能反映资金、工单和通知类动作的可靠性。

## C.14 人机协同指标

**接管精确率**衡量发起人工接管的任务中有多少确实需要人；**接管召回率**衡量所有本应由人处理的高风险或不确定任务中有多少被及时识别。只追求少打扰会牺牲召回，只追求安全又可能把 Agent 退化成不断请求确认的表单。

还应记录人从接管到理解上下文的时间、提供的信息是否足以决定、批准后参数变化率、误批准与误拒绝、人工修改是否真正提高结果，以及同类接管能否通过改进契约或工具被逐步消除。

## C.15 学习与发布指标

模型或策略更新至少要分别报告目标能力增益、旧能力回归、安全行为、经济性和校准/稳定性。一个总分会掩盖某些人群、语言、工具或风险场景的退化。对随机 Agent 还应在同一任务上运行多次，报告均值、方差、最差切片和置信区间。

使用离线策略评估时，除估计收益外必须报告行为策略重叠、有效样本量和置信区间。新策略选择了日志中从未出现的动作时，重要性加权无法凭空创造证据；这部分必须进入沙箱、shadow 或受限 canary，而不能用离线分数直接放行。

持续学习还应跟踪遗忘矩阵：按能力、用户群、时间、语言和风险切片比较新旧版本。所谓“安全违规为零”只能表示在明确攻击集、样本量和时间窗口内没有观察到违规，需要同时给出覆盖范围和统计上界。

## C.16 团队契约 Team Contract

Team Contract 是 Task Contract 在多智能体执行中的受限展开，不能放宽父契约的权限、预算、期限或禁止动作。建议至少包含以下字段。

- `team_contract_id`、`task_contract_id` 与 `version` 关联团队契约、父任务契约和每次有效变更。
- `effective_at`、`supersedes`、`change_type`、`cutover_mode` 与 `affected_work_units` 规定版本何时生效、替代谁以及怎样处理在途工作。权限收紧、取消或安全约束加严的 `effective_at` 不得晚于变更被接受的时刻，并必须立即递增契约/取消代次、撤销能力及 fence/cancel 受影响的在途 WorkUnit；只有显式兼容且未受影响的工作才可继续。
- `topology`、`members` 与 `roles` 描述已经选定的协作结构、成员身份、职责和替补关系；角色名称不自动授予能力。
- `delegation_rules`、`capability_ceiling` 与 `member_capabilities` 证明子能力是父任务能力的真子集或相等受限集，并记录谁可创建、取消或重派 WorkUnit。
- `shared_artifact_policy`、`message_policy` 与 `visibility_scope` 规定可以共享哪些版本化制品、哪些消息能转成事件，以及每个成员可见的数据范围。
- `verification_authority`、`merge_authority` 与 `completion_predicate_version` 标明谁能验证、谁能提交共享真相，以及团队完成判定使用哪个版本。
- `team_budget`、`deadline`、`retry_policy`、`handoff_policy`、`cancel_policy` 与 `cleanup_policy` 规定总成本、期限、重试/交接上限、取消传播和资源保留。
- `controller_id`、`controller_lease` 与 `failover_owner` 记录当前控制器、其租约和故障接管责任。

## C.17 工作图与工作单元 WorkGraph / WorkUnit

WorkGraph 表示逻辑依赖，不表示文件工作区。只有严格层级分解才可另称 WorkTree。WorkGraph 至少包含 `work_graph_id`、`team_contract_version`、图版本、节点和边集合、汇合规则、wait-for graph、失效传播规则、取消代次、创建者、创建时间和 superseded 版本。

每个 WorkUnit 建议包含：

- `work_unit_id`、`parent_ids`、`dependency_ids` 与 `affected_subgraph`，用于定位依赖、重规划和取消传播范围。
- `objective`、`input_artifact_refs`、`input_snapshot_version`、`deliverable_schema` 与 `local_completion_predicates`，用于证明该单元可以独立验收。
- `allowed_tools`、`data_scope`、`allowed_write_set`、`risk_level` 与 `capability_token_ref`，用于门控局部能力。
- `budget`、`deadline`、`priority`、`max_attempts`、`fallback` 与 `escalation_owner`，用于限制重试、交接和成本。
- `work_state_id`、`owner`、`lease_id`、`artifact_refs`、`merge_proposal_ids` 与 `conflict_case_ids`，用于关联执行和结果。

## C.18 团队/群组状态 Team/Swarm State 与 reducer

同一对象可以按实现命名为 TeamState 或 SwarmState，但名称不表示系统必然属于经典群体智能。它是事件流的可恢复投影，至少包含 `team_id`、`team_contract_version`、`work_graph_version`、各 WorkUnit 的状态索引、当前控制器及其 fencing token、共享 artifact 引用、未决 Merge Proposal、Conflict Case、预算余额、deadline、取消代次、完成谓词版本与评估结果、最近事件序号、快照版本和终态。

team reducer 的发布对象应记录 `reducer_version`、可接受事件类型、每类事件的幂等键、状态转换前置条件、冲突处理、投影 schema、迁移版本和重放测试摘要。team completion predicate 应记录 `predicate_version`、必要 WorkUnit 集、必要 artifact/业务回执、允许的部分完成条件、未决冲突规则、取消和失败的终态映射以及最近验证时间。worker 的自然语言自报不得直接修改这两个对象。

## C.19 可恢复工作状态 WorkState

WorkState 是本手册定义的可恢复工作单元状态，不声称是跨框架标准。建议字段包括 `work_state_id`、`work_unit_id`、`state`、`state_version`、`team_contract_version`、`input_snapshot`、`owner`、`attempt`、`lease_id`、`fencing_token`、`last_heartbeat`、`checkpoint_refs`、`artifact_refs`、`command_or_tool_receipts`、`budget_consumed`、`blocked_reason`、`failure_signature`、`cancel_generation`、`recovery_point`、`cleanup_deadline` 和 `last_event_id`。

主状态按 `queued → leased → running → submitted → verifying → merged → done` 推进。侧状态至少包括 `blocked`、`retryable_failed`、`needs_replan`、`escalated`、`cancelled` 和 `expired`。每个 actor 都只提交携带契约版本、取消代次、fencing token、幂等键和证据引用的事件；授权 reducer 校验允许前态、当前 token、当前契约与事件证据后，才应用状态转换。worker 不能直接写任何 WorkState，验证/合并服务也以带回执事件请求 `verifying → merged`，而不绕过 reducer。

代码 WorkState 还应增加 `repo_id`、`baseline_commit`、`worktree_id`、规范化 worktree 路径、唯一分支、目标分支、允许路径、环境或容器 digest、文件变更摘要、候选 commit、测试回执和 quarantine 状态。这些字段支持第 26 章的 Git worktree 创建、恢复、验证与清理流程。

## C.20 制品与协作事件 Artifact / Message / Event

Artifact 至少包含 `artifact_id`、`artifact_type`、`content_digest`、`storage_ref`、`schema_version`、`producer`、`work_unit_id`、`team_contract_version`、`input_refs`、`provenance`、`created_at`、`scope`、`verification_status` 和 `supersedes`。内容变化必须产生新 ID 或版本，不能原地覆盖已经被下游消费的制品。

Message 可包含 `message_id`、sender、recipient、conversation/subject、payload ref、发送时间和 TTL，但它默认只是通知。只有授权入口把它转换成 Event 后才可驱动状态。Event 至少包含 `event_id`、`event_type`、`aggregate_id`、`causal_parent_ids`、`idempotency_key`、`actor`、`contract_version`、`cancellation_generation`、`fencing_token`、payload/artifact refs、发生时间、接收时间和事件序号。取消、完成、租约与合并必须以 Event 表示，不能只存在于聊天文本。

## C.21 租约 Lease

Lease 建议包含 `lease_id`、`work_unit_id`、`owner`、`issued_at`、`expires_at`、`heartbeat_interval`、`last_heartbeat`、`fencing_token`、`capability_refs`、`max_renewals`、`renewal_count`、`revoked_at`、`revoke_reason` 与 `superseded_by`。fencing token 在重新分配时单调递增，持久层拒绝低于当前 token 的 checkpoint、提交或状态写入。

过期并不证明外部动作没有发生。租约对象还应关联待对账的幂等键、业务事务 ID、最后持久检查点和迟到回执。旧 owner 的结果可以进入诊断或新的 Merge Proposal，但必须重新验证，不能按最后到达者覆盖当前结果。

## C.22 合并提案与冲突案件 Merge Proposal / Conflict Case

Merge Proposal 至少包含 `proposal_id`、`work_unit_id`、作者与 fencing token、`target_ref`、`target_version`、输入和候选 artifact、change digest、依赖与前置条件、允许写集、验证/测试回执、风险、回滚方式、创建时契约版本、合并时当前契约版本、创建时间、状态、verifier 和最终 merge receipt。合并服务必须按当前生效的 Team Contract 重验权限、安全约束和完成谓词；`submitted`、`verified` 与 `merged` 必须是不同状态，存在 commit 或获得高评分都不等于已集成。

Conflict Case 至少包含 `conflict_case_id`、涉及的 proposal/artifact/claim、冲突类型、冲突字段或写集、各方证据与版本、受影响 WorkUnit/子图、检测事件、冻结范围、可用确定性规则、仲裁 owner、deadline、决定、理由、采用和拒绝的 artifact、后续重规划以及关闭时间。没有确定性规则时，简单多数或最后一个 Agent 的意见不能关闭冲突。

## C.23 团队协作指标

团队指标必须与相同任务分布、权限和验证口径下的强单 Agent 基线比较，并按拓扑、难度、风险和故障类型切片。最低指标集包括：

- 结果指标报告经验证成功率、错误完成率、单位安全验收任务成本和端到端 P95。
- 协调指标报告通信 token/总 token、协调等待延迟、重复 WorkUnit 率和 Merge Proposal 冲突率。
- 所有权指标报告 orphan task 率、未归属 artifact 率、lease 过期率、重新分配率和迟到结果率。
- 停止与恢复指标报告取消传播覆盖率/时间、故障恢复时间、控制器 failover 时间、补偿完成率和遗留未知副作用数。
- 证据指标报告独立证据比例、相关错误率、盲复核覆盖率以及需要人工仲裁的 Conflict Case 比例。
- 人机指标报告接管率、handoff packet 理解时间、人工返工量、人工修改后的接受率和合并后回滚率。

这些指标需要同时记录分母、观察窗口、样本量和版本。多个成员结论一致而来源相同，不应提高独立证据比例；任务因 worker 自报完成但未通过团队 completion predicate，不应计入经验证成功。

## C.24 本体状态与语义映射 OntologyState / Semantic Mapping

`OntologyState` 是已发布语义契约在某一版本的不可变快照，不是知识库内容、聊天记忆或某个 worker 可原地修改的共享 JSON。它至少包含以下字段。

- `ontology_id`、`namespace`、`domain_scope`、`owner`、`version`、`snapshot_id`、`effective_at`、`valid_until`、`supersedes`、`compatibility` 与 `migration_plan_ref`，用于确定快照身份、责任、适用域、生效窗口和迁移路径。
- `concepts`、`entity_types`、`relations`、`event_types` 与 `semantic_actions`，用于登记稳定 ID、规范名称、定义、允许属性、关系方向、域和值域、时间和辖区语义。
- `identity_rules`、`alias_rules`、`equivalence_rules` 与 `entity_resolution_policy`，用于区分名称相似、局部别名、近似映射和经批准的实体等同。候选相似度不能自行改写身份。
- `assertion_statuses`、`completeness_scopes` 与 `open_closed_policies`，用于区分已验证、候选、冲突、撤销和未知，并明确哪些有限数据集可以按闭合规则检查；缺少开放世界断言时不得默认推为否。
- `provenance_policy`、`confidence_policy`、`validation_status`、`acl_scope` 与 `purpose_scope`，用于保留定义、映射和断言的来源、责任、适用权限与用途。PROV-O 的 Entity、Activity、Agent 及 revision 关系可用于表达快照、变更活动和责任血缘，但溯源自洽不等于内容真实或发布获批。[R63]({{ '/references/#r63' | relative_url }})
- `mapping_proposal_ids`、`conflict_case_ids`、`local_extensions` 与 `deprecated_terms`，用于关联待决映射、未解决冲突、局部词汇的范围/TTL 和迁移中的弃用项。

本体主生命周期为 `proposed → reviewed → validated → active → superseded/deprecated/retired`。进入 `active` 后的 snapshot 内容不可变；修正必须产生新版本，并保留旧快照、差异、批准记录和回滚关系。`validated` 只表示通过预定的 schema、逻辑、形状、兼容性和回放检查，不自动表示业务事实正确。发布者必须是 Team Contract 或组织控制面指定的 authority；LLM、worker、检索器和实体解析器只能提交带证据的变更提案。

每个 `SemanticAction` 建议包含 `semantic_action_id`、输入/输出类型、`preconditions`、`postconditions`、`read_set`、`write_set`、影响范围、`reversibility`、`risk_level`、`required_capabilities`、`tool_mapping_version`、幂等/补偿要求和 `verifier_ref`。工具名称变化可以保持语义动作 ID 不变；若前置条件、副作用或验证标准变化，则必须评估为新语义版本，不能只修改描述文本后继续执行旧计划。

`Semantic Mapping Proposal` 至少包含源/目标概念或实体 ID、源/目标快照、映射类型、适用范围、证据与反例、置信度、提出者、影响分析、建议迁移和状态。它经过 `proposed → validated → accepted/rejected/needs_human`，只有被有权 owner 接受后才进入新快照。实体合并、概念拆分、关系方向改变、动作语义改变或 capability 扩大必须要求人工批准；旧 artifact 继续引用原快照，不得批量覆写历史含义。

Task Contract、RunState、WorkUnit、Artifact、Message/Event、Merge Proposal 和 Release Manifest 都应引用各自使用的 `ontology_snapshot_id`。Release Manifest 还应绑定实体解析器版本、别名/映射集、语义动作—工具映射、迁移器、验证器和回放报告。运行恢复或跨版本合并时，系统先判断快照兼容性；无法证明兼容，就把受影响对象转为 `stale_version` 或 Conflict Case，停止相关提交并重新解析，而不是让新版本静默解释旧制品。
