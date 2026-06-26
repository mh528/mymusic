# flutter-push

Commit all changes and push to github.com/mh528/mymusic.

## Steps

1. Run `flutter analyze` — if there are any **errors** (not warnings), stop and report them. The 4 `unused_element_parameter` warnings on `destructive` are expected and fine to ignore.
2. Run `git status` to show what's changed.
3. Ask the user for a commit message, or suggest one based on the changes.
4. Stage all changed files: `git add -A`
5. Commit with the message (append `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>`)
6. Push: `git push origin main`
7. Confirm with the commit SHA and link to https://github.com/mh528/mymusic
