GIT_HOOKS = $(addprefix .git/hooks/, commit-msg pre-commit)

git-hooks: $(GIT_HOOKS)

$(GIT_HOOKS): .git/hooks/%: mk/git-hooks/%
	@$(PRINT) CP '$@'
	@cp $< $@


.PHONY: git-hooks
