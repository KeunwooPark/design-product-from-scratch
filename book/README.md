# Print edition

Builds the print-ready PDFs from the chapter Markdown files in a language
folder (`ko/` by default).

```
make book     # build/book.pdf   interior, 138x198mm pages (128x188 trim + 5mm bleed)
make cover    # build/cover.pdf  back + spine + front, with 5mm bleed
make guides   # build/cover-guides.pdf  cover with cut / spine / safe-area lines
make cover-split     # build/cover-split.pdf  front (page 1) and back (page 2), no spine
make pdf      # pdf/design-product-from-scratch-ko.pdf  reading PDF (A5 + covers)
make pages    # print the interior page count
make figures  # img/<lang>/<name>.{pdf,png} from figures/<name>.tex, for ko and en
```

`make book lang=en` (or `book-a5`, `pages`) builds the interior from `en/`
into `build/en/`. Korean builds into `build/` as before.

Requirements: `pandoc` and TeX Live with XeLaTeX (`xetexko`, `titlesec`,
`fancyhdr`, `footmisc`, `xurl`, `float`, `enumitem`, `tikz`), Noto CJK KR fonts,
and `pdftocairo` (poppler) for the figure PNGs.

| File | What it controls |
|---|---|
| `layout.yaml` | trim size, bleed, margins, font size (all languages) |
| `layout-a5.yaml` | overrides for the A5 edition |
| `../<lang>/metadata.yaml` | title, author, fonts, `hangul`, labels (들어가며, 목차, 차례) |
| `book.tex` | interior layout: headings, running heads, TrimBox/BleedBox |
| `book.lua` | Markdown → print adjustments (links → footnotes, README → preface) |
| `cover.tex` | cover layout |
| `../<lang>/cover-text.tex` | cover text and fonts per language |
| `../figures/*.tex` | diagrams (TikZ, grayscale, drawn at the 95mm text width), text in every language |
| `cover-template.pdf` | printer's (RedPrinting) template, not committed |

## Reading PDF

`make pdf` builds the PDF that the website links to and commits it under
`pdf/`: the A5 interior (`layout-a5.yaml`) with the A5 covers as its first
and last pages. The covers are `cover.tex` in split mode with no bleed
(`build/ebook-cover.pdf`), so they are exactly A5 like the interior.
`book.tex` places them when the `cover` metadata is set:

front cover, blank inside cover, interior, (blank), back cover

The back cover always lands on a left-hand page, so two-page view shows the
same spreads as the printed book. Rebuild and commit the PDF after changing
the text: `make pdf`.

`make pdf lang=en` builds the English one the same way.

## Cover text

`cover.tex` holds the cover layout only. The words and fonts come from
`<lang>/cover-text.tex`: the title (and how it breaks into lines on the
front), the author, the cycle labels, the back-cover text, and optionally
`\backleading`, the back-cover line spacing. Every cover target takes
`lang=` like the interior, e.g. `make cover lang=en`; covers for languages
other than Korean go to `build/<lang>/`.

## Figures

Each diagram is a TikZ file in `figures/` sharing `figures/_preamble.tex`.
Text is written once for every language as `\tr{한국어}{English}`, so the
drawing itself is shared. Where English needs a different size or position,
the number is wrapped the same way, e.g. `minimum width=\tr{21mm}{24mm}`.

`make figures` builds every diagram in each language of `FIGURE_LANGS`
(Makefile) by defining `\figlang`, and writes two files per diagram into
`img/<lang>/`. Both are committed:

- `img/<lang>/<name>.png` (300dpi, white background) is what the Markdown
  links to (as `../img/<lang>/<name>.png`), so the pages render on GitHub.
- `img/<lang>/<name>.pdf` (vector) is what the print book uses: `book.lua`
  swaps a `.png` link for the `.pdf` next to it.

Screenshots that are the same in every language live in `img/shared/`.

Korean figures use Noto Sans CJK KR and break lines only between words;
English figures use Noto Sans with hyphenation turned off.

The Markdown alt text becomes the figure caption in the book.

## Spine width

The spine width depends on the page count and paper. After the interior is
final, download the cover template again from the printer with the real page
count, read the `세네카` value, and build with it:

```
make cover guides SPINE=3.2
```

Text is placed on the spine only when it is 5mm or wider.
