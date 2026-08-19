---
layout: default
title: "第三篇：Agent 如何把任务轨迹转化为受治理的进化"
permalink: /handbook/part-03-learning-evolution/
part_home: /
previous_page: /handbook/part-02-framework-models/
next_page: /handbook/part-03-learning-evolution/chapter-14/
---

# 第三篇：Agent 如何把任务轨迹转化为受治理的进化

一个 Agent 完成任务后会留下大量轨迹，但轨迹不是天然正确的训练数据。成功可能来自偶然，失败可能来自权限、工具、过期知识、完成定义或外部故障；如果未经验证便把轨迹写回记忆或模型，系统只会更快复制旧错误。持续进化首先是一套经验筛选、归因、评测和发布机制，其次才是训练算法。

本篇把学习分成多个时间尺度：本轮上下文适应、单轨迹纠错、跨会话记忆、提示/检索/路由优化、技能更新和模型参数训练。UCB、上下文 Bandit、强化学习、内在奖励、自博弈和世界模型会被放到相应决策位置中解释。核心问题不是“算法先进不先进”，而是它需要什么反馈、能优化什么目标、是否允许安全探索、怎样发现奖励投机，以及能力提升能否在独立评测中被证明并安全回滚。
