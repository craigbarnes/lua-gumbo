CHECKURL = curl -sSI -w "%{http_code}  $$URL  %{redirect_url}\n" -o /dev/null
PANDOC = pandoc
EXAMPLE_NAMES = find_links get_title remove_by_id table_align_fix text_content
EXAMPLE_FILES = $(addprefix examples/, $(addsuffix .lua, $(EXAMPLE_NAMES)))
DOCS = public/index.html public/dist/index.html

PANDOCFLAGS = \
    --smart --toc \
    --template=doc/template.html \
    --include-in-header=doc/style.css.inc

docs: $(DOCS) public/api.html

public/index.html: README.md doc/api.md build/examples.md
public/dist/index.html: doc/releases.md | public/dist/

$(DOCS): public/%.html: doc/template.html doc/style.css.inc | public/
	$(PANDOC) $(PANDOCFLAGS) -o '$@' $(filter %.md, $^)

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

check-docs: $(DOCS) | all
	@for file in $^; do \
	  $(LUA) examples/find_links.lua $$file | grep '^https\?:' | \
	    while read URL; do $(CHECKURL) "$$URL" || exit 1; done \
	done

clean-docs:
	$(RM) doc/style.css.inc
	$(RM) -r public/


.PHONY: docs check-docs clean-docs
