GIT_HOOKS = $(addprefix .git/hooks/, commit-msg pre-commit)
PERF_RECORD = perf record -g --call-graph=dwarf
LUA51_UTIL = LUA_CPATH='build/lua51/?.so;;' LUA_PATH='./?.lua;;' $(LUA51)
LUACOV ?= luacov
LCOV ?= lcov
LCOVFLAGS = --config-file mk/lcovrc
LCOV_REMOVE = $(foreach PAT, $(2), $(LCOV) -r $(1) -o $(1) '$(PAT)';)
GENHTML ?= genhtml
GENHTMLFLAGS = --config-file mk/lcovrc --title lua-gumbo

git-hooks: $(GIT_HOOKS)

perf:
	$(MAKE) -B -j$(NPROC) build/lib/benchmark CFLAGS='-O3 -pipe -DNDEBUG'
	$(PERF_RECORD) build/lib/benchmark test/benchmark/*.html

$(GIT_HOOKS): .git/hooks/%: mk/git-hooks/%
	$(E) CP '$@'
	$(Q) cp $< $@

coverage-report:
	$(MAKE) -B -j$(NPROC) build-lua51 check-lib CFLAGS='-Og -g -pipe --coverage -fno-inline' LDFLAGS='--coverage'
	$(LUA51_UTIL) -lluacov runtests.lua
	@echo
	$(LCOV) $(LCOVFLAGS) -c -b . -d build/ -o build/coverage.info
	$(call LCOV_REMOVE, build/coverage.info, */lib/char_ref.c */lib/error.c */lib/util.h */test/*)
	@echo
	$(LUACOV) -r lcov
	$(call LCOV_REMOVE, build/luacov-report.txt, */gumbo.lua)
	@echo
	$(GENHTML) $(GENHTMLFLAGS) -o public/coverage/ build/coverage.info build/luacov-report.txt
	find public/coverage/ -type f -regex '.*\.\(css\|html\)$$' | xargs $(XARGS_P) -- gzip -9 -k -f


.PHONY: git-hooks perf coverage-report
