# Build the print book.
#   make book    -> build/book.pdf   (interior, trim + bleed per page)
#   make cover   -> build/cover.pdf  (back + spine + front, with bleed)
#   make guides  -> build/cover-guides.pdf (cover with cut/spine lines, for checking)
#   make pages   -> print the interior page count
#   make figures -> img/<name>.pdf (print) + img/<name>.png (Markdown) from figures/<name>.tex
#
# SPINE is the spine (세네카) width in mm from the printer's cover template.
# It depends on the page count and paper; update it after re-downloading the
# template for the final page count, e.g. `make cover SPINE=3.2`.

SPINE ?= 5.76
CHAPTERS := README.md $(sort $(wildcard chapter*.md))
BUILD := build
FIGURE_SRC := $(filter-out figures/_preamble.tex,$(wildcard figures/*.tex))
FIGURES := $(patsubst figures/%.tex,img/%.pdf,$(FIGURE_SRC))

.PHONY: all book cover guides pages figures clean

all: book cover

book: $(BUILD)/book.pdf
cover: $(BUILD)/cover.pdf
guides: $(BUILD)/cover-guides.pdf
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

pages: $(BUILD)/book.pdf
	@pdfinfo $< | grep -E '^(Pages|Page size)'

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)
