-- Pandoc filter for the site's front page (`make site`): one entry per
-- language folder (a folder with metadata.yaml and README.md), with its
-- title, author, a link to read it, and its reading PDF when it exists.
-- Sets `languages` (and `lang`, `pagetitle` from the first language) for
-- site/landing.html.

local stringify = pandoc.utils.stringify
local path = pandoc.path

local function exists(p)
  local f = io.open(p, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function read_meta(yaml_file)
  local f = assert(io.open(yaml_file, "r"))
  local s = f:read("a")
  f:close()
  return pandoc.read("---\n" .. s .. "\n---\n", "markdown").meta
end

function Pandoc(doc)
  local dirs = {}
  for _, d in ipairs(pandoc.system.list_directory(".")) do
    if exists(path.join({ d, "metadata.yaml" })) and exists(path.join({ d, "README.md" })) then
      table.insert(dirs, d)
    end
  end
  -- the original (Korean) edition first, then the others alphabetically
  table.sort(dirs, function(a, b)
    if a == "ko" or b == "ko" then
      return a == "ko"
    end
    return a < b
  end)

  local langs = {}
  for _, d in ipairs(dirs) do
    local m = read_meta(path.join({ d, "metadata.yaml" }))
    local pdf = "pdf/design-product-from-scratch-" .. d .. ".pdf"
    table.insert(langs, pandoc.MetaMap({
      lang = d,
      title = stringify(m.title or ""),
      author = stringify(m.author or ""),
      description = stringify(m["site-description"] or ""),
      href = d .. "/index.html",
      read = stringify(m["site-read"] or "Read"),
      pdf = exists(pdf) and pdf or "",
      ["pdf-label"] = stringify(m["site-pdf"] or "PDF"),
      ["language-name"] = stringify(m["language-name"] or d),
    }))
  end
  doc.meta.languages = langs
  if #langs > 0 then
    doc.meta.lang = langs[1].lang
    doc.meta.pagetitle = langs[1].title
    doc.meta["multilingual"] = #langs > 1
  end
  return doc
end
