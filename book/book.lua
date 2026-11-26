-- Pandoc filter that adapts the web (GitHub) Markdown for print.
--
-- * README.md becomes the preface: its title becomes `preface-title` and its
--   `readme-toc-heading` section (the table of contents) is dropped, since the
--   book has its own. Both come from <lang>/metadata.yaml.
-- * "# Chapter N: title" headings lose the "Chapter N:" prefix; LaTeX numbers
--   the chapters itself.
-- * External links become footnotes with the URL (paper is not clickable).
-- * Links to other chapters / mailto links keep only their text.
-- * Diagrams referenced as ../img/<lang>/<name>.png (relative to <lang>/, so
--   GitHub renders them) use img/<lang>/<name>.pdf instead when it
--   exists (vector, built by `make figures` from figures/<name>.tex), scaled
--   by the optional `figure-scale` metadata.
-- * Inline code marks names (`경험커피`, `design team`), not code, so it is set
--   in the sans-serif face in every language. With `hangul: true`, emphasis
--   is set in the sans-serif (gothic) face too, because Korean fonts have no
--   italics; other languages keep italics.
-- * Without `hangul`, runs of Hangul are wrapped in \texthangul when
--   `hangul-font` is set, since the Latin font has no Hangul glyphs.

local stringify = pandoc.utils.stringify

local book_title = nil
local figure_scale = nil -- optional `figure-scale` metadata (e.g. the B5 edition)
local preface_title = nil -- `preface-title` metadata, e.g. "들어가며"
local readme_toc_heading = nil -- `readme-toc-heading` metadata, e.g. "목차"
local hangul = false -- `hangul` metadata
local hangul_font = false -- `hangul-font` metadata is set
local dropping = false -- true while inside the README table of contents

function Meta(meta)
  book_title = stringify(meta.title or "")
  preface_title = stringify(meta["preface-title"] or "")
  readme_toc_heading = stringify(meta["readme-toc-heading"] or "")
  hangul = meta.hangul == true
  hangul_font = meta["hangul-font"] ~= nil
  if meta["figure-scale"] then
    figure_scale = tonumber(stringify(meta["figure-scale"]))
  end
end

local function strip_chapter_prefix(inlines)
  local text = stringify(inlines)
  local rest = text:match("^[Cc]hapter%s*%d+%s*:%s*(.*)$")
  if rest then
    return pandoc.Inlines(pandoc.read(rest, "markdown").blocks[1].content)
  end
  return inlines
end

function Pandoc(doc)
  local blocks = doc.blocks
  local out = pandoc.Blocks({})
  for _, b in ipairs(blocks) do
    if b.t == "Header" then
      local text = stringify(b.content)
      if b.level == 1 then
        dropping = false
        if text == book_title then
          b.content = pandoc.Inlines({ pandoc.Str(preface_title) })
          b.classes:insert("unnumbered")
          out:insert(b)
          -- unnumbered chapters do not set the running head by themselves
          b = pandoc.RawBlock("latex", "\\markboth{" .. preface_title .. "}{" .. preface_title .. "}")
        else
          b.content = strip_chapter_prefix(b.content)
        end
      elseif b.level == 2 then
        dropping = (readme_toc_heading ~= "" and text == readme_toc_heading)
      end
    end
    if not dropping then
      out:insert(b)
    end
  end
  doc.blocks = out
  return doc
end

function Link(el)
  local url = el.target
  if url:match("^https?://") then
    local note = pandoc.Note({ pandoc.Plain({ pandoc.RawInline("latex", "\\url{" .. url .. "}") }) })
    local inl = pandoc.Inlines(el.content)
    inl:insert(note)
    return inl
  end
  return el.content
end

function Code(el)
  return pandoc.RawInline("latex", "\\textsf{" .. (el.text:gsub("([%%#&_{}$])", "\\%1")) .. "}")
end

-- Split a Str into Latin and Hangul runs; wrap the Hangul ones.
local function is_hangul(cp)
  return (cp >= 0xAC00 and cp <= 0xD7A3) or (cp >= 0x1100 and cp <= 0x11FF)
    or (cp >= 0x3130 and cp <= 0x318F)
end

function Str(el)
  if hangul or not hangul_font then
    return nil
  end
  local out, run, run_is_hangul = {}, {}, false
  local function flush()
    if #run > 0 then
      local text = table.concat(run)
      if run_is_hangul then
        table.insert(out, pandoc.RawInline("latex", "\\texthangul{" .. text .. "}"))
      else
        table.insert(out, pandoc.Str(text))
      end
      run = {}
    end
  end
  local found = false
  for _, cp in utf8.codes(el.text) do
    local h = is_hangul(cp)
    found = found or h
    if h ~= run_is_hangul then
      flush()
      run_is_hangul = h
    end
    table.insert(run, utf8.char(cp))
  end
  if not found then
    return nil
  end
  flush()
  return out
end

function Emph(el)
  if not hangul then
    return nil
  end
  return { pandoc.RawInline("latex", "\\textsf{"), table.unpack(el.content), pandoc.RawInline("latex", "}") }
end

function Image(el)
  -- Chapters live in <lang>/ and link ../img/; pandoc and xelatex run from
  -- the repo root, so drop the ../ for the print book.
  el.src = el.src:gsub("^%.%./img/", "img/")
  local base = el.src:match("^(img/.+)%.png$")
  if base then
    local f = io.open(base .. ".pdf", "r")
    if f then
      f:close()
      el.src = base .. ".pdf"
      -- Diagrams are drawn at 1:1 for the 95mm text width; a larger edition
      -- can scale them with its body text (\pandocbounded still shrinks a
      -- figure that would be wider than the text block).
      if figure_scale and figure_scale ~= 1 then
        return pandoc.RawInline("latex", string.format(
          "\\pandocbounded{\\includegraphics[scale=%.3f]{%s}}", figure_scale, el.src))
      end
    end
  end
  return el
end

-- Run Meta first so book_title and the labels are known when Pandoc runs.
return {
  { Meta = Meta },
  { Pandoc = Pandoc },
  { Link = Link, Code = Code, Emph = Emph, Image = Image, Str = Str },
}
