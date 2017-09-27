# Makefile for book publishing...

all: book
.PHONY: all

# figure out the OS...
OS := $(shell uname -s)

# .PHONY: all clean latex book preview
.SUFFIXES:
.SUFFIXES: .latex .pdf

PANDOC = pandoc
PANDOC_FLAGS = --from=markdown --to=latex

# LATEX = pdflatex
LATEX = xelatex
LATEX_FLAGS = -output-directory=$(outdir) --interaction=nonstopmode

INDEX = makeindex
INDEX_FLAGS = -s ./templates/index.sty

PREVIEW = evince
ifeq ($(OS),Darwin)
    PREVIEW = open
endif

outdir = output
bookname = BasenjiOwnersManual

srcdir = manuscript
manifest = $(srcdir)/Book.txt
#sources = $(shell sed -e '/#.*$/d;/^\s*$/d' manuscript/Book.txt)
#sources = $(addprefix $(srcdir)/,$(shell cat $(manifest)))
sources = \
	$(srcdir)/metadata.yaml \
	$(srcdir)/Ch1-About-Your-Basenji.md \
	$(srcdir)/Ch2-Living-with-a-Basenji.md \
	$(srcdir)/Ch3-Caring-For-Your-Basenji.md \
	$(srcdir)/Ch4-Basenji-Activities.md \
	$(srcdir)/Ch5-About-The-Evergreen-Basenji-Club.md \
	$(srcdir)/Reference-Library.md \

frontsources = \
	$(srcdir)/Introduction.md \
	$(srcdir)/Your-Basenji.md \

#backsources = \
#	$(srcdir)/Reference-Library.md \

templatesdir = templates

templatefiles = \
	$(templatesdir)/template.latex \
	$(templatesdir)/header.latex \
	$(templatesdir)/before-body.latex \
	$(templatesdir)/after-body.latex

book: $(outdir)/$(bookname).pdf
.PHONY: book

preview: book
	$(PREVIEW) $(outdir)/$(bookname).pdf
.PHONY: preview

$(outdir):
	mkdir $(outdir)

chaptercount = 2
ifdef FINAL_PDF
  chaptercount = 99
endif

ifdef FINAL_PDF
$(outdir)/frontmatter.latex: $(frontsources) | $(outdir)
	$(PANDOC) \
		$(PANDOC_FLAGS) \
		--output=$@ \
		$(frontsources)
else
$(outdir)/frontmatter.latex: | $(outdir)
	touch $@
endif

# $(outdir)/backmatter.latex: $(backsources) | $(outdir)
# 	$(PANDOC) \
# 		$(PANDOC_FLAGS) \
# 		--output=$@ \
# 		$(backsources)

ARG_TOC =
ARG_FRONTMATTER =

ifdef FINAL_PDF
    ARG_TOC = --table-of-contents
    ARG_FRONTMATTER = --include-before-body=$(outdir)/frontmatter.latex
endif

latex: clean $(outdir)/$(bookname).latex
.PHONY: latex

$(outdir)/$(bookname).latex: $(sources) $(templatefiles) $(outdir)/frontmatter.latex $(backsources)
	$(PANDOC) \
		$(PANDOC_FLAGS) \
		--standalone \
		--top-level-division=chapter \
		$(ARG_TOC) \
		--template=$(templatesdir)/template.latex \
		--include-in-header=$(templatesdir)/header.latex \
		--include-before-body=$(templatesdir)/before-body.latex \
		$(ARG_FRONTMATTER) \
		--include-after-body=$(templatesdir)/after-body.latex \
		--metadata=include-frontmatter:$(templatesdir)/before-body.latex \
		--output=$@ \
		$(wordlist 1, $(chaptercount), $(sources))

		# --include-after-body=$(backmatter) \

	@# Need to tweak output latex to change "\includegraphics{images/" into
	@# "\includegraphics{manuscript/images/" because pdflatex is being run
	@# from this directory (not from within manuscript or within output).
	sed -e 's/\(\\includegraphics{\)\(images\)/\1manuscript\/\2/' $@ > $@.sed1

	@# Specifically patch the height for one image...
	@#\includegraphics{manuscript/images/leash-for-lead-pop.png
	sed -e 's/\(\\includegraphics\)\({manuscript\/images\/leash-for-lead-pop.png}\)/\1[height=\\textheight]\2/' $@.sed1 > $@.sed2

	@# remove empty captions...
	sed -e '/^[[:space:]]*\\caption{}$$/d' $@.sed2 > $@.sed3
	rm -f $@
	mv $@.sed3 $@
	rm -f $@.sed*

# .latex.idx:
# 	latex $@

# .ids.ind:
# 	makeindex $(basename $@)

.latex.pdf:
ifdef FINAL_PDF
	@echo ===== LaTeX: first pass... =====
	-$(LATEX) $(LATEX_FLAGS) $^
	#@echo ===== BibTeX pass... =====
	bibtex $(basename $^)
	@echo ===== LaTeX: second pass... =====
	-$(LATEX) $(LATEX_FLAGS) $^
	@echo ===== mkindex pass... =====
	$(INDEX) $(INDEX_FLAGS) $(basename $^)
	@echo ===== LaTeX: third pass... =====
	@# expect non-zero exit code!
	-$(LATEX) $(LATEX_FLAGS) $^
endif
	@echo ===== LaTeX: final pass... =====
	-$(LATEX) $(LATEX_FLAGS) $^

clean:
	-rm -rfv $(outdir)
.PHONY: clean
