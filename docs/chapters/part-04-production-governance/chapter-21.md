---
layout: default
title: 第 21 章　可靠性工程：可恢复的状态、可解释的证据与可操作的停止
permalink: /chapters/part-04-production-governance/chapter-21/
part_home: /chapters/part-04-production-governance/
previous_page: /chapters/part-04-production-governance/chapter-20/
next_page: /chapters/part-04-production-governance/chapter-22/
---

# 第 21 章　可靠性工程：可恢复的状态、可解释的证据与可操作的停止

## 21.1 把 Agent 当成有副作用的分布式工作流

一个长期任务不能依赖进程、聊天数组或模型上下文一直存在。运行时应显式区分业务真相、执行状态、工作记忆、计划、证据、审批和预算；将每次外部调用前的意图、幂等键、版本和 deadline 持久化，再派发动作。工具返回以事件追加，状态由确定性 reducer 变更，业务系统的回执仍是事实来源。发生崩溃、重复投递、取消或版本升级时，系统先重新读取权限与当前业务状态，再决定恢复、补偿、等待或终止，而不是从旧 prompt 继续猜测。

对于单系统写入，只有当目标系统以业务幂等键或唯一事务 ID 持久、原子地去重，并能按该稳定 ID 查询写入结果时，幂等键与写后读才通常足够；客户端仅仅携带一个 key 并不能产生这种保证。若目标系统没有上述语义，就仍需在目标系统侧增加事务、唯一约束或与消息派发一致提交的 outbox。本地状态加消息可采用 transactional outbox；多个外部系统需要 saga 与补偿，并承认补偿未必恢复全部语义；不可逆动作必须把验证和审批放在不可逆点之前。超时也不是失败结论：它可能表示调用已在服务端成功但响应丢失，因此应先按事务 ID 查询状态而非盲重试。Temporal 等 durable execution 系统以持久事件历史与重放支持恢复；其模型强调 workflow 代码在重放时保持确定性，并将活动（activity）的外部副作用同 workflow 决策分开。无论使用何种框架，都必须自己定义业务幂等、权限重验和副作用语义。[Temporal workflow execution](https://github.com/temporalio/documentation/blob/main/docs/encyclopedia/workflow/workflow-execution/workflow-execution.mdx)

## 21.2 Trace 是运行证据，不是调试装饰

一个根 `run_id/trace_id` 应从用户/API 请求贯通编排、模型、检索、工具、审批与业务交易。为每个 span 保存身份与租户的伪名化标识、任务契约和风险等级、agent/prompt/model/参数版本、检索 query 与文档版本/ACL 结果、工具 schema 与参数摘要、策略理由码、审批、幂等键、错误/重试、token/成本/延迟、最终业务回执与数据保留等级。这样才能将“客户说没收到邮件”反查到哪个收件人、哪个审批和哪个工具版本。

OpenTelemetry 的 GenAI 语义约定可提供跨框架的模型、token、finish reason、消息和工具调用字段基础；Agent 相关语义约定截至 2026-08-19 仍在演进，应在内部以版本化映射层吸收变动，把实际采用的 tag 或 commit 及其 `schema_url` 写入 release manifest，而不把实验字段写死到所有查询和审计合同。核心 semantic-conventions 仓库自 v1.42 起已把 `gen_ai.*` 迁移到独立仓库；升级时要对旧、新 schema 做映射或阶段性双写，并用历史 trace 回放验证 emitter、collector、查询、告警和审计导出均兼容。开发中约定不能被表述为永久稳定的强制标准。[OpenTelemetry GenAI observability](https://opentelemetry.io/blog/2026/genai-observability/) [OpenTelemetry v1.42 迁移说明](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.42.0) [Agent conventions status](https://github.com/open-telemetry/semantic-conventions-genai/blob/main/docs/gen-ai/gen-ai-agent-spans.md)

可观测性与隐私之间必须有边界。完整原始 prompt、工具返回或模型推理文本未必需要全部保存，且可能引入敏感数据和知识产权风险。按照数据分类选择加密密封字段、哈希、结构化摘要或受控引用；记录访问审计、保留期限和删除例外。高风险任务的审计链还需要完整性保护，例如事件序号、不可变存储或哈希链，并让审计访问本身成为可观察事件。

## 21.3 重放、SLO 与五级停止

Replay 的目标是复原决策和故障，不是再次执行生产动作。低级重放只能查看输入/输出；更高等级还冻结 prompt、模型、工具 schema、检索快照和 feature flag；对写操作则以记录的工具返回、shadow target 或隔离模拟器代替生产凭证。一个系统应诚实标明哪些 run 无法完全重放，例如第三方网页、实时库存或人工电话的状态已变。把真实副作用为零作为隔离重放的验收条件，比“replay 成功率很高”更重要。

SLO 也应面向安全有效终态，而不是 HTTP 2xx。可定义有效任务成功率、正确允许/拒绝高风险动作比例、获得成功/明确降级/可行动人工接管的终态可用性、无重复副作用的恢复率、可重放覆盖率、质量漂移和每个安全验收任务的效率。阈值由后果、历史基线和错误预算共同决定；安全不变量不是平均可用性。错误预算耗尽时，冻结高风险发布、缩小权限或流量，并优先修复失败簇。

停止能力需要独立于模型和供应商。K1 feature flag 停单一租户/工具；K2 policy deny 阻断一类动作；K3 credential revoke 吊销能力；K4 release rollback 回到一致的已批准制品组合；K5 global kill 停 worker、冻结队列并转人工或只读。事故发生时先检测与分级，缩小 blast radius，撤销凭证，封存证据，在隔离环境重放，回滚已知良好版本，修复并补入回归/红队集，然后有限 canary 与复盘。每层停止都要定期演练，且不能要求 Agent 自己理解“请停止”。

## 21.4 团队状态与 WorkState 继承同一组可靠性语义

多智能体协作中的 TeamState 和 WorkState 不是例外的数据结构，它们同样由追加事件和确定性 reducer 生成。`work_unit_created`、`lease_granted`、`checkpointed`、`artifact_submitted`、`verification_failed`、`proposal_merged` 与 `cancel_requested` 等事件都要有唯一 ID、因果版本和幂等键。消息重复投递时，reducer 只能应用一次；投影损坏时，应从快照与后续事件重建，而不是要求各 worker 回忆自己的聊天历史。

lease 是暂时处理权，不是完成权。每次重新分配产生更高 fencing token，旧 worker 的迟到 checkpoint、回执或提交只能作为待对账证据，不能覆盖当前 WorkState。对可能已发生的外部副作用，恢复者先依据业务幂等键和权威查询确认世界状态，再决定接受、补偿或重派；“worker 已超时”本身不是可以安全重做写操作的证据。

团队重放必须冻结或版本化 Team Contract、WorkGraph、reducer、completion predicate、租约事件和 artifact 引用。重放用于恢复投影和解释决策，不能再次向生产目标发送 worker 原先的写操作。重放发现某个输入制品已失效时，只使依赖它的子图进入 `needs_replan`，而不是丢弃所有已验证分支。

取消与 kill 也必须进入持久状态。取消事件携带单调递增的取消代次，停止新派发，使未终结 WorkState 转入取消流程，并要求 worker 在下一个安全点保存诊断、撤销短期能力、报告未知副作用；仅发送一条取消消息不能证明传播完成。更高等级的 kill 会同时冻结队列、吊销凭证和阻止合并，但已经越过不可逆点的动作仍需对账或补偿。只有当 reducer 证明取消已经覆盖目标子图、未决写入已处理且必要制品已保留，控制面才能清理资源或报告团队终态。
