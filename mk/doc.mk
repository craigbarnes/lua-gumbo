CHECKURL = curl -sSI -w "%{http_code}  $$URL  %{redirect_url}\n" -o /dev/null
PANDOC = pandoc
EXAMPLE_NAMES = find_links get_title remove_by_id table_align_fix text_content
EXAMPLE_FILES = $(addprefix examples/, $(addsuffix .lua, $(EXAMPLE_NAMES)))
DOC_FILES = README.md doc/api.md build/examples.md

docs: public/index.html public/api.html

public/index.html: $(DOC_FILES) doc/template.html doc/style.css.inc | public/
	sed '/^For full API documentation/d' $(DOC_FILES) | \
	  $(PANDOC) --smart --toc --include-in-header=doc/style.css.inc \
	  --template=doc/template.html --output=$@

public/api.html: doc/redir.html | public/
	cp $< $@

doc/style.css.inc: doc/style.css
	echo '<style>' > $@
	cat $< >> $@
	echo '</style>' >> $@

build/examples.md: $(EXAMPLE_FILES) | build/
	printf "## Examples\n\n" > $@
	for file in $^; do \
	  printf '```lua\n' >> $@; \
	  cat $$file >> $@; \
	  printf '```\n\n' >> $@; \
	done

public/:
	$(MKDIR) $@

check-docs: public/index.html all
	@$(LUA) examples/find_links.lua $< | grep '^https\?:' | \
	  while read URL; do $(CHECKURL) "$$URL" || exit 1; done

clean-docs:
	$(RM) doc/style.css.inc
	$(RM) -r public/


.PHONY: docs check-docs clean-docs
