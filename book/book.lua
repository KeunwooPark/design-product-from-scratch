-- Pandoc filter that adapts the web (GitHub) Markdown for print.
--
-- * README.md becomes the preface: its title becomes "들어가며" and the
--   "목차" (table of contents) section is dropped, since the book has its own.
-- * "# Chapter N: title" headings lose the "Chapter N:" prefix; LaTeX numbers
--   the chapters itself.
-- * External links become footnotes with the URL (paper is not clickable).
-- * Links to other chapters / mailto links keep only their text.
-- * Inline code (used for names like `경험커피`) and emphasis are set in the
--   sans-serif (gothic) face, because Korean fonts have no italics.

local stringify = pandoc.utils.stringify

local book_title = nil
local dropping = false -- true while inside the README "목차" section

function Meta(meta)
  book_title = stringify(meta.title or "")
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
          b.content = pandoc.Inlines({ pandoc.Str("들어가며") })
          b.classes:insert("unnumbered")
          out:insert(b)
          -- unnumbered chapters do not set the running head by themselves
          b = pandoc.RawBlock("latex", "\\markboth{들어가며}{들어가며}")
        else
          b.content = strip_chapter_prefix(b.content)
        end
      elseif b.level == 2 then
        dropping = (text == "목차")
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

function Emph(el)
  return { pandoc.RawInline("latex", "\\textsf{"), table.unpack(el.content), pandoc.RawInline("latex", "}") }
end

-- Run Meta first so book_title is known when Pandoc runs.
return {
  { Meta = Meta },
  { Pandoc = Pandoc },
  { Link = Link, Code = Code, Emph = Emph },
}
