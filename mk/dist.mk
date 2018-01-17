TAGS = 0.4 0.3 0.2 0.1
ROCKSPEC_VERS = $(addprefix $(firstword $(TAGS))., 53 52 51)

dist: $(addprefix public/dist/lua-gumbo-, $(addsuffix .tar.gz, $(TAGS)))
rockspecs: $(addprefix gumbo-, $(addsuffix -1.rockspec, $(ROCKSPEC_VERS)))

check-dist: dist
	sha1sum -c test/dist-sha1sums.txt

public/dist/lua-gumbo-%.tar.gz: | public/dist/
	$(E) ARCHIVE '$@'
	$(Q) git archive --prefix=lua-gumbo-$*/ -o $@ $*

gumbo-%-1.rockspec: rockspec.in mk/rockspec.sh
	$(E) GEN $@
	$(Q) mk/rockspec.sh '$*' < $< > $@

public/dist/: | public/
	@$(MKDIR) $@


CLEANFILES += gumbo-*.rockspec gumbo-*.rock
.PHONY: dist rockspecs check-dist
