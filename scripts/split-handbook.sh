#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="${REPO_ROOT}/handbook/full/ai-agent-playbook.md"

if [[ ! -f "${SOURCE_FILE}" ]]; then
  printf 'Missing source manuscript: %s\n' "${SOURCE_FILE}" >&2
  exit 1
fi

mkdir -p \
  "${REPO_ROOT}/handbook/part-01-runtime" \
  "${REPO_ROOT}/handbook/part-02-framework-models" \
  "${REPO_ROOT}/handbook/part-03-learning-evolution" \
  "${REPO_ROOT}/handbook/part-04-production-governance" \
  "${REPO_ROOT}/handbook/part-05-cases-roadmap" \
  "${REPO_ROOT}/handbook/appendices" \
  "${REPO_ROOT}/handbook/full" \
  "${REPO_ROOT}/_data"

awk '
BEGIN {
  print "---"
  print "layout: default"
  print "title: \"AI Agent 产业级实践手册（完整单文件）\""
  print "permalink: /handbook/full/"
  print "part_home: /"
  print "previous_page: /handbook/00-overview/"
  print "next_page: /handbook/part-01-runtime/"
  print "---"
  print ""
}
{ print }
' "${SOURCE_FILE}" > "${REPO_ROOT}/handbook/full/index.md"

awk -v root="${REPO_ROOT}" '
function part_dir_for_chapter(n) {
  if (n <= 8) return "part-01-runtime"
  if (n <= 13) return "part-02-framework-models"
  if (n <= 18) return "part-03-learning-evolution"
  if (n <= 23) return "part-04-production-governance"
  return "part-05-cases-roadmap"
}

function part_number_for_chapter(n) {
  if (n <= 8) return 1
  if (n <= 13) return 2
  if (n <= 18) return 3
  if (n <= 23) return 4
  return 5
}

function part_route(n) {
  if (n == 1) return "/handbook/part-01-runtime/"
  if (n == 2) return "/handbook/part-02-framework-models/"
  if (n == 3) return "/handbook/part-03-learning-evolution/"
  if (n == 4) return "/handbook/part-04-production-governance/"
  return "/handbook/part-05-cases-roadmap/"
}

function chapter_route(n) {
  return "/handbook/" part_dir_for_chapter(n) "/chapter-" sprintf("%02d", n) "/"
}

function yaml_escape(s) {
  gsub(/\\/, "\\\\", s)
  gsub(/\"/, "\\\"", s)
  return s
}

function open_page(path, title, permalink, previous, following, home,   safe_title) {
  outfile = root "/" path
  safe_title = yaml_escape(title)
  print "---" > outfile
  print "layout: default" > outfile
  print "title: \"" safe_title "\"" > outfile
  print "permalink: " permalink > outfile
  if (home != "") print "part_home: " home > outfile
  if (previous != "") print "previous_page: " previous > outfile
  if (following != "") print "next_page: " following > outfile
  print "---" > outfile
  print "" > outfile
}

function open_part(n, heading, first_chapter, previous_part, next_part,   title) {
  title = heading
  sub(/^## /, "", title)
  print "  - title: \"" yaml_escape(title) "\"" > navigation_file
  print "    url: " part_route(n) > navigation_file
  print "    chapters:" > navigation_file
  open_page("handbook/" substr(part_route(n), 11) "README.md", title, part_route(n), previous_part, chapter_route(first_chapter), "/")
  sub(/^## /, "# ", heading)
  print heading > outfile
}

BEGIN {
  mode = "overview"
  open_page("handbook/00-overview.md", "导读与全书任务执行链", "/handbook/00-overview/", "/", "/handbook/full/", "/")

  navigation_file = root "/_data/navigation.yml"
  print "parts:" > navigation_file

  appendices_index = root "/handbook/appendices/README.md"
  print "---" > appendices_index
  print "layout: default" > appendices_index
  print "title: \"附录\"" > appendices_index
  print "permalink: /handbook/appendices/" > appendices_index
  print "part_home: /" > appendices_index
  print "previous_page: /handbook/conclusion/" > appendices_index
  print "next_page: /handbook/appendices/appendix-a/" > appendices_index
  print "---" > appendices_index
  print "" > appendices_index
  print "# 附录" > appendices_index
  print "" > appendices_index
  print "- [附录 A：150 个关键问题的正文导航索引]({{ \"/handbook/appendices/appendix-a/\" | relative_url }})" > appendices_index
  print "- [附录 B：架构评审与上线门禁清单]({{ \"/handbook/appendices/appendix-b/\" | relative_url }})" > appendices_index
  print "- [附录 C：核心状态对象与指标字典]({{ \"/handbook/appendices/appendix-c/\" | relative_url }})" > appendices_index
  print "- [附录 D：一手资料与继续研究入口]({{ \"/handbook/appendices/appendix-d/\" | relative_url }})" > appendices_index
}

/^## 第一篇/ {
  mode = "part"
  open_part(1, $0, 1, "/handbook/00-overview/", "/handbook/part-02-framework-models/")
  next
}

/^## 第二篇/ {
  mode = "part"
  open_part(2, $0, 9, "/handbook/part-01-runtime/", "/handbook/part-03-learning-evolution/")
  next
}

/^## 第三篇/ {
  mode = "part"
  open_part(3, $0, 14, "/handbook/part-02-framework-models/", "/handbook/part-04-production-governance/")
  next
}

/^## 第四篇/ {
  mode = "part"
  open_part(4, $0, 19, "/handbook/part-03-learning-evolution/", "/handbook/part-05-cases-roadmap/")
  next
}

/^## 第五篇/ {
  mode = "part"
  open_part(5, $0, 24, "/handbook/part-04-production-governance/", "/handbook/conclusion/")
  next
}

/^### 第 [0-9]+ 章/ {
  heading = $0
  number_text = $0
  sub(/^### 第 /, "", number_text)
  sub(/ 章.*/, "", number_text)
  chapter = number_text + 0
  title = heading
  sub(/^### /, "", title)
  previous = chapter == 1 ? "/handbook/part-01-runtime/" : chapter_route(chapter - 1)
  next_page = chapter == 28 ? "/handbook/conclusion/" : chapter_route(chapter + 1)
  path = "handbook/" part_dir_for_chapter(chapter) "/chapter-" sprintf("%02d", chapter) ".md"
  print "      - number: " chapter > navigation_file
  print "        title: \"" yaml_escape(title) "\"" > navigation_file
  print "        url: " chapter_route(chapter) > navigation_file
  open_page(path, title, chapter_route(chapter), previous, next_page, part_route(part_number_for_chapter(chapter)))
  sub(/^### /, "# ", heading)
  print heading > outfile
  mode = "chapter"
  next
}

/^## 结语/ {
  heading = $0
  title = heading
  sub(/^## /, "", title)
  open_page("handbook/conclusion.md", title, "/handbook/conclusion/", chapter_route(28), "/handbook/appendices/", "/")
  sub(/^## /, "# ", heading)
  print heading > outfile
  mode = "appendix"
  next
}

/^## 附录 A/ {
  heading = $0
  title = heading
  sub(/^## /, "", title)
  open_page("handbook/appendices/appendix-a.md", title, "/handbook/appendices/appendix-a/", "/handbook/appendices/", "/handbook/appendices/appendix-b/", "/handbook/appendices/")
  sub(/^## /, "# ", heading)
  print heading > outfile
  mode = "appendix"
  next
}

/^## 附录 B/ {
  heading = $0
  title = heading
  sub(/^## /, "", title)
  open_page("handbook/appendices/appendix-b.md", title, "/handbook/appendices/appendix-b/", "/handbook/appendices/appendix-a/", "/handbook/appendices/appendix-c/", "/handbook/appendices/")
  sub(/^## /, "# ", heading)
  print heading > outfile
  mode = "appendix"
  next
}

/^## 附录 C/ {
  heading = $0
  title = heading
  sub(/^## /, "", title)
  open_page("handbook/appendices/appendix-c.md", title, "/handbook/appendices/appendix-c/", "/handbook/appendices/appendix-b/", "/handbook/appendices/appendix-d/", "/handbook/appendices/")
  sub(/^## /, "# ", heading)
  print heading > outfile
  mode = "appendix"
  next
}

/^## 附录 D/ {
  heading = $0
  title = heading
  sub(/^## /, "", title)
  open_page("handbook/appendices/appendix-d.md", title, "/handbook/appendices/appendix-d/", "/handbook/appendices/appendix-c/", "/", "/handbook/appendices/")
  sub(/^## /, "# ", heading)
  print heading > outfile
  mode = "appendix"
  next
}

{
  line = $0
  if (mode == "chapter" && line ~ /^#### /) sub(/^#### /, "## ", line)
  else if (mode == "appendix" && line ~ /^#### /) sub(/^#### /, "### ", line)
  else if (mode == "appendix" && line ~ /^### /) sub(/^### /, "## ", line)
  print line > outfile
}
' "${SOURCE_FILE}"

find "${REPO_ROOT}/handbook" -type f -name '*.md' ! -path "${SOURCE_FILE}" \
  -exec perl -0pi -e 's/\n+\z/\n/' {} +

printf 'Split handbook generated from %s\n' "${SOURCE_FILE}"
