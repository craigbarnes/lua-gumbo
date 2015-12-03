HOMEURL = https://craigbarnes.github.io/lua-gumbo
GITURL  = git://github.com/craigbarnes/lua-gumbo.git
VERSION = $(or $(shell git describe --abbrev=0),$(error No version info))

dist:
	@$(MAKE) -s lua-gumbo-$(VERSION).tar.gz gumbo-$(VERSION)-1.rockspec

lua-gumbo-%.tar.gz:
	@git archive --prefix=lua-gumbo-$*/ -o $@ $*
	@echo 'Generated: $@'

gumbo-%-1.rockspec: URL = $(HOMEURL)/dist/lua-gumbo-$*.tar.gz
gumbo-%-1.rockspec: MD5 = `md5sum lua-gumbo-$*.tar.gz | cut -d' ' -f1`
gumbo-%-1.rockspec: rockspec.in lua-gumbo-%.tar.gz
	@sed "s|%VERSION%|$*|;s|%URL%|$(URL)|;s|%SRCX%|md5 = '$(MD5)'|" $< > $@
	@echo 'Generated: $@'

gumbo-scm-1.rockspec: SRCX = branch = "master"
gumbo-scm-1.rockspec: rockspec.in
	@sed 's|%VERSION%|scm|;s|%URL%|$(GITURL)|;s|%SRCX%|$(SRCX)|' $< > $@
	@echo 'Generated: $@'

.PHONY: dist
