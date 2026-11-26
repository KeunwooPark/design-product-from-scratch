-- Pandoc filter for the website (`make site`): one HTML page per Markdown file.
--
-- The site mirrors the repo layout (<lang>/chapterN.html, img/, pdf/), so the
-- Markdown's relative image links (../img/...) work unchanged.
--
-- * Links to other chapters (chapter3.md, README.md) point to their pages
--   (chapter3.html, index.html).
-- * Sets the variables site/template.html uses:
--     book-title, pagetitle, is-index   page and book titles
--     nav, prev, next                   the chapter list and its neighbours
--     other-languages                   the same page in the other languages
--     pdf                               the reading PDF, when it exists
--   Languages are the folders with a metadata.yaml and a README.md, so a new
--   language shows up without changing this file.
-- * Images load lazily.

local stringify = pandoc.utils.stringify
local path = pandoc.path

local input = PANDOC_STATE.input_files[1] -- e.g. "ko/chapter1.md"
local dir = path.directory(input) -- "ko"
local name = path.filename(input) -- "chapter1.md"

local function exists(p)
  local f = io.open(p, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function read_file(p)
  local f = assert(io.open(p, "r"))
  local s = f:read("a")
  f:close()
  return s
end

local function html_name(md)
  if md == "README.md" then
    return "index.html"
  end
  return (md:gsub("%.md$", ".html"))
end

-- README.md first, then chapter1.md, chapter2.md, ... in number order.
local function page_files(d)
  local chapters = {}
  for _, f in ipairs(pandoc.system.list_directory(d)) do
    local n = f:match("^chapter(%d+)%.md$")
    if n then
      table.insert(chapters, { n = tonumber(n), file = f })
    end
  end
  table.sort(chapters, function(a, b) return a.n < b.n end)
  local files = { "README.md" }
  for _, c in ipairs(chapters) do
    table.insert(files, c.file)
  end
  return files
end

-- "Chapter 3: 스케치" -> "3", "스케치"
local function split_chapter_title(text)
  local num, rest = text:match("^[Cc]hapter%s*(%d+)%s*:%s*(.*)$")
  if num then
    return num, rest
  end
  return nil, text
end

local function first_heading(file)
  local doc = pandoc.read(read_file(file), "markdown")
  for _, b in ipairs(doc.blocks) do
    if b.t == "Header" and b.level == 1 then
      return stringify(b.content)
    end
  end
  return file
end

local function read_meta(yaml_file)
  return pandoc.read("---\n" .. read_file(yaml_file) .. "\n---\n", "markdown").meta
end

local function languages()
  local langs = {}
  for _, d in ipairs(pandoc.system.list_directory(".")) do
    if exists(path.join({ d, "metadata.yaml" })) and exists(path.join({ d, "README.md" })) then
      table.insert(langs, d)
    end
  end
  table.sort(langs)
  return langs
end

function Pandoc(doc)
  local meta = doc.meta
  local book_title = stringify(meta.title or "")
  meta["book-title"] = book_title

  -- chapter list, current page, neighbours
  local nav, current = {}, nil
  for i, f in ipairs(page_files(dir)) do
    local num, label
    if f == "README.md" then
      label = stringify(meta["preface-title"] or book_title)
    else
      num, label = split_chapter_title(first_heading(path.join({ dir, f })))
    end
    nav[i] = pandoc.MetaMap({
      href = html_name(f),
      label = label,
      number = num or "",
      current = (f == name),
    })
    if f == name then
      current = i
    end
  end
  meta.nav = nav
  if current and current > 1 then
    meta.prev = nav[current - 1]
  end
  if current and current < #nav then
    meta.next = nav[current + 1]
  end

  if name == "README.md" then
    meta.pagetitle = book_title
    meta["is-index"] = true
  elseif current then
    meta.pagetitle = stringify(nav[current].label)
  end

  -- the same page in the other languages (their front page if it's missing)
  local others = {}
  for _, l in ipairs(languages()) do
    if l ~= dir then
      local m = read_meta(path.join({ l, "metadata.yaml" }))
      local target = exists(path.join({ l, name })) and html_name(name) or "index.html"
      table.insert(others, pandoc.MetaMap({
        href = "../" .. l .. "/" .. target,
        label = stringify(m["language-name"] or l),
        lang = l,
      }))
    end
  end
  if #others > 0 then -- an empty table would become a map, not a list
    meta["other-languages"] = others
  end

  local pdf = "pdf/design-product-from-scratch-" .. dir .. ".pdf"
  if exists(pdf) then
    meta.pdf = "../" .. pdf
  end

  doc.meta = meta
  return doc
end

function Link(el)
  -- relative links only (no scheme such as https: or mailto:)
  if not el.target:match("^%a[%w+.-]*:") then
    local file, frag = el.target:match("^([^#]*)(#?.*)$")
    if file:match("%.md$") then
      el.target = html_name(path.filename(file)) .. frag
    end
  end
  return el
end

function Image(el)
  el.attributes.loading = "lazy"
  return el
end

-- Pandoc first, so the Link and Image rewrites see the original targets.
return {
  { Pandoc = Pandoc },
  { Link = Link, Image = Image },
}
