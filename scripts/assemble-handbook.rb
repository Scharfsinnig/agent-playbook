#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
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

def source_paths
  paths = ["guide/overview.md"]
  PARTS.each do |slug, first, last|
    paths << "chapters/#{slug}/index.md"
    (first..last).each { |number| paths << format("chapters/%s/chapter-%02d.md", slug, number) }
  end
  paths.concat(%w[
    guide/conclusion.md
    appendices/appendix-a.md
    appendices/appendix-b.md
    appendices/appendix-c.md
    references.md
  ])
  paths
end

def parse_page(relative_path)
  path = File.join(DOCS, relative_path)
  text = File.read(path, encoding: "UTF-8")
  match = text.match(/\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n/m)
  abort "Missing front matter: #{relative_path}" unless match

  data = YAML.safe_load(match[1], permitted_classes: [], permitted_symbols: [], aliases: false)
  abort "Invalid front matter mapping: #{relative_path}" unless data.is_a?(Hash)

  { path: relative_path, data: data, body: text[match.end(0)..-1].to_s }
rescue Psych::SyntaxError => error
  abort "Invalid YAML in #{relative_path}: #{error.message}"
end

def heading_anchor(title)
  title.downcase
       .gsub(/<[^>]+>/, "")
       .gsub(/\{#[^}]+\}\s*\z/, "")
       .gsub(/[^\p{L}\p{N}\s_-]/u, "")
       .strip
       .gsub(/[\s_]+/, "-")
       .gsub(/-+/, "-")
end

def first_heading(body)
  line = body.each_line.find { |candidate| candidate.match?(/^#\s+/) }
  line&.sub(/^#\s+/, "")&.strip
end

def convert_internal_links(body, anchors)
  converted = body.gsub(/\{\{\s*(['"])(\/[^'"]*)\1\s*\|\s*relative_url\s*\}\}/) do
    target = Regexp.last_match(2)
    path, fragment = target.split("#", 2)
    if fragment && !fragment.empty?
      "##{fragment}"
    elsif anchors.key?(path)
      "##{anchors.fetch(path)}"
    else
      target
    end
  end

  converted.gsub(/\]\((\/[^)\s]+)\)/) do
    target = Regexp.last_match(1)
    path, fragment = target.split("#", 2)
    replacement = if fragment && !fragment.empty?
                    "##{fragment}"
                  elsif anchors.key?(path)
                    "##{anchors.fetch(path)}"
                  else
                    target
                  end
    "](#{replacement})"
  end
end

def shift_headings(body, amount)
  fence = nil
  body.each_line.map do |line|
    marker = line[/^\s*(```+|~~~+)/, 1]
    if marker
      fence = fence ? nil : marker[0, 3]
      next line
    end

    if fence.nil? && line =~ /\A(\#{1,6})(\s+)/
      hashes = Regexp.last_match(1)
      line = ("#" * [hashes.length + amount, 6].min) + Regexp.last_match(2) + line[Regexp.last_match(0).length..-1].to_s
    end
    line
  end.join
end

def heading_shift_for(relative_path)
  return 0 if relative_path == "guide/overview.md"
  return 2 if relative_path.match?(%r{\Achapters/[^/]+/chapter-\d{2}\.md\z})

  1
end

pages = source_paths.map { |path| parse_page(path) }
anchors = pages.each_with_object({}) do |page, result|
  permalink = page[:data]["permalink"]
  title = first_heading(page[:body]) || page[:data]["title"]
  result[permalink] = heading_anchor(title.to_s) if permalink
end

sections = pages.map do |page|
  body = convert_internal_links(page[:body], anchors)
  body = shift_headings(body, heading_shift_for(page[:path]))
  body.strip
end

output = ARGV.fetch(0, File.join(ROOT, "build", "agent-playbook.md"))
output = File.expand_path(output, ROOT)
FileUtils.mkdir_p(File.dirname(output))
File.write(output, sections.join("\n\n") + "\n", encoding: "UTF-8")

puts "Assembled #{pages.length} source files into #{output}"
