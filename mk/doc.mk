PANDOC = pandoc
DATE   = $(shell date +'%B %d, %Y')

docs: README.html README.pdf

README.html: metadata.yml README.md template.html style.css.inc
	$(PANDOC) -S --toc --template template.html -H style.css.inc -o $@ \
	  metadata.yml README.md

README.pdf: metadata.yml README.md
	sed '/^\[!\[Build Status/d' metadata.yml README.md | \
	  $(PANDOC) --toc -M date='$(DATE)' -V geometry:margin=3.5cm -o $@

style.css.inc: style.css
	echo '<style>' > $@
	cat $< >> $@
	echo '</style>' >> $@


.PHONY: docs
