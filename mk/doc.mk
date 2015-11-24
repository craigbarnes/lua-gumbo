PANDOC = pandoc
DATE   = $(shell date +'%B %d, %Y')

docs: README.html README.pdf

README.html: README.md doc/template.html doc/style.css.inc
	$(PANDOC) -S --toc --template $(word 2, $^) -H $(word 3, $^) -o $@ $<

README.pdf: doc/metadata.yml README.md
	sed '/^\[!\[Build Status/d' $^ | \
	  $(PANDOC) --toc -M date='$(DATE)' -V geometry:margin=3.5cm -o $@

doc/style.css.inc: doc/style.css
	echo '<style>' > $@
	cat $< >> $@
	echo '</style>' >> $@

clean-docs:
	$(RM) README.html README.pdf doc/style.css.inc


.PHONY: docs clean-docs
