HOMEURL = https://craigbarnes.gitlab.io/lua-gumbo
GITURL  = git+https://gitlab.com/craigbarnes/lua-gumbo.git
TAGS    = 0.4 0.3 0.2 0.1

dist: $(addprefix public/dist/lua-gumbo-, $(addsuffix .tar.gz, $(TAGS)))

check-dist: dist
	sha1sum -c test/dist-sha1sums.txt

public/dist/lua-gumbo-%.tar.gz: | public/dist/
	@$(PRINT) ARCHIVE '$@'
	@git archive --prefix=lua-gumbo-$*/ -o $@ $*

gumbo-%-1.rockspec: URL = $(HOMEURL)/dist/lua-gumbo-$*.tar.gz
gumbo-%-1.rockspec: MD5 = `md5sum $(word 2, $^) | cut -d' ' -f1`
gumbo-%-1.rockspec: rockspec.in public/dist/lua-gumbo-%.tar.gz
	@$(PRINT) ROCKSPEC $@
	@sed "s|%VERSION%|$*|;s|%URL%|$(URL)|;s|%SRCX%|md5 = '$(MD5)'|" $< > $@

gumbo-scm-1.rockspec: SRCX = branch = "master"
gumbo-scm-1.rockspec: rockspec.in
	@$(PRINT) ROCKSPEC $@
	@sed 's|%VERSION%|scm|;s|%URL%|$(GITURL)|;s|%SRCX%|$(SRCX)|' $< > $@

public/dist/: | public/
	@$(MKDIR) $@


CLEANFILES += gumbo-*.rockspec gumbo-*.rock
.PHONY: dist check-dist
