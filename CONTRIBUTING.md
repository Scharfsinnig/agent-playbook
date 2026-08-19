# 贡献指南

## 编辑范围

- 直接编辑 `docs/` 下的页面；`docs/` 是手册的唯一内容源。
- 不要编辑 `_site/`、`build/`，也不要重新创建 `handbook/`。这些位置不是可维护的正文来源。
- 每页保留一个 H1 页面标题。章节页用 H2 表示章内一级小节、H3 表示更深一层；沿用相邻页面的标题层级、编号方式和既有术语。
- 不添加图示、图片或 Markdown 表格；需要表达结构时使用标题、正文和列表。

## 内容与引用

- 使用原创表达，不复制来源原文，也不沿用来源的段落结构。
- 外部来源只写入 `docs/references.md`；正文只使用指向该页的稳定 `Rnn` 引用链接。
- 明确区分有来源支持的事实与推断、意见。推断和意见不得写成来源已经证明的结论。
- 对软件版本、协议、法规和其他时效性主张，在修改时重新核验，并写清适用时点和边界。
- 新增引用时保持 `Rnn` 连续、唯一，并同步检查正文引用和参考资料定义。

## 提交前验证

运行全部三项检查：

```sh
ruby -Itest test/docs_tooling_test.rb
ruby scripts/verify-docs.rb
ruby scripts/assemble-handbook.rb
```

## Pages 与回滚

Pull Request 会运行文档测试、完整验证和组装检查。推送到 `main` 或手动触发工作流时，只有验证通过后才会从 `docs/` 构建并部署 GitHub Pages。

GitHub 的 billing 或账户限制可能阻止 Actions 启动；仓库工作流不能绕过这些限制。

需要回滚时，使用普通的 Git revert 或 revert Pull Request，并重新运行同样的检查。不要直接编辑生成的 HTML 或 `_site/`。
