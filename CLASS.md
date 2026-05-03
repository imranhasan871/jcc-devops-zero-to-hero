# Class 11 — CI Doesn't Lie

## The Scenario
Three developers merged code to `main` this week. Friday at 5:45 pm, a client
calls: the `/api/applicants` POST endpoint returns `500` on production. You dig
into the logs and find a JavaScript syntax error committed at 3:04 pm by a
developer who "quickly fixed something." Nobody caught it because there are no
automated checks. The entire team's Friday evening is gone. The client's
applications are blocked. This never happens again starting today.

## The Problem
There is no GitHub Actions workflow in this repository. Nothing validates code
before it reaches `main`. A single typo in `server.js` can take production down
for hours and nobody finds out until a client calls.

## Your Mission
1. Create a GitHub Actions workflow that runs on every push to every branch and
   on every pull request targeting `main`.
2. The workflow must: install dependencies, run the linter, run the full test
   suite. If any step fails the entire workflow fails.
3. Cache `node_modules` between runs using `actions/cache` — the workflow must
   finish in under 3 minutes total.
4. Demonstrate the workflow catching a real fault: introduce a deliberate syntax
   error in `server.js`, push it, confirm the Actions tab shows a red ✗, then
   fix it and confirm a green ✓.
5. Document (in a `notes.md` or inline comments) exactly what GitHub branch
   protection settings must be enabled so that a failing CI blocks the merge
   button — not just shows a warning.

## What You Need to Know First
- GitHub Actions workflow syntax: `on`, `jobs`, `steps`, `uses`, `run`
- The difference between `npm install` and `npm ci`
- `actions/checkout`, `actions/setup-node`, `actions/cache` — what each does
- How GitHub branch protection rules connect to required status checks
- What a workflow `needs:` dependency does between jobs

## Constraints
- Only three external actions are allowed: `actions/checkout`,
  `actions/setup-node`, `actions/cache`. No marketplace shortcuts.
- The cache key must incorporate `package-lock.json` so it invalidates when
  dependencies change.
- The workflow file must live at `.github/workflows/ci.yml`.
- Branch protection documentation must name the exact repository setting path:
  Settings → Branches → Branch protection rules → "Require status checks to
  pass before merging."

## Verification
```bash
# 1. Introduce a syntax error
echo "const x = {" >> server.js
git add server.js && git commit -m "deliberate syntax error"
git push origin class-11

# 2. Check Actions tab — must show red ✗ for the push above.

# 3. Revert the error
git revert HEAD --no-edit
git push origin class-11

# 4. Check Actions tab — must show green ✓ for the revert push.

# 5. Locally confirm the cache is being used on the second run:
#    In the Actions log, the "Restore cache" step must say "Cache restored".
```
Both run URLs (one red, one green) must be recorded in your notes.

## Stretch Challenge
Add a step that posts a comment on pull requests with the Jest test coverage
percentage. The comment must only fire on PR events — never on direct pushes.
If you push a second commit to the same PR the step must update the existing
comment rather than posting a new one.

## Instructor Notes
Branch protection rules are the enforcement mechanism. CI without branch
protection is a polite suggestion — any developer can ignore it and merge.
Requiring the status check in branch protection is what makes CI mandatory.

The cache step is not cosmetic. Without it, `npm ci` takes 40–50 seconds on
every run. With caching, subsequent runs restore in under 5 seconds. Over 50
pushes per week that is 30+ minutes of unnecessary waiting for the team.

Wrong approach to avoid: using `npm install` instead of `npm ci`. `npm ci`
installs from the lockfile exactly, making the CI environment deterministic.
`npm install` can silently upgrade patch versions and introduce inconsistency
between local and CI environments — exactly the kind of subtle bug that
causes "it works on my machine" failures.
