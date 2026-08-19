---
layout: default
title: AI Agent Playbook
description: 产业级 AI Agent 技术框架、任务执行、模型适配、持续学习与生产治理手册
permalink: /
next_page: /handbook/00-overview/
---

# AI Agent 产业级实践手册

这是一份站在 Agent 执行视角整理的产业级手册：先讲一次任务怎样从请求进入、建立契约、编译上下文、规划、调用工具、验证与停止，再讲框架和模型怎样承担这些责任，最后讨论数据飞轮、微调、Bandit/RL、生产可靠性、安全、合规与组织治理。

本文档不是产品排行榜，也不把“持续进化”理解为生产模型自动改写自己。每一种技术都被放回具体失败、控制边界、证据要求和上线门禁中讨论。

<div class="entry-links">
  <a href="{{ '/handbook/00-overview/' | relative_url }}">从导读开始</a>
  <a href="{{ '/handbook/full/' | relative_url }}">阅读完整单文件</a>
  <a href="{{ '/handbook/appendices/appendix-b/' | relative_url }}">打开上线门禁清单</a>
</div>

## 五篇、二十八章

{% for part in site.data.navigation.parts %}
### [{{ part.title }}]({{ part.url | relative_url }})

<ol class="chapter-list">
{% for chapter in part.chapters %}
  <li><a href="{{ chapter.url | relative_url }}">{{ chapter.title }}</a></li>
{% endfor %}
</ol>
{% endfor %}

## 附录

- [150 个关键问题的正文导航索引]({{ '/handbook/appendices/appendix-a/' | relative_url }})
- [架构评审与上线门禁清单]({{ '/handbook/appendices/appendix-b/' | relative_url }})
- [核心状态对象与指标字典]({{ '/handbook/appendices/appendix-c/' | relative_url }})
- [一手资料与继续研究入口]({{ '/handbook/appendices/appendix-d/' | relative_url }})
