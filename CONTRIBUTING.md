Bug Reports
-----------

* Check if the bug already exists in the [issue tracker]. If not, open a
  [new issue].
* Include any relevant error messages and test cases, formatted as
  Markdown [code blocks]. Avoid linking to external paste services.
* Make test cases as minimal as possible.
* For general suggestions or feedback, leave a message in the [chat room].

[issue tracker]: https://github.com/craigbarnes/lua-gumbo/issues
[new issue]: https://github.com/craigbarnes/lua-gumbo/issues/new
[code blocks]: https://help.github.com/articles/github-flavored-markdown/#fenced-code-blocks
[chat room]: https://gitter.im/craigbarnes/lua-gumbo

Pull Requests
-------------

* Create a feature branch and submit a separate [pull request] for each
  issue. Avoid mixing unrelated improvements/commits in a single request.
* Include as few commits as necessary, without any merge commits.
* Add test coverage for new code. Update tests for modified code. All new
  and existing tests should pass.

[pull request]: https://github.com/craigbarnes/lua-gumbo/pulls

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
