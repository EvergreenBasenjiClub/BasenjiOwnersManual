# Makefile for book publishing...

all: book

.PHONY: all clean latex book preview
.SUFFIXES:
.SUFFIXES: .latex .pdf

LATEX = pdflatex
LATEX_FLAGS = --output-directory=$(outdir) --interaction=nonstopmode

PANDOC = pandoc
PANDOC_FLAGS = --from=markdown --to=latex

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

latex: $(outdir)/$(bookname).latex

book: $(outdir)/$(bookname).pdf

preview: book
	evince $(outdir)/$(bookname).pdf

$(outdir):
	mkdir $(outdir)

frontmatter = $(outdir)/frontmatter.latex
#backmatter = $(outdir)/backmatter.latex

$(outdir)/$(bookname).latex: $(sources) $(templatefiles) $(frontsources) $(backsources) | $(outdir)
	$(PANDOC) \
		$(PANDOC_FLAGS) \
		--output=$(frontmatter) \
		$(frontsources)

#	$(PANDOC) \
#		$(PANDOC_FLAGS) \
#		--output=$(backmatter) \
#		$(backsources)

	$(PANDOC) \
		$(PANDOC_FLAGS) \
		--standalone \
		--chapters \
		--table-of-contents \
		--template=$(templatesdir)/template.latex \
		--include-in-header=$(templatesdir)/header.latex \
		--include-before-body=$(templatesdir)/before-body.latex \
		--include-before-body=$(frontmatter) \
		--include-after-body=$(templatesdir)/after-body.latex \
		--metadata=include-frontmatter:$(templatesdir)/before-body.latex \
		--output=$@ \
		$(sources)

#		--include-after-body=$(backmatter) \

	# Need to tweak output latex to change "\includegraphics{images/" into
	# "\includegraphics{manuscript/images/" because pdflatex is being run
	# from this directory (not from within manuscript or within output).
	sed --in-place --expression='s/\(\\includegraphics{\)\(images\)/\1manuscript\/\2/' $@

# .latex.idx:
# 	latex $@

# .ids.ind:
# 	makeindex $(basename $@)

.latex.pdf:
	@echo ===== LaTeX: first pass... =====
	$(LATEX) $(LATEX_FLAGS) $^
	#@echo ===== BibTeX pass... =====
	#bibtex $(basename $^)
	@echo ===== LaTeX: second pass... =====
	$(LATEX) $(LATEX_FLAGS) $^
	@echo ===== mkindex pass... =====
	mkindex $(basename $^)
	# @echo ===== LaTeX: third pass... =====
	# $(LATEX) $(LATEX_FLAGS) $^
	@echo ===== LaTeX: final pass... =====
	-$(LATEX) $(LATEX_FLAGS) $^
#dvipdf $(basename $^).dvi $@
#pandoc -o $@ $^

# book: xxx.pdf xxx.latex

# input = manuscript/a-brief-background.md
# xxx.pdf: $(input)
# 	pandoc -o xxx.pdf $(input)

# yyy.latex: $(input)
# 	pandoc -o yyy.latex $(input)

# yyy.pdf: yyy.latex

clean:
	-rm -rfv $(outdir)
