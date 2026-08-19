---
layout: default
title: "第四篇：从能够运行，走向能够证明、恢复与治理"
permalink: /handbook/part-04-production-governance/
part_home: /
previous_page: /handbook/part-03-learning-evolution/
next_page: /handbook/part-04-production-governance/chapter-19/
---

# 第四篇：从能够运行，走向能够证明、恢复与治理

原型环境只需要展示一次成功；生产环境必须面对长期随机性、外部系统故障、并发、权限变化、恶意输入、供应商升级和组织责任。一个 Agent 即使平均答案质量很高，只要无法确认真实业务结果、不能恢复不确定写入、不能追踪身份和版本，或在事故时无法独立停止，就不具备生产自治的基础。

本篇把评测、安全、可靠性、成本和治理视为执行闭环的一部分，而不是上线前补写的文档。评测定义什么叫可接受；权限与策略限定候选动作；Trace 与 Replay 保存运行证据；SLO 和错误预算决定何时缩小自治；组织与合规规定谁有权批准、运营、豁免和下线。它们共同决定系统最多可以承担多大后果。
