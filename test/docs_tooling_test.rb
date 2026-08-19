# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "open3"
require "tmpdir"

class DocsToolingTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def run_script(*arguments)
    Open3.capture3(*arguments, chdir: ROOT)
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

  def test_assembler_emits_one_ordered_document_without_front_matter
    Dir.mktmpdir("agent-playbook-test") do |directory|
      output = File.join(directory, "assembled.md")
      stdout, stderr, status = run_script("ruby", "scripts/assemble-handbook.rb", output)

      assert status.success?, [stdout, stderr].reject(&:empty?).join("\n")
      text = File.read(output, encoding: "UTF-8")
      refute_match(/\A---\s*$/, text)
      assert_equal 28, text.scan(/^## 第 \d+ 章/u).length

      positions = [
        "# AI Agent 产业级技术框架、任务执行与持续进化实践手册",
        "## 第一篇：站在 Agent 的视角，看一次任务怎样真正完成",
        "## 第 1 章",
        "## 第 28 章",
        "## 结语：",
        "## 附录 A：",
        "## 附录 C：",
        "## 附录 D："
      ].map { |marker| text.index(marker) }

      assert positions.all?, "assembled document is missing an expected section"
      assert_equal positions.sort, positions, "assembled sections are out of order"
    end
  end

  def test_full_verifier_counts_legacy_wording_in_all_site_copy
    terms = %w[产业级 产业实践 产业现场 产业价值 产业案例 产业架构]
    source_paths = Dir.glob(File.join(ROOT, "docs/**/*.{md,yml,html}"))
    expected_count = source_paths.sum do |path|
      text = File.read(path, encoding: "UTF-8")
      terms.sum { |term| text.scan(term).length }
    end

    stdout, stderr, status = run_script("ruby", "scripts/verify-docs.rb")

    refute status.success?, "legacy content should keep the full gate red during Task 1"
    assert_includes [stdout, stderr].join("\n"), "Legacy industry wording: #{expected_count} occurrences"
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
