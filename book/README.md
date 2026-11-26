# Print edition

Builds the print-ready PDFs from the chapter Markdown files in a language
folder (`ko/` by default).

```
make book     # build/book.pdf   interior, 138x198mm pages (128x188 trim + 5mm bleed)
make cover    # build/cover.pdf  back + spine + front, with 5mm bleed
make guides   # build/cover-guides.pdf  cover with cut / spine / safe-area lines
make pages    # print the interior page count
make figures  # img/<name>.pdf + img/<name>.png from figures/<name>.tex
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
| `../figures/*.tex` | diagrams (TikZ, grayscale, drawn at the 95mm text width) |
| `cover-template.pdf` | printer's (RedPrinting) template, not committed |

## Figures

Each diagram is a TikZ file in `figures/` sharing `figures/_preamble.tex`.
`make figures` writes two files per diagram into `img/`, and both are committed:

- `img/<name>.png` (300dpi, white background) is what the Markdown links to
  (as `../img/<name>.png` from the language folder), so the pages render on
  GitHub.
- `img/<name>.pdf` (vector) is what the print book uses: `book.lua` swaps a
  `.png` link for the `.pdf` next to it.

The Markdown alt text becomes the figure caption in the book.

## Spine width

The spine width depends on the page count and paper. After the interior is
final, download the cover template again from the printer with the real page
count, read the `세네카` value, and build with it:

```
make cover guides SPINE=3.2
```

Text is placed on the spine only when it is 5mm or wider.
