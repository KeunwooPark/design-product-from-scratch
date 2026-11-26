# Build the print book.
#   make book    -> build/book.pdf   (interior, trim + bleed per page)
#   make book-a5 -> build/book-a5.pdf (interior on plain A5 sheets, no bleed)
#   make book lang=en -> build/en/book.pdf (any language folder; default ko)
#   make cover   -> build/cover.pdf  (back + spine + front, with bleed)
#                   covers take lang= too: text from <lang>/cover-text.tex,
#                   output in build/<lang>/ for languages other than ko
#   make guides  -> build/cover-guides.pdf (cover with cut/spine lines, for checking)
#   make cover-a5 -> build/cover-a5.pdf + build/cover-a5-guides.pdf (A5 edition)
#   make cover-split -> build/cover-split.pdf + build/cover-split-guides.pdf
#                    (no spine: page 1 = front, page 2 = back, with bleed)
#   make cover-a5-split -> build/cover-a5-split.pdf + build/cover-a5-split-guides.pdf
#   make pdf     -> pdf/design-product-from-scratch-<lang>.pdf, the reading PDF
#                   for the website: A5 interior with the covers, committed
#   make site    -> build/site/, the website (GitHub Pages): every language
#                   folder as HTML, plus img/ and pdf/. Needs only pandoc.
#   make pages   -> print the interior page count
#   make figures -> img/<l>/<name>.pdf (print) + img/<l>/<name>.png (Markdown)
#                   from figures/<name>.tex, for every language <l> in FIGURE_LANGS
#
# SPINE is the spine (세네카) width in mm from the printer's cover template.
# It depends on the page count and paper; update it after re-downloading the
# template for the final page count, e.g. `make cover SPINE=3.2`.

SPINE ?= 7.85
# A5 edition (148x210 panels). Placeholder estimated from the 사륙판 value
# (7.85mm for 69 pages, scaled to 60 pages); replace it with the 세네카 from
# the printer's A5 template.
SPINE_A5 ?= 6.83
# Language of the interior: the folder holding README.md, chapter*.md and
# metadata.yaml. Korean builds into build/ as before; others into build/<lang>/.
lang ?= ko
# sort -V so that chapter10.md comes after chapter9.md, not after chapter1.md
CHAPTERS := $(lang)/README.md $(shell ls $(lang)/chapter*.md | sort -V)
BUILD := build
OUT := $(if $(filter ko,$(lang)),$(BUILD),$(BUILD)/$(lang))
# The reading PDF, committed so the website (and GitHub) can serve it.
PDF := pdf/design-product-from-scratch-$(lang).pdf
FIGURE_SRC := $(filter-out figures/_preamble.tex,$(wildcard figures/*.tex))
FIGURE_NAMES := $(patsubst figures/%.tex,%,$(FIGURE_SRC))
# Languages the diagrams are built in (\tr{한국어}{English} in figures/*.tex).
FIGURE_LANGS := ko en
# The book needs only its own language's diagrams; `make figures` builds all.
FIGURES := $(patsubst %,img/$(lang)/%.pdf,$(FIGURE_NAMES))
ALL_FIGURES := $(foreach l,$(FIGURE_LANGS),$(patsubst %,img/$(l)/%.pdf,$(FIGURE_NAMES)))

.PHONY: all book book-a5 cover cover-a5 cover-split cover-a5-split guides pages figures pdf site clean

all: book cover

book: $(OUT)/book.pdf
book-a5: $(OUT)/book-a5.pdf
cover: $(OUT)/cover.pdf
guides: $(OUT)/cover-guides.pdf
cover-a5: $(OUT)/cover-a5.pdf $(OUT)/cover-a5-guides.pdf
cover-split: $(OUT)/cover-split.pdf $(OUT)/cover-split-guides.pdf
cover-a5-split: $(OUT)/cover-a5-split.pdf $(OUT)/cover-a5-split-guides.pdf
figures: $(ALL_FIGURES)
pdf: $(PDF)

# Diagrams: vector PDF for the print book, 300dpi PNG for the Markdown.
# Both are committed so GitHub shows the PNGs without building anything.
# One pattern rule per language: img/<l>/%.pdf, with \figlang set to <l>.
define figure_rule
img/$(1)/%.pdf: figures/%.tex figures/_preamble.tex | $(BUILD)
	@mkdir -p $(BUILD)/figures/$(1) img/$(1)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD)/figures/$(1) \
	  -jobname=$$* "\def\figlang{$(1)}\input{$$<}" >/dev/null
	cp $(BUILD)/figures/$(1)/$$*.pdf $$@
	pdftocairo -png -r 300 -singlefile $$@ img/$(1)/$$*
endef
$(foreach l,$(FIGURE_LANGS),$(eval $(call figure_rule,$(l))))

$(OUT)/book.tex: $(CHAPTERS) book/book.tex book/book.lua book/layout.yaml $(lang)/metadata.yaml $(FIGURES) | $(OUT)
	pandoc $(CHAPTERS) \
	  --from markdown \
	  --metadata-file book/layout.yaml \
	  --metadata-file $(lang)/metadata.yaml \
	  --lua-filter book/book.lua \
	  --template book/book.tex \
	  --top-level-division=chapter \
	  -o $@

$(OUT)/book.pdf: $(OUT)/book.tex $(FIGURES) $(wildcard img/shared/*)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) $< >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) $< >/dev/null
	@$(MAKE) --no-print-directory pages

# A5 edition: same chapters, book/layout-a5.yaml overrides size and type.
$(OUT)/book-a5.tex: $(CHAPTERS) book/book.tex book/book.lua book/layout.yaml book/layout-a5.yaml $(lang)/metadata.yaml $(FIGURES) | $(OUT)
	pandoc $(CHAPTERS) \
	  --from markdown \
	  --metadata-file book/layout.yaml \
	  --metadata-file book/layout-a5.yaml \
	  --metadata-file $(lang)/metadata.yaml \
	  --lua-filter book/book.lua \
	  --template book/book.tex \
	  --top-level-division=chapter \
	  -o $@

$(OUT)/book-a5.pdf: $(OUT)/book-a5.tex $(FIGURES) $(wildcard img/shared/*)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) $< >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) $< >/dev/null
	@pdfinfo $@ | grep -E '^(Pages|Page size)'

$(OUT)/cover.pdf: book/cover.tex $(lang)/cover-text.tex Makefile | $(OUT)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover "\def\coverlang{$(lang)}\def\spine{$(SPINE)}\input{book/cover.tex}" >/dev/null
	@# second run places the overlay correctly
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover "\def\coverlang{$(lang)}\def\spine{$(SPINE)}\input{book/cover.tex}" >/dev/null

$(OUT)/cover-guides.pdf: book/cover.tex $(lang)/cover-text.tex Makefile | $(OUT)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-guides "\def\coverlang{$(lang)}\def\spine{$(SPINE)}\def\guides{}\input{book/cover.tex}" >/dev/null
	@# second run places the overlay correctly
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-guides "\def\coverlang{$(lang)}\def\spine{$(SPINE)}\def\guides{}\input{book/cover.tex}" >/dev/null

A5COVER = \def\spine{$(SPINE_A5)}\def\trimW{148}\def\trimH{210}
$(OUT)/cover-a5.pdf: book/cover.tex $(lang)/cover-text.tex Makefile | $(OUT)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-a5 "\def\coverlang{$(lang)}$(A5COVER)\input{book/cover.tex}" >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-a5 "\def\coverlang{$(lang)}$(A5COVER)\input{book/cover.tex}" >/dev/null

$(OUT)/cover-a5-guides.pdf: book/cover.tex $(lang)/cover-text.tex Makefile | $(OUT)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-a5-guides "\def\coverlang{$(lang)}$(A5COVER)\def\guides{}\input{book/cover.tex}" >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-a5-guides "\def\coverlang{$(lang)}$(A5COVER)\def\guides{}\input{book/cover.tex}" >/dev/null

$(OUT)/cover-split.pdf: book/cover.tex $(lang)/cover-text.tex Makefile | $(OUT)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-split "\def\coverlang{$(lang)}\def\split{}\input{book/cover.tex}" >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-split "\def\coverlang{$(lang)}\def\split{}\input{book/cover.tex}" >/dev/null

$(OUT)/cover-split-guides.pdf: book/cover.tex $(lang)/cover-text.tex Makefile | $(OUT)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-split-guides "\def\coverlang{$(lang)}\def\split{}\def\guides{}\input{book/cover.tex}" >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-split-guides "\def\coverlang{$(lang)}\def\split{}\def\guides{}\input{book/cover.tex}" >/dev/null

$(OUT)/cover-a5-split.pdf: book/cover.tex $(lang)/cover-text.tex Makefile | $(OUT)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-a5-split "\def\coverlang{$(lang)}$(A5COVER)\def\split{}\input{book/cover.tex}" >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-a5-split "\def\coverlang{$(lang)}$(A5COVER)\def\split{}\input{book/cover.tex}" >/dev/null

$(OUT)/cover-a5-split-guides.pdf: book/cover.tex $(lang)/cover-text.tex Makefile | $(OUT)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-a5-split-guides "\def\coverlang{$(lang)}$(A5COVER)\def\split{}\def\guides{}\input{book/cover.tex}" >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=cover-a5-split-guides "\def\coverlang{$(lang)}$(A5COVER)\def\split{}\def\guides{}\input{book/cover.tex}" >/dev/null

# Reading PDF: the A5 interior with the A5 covers (split, no bleed) as its
# first and last pages. book.tex places them when `cover` is set.
EBOOK_COVER = $(A5COVER)\def\bleed{0}\def\split{}
$(OUT)/ebook-cover.pdf: book/cover.tex $(lang)/cover-text.tex Makefile | $(OUT)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=ebook-cover "\def\coverlang{$(lang)}$(EBOOK_COVER)\input{book/cover.tex}" >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) \
	  -jobname=ebook-cover "\def\coverlang{$(lang)}$(EBOOK_COVER)\input{book/cover.tex}" >/dev/null

$(OUT)/ebook.tex: $(CHAPTERS) book/book.tex book/book.lua book/layout.yaml book/layout-a5.yaml $(lang)/metadata.yaml $(FIGURES) | $(OUT)
	pandoc $(CHAPTERS) \
	  --from markdown \
	  --metadata-file book/layout.yaml \
	  --metadata-file book/layout-a5.yaml \
	  --metadata-file $(lang)/metadata.yaml \
	  --metadata cover=$(OUT)/ebook-cover.pdf \
	  --lua-filter book/book.lua \
	  --template book/book.tex \
	  --top-level-division=chapter \
	  -o $@

$(OUT)/ebook.pdf: $(OUT)/ebook.tex $(OUT)/ebook-cover.pdf $(FIGURES) $(wildcard img/shared/*)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) $< >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(OUT) $< >/dev/null

$(PDF): $(OUT)/ebook.pdf
	@mkdir -p $(dir $@)
	cp $< $@
	@pdfinfo $@ | grep -E '^(Pages|Page size|File size)'

# Website: one page per Markdown file of every language folder (a folder
# with metadata.yaml), laid out like the repo so relative links keep working.
# Uses the committed PNGs and PDFs, so CI needs no TeX.
SITE := $(BUILD)/site
SITE_LANGS := $(patsubst %/metadata.yaml,%,$(wildcard */metadata.yaml))
SITE_DEPS := site/template.html site/site.lua site/landing.html site/landing.lua site/style.css

site: $(SITE_DEPS)
	rm -rf $(SITE)
	mkdir -p $(SITE)
	@set -e; for l in $(SITE_LANGS); do \
	  mkdir -p $(SITE)/$$l; \
	  for f in $$l/README.md $$l/chapter*.md; do \
	    out=$$(basename $$f .md); [ $$out = README ] && out=index; \
	    pandoc $$f --from markdown --to html5 --standalone --wrap=none \
	      --metadata-file $$l/metadata.yaml \
	      --lua-filter site/site.lua --template site/template.html \
	      -o $(SITE)/$$l/$$out.html; \
	  done; \
	  echo "site: $$l ($$(ls $(SITE)/$$l | wc -l) pages)"; \
	done
	pandoc site/landing.md --from markdown --to html5 --standalone --wrap=none \
	  --lua-filter site/landing.lua --template site/landing.html -o $(SITE)/index.html
	cp site/style.css $(SITE)/
	cp -r img $(SITE)/img
	find $(SITE)/img -name '*.pdf' -delete
	if [ -d pdf ]; then cp -r pdf $(SITE)/pdf; fi

pages: $(OUT)/book.pdf
	@pdfinfo $< | grep -E '^(Pages|Page size)'

$(BUILD) $(BUILD)/$(lang):
	mkdir -p $@

clean:
	rm -rf $(BUILD)
