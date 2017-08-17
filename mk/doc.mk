CHECKURL = curl -sSI -w "%{http_code}  $$URL  %{redirect_url}\n" -o /dev/null
PANDOC = pandoc
FIND_LINKS = $(LUA53_UTIL) examples/find_links.lua
EXAMPLE_NAMES = find_links get_title remove_by_id table_align_fix text_content
EXAMPLE_FILES = $(addprefix examples/, $(addsuffix .lua, $(EXAMPLE_NAMES)))
DOCS = public/index.html public/dist/index.html

PANDOCFLAGS = \
    --smart --toc \
    --template=doc/template.html \
    --include-in-header=doc/style.css.inc

docs: $(DOCS) public/api.html $(patsubst %, %.gz, $(DOCS))

public/index.html: README.md doc/api.md build/examples.md
public/dist/index.html: doc/releases.md | public/dist/

$(DOCS): public/%.html: doc/template.html doc/style.css.inc | public/
	@$(PRINT) PANDOC '$@'
	@$(PANDOC) $(PANDOCFLAGS) -o '$@' $(filter %.md, $^)

public/api.html: doc/redir.html | public/
	@$(PRINT) CP '$@'
	@cp $< $@

public/%.gz: public/%
	@$(PRINT) GZIP '$@'
	@gzip -9 < $< > $@

doc/style.css.inc: doc/layout.css doc/style.css
	@$(PRINT) CSSCAT '$@'
	@echo '<style>' > $@
	@cat $^ >> $@
	@echo '</style>' >> $@

build/examples.md: $(EXAMPLE_FILES) | build/
	@$(PRINT) MDCAT '$@'
	@printf "## Examples\n\n" > $@
	@for file in $^; do \
	  printf '```lua\n' >> $@; \
	  cat $$file >> $@; \
	  printf '```\n\n' >> $@; \
	done

public/:
	@$(MKDIR) $@

check-docs: $(DOCS) | build-lua53
	@for file in $^; do \
	  $(FIND_LINKS) $$file | grep '^https\?:' | \
	    while read URL; do $(CHECKURL) "$$URL" || exit 1; done \
	done

clean-docs:
	$(RM) doc/style.css.inc
	$(RM) -r public/


.PHONY: docs check-docs clean-docs
