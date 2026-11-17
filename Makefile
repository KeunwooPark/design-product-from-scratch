# Build the print book.
#   make book    -> build/book.pdf   (interior, trim + bleed per page)
#   make book-a5 -> build/book-a5.pdf (interior on plain A5 sheets, no bleed)
#   make cover   -> build/cover.pdf  (back + spine + front, with bleed)
#   make guides  -> build/cover-guides.pdf (cover with cut/spine lines, for checking)
#   make cover-a5 -> build/cover-a5.pdf + build/cover-a5-guides.pdf (A5 edition)
#   make pages   -> print the interior page count
#   make figures -> img/<name>.pdf (print) + img/<name>.png (Markdown) from figures/<name>.tex
#
# SPINE is the spine (세네카) width in mm from the printer's cover template.
# It depends on the page count and paper; update it after re-downloading the
# template for the final page count, e.g. `make cover SPINE=3.2`.

SPINE ?= 7.85
# A5 edition (148x210 panels). Placeholder estimated from the 사륙판 value
# (7.85mm for 69 pages, scaled to 60 pages); replace it with the 세네카 from
# the printer's A5 template.
SPINE_A5 ?= 6.83
# sort -V so that chapter10.md comes after chapter9.md, not after chapter1.md
CHAPTERS := README.md $(shell ls chapter*.md | sort -V)
BUILD := build
FIGURE_SRC := $(filter-out figures/_preamble.tex,$(wildcard figures/*.tex))
FIGURES := $(patsubst figures/%.tex,img/%.pdf,$(FIGURE_SRC))

.PHONY: all book book-a5 cover cover-a5 guides pages figures clean

all: book cover

book: $(BUILD)/book.pdf
book-a5: $(BUILD)/book-a5.pdf
cover: $(BUILD)/cover.pdf
guides: $(BUILD)/cover-guides.pdf
cover-a5: $(BUILD)/cover-a5.pdf $(BUILD)/cover-a5-guides.pdf
figures: $(FIGURES)

# Diagrams: vector PDF for the print book, 300dpi PNG for the Markdown.
# Both are committed so GitHub shows the PNGs without building anything.
img/%.pdf: figures/%.tex figures/_preamble.tex | $(BUILD)
	@mkdir -p $(BUILD)/figures img
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD)/figures $< >/dev/null
	cp $(BUILD)/figures/$*.pdf $@
	pdftocairo -png -r 300 -singlefile $@ img/$*

$(BUILD)/book.tex: $(CHAPTERS) book/book.tex book/book.lua book/metadata.yaml $(FIGURES) | $(BUILD)
	pandoc $(CHAPTERS) \
	  --from markdown \
	  --metadata-file book/metadata.yaml \
	  --lua-filter book/book.lua \
	  --template book/book.tex \
	  --top-level-division=chapter \
	  -o $@

$(BUILD)/book.pdf: $(BUILD)/book.tex img/*
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) $< >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) $< >/dev/null
	@$(MAKE) --no-print-directory pages

# A5 edition: same chapters, book/metadata-a5.yaml overrides size and type.
$(BUILD)/book-a5.tex: $(CHAPTERS) book/book.tex book/book.lua book/metadata.yaml book/metadata-a5.yaml $(FIGURES) | $(BUILD)
	pandoc $(CHAPTERS) \
	  --from markdown \
	  --metadata-file book/metadata.yaml \
	  --metadata-file book/metadata-a5.yaml \
	  --lua-filter book/book.lua \
	  --template book/book.tex \
	  --top-level-division=chapter \
	  -o $@

$(BUILD)/book-a5.pdf: $(BUILD)/book-a5.tex img/*
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) $< >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) $< >/dev/null
	@pdfinfo $@ | grep -E '^(Pages|Page size)'

$(BUILD)/cover.pdf: book/cover.tex Makefile | $(BUILD)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) \
	  -jobname=cover "\def\spine{$(SPINE)}\input{book/cover.tex}" >/dev/null
	@# second run places the overlay correctly
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) \
	  -jobname=cover "\def\spine{$(SPINE)}\input{book/cover.tex}" >/dev/null

$(BUILD)/cover-guides.pdf: book/cover.tex Makefile | $(BUILD)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) \
	  -jobname=cover-guides "\def\spine{$(SPINE)}\def\guides{}\input{book/cover.tex}" >/dev/null
	@# second run places the overlay correctly
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) \
	  -jobname=cover-guides "\def\spine{$(SPINE)}\def\guides{}\input{book/cover.tex}" >/dev/null

A5COVER = \def\spine{$(SPINE_A5)}\def\trimW{148}\def\trimH{210}
$(BUILD)/cover-a5.pdf: book/cover.tex Makefile | $(BUILD)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) \
	  -jobname=cover-a5 "$(A5COVER)\input{book/cover.tex}" >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) \
	  -jobname=cover-a5 "$(A5COVER)\input{book/cover.tex}" >/dev/null

$(BUILD)/cover-a5-guides.pdf: book/cover.tex Makefile | $(BUILD)
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) \
	  -jobname=cover-a5-guides "$(A5COVER)\def\guides{}\input{book/cover.tex}" >/dev/null
	xelatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD) \
	  -jobname=cover-a5-guides "$(A5COVER)\def\guides{}\input{book/cover.tex}" >/dev/null

pages: $(BUILD)/book.pdf
	@pdfinfo $< | grep -E '^(Pages|Page size)'

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)
