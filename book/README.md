# Print edition

Builds the print-ready PDFs from the chapter Markdown files in the repo root.

```
make book     # build/book.pdf   interior, 138x198mm pages (128x188 trim + 5mm bleed)
make cover    # build/cover.pdf  back + spine + front, with 5mm bleed
make guides   # build/cover-guides.pdf  cover with cut / spine / safe-area lines
make pages    # print the interior page count
```

Requirements: `pandoc` and TeX Live with XeLaTeX (`xetexko`, `titlesec`,
`fancyhdr`, `footmisc`, `xurl`, `float`, `enumitem`, `tikz`), Noto CJK KR fonts.

| File | What it controls |
|---|---|
| `metadata.yaml` | title, author, trim size, bleed, margins, fonts, font size |
| `book.tex` | interior layout: headings, running heads, TrimBox/BleedBox |
| `book.lua` | Markdown → print adjustments (links → footnotes, README → 들어가며) |
| `cover.tex` | cover design and text |
| `cover-template.pdf` | printer's (RedPrinting) template, not committed |

## Spine width

The spine width depends on the page count and paper. After the interior is
final, download the cover template again from the printer with the real page
count, read the `세네카` value, and build with it:

```
make cover guides SPINE=3.2
```

Text is placed on the spine only when it is 5mm or wider.
