---
layout: default
title: 参考资料
permalink: /references/
part_home: /appendices/
previous_page: /appendices/appendix-c/
---

# 参考资料

本页集中收录正文所用的论文、项目规范、官方文档和监管原文。每条只界定可支持的论断与不能外推的边界；软件、协议与法规类资料均以 2026-08-19 为核验时点，实施时仍需固定版本并重新核对。

## Agent 闭环、上下文与可恢复执行

### R01 · Building Effective Agents {#r01}

Anthropic：[Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)。用于区分预定路径的 workflow 与由模型动态选择路径的 agent；不证明任一框架已具备业务事务或授权能力。

### R02 · ReAct {#r02}

Yao 等：[ReAct: Synergizing Reasoning and Acting in Language Models](https://arxiv.org/abs/2210.03629)。用于说明推理、行动与环境观察可交替组织；不提供权限、事务或完成判定。

### R03 · Effective Context Engineering {#r03}

Anthropic：[Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)。用于说明每次推理的上下文是按当前决策编译的有限输入；不代替独立的持久状态与访问控制。

### R04 · AgentDojo {#r04}

Debenedetti 等：[AgentDojo](https://arxiv.org/abs/2406.13352)。用于研究工具使用环境中的间接提示注入与防御；不证明单一过滤器可成为授权边界。

### R05 · LangGraph 状态、中断与记忆 {#r05}

LangChain：[LangGraph overview](https://docs.langchain.com/oss/python/langgraph/overview)、[Persistence](https://docs.langchain.com/oss/python/langgraph/persistence)、[Memory](https://docs.langchain.com/oss/python/langgraph/add-memory)、[Persistence 源文档](https://github.com/langchain-ai/docs/blob/main/src/oss/langgraph/persistence.mdx)、[time travel](https://langchain-ai.github.io/langgraph/concepts/time-travel/?h=time+travel) 与[interrupts](https://langchain-ai.github.io/langgraph/how-tos/human_in_the_loop/breakpoints/)。这些页面说明检查点、thread/store 和中断恢复的框架语义；外部副作用、业务幂等和删除治理仍由应用负责。

### R06 · Model Context Protocol 2026-07-28 {#r06}

MCP 项目：[2026-07-28 发布说明](https://blog.modelcontextprotocol.io/posts/2026-07-28/)、[正式规范](https://modelcontextprotocol.io/specification/2026-07-28) 与[Schema Reference](https://modelcontextprotocol.io/specification/2026-07-28/schema)。用于核对该时点的无状态核心、扩展和工具注释；协议互操性不等于应用状态、权限或事务语义。

### R07 · Temporal 持久执行 {#r07}

Temporal：[Workflows](https://docs.temporal.io/workflows)、[SDK Architecture](https://github.com/temporalio/documentation/blob/main/docs/encyclopedia/architecture/temporal-sdks.mdx)、[Workflow Execution](https://github.com/temporalio/documentation/blob/main/docs/encyclopedia/workflow/workflow-execution/workflow-execution.mdx) 与[AI FAQ](https://go.temporal.io/platform-hub/faqs)。用于核对事件历史、确定性重放与 Activity 副作用边界；不保证业务幂等或模型判断正确。

### R08 · Event Sourcing 与恢复模式 {#r08}

Microsoft Azure Architecture Center：[Event Sourcing](https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing)、[Asynchronous Request-Reply](https://learn.microsoft.com/en-us/azure/architecture/patterns/asynchronous-request-reply) 与[Compensating Transaction](https://learn.microsoft.com/en-us/azure/architecture/patterns/compensating-transaction)。用于说明追加事件、乐观并发、幂等投影、异步查询与补偿边界；具体业务不变量仍需单独设计。

### R09 · Track-and-Stop {#r09}

Garivier 与 Kaufmann：[Optimal Best Arm Identification with Fixed Confidence](https://proceedings.mlr.press/v49/garivier16a.html)。用于说明固定置信度最佳臂识别的采样与停止；不能被当作通用业务完成谓词。

### R10 · Agent 评测对象 {#r10}

Anthropic：[Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)。用于区分 task、trial、grader、transcript、outcome 和 harness；不规定特定业务的放行阈值。

### R11 · Reflexion {#r11}

Shinn 等：[Reflexion](https://arxiv.org/abs/2303.11366)。用于研究在外部反馈下利用文本反思调整后续轨迹；模型自评不因此成为事实验证。

## 多智能体、协作与隔离工作区

### R12 · Swarm Intelligence 经典边界 {#r12}

Bonabeau、Dorigo 与 Theraulaz：[Swarm Intelligence: From Natural to Artificial Systems](https://doi.org/10.1093/oso/9780195131581.001.0001)。用于界定基于局部信息和简单交互的经典群体智能；不宜将所有 LLM 多角色编排都归入该范畴。

### R13 · OpenAI Agents 编排 {#r13}

OpenAI：[Agents SDK](https://developers.openai.com/api/docs/guides/agents)、[Running agents](https://developers.openai.com/api/docs/guides/agents/running-agents)、[Orchestration](https://developers.openai.com/api/docs/guides/agents/orchestration) 与[Guardrails and human review](https://developers.openai.com/api/docs/guides/agents/guardrails-approvals)。用于区分 manager 将专家当工具调用与 handoff 转移当前控制的编排形式；SDK 并不提供组织的业务事务或最终责任。

### R14 · AutoGen Core 与 Swarm {#r14}

Microsoft AutoGen：[Core API](https://microsoft.github.io/autogen/stable/user-guide/core-user-guide/index.html)、[Teams](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/tutorial/teams.html) 与[Swarm](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/swarm.html)。用于核对 actor/消息基础、团队拓扑及 Swarm handoff 约束；其中并行工具调用可产生多个 handoff 的限制不能靠角色提示消除。

### R15 · Google Agent Development Kit {#r15}

Google：[ADK 多智能体介绍](https://developers.googleblog.com/agent-development-kit-easy-to-build-multi-agent-applications/) 与[workflow 文档](https://github.com/google/adk-docs/blob/main/docs/workflows/index.md)。用于说明确定性 workflow agents 可与模型驱动的 transfer 共存；不证明组合后自动具有恢复或授权语义。

### R16 · CrewAI {#r16}

CrewAI：[Official documentation](https://docs.crewai.com/index)。用于核对 crew 与 flow 的实现边界；不把框架层状态等同于完整的业务控制面。

### R17 · Git Worktree {#r17}

Git 项目：[git-worktree 官方手册](https://git-scm.com/docs/git-worktree)。用于核对主工作树、linked worktree、独立 `HEAD`/index 与共享仓库数据的语义；它不是安全沙箱、任务图或合并授权系统。

### R18 · Cascading Failures {#r18}

Google SRE：[Addressing Cascading Failures](https://sre.google/sre-book/addressing-cascading-failures/)。用于说明无限重试会放大负载，以及指数退避、jitter 和重试预算的作用；不定义具体 WorkUnit 的可重试性。

### R19 · Deadlock Conditions {#r19}

Coffman、Elphick 与 Shoshani：[System Deadlocks](https://doi.org/10.1145/356586.356588)。用于说明死锁条件与等待依赖的系统化分析；具体的断环优先级仍必须由任务契约决定。

## 检索、提示优化与参数训练

### R20 · Retrieval-Augmented Generation {#r20}

Lewis 等：[Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks](https://arxiv.org/abs/2005.11401)。用于说明参数化生成器与显式非参数记忆的结合；向量召回不证明授权或事实蕴含。

### R21 · OpenAI Responses Tools {#r21}

OpenAI：[Responses API tools reference](https://platform.openai.com/docs/api-reference/responses/create#responses_create-tools)。用于核对工具调用的结构化接口；模型产生的参数仍需由应用验证。

### R22 · DSPy {#r22}

Khattab 等：[DSPy](https://arxiv.org/abs/2310.03714)。用于把提示和模块组合视为可评测程序的优化问题；不能绕过独立任务集与发布门禁。

### R23 · GEPA {#r23}

Agrawal 等：[GEPA](https://arxiv.org/abs/2507.19457)。用于了解借助反思式文本反馈优化系统组件的研究路线；不证明生产轨迹可不经治理直接改写系统。

### R24 · LoRA {#r24}

Hu 等：[LoRA](https://arxiv.org/abs/2106.09685)。用于说明冻结基座权重并学习低秩增量的参数高效适配方法；不证明它适合每个任务。

### R25 · QLoRA {#r25}

Dettmers 等：[QLoRA](https://arxiv.org/abs/2305.14314)。用于说明在量化冻结基座上训练 LoRA adapter 的方法和显存权衡；具体硬件结果不应外推到所有模型与内核。

### R26 · Direct Preference Optimization {#r26}

Rafailov 等：[Direct Preference Optimization](https://arxiv.org/abs/2305.18290)。用于说明一种直接利用偏好对优化策略的目标；偏好胜率不证明事实或工具结果正确。

### R27 · InstructGPT {#r27}

Ouyang 等：[Training language models to follow instructions with human feedback](https://arxiv.org/abs/2203.02155)。用于说明示范、偏好排序、奖励模型和 RL 的代表性流程；论文结果受所用 prompt 分布和人评条件限制。

### R28 · Knowledge Distillation {#r28}

Hinton、Vinyals 与 Dean：[Distilling the Knowledge in a Neural Network](https://arxiv.org/abs/1503.02531)。用于说明用教师软目标训练学生模型的经典方法；不保证长链工具行为可完全复制。

### R29 · Proximal Policy Optimization {#r29}

Schulman 等：[Proximal Policy Optimization Algorithms](https://arxiv.org/abs/1707.06347)。用于说明通过裁剪代理目标限制 on-policy 更新的方法；不解决奖励错配或高成本采样。

### R30 · DeepSeekMath / GRPO {#r30}

Shao 等：[DeepSeekMath](https://arxiv.org/abs/2402.03300)。用于核对 GRPO 的组内相对优势构造和降低 critic 内存开销的动机；它仍依赖可靠奖励与组内方差。

### R31 · DeepSeek-R1 {#r31}

DeepSeek-AI：[DeepSeek-R1](https://arxiv.org/abs/2501.12948)。用于了解大规模可验证奖励下的 RL 和冷启动训练组合；不能将数学或代码结果直接外推到开放业务任务。

## Bandit、强化学习与持续改进

### R32 · UCB {#r32}

Auer、Cesa-Bianchi 与 Fischer：[Finite-time Analysis of the Multiarmed Bandit Problem](https://link.springer.com/article/10.1023/A:1013689704352)。用于说明 UCB 类方法的探索—利用与累计遗憾目标；不定义 Agent 何时完成业务任务。

### R33 · LinUCB {#r33}

Li 等：[A Contextual-Bandit Approach to Personalized News Article Recommendation](https://arxiv.org/abs/1003.0146)。用于说明线性上下文 Bandit 和离线回放的经典应用；新策略的支持度仍必须单独检查。

### R34 · Doubly Robust Policy Evaluation {#r34}

Dudík 等：[Doubly Robust Policy Evaluation and Learning](https://arxiv.org/abs/1103.4601)。用于说明结合 reward 模型与倾向加权的离线评估；它仍要求可观测决策上下文、正确 propensity 和 overlap。

### R35 · Conservative Q-Learning {#r35}

Kumar 等：[Conservative Q-Learning](https://arxiv.org/abs/2006.04779)。用于说明在离线 RL 中抑制对数据支持外动作过度乐观的思路；不会凭空创造缺失的覆盖证据。

### R36 · Diversity Is All You Need {#r36}

Eysenbach 等：[Diversity Is All You Need](https://openreview.net/forum?id=SJx63jRqFm)。用于说明通过技能与访问状态的可区分性进行无监督技能发现；多样性不等于安全或业务有用。

### R37 · Constitutional AI {#r37}

Bai 等：[Constitutional AI](https://arxiv.org/abs/2212.08073)。用于说明利用人类编写的原则和 AI 反馈减少某些人工标注的训练方式；该方法仍有外部目标与奖励信号。

### R38 · Curiosity-driven Exploration {#r38}

Pathak 等：[Curiosity-driven Exploration by Self-supervised Prediction](https://proceedings.mlr.press/v70/pathak17a.html)。用于说明以自监督特征预测误差构造内在奖励；随机不可控观测可导致高误差而非有价值探索。

### R39 · Never Give Up {#r39}

Badia 等：[Never Give Up](https://arxiv.org/abs/2002.06038)。用于了解情景新颖性与长期探索的组合；不证明新颖行为可直接进入真实系统。

### R40 · Voyager {#r40}

Wang 等：[Voyager](https://arxiv.org/abs/2305.16291)。用于研究开放环境中自动课程、代码技能库与环境反馈的组合；其结果不直接证明高后果任务可自主运行。

### R41 · Dreamer 系列 {#r41}

Hafner 等：[DreamerV2](https://arxiv.org/abs/2010.02193) 与[DreamerV3](https://arxiv.org/abs/2301.04104)。用于说明在潜空间动态模型中进行想象学习的世界模型路线；不应与语言模型的一般知识等同。

### R42 · Specification Gaming {#r42}

Google DeepMind：[Specification gaming](https://deepmind.google/blog/specification-gaming-the-flip-side-of-ai-ingenuity/)。用于说明策略可以利用可见目标的漏洞得分；不把案例列表当作对任一新系统的完整威胁模型。

### R43 · Reward Tampering {#r43}

Anthropic：[Reward tampering](https://www.anthropic.com/research/reward-tampering)。用于研究模型干预奖励过程而非完成目标的风险；不证明隐藏单个奖励函数就能消除该类风险。

### R44 · Process Supervision {#r44}

Lightman 等：[Let’s Verify Step by Step](https://arxiv.org/abs/2305.20050)。用于说明在特定数学任务上的过程监督研究结果；不能把语言上合理的中间步骤当作普遍正确。

### R45 · Agent Lightning {#r45}

Jiang 等：[Agent Lightning](https://arxiv.org/abs/2508.03680)。用于了解将 Agent 执行轨迹与 RL 训练解耦的研究路线；生产数据权限、奖励正确性与发布门禁仍是独立问题。

## 评测基准与轨迹评估

### R46 · AgentBench {#r46}

Liu 等：[AgentBench](https://arxiv.org/abs/2308.03688)。用于了解多环境 Agent 能力评测；基准分数不代替指定任务的业务验收。

### R47 · GAIA {#r47}

Mialon 等：[GAIA](https://arxiv.org/abs/2311.12983)。用于了解现实世界问答与工具使用能力的评测设计；不覆盖组织内部权限与副作用。

### R48 · WebArena {#r48}

Zhou 等：[WebArena](https://arxiv.org/abs/2307.13854)。用于了解可复现网站环境中的自主任务评测；不证明公网或真实账户操作可直接放行。

### R49 · OSWorld {#r49}

Xie 等：[OSWorld](https://arxiv.org/abs/2404.07972)。用于了解真实计算机环境中的多模态 Agent 评测；沙箱成绩不代替生产权限和恢复测试。

### R50 · τ-bench {#r50}

Yao 等：[τ-bench](https://arxiv.org/abs/2406.12045)。用于了解工具—用户交互与策略遵循评测；其任务和用户模拟不能覆盖所有真实业务对手行为。

### R51 · SWE-bench Verified 评测边界 {#r51}

OpenAI：[Why we no longer evaluate SWE-bench Verified](https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/)。用于说明公开 benchmark 可随污染、坏题与可验证性变化而失效；该分析不足以评价所有代码任务。

### R52 · LangSmith Agent Evaluation {#r52}

LangChain：[Agent evaluation approaches](https://docs.langchain.com/langsmith/evaluation-approaches) 与[offline/online evaluation](https://docs.langchain.com/langsmith/evaluation)。用于区分最终答案、单步、轨迹以及离线回归与线上监测；这是分类参考而非特定平台的默认验收标准。

### R53 · Google Agents CLI Evaluation {#r53}

Google：[Agents CLI evaluation guide](https://google.github.io/agents-cli/guide/evaluation/)。用于说明工具使用、多轮轨迹、任务成功、grounding、hallucination 和 safety 可分开评估；不能用一个总分抵消高后果违规。

## 安全、可靠性、观测与治理

### R54 · OWASP LLM 与 Agentic AI 风险 {#r54}

OWASP：[Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/)、[Unbounded Consumption](https://genai.owasp.org/llmrisk/llm10-unbounded-consumption/)、[Agentic Security Initiative](https://genai.owasp.org/initiatives/agentic-security-initiative/) 与[Agentic AI Threats and Mitigations](https://genai.owasp.org/resource/agentic-ai-threats-and-mitigations/)。用于组织威胁建模与测试矩阵；这些资料不是产品认证。

### R55 · NIST Secure Software Development Framework {#r55}

NIST：[SP 800-218](https://csrc.nist.gov/pubs/sp/800/218/final) 与[SSDF profiles](https://csrc.nist.gov/Projects/ssdf)。用于把供应链与安全开发实践放入软件生命周期；不替代组织或特定领域的风险判定。

### R56 · OpenTelemetry GenAI Semantic Conventions {#r56}

OpenTelemetry：[GenAI 语义约定仓库](https://github.com/open-telemetry/semantic-conventions-genai)、[Agent spans 状态](https://github.com/open-telemetry/semantic-conventions-genai/blob/main/docs/gen-ai/gen-ai-agent-spans.md)、[v1.42 迁移说明](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.42.0)、[GenAI observability 更新](https://opentelemetry.io/blog/2026/genai-observability/) 与[stability 规则](https://opentelemetry.io/docs/specs/semconv/general/semantic-convention-groups/)。用于核对字段、仓库迁移和稳定性状态；实施必须固定 tag/commit 和 `schema_url`，不应把开发中字段表述为永久标准。

### R57 · NIST AI Risk Management Framework {#r57}

NIST：[AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework)、[Generative AI Profile 出版页](https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-generative-artificial-intelligence) 与[AI 600-1 PDF](https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.600-1.pdf)。用于组织 GOVERN、MAP、MEASURE 和 MANAGE 等风险管理活动；它们不是强制认证，也不替代特定法规。

### R58 · 欧盟 AI Act 与时间线 {#r58}

欧盟：[Regulation (EU) 2024/1689](https://eur-lex.europa.eu/eli/reg/2024/1689/oj/eng)、[European Commission application timeline](https://digital-strategy.ec.europa.eu/en/policies/regulatory-framework-ai)、[enforcement timeline](https://digital-strategy.ec.europa.eu/en/policies/enforcement-ai-act) 与[AI Omnibus 最终文本](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=OJ%3AL_202601744)。用于按角色、预期用途与修订后日期核对义务；不能把单一日期或分类推广到所有 Agent。

### R59 · 中国生成式 AI 与内容标识规则 {#r59}

中国国家互联网信息办公室等：[《生成式人工智能服务管理暂行办法》](https://www.cac.gov.cn/2023-07/13/c_1690898327029107.htm) 与[《人工智能生成合成内容标识办法》](https://www.cac.gov.cn/2025-03/14/c_1743654684782215.htm)。用于按是否面向境内公众、服务类型、传播角色与数据活动核对要求；不应泛化为全部内部 Agent 的统一规则。
