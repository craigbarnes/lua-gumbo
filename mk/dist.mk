TAGS = 0.4 0.3 0.2 0.1

dist: $(addprefix public/dist/lua-gumbo-, $(addsuffix .tar.gz, $(TAGS)))

check-dist: dist
	sha1sum -c test/dist-sha1sums.txt

public/dist/lua-gumbo-%.tar.gz: | public/dist/
	$(E) ARCHIVE '$@'
	$(Q) git archive --prefix=lua-gumbo-$*/ -o $@ $*

public/dist/: | public/
	@$(MKDIR) $@


.PHONY: dist check-dist
