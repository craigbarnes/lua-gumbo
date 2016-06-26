PANDOC = pandoc

docs: public/index.html public/api.html

public/index.html: README.md doc/api.md doc/template.html doc/style.css.inc | public/
	$(PANDOC) --smart --toc --include-in-header=doc/style.css.inc \
	  --template=doc/template.html --output=$@ README.md doc/api.md

public/api.html: doc/redir.html | public/
	cp $< $@

doc/style.css.inc: doc/style.css
	echo '<style>' > $@
	cat $< >> $@
	echo '</style>' >> $@

public/:
	$(MKDIR) $@

clean-docs:
	$(RM) doc/style.css.inc
	$(RM) -r public/


.PHONY: docs clean-docs
