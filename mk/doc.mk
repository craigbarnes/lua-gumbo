PANDOC = pandoc

docs: public/index.html public/api.html

public/%.html: doc/%.md doc/template.html doc/style.css.inc | public/
	$(PANDOC) -S --toc --template $(word 2, $^) -H $(word 3, $^) -o $@ $<

public/index.html: README.md doc/template.html doc/style.css.inc | public/
	$(PANDOC) -S --toc --template $(word 2, $^) -H $(word 3, $^) -o $@ $<

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
