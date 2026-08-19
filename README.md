# AI Agent Playbook

AI Agent Playbook 是一份面向工程实践的系统手册，覆盖 Agent 任务执行、框架与模型、上下文与记忆、训练与学习、多智能体协作、评测、可靠性、安全治理和持续进化。

## 在线文档

<https://scharfsinnig.github.io/agent-playbook/>

## 仓库结构

- `docs/`：手册正文，也是 Jekyll 的唯一内容源。
- `scripts/`：文档验证与单文件组装工具。
- `test/`：文档工具测试。
- `.github/workflows/`：Pull Request 验证与 GitHub Pages 发布流程。

## 本地验证

```sh
ruby -Itest test/docs_tooling_test.rb
ruby scripts/verify-docs.rb
ruby scripts/assemble-handbook.rb
```

编辑规则与提交流程见 [CONTRIBUTING.md](CONTRIBUTING.md)。
