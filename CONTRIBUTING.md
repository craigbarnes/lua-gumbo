Pull Requests
-------------

* Do not mix unrelated improvements/commits in a single pull request. Open
  a new request for each issue so that they can be reviewed and merged
  separately.
* Include as few commits as necessary. Use `git rebase`, if necessary, to
  keep the history amenable to `git bisect`.
* Add test coverage for any new code. Update tests for any modified
  code. All new and existing tests should pass.

Commit Messages
---------------

* Hard wrap lines at no more than 72 columns.
* Don't use GitHub-specific features/references (e.g. "fixes issue #9").
* If there's more than a single line, the first line should be a short
  summary, followed by a blank line and any number of longer paragraphs.
* Use proper sentence case and punctuation, but don't add a period after
  single-line summaries.
* Add an ellipsis (`...`) to the end of the first line if it's followed
  by any additional paragraphs, so that it's clear from looking at
  `git log --oneline` which commits have additional information.

Coding Style
------------

* Above all else, be consistent with the existing code.
