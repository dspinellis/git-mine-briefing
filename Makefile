HTMLDIR?=$(UH)/dds/pubs/web/home/ghtorrent-briefing
TARGETS=$(shell sed -n 's|.*<a href="\([^"]*\).html">presentation.*|$(HTMLDIR)/\1.html $(HTMLDIR)/\1.pdf|p' index.html)
INDEX=$(HTMLDIR)/index.html
INDEX_PRES=$(HTMLDIR)/index.html

.SUFFIXES:.html .md .pdf

$(HTMLDIR)/%.html: %.md
	( cat head1.html ; \
	  sed -n 's|<li><a href="$(@F)">\([^<]*\)<.*|<title>\1<\/title>|p' index.html ; \
	  cat head2.html ; \
	  sed -n 's|<li><a href="$(@F)">\([^<]*\)<.*|## \1|p' index.html ; \
	  cat title.md ; \
	  cat $< ; \
	  cat tail.html ) >$@

$(HTMLDIR)/%.pdf: %.md
	( cat head1.md ; \
	  sed -n 's|<li><a href="$(basename $(@F)).html">\([^<]*\)<.*|{\\Large \1} \\\\|p' index.html ; \
	  cat head2.md ; \
	  date -r $< +'%F' ; \
	  echo '\end{center}'; \
	  sed 's/^---$$//' $< ; \
	  cat tail.md ) | \
	pandoc --variable mainfont=Arial --variable sansfont=Arial --from markdown-yaml_metadata_block+raw_tex --latex-engine=xelatex - -o $$(cygpath -w $@)

all: $(TARGETS) $(INDEX) $(INDEX_PRES)
	cp -ru a $(HTMLDIR)/

$(INDEX): index.html
	cp $< $@

clean:
	rm -f $(TARGETS)
