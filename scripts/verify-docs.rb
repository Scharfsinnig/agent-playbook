#!/usr/bin/env ruby
# frozen_string_literal: true

require "set"
require "yaml"

ROOT = File.expand_path("..", __dir__)
DOCS = File.join(ROOT, "docs")
PARTS = [
  ["part-01-runtime", 1, 8],
  ["part-02-framework-models", 9, 13],
  ["part-03-learning-evolution", 14, 18],
  ["part-04-production-governance", 19, 23],
  ["part-05-cases-roadmap", 24, 28]
].freeze
LEGACY_PATHS = %w[handbook _config.yml _data _layouts assets index.md 404.md scripts/split-handbook.sh].freeze
INDUSTRY_TERMS = %w[产业级 产业实践 产业现场 产业价值 产业案例 产业架构].freeze
EXTERNAL_URL_PATTERN = %r!https?://[^\s)>"']+!
REFERENCE_HEADING_PATTERN = /^### (R\d{2,}) · (\S(?:.*\S)?) \{#(r\d{2,})\}\s*$/
REFERENCE_HEADING_CANDIDATE_PATTERN = /^###\s+R\d{2,}\b.*$/
BODY_REFERENCE_PATTERN = /\A\[(R\d{2,})\]\(\{\{ '\/references\/#(r\d{2,})' \| relative_url \}\}\)\z/
BODY_REFERENCE_LINK_PATTERN = /\[([^\]\r\n]*)\]\(\{\{\s*(['"])\/references\/#([rR]\d{2,})\2\s*\|\s*relative_url\s*\}\}\)/
BODY_REFERENCE_ROUTE_PATTERN = /\{\{\s*(['"])\/references\/#([rR]\d{2,})\1\s*\|\s*relative_url\s*\}\}/

def expected_pages
  pages = {
    "docs/index.md" => ["/", nil, "/guide/overview/", "/"],
    "docs/404.md" => ["/404.html", nil, nil, nil],
    "docs/guide/overview.md" => ["/guide/overview/", "/", "/chapters/part-01-runtime/", "/"]
  }

  previous = "/guide/overview/"
  PARTS.each_with_index do |(slug, first, last), part_index|
    part_url = "/chapters/#{slug}/"
    pages["docs/chapters/#{slug}/index.md"] = [part_url, previous, format("%schapter-%02d/", part_url, first), "/"]
    (first..last).each do |number|
      prev_url = number == first ? part_url : format("%schapter-%02d/", part_url, number - 1)
      next_url = if number < last
                   format("%schapter-%02d/", part_url, number + 1)
                 elsif part_index + 1 < PARTS.length
                   "/chapters/#{PARTS[part_index + 1][0]}/"
                 else
                   "/guide/conclusion/"
                 end
      pages[format("docs/chapters/%s/chapter-%02d.md", slug, number)] = [part_url + format("chapter-%02d/", number), prev_url, next_url, part_url]
    end
    previous = part_url + format("chapter-%02d/", last)
  end

  pages.merge!(
    "docs/guide/conclusion.md" => ["/guide/conclusion/", previous, "/appendices/", "/"],
    "docs/appendices/index.md" => ["/appendices/", "/guide/conclusion/", "/appendices/appendix-a/", "/"],
    "docs/appendices/appendix-a.md" => ["/appendices/appendix-a/", "/appendices/", "/appendices/appendix-b/", "/appendices/"],
    "docs/appendices/appendix-b.md" => ["/appendices/appendix-b/", "/appendices/appendix-a/", "/appendices/appendix-c/", "/appendices/"],
    "docs/appendices/appendix-c.md" => ["/appendices/appendix-c/", "/appendices/appendix-b/", "/references/", "/appendices/"],
    "docs/references.md" => ["/references/", "/appendices/appendix-c/", nil, "/appendices/"]
  )
  pages
end

def parse_yaml_file(path, errors)
  YAML.safe_load(File.read(path, encoding: "UTF-8"), permitted_classes: [], permitted_symbols: [], aliases: false)
rescue Errno::ENOENT => error
  errors << "missing YAML file: #{path.delete_prefix(ROOT + "/")}"
  nil
rescue Psych::SyntaxError => error
  errors << "invalid YAML in #{path.delete_prefix(ROOT + "/")}: #{error.message.lines.first.strip}"
  nil
end

def parse_markdown(path, errors)
  relative = path.delete_prefix(ROOT + "/")
  text = File.read(path, encoding: "UTF-8")
  match = text.match(/\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n/m)
  unless match
    errors << "missing front matter: #{relative}"
    return { path: relative, data: {}, body: text }
  end

  data = YAML.safe_load(match[1], permitted_classes: [], permitted_symbols: [], aliases: false)
  unless data.is_a?(Hash)
    errors << "front matter is not a mapping: #{relative}"
    data = {}
  end
  { path: relative, data: data, body: text[match.end(0)..-1].to_s }
rescue Psych::SyntaxError => error
  errors << "invalid front matter YAML in #{relative}: #{error.message.lines.first.strip}"
  { path: relative, data: {}, body: text.to_s }
end

def internal_targets(text)
  liquid = text.scan(/\{\{\s*['"](\/[^'"]*)['"]\s*\|\s*relative_url\s*\}\}/).flatten
  markdown = text.scan(/\]\((\/[^)\s]+)\)/).flatten
  (liquid + markdown).map { |target| target.split("#", 2).first }.reject(&:empty?)
end

def markdown_table_separator?(line)
  candidate = line.strip
  return false unless candidate.include?("|")

  candidate = candidate[1..-1].to_s.strip if candidate.start_with?("|")
  candidate = candidate[0...-1].strip if candidate.end_with?("|")
  cells = candidate.split("|", -1).map(&:strip)
  cells.length >= 2 && cells.all? { |cell| cell.match?(/\A:?-{3,}:?\z/) }
end

def markdown_table_row?(line)
  candidate = line.strip
  return false unless candidate.include?("|")

  candidate = candidate[1..-1].to_s if candidate.start_with?("|")
  candidate = candidate[0...-1] if candidate.end_with?("|")
  candidate.split("|", -1).length >= 2
end

def markdown_table_count(body)
  lines = body.lines
  lines.each_index.count do |index|
    index.positive? && markdown_table_separator?(lines[index]) && markdown_table_row?(lines[index - 1])
  end
end

structure_only = false
ARGV.each do |argument|
  if argument == "--structure-only"
    structure_only = true
  else
    warn "Usage: ruby scripts/verify-docs.rb [--structure-only]"
    exit 2
  end
end

errors = []
warnings = []
expected = expected_pages
actual_paths = Dir.glob(File.join(DOCS, "**", "*.md")).sort.map { |path| path.delete_prefix(ROOT + "/") }

(expected.keys - actual_paths).each { |path| errors << "missing Markdown page: #{path}" }
(actual_paths - expected.keys).each { |path| errors << "unexpected Markdown page in docs/: #{path}" }

pages = actual_paths.map { |relative| parse_markdown(File.join(ROOT, relative), errors) }
pages.each do |page|
  %w[layout title permalink].each do |key|
    errors << "missing front matter #{key}: #{page[:path]}" if page[:data][key].to_s.empty?
  end
end

permalink_groups = pages.group_by { |page| page[:data]["permalink"] }.reject { |key, _| key.to_s.empty? }
permalink_groups.each do |permalink, group|
  errors << "duplicate permalink #{permalink}: #{group.map { |page| page[:path] }.join(', ')}" if group.length > 1
end
routes = permalink_groups.keys.to_set

expected.each do |path, (permalink, previous_page, next_page, part_home)|
  page = pages.find { |candidate| candidate[:path] == path }
  next unless page

  data = page[:data]
  errors << "wrong permalink in #{path}: expected #{permalink}, got #{data['permalink'].inspect}" unless data["permalink"] == permalink
  { "previous_page" => previous_page, "next_page" => next_page, "part_home" => part_home }.each do |key, value|
    actual = data[key]
    errors << "wrong #{key} in #{path}: expected #{value.inspect}, got #{actual.inspect}" unless actual == value
  end
end

pages.each do |page|
  %w[previous_page next_page part_home].each do |key|
    target = page[:data][key]
    errors << "#{page[:path]} has missing #{key} target: #{target}" if target && !routes.include?(target)
  end
  internal_targets(page[:body]).each do |target|
    errors << "#{page[:path]} has broken internal link: #{target}" unless routes.include?(target)
  end
end

config = parse_yaml_file(File.join(DOCS, "_config.yml"), errors)
errors << "docs/_config.yml must be a YAML mapping" if config && !config.is_a?(Hash)
navigation = parse_yaml_file(File.join(DOCS, "_data", "navigation.yml"), errors)

if navigation.is_a?(Hash)
  parts = navigation["parts"]
  errors << "navigation must contain 5 parts" unless parts.is_a?(Array) && parts.length == 5
  if parts.is_a?(Array)
    numbers = parts.flat_map { |part| Array(part["chapters"]).map { |chapter| chapter["number"] } }
    errors << "navigation chapter numbers must be 1 through 28" unless numbers == (1..28).to_a
  end

  nav_urls = []
  nav_urls << navigation.dig("overview", "url")
  Array(parts).each do |part|
    nav_urls << part["url"]
    Array(part["chapters"]).each { |chapter| nav_urls << chapter["url"] }
  end
  nav_urls << navigation.dig("conclusion", "url")
  nav_urls << navigation.dig("appendices", "url")
  Array(navigation.dig("appendices", "items")).each { |item| nav_urls << item["url"] }
  nav_urls << navigation.dig("references", "url")
  nav_urls.compact.each { |url| errors << "navigation target does not exist: #{url}" unless routes.include?(url) }

  expected_nav = routes - ["/", "/404.html"]
  missing_nav = expected_nav - nav_urls.to_set
  extra_nav = nav_urls.to_set - expected_nav
  errors << "navigation is missing: #{missing_nav.to_a.sort.join(', ')}" unless missing_nav.empty?
  errors << "navigation has unknown targets: #{extra_nav.to_a.sort.join(', ')}" unless extra_nav.empty?
end

LEGACY_PATHS.each do |relative|
  errors << "legacy source remains: #{relative}" if File.exist?(File.join(ROOT, relative))
end
errors << "docs/ must not contain README.md files" unless Dir.glob(File.join(DOCS, "**", "README.md")).empty?

forbidden = {
  "Mermaid block" => /^\s*```mermaid\b/i,
  "Markdown image" => /!\[[^\]]*\](?:\s*\([^)]*\)|\s*\[[^\]]*\])?/,
  "HTML image or SVG" => /<(?:img|svg)\b/i
}
pages.each do |page|
  table_count = markdown_table_count(page[:body])
  errors << "Markdown table is forbidden in #{page[:path]} (#{table_count})" if table_count.positive?
  forbidden.each do |name, pattern|
    count = page[:body].scan(pattern).length
    errors << "#{name} is forbidden in #{page[:path]} (#{count})" if count.positive?
  end
end

chapter_count = actual_paths.grep(%r{\Adocs/chapters/part-[^/]+/chapter-\d{2}\.md\z}).length
part_count = actual_paths.grep(%r{\Adocs/chapters/part-[^/]+/index\.md\z}).length
appendix_count = actual_paths.grep(%r{\Adocs/appendices/appendix-[a-c]\.md\z}).length
errors << "expected 28 chapters, found #{chapter_count}" unless chapter_count == 28
errors << "expected 5 parts, found #{part_count}" unless part_count == 5
errors << "expected 3 appendices, found #{appendix_count}" unless appendix_count == 3

puts "Structure: #{chapter_count} chapters, #{part_count} parts, #{appendix_count} appendices, #{routes.length} unique permalinks"

unless structure_only
  reference_page = pages.find { |page| page[:path] == "docs/references.md" }
  reference_body = reference_page ? reference_page[:body] : ""
  definition_entries = []
  invalid_definition_headings = []
  reference_body.each_line do |line|
    next unless line.match?(REFERENCE_HEADING_CANDIDATE_PATTERN)

    match = line.match(REFERENCE_HEADING_PATTERN)
    if match && match[1].downcase == match[3]
      definition_entries << { id: match[1], anchor: match[3], heading: line.strip }
    else
      invalid_definition_headings << line.strip
    end
  end

  unless invalid_definition_headings.empty?
    errors << "invalid reference definition heading or anchor: #{invalid_definition_headings.join(' | ')}"
  end

  duplicate_groups = definition_entries.group_by { |entry| entry[:id] }.select { |_, entries| entries.length > 1 }
  duplicate_count = duplicate_groups.values.sum { |entries| entries.length - 1 }
  unless duplicate_groups.empty?
    errors << "duplicate reference definitions: #{duplicate_count} (#{duplicate_groups.keys.sort.join(', ')})"
  end

  ordered_definition_ids = definition_entries.map { |entry| entry[:id] }
  expected_definition_ids = (1..ordered_definition_ids.length).map { |number| format("R%02d", number) }
  non_continuous_count = ordered_definition_ids.each_index.count do |index|
    ordered_definition_ids[index] != expected_definition_ids[index]
  end
  if non_continuous_count.positive?
    errors << "non-continuous reference IDs: expected #{expected_definition_ids.join(', ')}, got #{ordered_definition_ids.join(', ')}"
  end

  reference_ids = ordered_definition_ids.to_set
  body_reference_ids = Set.new
  pages.reject { |page| page[:path] == "docs/references.md" }.each do |page|
    invalid_reference_labels = []
    scrubbed = page[:body].gsub(BODY_REFERENCE_LINK_PATTERN) do |citation|
      candidate_match = Regexp.last_match
      label = candidate_match[1]
      candidate_anchor = candidate_match[3]
      exact_match = citation.match(BODY_REFERENCE_PATTERN)
      if exact_match && exact_match[1].downcase == exact_match[2]
        body_reference_ids << exact_match[1]
      else
        invalid_reference_labels << (label.empty? ? candidate_anchor : label)
      end
      " " * citation.length
    end
    scrubbed = scrubbed.gsub(BODY_REFERENCE_ROUTE_PATTERN) do |route|
      invalid_reference_labels << Regexp.last_match(2)
      " " * route.length
    end
    invalid_ids = scrubbed.scan(/\bR\d{2,}\b/).uniq.sort
    invalid_markers = (invalid_reference_labels + invalid_ids).uniq.sort
    errors << "invalid body reference syntax in #{page[:path]}: #{invalid_markers.join(', ')}" unless invalid_markers.empty?
  end

  missing_references = body_reference_ids - reference_ids
  unused_references = reference_ids - body_reference_ids
  errors << "undefined body references: #{missing_references.to_a.sort.join(', ')}" unless missing_references.empty?
  errors << "unused reference definitions: #{unused_references.to_a.sort.join(', ')}" unless unused_references.empty?

  definition_entries.each do |entry|
    start_index = reference_body.index(entry[:heading])
    next unless start_index

    remaining = reference_body[(start_index + entry[:heading].length)..-1].to_s
    section = remaining.split(/^###\s+/, 2).first.to_s
    errors << "reference definition has no external URL: #{entry[:id]}" unless section.match?(EXTERNAL_URL_PATTERN)
  end

  markdown_url_counts = actual_paths.each_with_object({}) do |relative, result|
    count = File.read(File.join(ROOT, relative), encoding: "UTF-8").scan(EXTERNAL_URL_PATTERN).length
    result[relative] = count if count.positive?
  end
  body_url_counts = markdown_url_counts.reject { |path, _| path == "docs/references.md" }
  body_url_total = body_url_counts.values.sum
  reference_urls = reference_body.scan(EXTERNAL_URL_PATTERN)
  reference_url_total = reference_urls.length
  reference_unique_url_total = reference_urls.to_set.length
  errors << "external URLs outside docs/references.md: #{body_url_total} across #{body_url_counts.length} files" if body_url_total.positive?

  site_copy_paths = Dir.glob(File.join(DOCS, "**", "*.{md,yml,html}"))
  term_counts = INDUSTRY_TERMS.each_with_object({}) do |term, result|
    count = site_copy_paths.sum { |path| File.read(path, encoding: "UTF-8").scan(term).length }
    result[term] = count if count.positive?
  end
  total_terms = term_counts.values.sum
  errors << "legacy industry wording: #{total_terms} occurrences (#{term_counts.map { |term, count| "#{term}=#{count}" }.join(', ')})" if total_terms.positive?

  puts "References: #{body_reference_ids.length} used, #{reference_ids.length} defined, #{missing_references.length} missing, #{unused_references.length} unused, #{duplicate_count} duplicate, #{non_continuous_count} non-continuous"
  puts "External URLs: #{body_url_total} outside references across #{body_url_counts.length} files; #{reference_url_total} in references (#{reference_unique_url_total} unique)"
  puts "Legacy industry wording: #{total_terms} occurrences"
else
  puts "Content gates skipped (--structure-only)"
end

warnings.each { |warning| warn "WARNING: #{warning}" }
if errors.empty?
  puts structure_only ? "Structure verification passed" : "Documentation verification passed"
  exit 0
end

errors.each { |error| warn "ERROR: #{error}" }
warn "Verification failed with #{errors.length} error(s)"
exit 1
