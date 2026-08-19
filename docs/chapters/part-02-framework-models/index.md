---
layout: default
title: 第二篇：框架与模型如何共同支撑这条执行链
permalink: /chapters/part-02-framework-models/
part_home: /
previous_page: /chapters/part-01-runtime/chapter-08/
next_page: /chapters/part-02-framework-models/chapter-09/
---

# 第二篇：框架与模型如何共同支撑这条执行链

第一篇解决的是“任务怎样跑”；第二篇解决的是“谁来承担每一段责任”。生产系统通常同时包含模型 SDK、Agent 运行时、状态图、持久工作流、工具协议、知识与记忆服务、验证器、策略网关和观测系统。它们不是同一层的替代品。选择错误时，团队往往会拿协议处理事务、拿 Prompt 处理权限、拿多 Agent 处理本应由状态机解决的控制流。

模型也不是一个单一角色。同一条任务链中，可以存在理解与规划模型、低成本抽取模型、Embedding 模型、重排器、执行模型和 Judge；某些环节甚至完全不需要生成模型。第二篇因此先建立参考架构与 Workflow/Agent 边界，再讨论怎样选择模型、Prompt、RAG、工具工程和参数训练，使每一种方法都对应可观察的失败，而不是因为技术流行就被加入系统。
