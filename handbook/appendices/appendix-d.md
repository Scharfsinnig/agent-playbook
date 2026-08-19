---
layout: default
title: "附录 D：一手资料与继续研究入口"
permalink: /handbook/appendices/appendix-d/
part_home: /handbook/appendices/
previous_page: /handbook/appendices/appendix-c/
next_page: /
---

# 附录 D：一手资料与继续研究入口

以下资料优先选择论文、项目规范、官方文档和监管机构原文。框架文档用于理解一种实现方式，不等于该框架自动提供了生产所需的权限、事务、验证和治理；公开 benchmark 用于发现能力和失败，不等于企业场景已经通过验收。协议、软件和法规会继续变化，实际建设时应固定版本并重新核验。

## D.1 Agent 架构、任务闭环与上下文

- Anthropic：[Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)。用于理解 Workflow 与 Agent 的工程边界，以及为什么应从最简单充分方案开始。
- Anthropic：[Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)。用于理解上下文是每次推理的有限、动态编译结果，而不是无限增长的历史。
- Anthropic：[Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)。区分 task、trial、grader、transcript、outcome 与 harness。
- Yao 等：[ReAct: Synergizing Reasoning and Acting in Language Models](https://arxiv.org/abs/2210.03629)。推理与行动交替的经典范式。
- Shinn 等：[Reflexion: Language Agents with Verbal Reinforcement Learning](https://arxiv.org/abs/2303.11366)。适合研究有外部反馈时的轨迹反思，但不能据此把模型自评当成真值。
- Wang 等：[Voyager](https://arxiv.org/abs/2305.16291)。开放式探索、技能库与环境反馈的代表工作。
- Temporal：[Workflow Execution 与 Replay](https://github.com/temporalio/documentation/blob/main/docs/encyclopedia/workflow/workflow-execution/workflow-execution.mdx)；[SDK 架构](https://github.com/temporalio/documentation/blob/main/docs/encyclopedia/architecture/temporal-sdks.mdx)。用于理解事件历史、确定性重放以及决策与副作用分离。
- LangGraph：[Persistence](https://docs.langchain.com/oss/python/langgraph/persistence) 与 [Memory](https://docs.langchain.com/oss/python/langgraph/add-memory)。用于理解状态图编排中的检查点、线程和记忆接口；业务事务仍需在应用层设计。
- Model Context Protocol：[2026-07-28 正式规范](https://modelcontextprotocol.io/specification/2026-07-28) 与 [Schema Reference](https://modelcontextprotocol.io/specification/2026-07-28/schema)。用于工具、资源和上下文能力的互操作；协议本身不替代应用状态与授权。
- OpenAI Docs：[Agents SDK](https://developers.openai.com/api/docs/guides/agents)、[Running agents](https://developers.openai.com/api/docs/guides/agents/running-agents)、[Orchestration and handoffs](https://developers.openai.com/api/docs/guides/agents/orchestration)、[Guardrails and human review](https://developers.openai.com/api/docs/guides/agents/guardrails-approvals)。作为代码式 Agent SDK 的一组实现参考。
- Microsoft AutoGen：[Teams](https://microsoft.github.io/autogen/stable/user-guide/agentchat-user-guide/tutorial/teams.html)。用于理解团队拓扑、交接和终止条件，不应被误读为多 Agent 天然优于强单 Agent。
- Google：[Agent Development Kit](https://developers.googleblog.com/agent-development-kit-easy-to-build-multi-agent-applications/)。作为确定性工作流与模型驱动协作共存的实现实例。

## D.2 模型适配、提示优化与参数训练

- Hu 等：[LoRA](https://arxiv.org/abs/2106.09685)。低秩参数高效适配的基础论文。
- Dettmers 等：[QLoRA](https://arxiv.org/abs/2305.14314)。在量化冻结基座上训练 LoRA adapter；不是与 LoRA 无关的另一种 adapter 类型。
- Rafailov 等：[Direct Preference Optimization](https://arxiv.org/abs/2305.18290)。偏好对优化方法；它不直接证明事实、工具或长期业务结果正确。
- Shao 等：[DeepSeekMath / Group Relative Policy Optimization](https://arxiv.org/abs/2402.03300)。GRPO 的代表资料；组内相对优势仍依赖可靠奖励与足够组内方差。
- Ouyang 等：[Training language models to follow instructions with human feedback](https://arxiv.org/abs/2203.02155)。SFT、奖励模型与 RLHF 流水线的代表工作。
- Khattab 等：[DSPy](https://arxiv.org/abs/2310.03714)。将提示与模块组合的优化视为可评测程序，而不是手工改几句话。
- Agrawal 等：[GEPA](https://arxiv.org/abs/2507.19457)。以反思式文本反馈进行系统优化的研究入口，生产应用仍需独立盲测与发布门禁。

## D.3 Bandit、强化学习与持续进化

- Garivier 与 Kaufmann：[Track-and-Stop](https://proceedings.mlr.press/v49/garivier16a.html)。用于理解固定置信度最佳臂识别的采样与停止；它与普通 UCB 路由并不是一回事。
- Li 等：[A Contextual-Bandit Approach to Personalized News Article Recommendation](https://arxiv.org/abs/1003.0146)。LinUCB 与离线回放评估的经典应用入口。
- Pathak 等：[Curiosity-driven Exploration by Self-supervised Prediction](https://proceedings.mlr.press/v70/pathak17a.html)。内在好奇心奖励的代表工作。
- Badia 等：[Never Give Up](https://arxiv.org/abs/2002.06038)。结合情景新颖性与长期探索的代表算法。
- Eysenbach 等：[Diversity Is All You Need](https://openreview.net/forum?id=SJx63jRqFm)。无监督技能发现的经典工作。
- Hafner 等：[DreamerV2](https://arxiv.org/abs/2010.02193)。世界模型与想象学习的代表资料。
- Jiang 等：[Agent Lightning](https://arxiv.org/abs/2508.03680)。将 Agent 执行轨迹与强化学习训练解耦的研究入口。
- Dudík 等：[Doubly Robust Policy Evaluation and Learning](https://arxiv.org/abs/1103.4601)。离线策略评估中双重稳健方法的基础资料；仍要求行为策略支持与可靠日志概率。
- DeepMind：[Specification gaming](https://deepmind.google/blog/specification-gaming-the-flip-side-of-ai-ingenuity/)。理解代理目标被钻空子的实例集合。
- Anthropic：[Reward tampering](https://www.anthropic.com/research/reward-tampering)。理解模型可能干预奖励过程而非完成真实目标的研究入口。

## D.4 Agent 评测与环境基准

- Liu 等：[AgentBench](https://arxiv.org/abs/2308.03688)。多环境 Agent 能力评测。
- Mialon 等：[GAIA](https://arxiv.org/abs/2311.12983)。现实世界问答与工具使用能力基准。
- Zhou 等：[WebArena](https://arxiv.org/abs/2307.13854)。可复现网站环境中的自主网页任务。
- Xie 等：[OSWorld](https://arxiv.org/abs/2404.07972)。真实计算机环境中的多模态 Agent 基准。
- Yao 等：[τ-bench](https://arxiv.org/abs/2406.12045)。工具—用户交互与策略遵循评测。
- OpenAI：[Why we no longer evaluate SWE-bench Verified](https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/)。公开 benchmark 污染、坏题和可验证性会变化的实例。

## D.5 安全、可靠性、观测与风险治理

- NIST：[AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework) 与 [Generative AI Profile, NIST AI 600-1](https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-generative-artificial-intelligence)。用于组织风险识别、测量、管理和治理。
- NIST：[Secure Software Development Framework SP 800-218](https://csrc.nist.gov/pubs/sp/800/218/final)。用于把供应链和安全开发实践放进生命周期。
- OWASP：[Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/) 与 [Agentic AI Threats and Mitigations](https://genai.owasp.org/resource/agentic-ai-threats-and-mitigations/)。用于威胁建模和红队测试矩阵，不是产品认证。
- Debenedetti 等：[AgentDojo](https://arxiv.org/abs/2406.13352)。动态环境中的提示注入与 Agent 防御评测。
- OpenTelemetry：[GenAI semantic conventions 仓库](https://github.com/open-telemetry/semantic-conventions-genai)、[v1.42 迁移说明](https://github.com/open-telemetry/semantic-conventions/releases/tag/v1.42.0)与 [semantic convention stability](https://opentelemetry.io/docs/specs/semconv/general/semantic-convention-groups/)。相关 Agent 字段仍在演进；实施时需固定具体 tag 或 commit 及其 `schema_url`，并用内部映射或阶段性双写、查询兼容和历史 trace 回放治理升级。
- Azure Architecture Center：[Event Sourcing](https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing)、[Asynchronous Request-Reply](https://learn.microsoft.com/en-us/azure/architecture/patterns/asynchronous-request-reply)、[Compensating Transaction](https://learn.microsoft.com/en-us/azure/architecture/patterns/compensating-transaction)。作为状态、异步等待与补偿的通用工程模式参考。

## D.6 法规与时点敏感资料

- 欧盟：[Regulation (EU) 2024/1689 / AI Act](https://eur-lex.europa.eu/eli/reg/2024/1689/oj/eng)、[European Commission application timeline](https://digital-strategy.ec.europa.eu/en/policies/regulatory-framework-ai)、[AI Act enforcement timeline](https://digital-strategy.ec.europa.eu/en/policies/enforcement-ai-act)、[AI Omnibus final text](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=OJ%3AL_202601744)。必须按预期用途、角色和修订后的适用日期逐用例核对：既有 GPAI 模型、Article 50(2) 标记义务、Annex III、Annex I 和新增禁止实践分别存在 2027-08-02、2026-12-02、2027-12-02、2028-08-02 与 2026-12-02 等不同边界，不能把某一日期推广为全部义务的生效时间。
- 中国国家互联网信息办公室等：[《生成式人工智能服务管理暂行办法》](https://www.cac.gov.cn/2023-07/13/c_1690898327029107.htm) 与 [《人工智能生成合成内容标识办法》](https://www.cac.gov.cn/2025-03/14/c_1743654684782215.htm)。应按是否面向境内公众、服务类型、内容传播角色和具体数据处理活动判断，不能泛化到所有内部 Agent。

## D.7 建议的持续更新方法

每季度至少做一次“技术雷达、事故雷达与规则雷达”联合更新。技术雷达核对模型、框架、协议、观测约定与供应商变更；事故雷达汇总线上失败、红队、人工接管和外部公开事故；规则雷达由法务、隐私和合规团队核对法规、标准、合同与地域变化。任何新技术进入架构前，都应回答三个问题：它解决了哪一个可观察失败；相对最小基线提高了多少；它新增了哪些权限、数据、状态和故障面。若这三问没有证据，新名词不应进入生产主路径。
