PANDOC = pandoc
DATE = $(shell date +'%B %d, %Y')
DOC_TARGETS = README.html README.pdf doc/api.html

docs: $(DOC_TARGETS)

doc/%.html: doc/%.md doc/template.html doc/style.css.inc all
	$(PANDOC) -S --toc --template $(word 2, $^) -H $(word 3, $^) $< | \
	  $(LUA) examples/table_align_fix.lua > $@

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
	$(RM) $(DOC_TARGETS) doc/style.css.inc


.PHONY: docs clean-docs
