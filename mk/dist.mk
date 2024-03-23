TAGS = 0.5 0.4 0.3 0.2 0.1

dist: $(addprefix public/dist/lua-gumbo-, $(addsuffix .tar.gz, $(TAGS)))

public/dist/lua-gumbo-%.tar.gz: | public/dist/
	$(E) ARCHIVE '$@'
	$(Q) git archive --prefix=lua-gumbo-$*/ -o $@ $*

public/dist/: | public/
	@$(MKDIR) $@


.PHONY: dist
