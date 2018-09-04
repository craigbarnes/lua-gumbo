GIT_HOOKS = $(addprefix .git/hooks/, commit-msg pre-commit)
PERF_RECORD = perf record -g --call-graph=dwarf

git-hooks: $(GIT_HOOKS)

perf:
	$(MAKE) -B -j$(NPROC) build/lib/benchmark CFLAGS='-O3 -pipe -DNDEBUG'
	$(PERF_RECORD) build/lib/benchmark test/benchmark/*.html

$(GIT_HOOKS): .git/hooks/%: mk/git-hooks/%
	$(E) CP '$@'
	$(Q) cp $< $@


.PHONY: git-hooks perf
