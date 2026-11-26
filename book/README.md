# Print edition

Builds the print-ready PDFs from the chapter Markdown files in a language
folder (`ko/` by default).

```
make book     # build/book.pdf   interior, 138x198mm pages (128x188 trim + 5mm bleed)
make cover    # build/cover.pdf  back + spine + front, with 5mm bleed
make guides   # build/cover-guides.pdf  cover with cut / spine / safe-area lines
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
| `cover.tex` | cover design and text |
| `../figures/*.tex` | diagrams (TikZ, grayscale, drawn at the 95mm text width), text in every language |
| `cover-template.pdf` | printer's (RedPrinting) template, not committed |

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
