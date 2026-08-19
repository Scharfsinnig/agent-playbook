---
layout: default
title: "第 20 章　安全与权限：让错误输入不能扩大为错误行动"
permalink: /handbook/part-04-production-governance/chapter-20/
part_home: /handbook/part-04-production-governance/
previous_page: /handbook/part-04-production-governance/chapter-19/
next_page: /handbook/part-04-production-governance/chapter-21/
---

# 第 20 章　安全与权限：让错误输入不能扩大为错误行动

## 20.1 威胁的本质是控制流越界

Prompt injection 的危险不在于模型读到了一句粗鲁的文字，而在于来自网页、邮件、检索文档、工具返回或记忆的不可信数据影响了一个高价值 sink，例如发信、付款、权限变更、代码执行或向外部域名发送资料。系统提示和输入检测有价值，但它们都是概率性模型输入，不能成为授权边界。OWASP 的 2025 LLM Top 10 将提示注入、敏感信息披露、供应链、数据投毒、输出处理、过度代理和无界消耗列为主要风险；Agentic Security Initiative 进一步指出目标劫持、工具滥用、身份与特权滥用、供应链以及记忆/上下文投毒。它们适合转译为威胁建模和测试矩阵，并不是产品认证。[OWASP LLM Top 10 2025](https://genai.owasp.org/llm-top-10/) [OWASP Agentic Security Initiative](https://genai.owasp.org/initiatives/agentic-security-initiative/)

一个可执行的威胁模型从资产、入口、主体、能力和后果开始。资产包括个人信息、商业秘密、订单、代码仓库、支付额度、身份令牌和审计记录；入口包括用户输入、网页、PDF、RAG 文档、工具返回、第三方 MCP server 与持久记忆；主体包括最终用户、服务工作负载、子 Agent、审批者和供应商；后果包括泄露、越权、错误交易、持久化后门、远程代码执行和成本耗尽。红队的成功条件应是某个不变量真的被破坏，例如“含 canary secret 的字段到达未批准域名”，而非模型复述了攻击语句。

## 20.2 权限不属于模型，属于工具边界

每一个敏感工具调用都要能够说明：它代表谁，目的是什么，访问哪一个资源，在何时失效，允许的额度和后果是什么。实践中可用用户身份或工作负载身份换取短时、资源受限的 capability token；工具网关再依据主体、租户、动作、目的、数据标签、时间和风险环境执行 ABAC 或关系型授权。模型只能提出“调用 `create_refund`，金额 80 元”的候选，网关必须检查订单归属、退款政策、余额、审批、幂等键和当前预算，才可实际调用。共享长期管理员密钥会让授权、问责和撤销同时失效。

工具契约也不应停留在名称和自然语言描述。它应有严格输入/输出 schema、可选值、服务端租户过滤、前置/后置条件、超时、费用、幂等性、补偿、错误类型、数据类别与审计字段。不要把模型输出直接拼到 shell、SQL、URL 或 HTTP body；使用参数化查询、类型化 API、枚举和域名 allowlist。MCP 的 `readOnlyHint`、`destructiveHint`、`idempotentHint`、`openWorldHint` 是客户端提示，规范明确它们并非忠实行为保证，尤其不可信服务器的注释不能决定安全动作；截至本稿日期应固定所采用的 MCP 规范版本并在适配层升级。[MCP ToolAnnotations（2026-07-28）](https://modelcontextprotocol.io/specification/2026-07-28/schema)

高后果动作采用两阶段而不是“让模型再确认一次”。第一阶段生成结构化提议，包含对象、参数、影响范围、证据与预览；第二阶段在模型外进行策略检查，必要时将参数 hash、对象、范围与有效期绑定给人工审批；第三阶段以短时凭证和幂等键执行；最后通过写后读或独立回执验证。审批界面必须显示差异、收件人、金额、不可逆性和证据，不能只问“是否继续”。

## 20.3 数据、沙箱与供应链的三层隔离

不可信内容应携带来源与信任标签，在上下文中只作为事实候选而不能改变任务契约或权限。检索系统在 ingest 时记录 owner、ACL、版本、有效期和来源，在查询时再次以调用主体过滤；只在索引时过滤无法阻止权限变更后的泄露。长期记忆的写入面比读取面更危险：自动把网页摘要或模型反思写入记忆，会把一次注入持久化为未来任务的“组织规则”。因此写入先进入 quarantine，经过来源、结果、敏感性、用途和过期策略检查；敏感偏好需让用户可查看、更正和删除。

代码执行、浏览器自动化、文件转换和第三方插件应在临时、最小权限的环境运行：独立租户、只读根文件系统、无宿主 metadata 和 socket、网络 egress allowlist、资源与时长上限、一次性凭证。沙箱不是免罪符；若沙箱可访问通用云凭证或不限域的互联网，注入仍能把它当跳板。密钥留在 vault 或 HSM，按工具、环境和租户拆分，禁止出现在 prompt、镜像、向量库与普通日志；发生异常 egress 时应可立刻吊销。

供应链要包含模型、embedding、adapter、prompt 包、工具 schema、MCP server、容器、依赖、索引语料和评测资产。每个制品应有 owner、来源、许可/合同、版本或 digest、数据地域、测试证据和撤销开关；构建阶段检查锁定依赖、漏洞、秘密、IaC 与签名 provenance，运行时只加载批准的 digest。NIST SSDF 提供了把安全实践嵌入软件生命周期的通用框架，并已有面向生成式 AI 与双用途基础模型的社区 profile；它并不替代本组织的风险评估或行业规则。[NIST SP 800-218](https://csrc.nist.gov/pubs/sp/800/218/final) [NIST SSDF profiles](https://csrc.nist.gov/Projects/ssdf)
