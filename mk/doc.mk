CHECKURL = curl -sSI -w "%{http_code}  $$URL  %{redirect_url}\n" -o /dev/null
DOXYGEN = doxygen
PANDOC = pandoc
PANDOCFLAGS = --toc --template=docs/template.html -Mtitle=_
FIND_LINKS = $(LUA53_UTIL) examples/find_links.lua
EXAMPLE_NAMES = find_links get_title remove_by_id table_align_fix text_content
EXAMPLE_FILES = $(addprefix examples/, $(addsuffix .lua, $(EXAMPLE_NAMES)))
DOCS = public/index.html public/releases.html

docs: $(DOCS) public/api.html $(patsubst %, %.gz, $(DOCS))
doxygen: public/libgumbo/index.html

public/index.html: README.md docs/api.md build/docs/examples.md
public/releases.html: docs/releases.md

$(DOCS): public/%.html: docs/template.html | public/style.css.gz
	$(E) PANDOC '$@'
	$(Q) $(PANDOC) $(PANDOCFLAGS) -o '$@' $(filter %.md, $^)

public/api.html: docs/redir.html | public/
	$(E) CP '$@'
	$(Q) cp $< $@

public/%.gz: public/%
	$(E) GZIP '$@'
	$(Q) gzip -9 < $< > $@

public/style.css: docs/layout.css docs/style.css | public/
	$(E) CAT '$@'
	$(Q) cat $^ > $@

build/docs/examples.md: $(EXAMPLE_FILES) | build/docs/
	$(E) CAT '$@'
	$(Q) printf "## Examples\n\n" > $@
	$(Q) for file in $^; do \
	  printf '```lua\n' >> $@; \
	  cat $$file >> $@; \
	  printf '```\n\n' >> $@; \
	done

public/libgumbo/index.html: docs/doxygen-layout.xml docs/doxygen-footer.html
public/libgumbo/index.html: docs/libgumbo.doxy lib/gumbo.h | public/
	$(E) DOXYGEN $(@D)/
	$(Q) $(DOXYGEN) $<

build/docs/ public/:
	@$(MKDIR) $@

check-docs: $(DOCS) | build-lua53
	@for file in $^; do \
	  $(FIND_LINKS) $$file | grep '^https\?:' | \
	    while read URL; do $(CHECKURL) "$$URL" || exit 1; done \
	done

clean-docs:
	$(RM) -r public/


.PHONY: docs doxygen check-docs clean-docs
