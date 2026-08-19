# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "open3"
require "tmpdir"
require "yaml"

class DocsToolingTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def run_script(*arguments)
    Open3.capture3(*arguments, chdir: ROOT)
  end

  def assemble_handbook
    Dir.mktmpdir("agent-playbook-test") do |directory|
      output = File.join(directory, "assembled.md")
      stdout, stderr, status = run_script("ruby", "scripts/assemble-handbook.rb", output)
      assert status.success?, [stdout, stderr].reject(&:empty?).join("\n")
      yield File.read(output, encoding: "UTF-8")
    end
  end

  def run_structure_verifier_with(body_fragment)
    Dir.mktmpdir("agent-playbook-verifier-test") do |directory|
      FileUtils.cp_r(File.join(ROOT, "docs"), directory)
      FileUtils.mkdir_p(File.join(directory, "scripts"))
      FileUtils.cp(File.join(ROOT, "scripts/verify-docs.rb"), File.join(directory, "scripts"))
      File.open(File.join(directory, "docs/guide/overview.md"), "a", encoding: "UTF-8") do |file|
        file.write("\n#{body_fragment}\n")
      end
      return Open3.capture3("ruby", "scripts/verify-docs.rb", "--structure-only", chdir: directory)
    end
  end

  def run_full_verifier_with_mutations
    Dir.mktmpdir("agent-playbook-verifier-test") do |directory|
      FileUtils.cp_r(File.join(ROOT, "docs"), directory)
      FileUtils.mkdir_p(File.join(directory, "scripts"))
      FileUtils.cp(File.join(ROOT, "scripts/verify-docs.rb"), File.join(directory, "scripts"))
      yield directory
      return Open3.capture3("ruby", "scripts/verify-docs.rb", chdir: directory)
    end
  end

  def append_to_copied_file(directory, relative_path, fragment)
    File.open(File.join(directory, relative_path), "a", encoding: "UTF-8") do |file|
      file.write("\n#{fragment}\n")
    end
  end

  def replace_in_copied_file(directory, relative_path)
    path = File.join(directory, relative_path)
    text = File.read(path, encoding: "UTF-8")
    File.write(path, yield(text), encoding: "UTF-8")
  end

  def assert_forbidden_content(fragment, expected_error)
    stdout, stderr, status = run_structure_verifier_with(fragment)

    refute status.success?, stdout
    assert_includes stderr, expected_error
  end

  def test_structure_verifier_accepts_the_migrated_repository
    stdout, stderr, status = run_script("ruby", "scripts/verify-docs.rb", "--structure-only")

    assert status.success?, [stdout, stderr].reject(&:empty?).join("\n")
    assert_includes stdout, "28 chapters"
    assert_includes stdout, "5 parts"
  end

  def test_docs_is_the_only_handbook_source
    assert Dir.exist?(File.join(ROOT, "docs"))
    refute Dir.exist?(File.join(ROOT, "handbook"))
    assert_equal 28, Dir.glob(File.join(ROOT, "docs/chapters/part-*/chapter-*.md")).length

    %w[_config.yml _data _layouts assets index.md 404.md].each do |legacy_path|
      refute File.exist?(File.join(ROOT, legacy_path)), "legacy path remains: #{legacy_path}"
    end
  end

  def test_pages_workflow_scopes_pages_permissions_by_job
    path = File.join(ROOT, ".github/workflows/pages.yml")
    workflow = YAML.safe_load(File.read(path, encoding: "UTF-8"), aliases: false)
    jobs = workflow.fetch("jobs")

    assert_equal({ "contents" => "read", "pages" => "read" }, jobs.fetch("build")["permissions"])
    assert_equal({ "pages" => "write", "id-token" => "write" }, jobs.fetch("deploy").fetch("permissions"))
    pages_writers = jobs.each_with_object([]) do |(name, job), result|
      result << name if job.dig("permissions", "pages") == "write"
    end
    oidc_writers = jobs.each_with_object([]) do |(name, job), result|
      result << name if job.dig("permissions", "id-token") == "write"
    end

    assert_equal ["deploy"], pages_writers
    assert_equal ["deploy"], oidc_writers
  end

  def test_assembler_emits_one_ordered_document_without_front_matter
    assemble_handbook do |text|
      refute_match(/\A---\s*$/, text)

      positions = [
        "# AI Agent 技术框架、任务执行与持续进化实践手册",
        "## 第一篇：站在 Agent 的视角，看一次任务怎样真正完成",
        "### 第 1 章",
        "### 第 28 章",
        "## 结语：",
        "## 附录 A：",
        "## 附录 C：",
        "## 参考资料"
      ].map { |marker| text.index(marker) }

      assert positions.all?, "assembled document is missing an expected section"
      assert_equal positions.sort, positions, "assembled sections are out of order"
    end
  end

  def test_assembler_emits_the_exact_handbook_heading_hierarchy
    assemble_handbook do |text|
      assert_equal 1, text.scan(/^# AI Agent 技术框架、任务执行与持续进化实践手册$/).length
      assert_equal 5, text.scan(/^## 第[一二三四五]篇：/).length
      assert_equal 28, text.scan(/^### 第 \d+ 章/u).length
      assert_match(/^#### 1\.1\s/u, text)
      refute_match(/^(?:#){1,3} \d+\.\d+\s/u, text)
      refute_match(/^(?:#){5,6} \d+\.\d+\s/u, text)
      assert_match(/^##### \d+\.\d+\.\d+\s/u, text)
      refute_match(/^(?:#){1,4} \d+\.\d+\.\d+\s/u, text)
      refute_match(/^###### \d+\.\d+\.\d+\s/u, text)
      assert_equal 1, text.scan(/^## 结语：/).length
      assert_equal 3, text.scan(/^## 附录 [A-C]：/).length
      assert_equal 1, text.scan(/^## 参考资料$/).length
      refute_match(/^## 第 \d+ 章/u, text)
    end
  end

  def test_assembler_resolves_jekyll_liquid_and_internal_links
    assemble_handbook do |text|
      refute_includes text, "{{"
      refute_includes text, "{%"
      refute_match(/\]\(\//, text)
      assert_operator text.scan(/\[R\d{2,}\]\(#r\d{2,}\)/).length, :>, 0
    end
  end

  def test_full_verifier_accepts_complete_continuous_reference_coverage
    stdout, stderr, status = run_script("ruby", "scripts/verify-docs.rb")

    assert status.success?, [stdout, stderr].reject(&:empty?).join("\n")
    assert_match(/References: \d+ used, \d+ defined, 0 missing, 0 unused, 0 duplicate, 0 non-continuous/, stdout)
    assert_includes stdout, "External URLs: 0 outside references"
    assert_includes stdout, "Legacy industry wording: 0 occurrences"
  end

  def test_full_verifier_rejects_external_url_outside_references
    stdout, stderr, status = run_full_verifier_with_mutations do |directory|
      append_to_copied_file(directory, "docs/guide/overview.md", "[unexpected source](https://example.com/source)")
    end

    refute status.success?, stdout
    assert_includes stderr, "external URLs outside docs/references.md: 1 across 1 files"
  end

  def test_casual_reference_text_is_not_a_definition
    stdout, stderr, status = run_full_verifier_with_mutations do |directory|
      append_to_copied_file(directory, "docs/guide/overview.md", "[R99]({{ '/references/#r99' | relative_url }})")
      append_to_copied_file(directory, "docs/references.md", "R99 is mentioned here, but this prose is not a definition.")
    end

    refute status.success?, stdout
    assert_includes stderr, "undefined body references: R99"
  end

  def test_full_verifier_rejects_non_site_safe_body_reference_syntax
    stdout, stderr, status = run_full_verifier_with_mutations do |directory|
      append_to_copied_file(directory, "docs/guide/overview.md", "See [R01](#r01).")
    end

    refute status.success?, stdout
    assert_includes stderr, "invalid body reference syntax in docs/guide/overview.md: R01"
  end

  def test_full_verifier_rejects_mismatched_body_reference_anchor
    stdout, stderr, status = run_full_verifier_with_mutations do |directory|
      append_to_copied_file(directory, "docs/guide/overview.md", "[R01]({{ '/references/#r02' | relative_url }})")
    end

    refute status.success?, stdout
    assert_includes stderr, "invalid body reference syntax in docs/guide/overview.md: R01"
  end

  def test_full_verifier_rejects_alternate_body_reference_label
    stdout, stderr, status = run_full_verifier_with_mutations do |directory|
      append_to_copied_file(directory, "docs/guide/overview.md", "[source]({{ '/references/#r01' | relative_url }})")
    end

    refute status.success?, stdout
    assert_includes stderr, "invalid body reference syntax in docs/guide/overview.md: source"
  end

  def test_full_verifier_rejects_lowercase_body_reference_label
    stdout, stderr, status = run_full_verifier_with_mutations do |directory|
      append_to_copied_file(directory, "docs/guide/overview.md", "[r01]({{ '/references/#r01' | relative_url }})")
    end

    refute status.success?, stdout
    assert_includes stderr, "invalid body reference syntax in docs/guide/overview.md: r01"
  end

  def test_full_verifier_rejects_duplicate_reference_definition
    stdout, stderr, status = run_full_verifier_with_mutations do |directory|
      path = File.join(directory, "docs/references.md")
      text = File.read(path, encoding: "UTF-8")
      heading = text.lines.find { |line| line.match?(/^### R\d{2,} · .+ \{#r\d{2,}\}\s*$/) }
      append_to_copied_file(directory, "docs/references.md", heading || "### R01 · Duplicate {#r01}")
    end

    refute status.success?, stdout
    assert_includes stderr, "duplicate reference definitions: 1"
  end

  def test_full_verifier_rejects_non_continuous_reference_ids
    stdout, stderr, status = run_full_verifier_with_mutations do |directory|
      append_to_copied_file(directory, "docs/references.md", "### R99 · Gap {#r99}\n\n- Source: https://example.com/gap")
    end

    refute status.success?, stdout
    assert_includes stderr, "non-continuous reference IDs"
  end

  def test_full_verifier_rejects_mismatched_definition_anchor
    stdout, stderr, status = run_full_verifier_with_mutations do |directory|
      replace_in_copied_file(directory, "docs/references.md") do |text|
        text.sub("{#r01}", "{#r02}")
      end
    end

    refute status.success?, stdout
    assert_includes stderr, "invalid reference definition heading or anchor"
  end

  def test_full_verifier_rejects_malformed_definition_heading
    stdout, stderr, status = run_full_verifier_with_mutations do |directory|
      replace_in_copied_file(directory, "docs/references.md") do |text|
        text.sub("### R01 · Building Effective Agents {#r01}", "### R01 - Building Effective Agents {#r01}")
      end
    end

    refute status.success?, stdout
    assert_includes stderr, "invalid reference definition heading or anchor"
  end

  def test_full_verifier_rejects_unused_reference_definition
    stdout, stderr, status = run_full_verifier_with_mutations do |directory|
      path = File.join(directory, "docs/references.md")
      text = File.read(path, encoding: "UTF-8")
      next_number = text.scan(/^### R(\d{2,})\b/).flatten.map(&:to_i).max.to_i + 1
      id = format("R%02d", next_number)
      append_to_copied_file(directory, "docs/references.md", "### #{id} · Unused {##{id.downcase}}\n\n- Source: https://example.com/unused")
    end

    refute status.success?, stdout
    assert_includes stderr, "unused reference definitions:"
  end

  def test_structure_verifier_rejects_table_with_edge_pipes
    assert_forbidden_content("| A | B |\n| --- | --- |\n| one | two |", "Markdown table is forbidden")
  end

  def test_structure_verifier_rejects_table_without_edge_pipes
    assert_forbidden_content("A | B\n--- | ---\none | two", "Markdown table is forbidden")
  end

  def test_structure_verifier_rejects_inline_image
    assert_forbidden_content("![architecture](architecture.png)", "Markdown image is forbidden")
  end

  def test_structure_verifier_rejects_reference_style_image
    assert_forbidden_content("![architecture][diagram]\n\n[diagram]: architecture.png", "Markdown image is forbidden")
  end

  def test_structure_verifier_allows_an_ordinary_vertical_bar
    stdout, stderr, status = run_structure_verifier_with("Use A | B to describe two alternatives in prose.")

    assert status.success?, [stdout, stderr].reject(&:empty?).join("\n")
  end

  def test_workers_emit_events_and_authorized_reducers_own_work_state_transitions
    paths = %w[
      docs/chapters/part-01-runtime/chapter-08.md
      docs/chapters/part-05-cases-roadmap/chapter-26.md
      docs/appendices/appendix-c.md
    ]
    text = paths.map { |path| File.read(File.join(ROOT, path), encoding: "UTF-8") }.join("\n")

    assert_includes text, "worker 只发出携带 lease ID、fencing token、契约版本和幂等键的状态事件"
    assert_includes text, "每个 actor 都只提交携带契约版本、取消代次、fencing token、幂等键和证据引用的事件"
    assert_operator text.scan("授权 reducer").length, :>=, 6
    assert_includes text, "`work_started` 事件"
    assert_includes text, "`work_submitted` 事件"
    refute_match(/worker[^。\n]{0,120}(?:将|把|使) WorkState (?:改为|从|进入)/, text)
  end

  def test_team_contract_versions_define_safe_effective_time_and_cutover
    chapter = File.read(File.join(ROOT, "docs/chapters/part-01-runtime/chapter-08.md"), encoding: "UTF-8")
    appendix = File.read(File.join(ROOT, "docs/appendices/appendix-c.md"), encoding: "UTF-8")

    assert_includes chapter, "每个版本必须声明 `effective_at`、被替代版本、变更类型和 cutover 规则"
    assert_includes chapter, "权限收紧、取消或安全约束加严的 `effective_at` 不得晚于变更被接受的时刻"
    assert_includes chapter, "必须立即递增契约/取消代次、撤销相关能力"
    assert_includes chapter, "将受影响的在途 WorkUnit fence/cancel"
    assert_includes chapter, "submitted proposal 也不得被自动保留资格"
    assert_includes chapter, "按当前生效的 Team Contract、权限和完成谓词重新验证"
    assert_includes appendix, "`effective_at`、`supersedes`、`change_type`、`cutover_mode` 与 `affected_work_units`"
    assert_includes appendix, "合并服务必须按当前生效的 Team Contract 重验权限、安全约束和完成谓词"
    refute_includes chapter, "契约发生版本变化时，只影响尚未提交的工作"
  end
end
