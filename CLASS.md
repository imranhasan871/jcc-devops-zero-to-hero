# Class 03 — Security Incident: Secrets in Git

## The Scenario

A second developer joined the team this morning. Excited to contribute, they cloned the
repo, ran `npm install`, and committed their changes. You get a Slack message ten minutes
later: "I pushed some files, hope that's okay." You check the commit. They have committed
the entire `node_modules/` directory (437 MB) and their `.env` file — which contains a
live Stripe test API key and the staging database password. Both are now in the public
Git history. The repo is hosted on GitHub.

You need to act in the next 30 minutes: rotate the credentials, scrub the history, and
make it structurally impossible for this to happen again.

## The Problem

Evidence from the repository:

```
$ git log --oneline -3
a3f9c12  add my changes
b1e4d77  class-02: add express server
...

$ git show --stat a3f9c12 | head -20
 .env                          |   4 +
 node_modules/.package-lock.json | 12 +
 node_modules/accepts/index.js  |  ...
 ... (thousands of files)
```

The `.env` file in that commit contains:
```
STRIPE_SECRET_KEY=sk_test_abc123realkey
DB_PASSWORD=supersecret
```

Even after deleting the files, they remain in Git history forever — anyone with repo
access can run `git checkout a3f9c12 -- .env` and recover the credentials.

## Your Mission

- Remove `node_modules/` and all `.env` files from the entire Git history so that
  `git log --all --full-history -- "node_modules/"` and
  `git log --all --full-history -- ".env"` both return empty output.
- Add a `.gitignore` to the repository root that prevents `node_modules/`, any `*.env`
  file, `.env`, `.env.local`, `.env.*.local`, and common OS noise files (`.DS_Store`,
  `Thumbs.db`) from ever being tracked again.
- Reorganise the project: move `index.html` to `public/index.html`. `server.js` stays at
  the project root. Update `server.js` so `express.static('public')` serves from the
  correct location after the move.
- Write a `README.md` that allows a developer who has never seen this project to go from
  a fresh `git clone` to a running server in under 3 minutes. The README must contain
  exact commands, not descriptions of commands. Every command must be copy-pasteable and
  correct.
- After all changes, `git status` must show a clean working tree.

## What You Need to Know First

- **`.gitignore`** — a file at the repo root that tells Git which files and directories to
  never track. Patterns use glob syntax. Once a file is already tracked, adding it to
  `.gitignore` does not remove it from history — you must explicitly untrack it.
- **`git rm --cached`** — removes a file from the Git index (stops tracking it) without
  deleting it from disk. Essential for untracking files that slipped into the index before
  `.gitignore` was set up.
- **`git filter-repo`** — a modern tool (faster and safer than `git filter-branch`) for
  rewriting Git history to remove files. Install with `pip install git-filter-repo` or via
  Homebrew. `git filter-repo --path node_modules/ --invert-paths` removes a path from all
  commits.
- **Git history rewriting** — any command that changes past commits (filter-repo,
  interactive rebase) creates new commit SHAs for every affected commit. After a history
  rewrite, a `git push --force` is required to update a remote. This is destructive on
  shared branches — coordinate with teammates first.
- **Credential rotation** — simply removing a secret from Git history is not enough if the
  repo was ever public or if other people have cloned it. The only safe response to an
  exposed credential is to revoke it immediately in the service that issued it, then issue
  a new one.

## Constraints

- After your changes, `git log --all --full-history -- "node_modules/"` must return
  absolutely nothing. The examiner will run this exact command.
- After your changes, `git log --all --full-history -- ".env"` must return absolutely
  nothing.
- The `README.md` must contain actual runnable commands (`npm install`, `npm start`,
  `curl http://localhost:3000/health`). Prose descriptions without commands do not count.
- You may not simply create a fresh repository and copy files in — the Git history of
  class-01 and class-02 commits must be preserved (only the offending files removed).

## Verification

```bash
# History must be clean of node_modules
git log --all --full-history -- "node_modules/"
# must return: (nothing)

# History must be clean of .env files
git log --all --full-history -- ".env"
# must return: (nothing)

# Working tree must be clean
git status
# must output: nothing to commit, working tree clean

# README must reference npm install
grep "npm install" README.md
# must return the matching line

# Public directory must exist with index.html
ls public/index.html
# must succeed (exit 0)

# Server must still start and respond after the refactor
npm install && node server.js &
sleep 2
curl -s http://localhost:3000/health | grep '"status":"ok"'
# must match
kill %1
```

## Stretch Challenge

Write a Git pre-commit hook at `.git/hooks/pre-commit` that automatically blocks any
commit containing:

1. A file larger than 1 MB.
2. A file whose name matches `*.env` or `.env`.

The hook must print a clear error message identifying the offending file by name and exit
non-zero to abort the commit. Test it: try to commit a `.env` file — the hook must stop
you. The hook must be a plain shell script (no Node.js, no Python dependencies).

## Instructor Notes

Credential exposure is among the top five causes of cloud security incidents. This class
makes the lesson visceral: students must manually scrub a history, which takes longer and
feels worse than setting up `.gitignore` in the first place.

**`git filter-branch` vs `git filter-repo`:** `filter-branch` is the built-in tool but is
slow, has subtle edge cases, and Git itself now prints a warning recommending `filter-repo`.
Use `filter-repo`. If the student only has `filter-branch` available, it works but takes
longer on large repos.

**Common wrong approaches:**

- Deleting the file and committing a new commit — the credential is still in the previous
  commit; `git log -p` reveals it instantly.
- Adding `.gitignore` without `git rm --cached` — the files stay tracked; `.gitignore`
  only affects untracked files.
- Starting a fresh repo — loses the course history; the examiner can tell.

**Why reorganise into `public/`?** It is good practice to separate files served to the
internet from files that run on the server. This separation becomes load-bearing when we
write a Dockerfile: we will explicitly copy only `public/` into the image for the static
tier and only `server.js` / `package.json` for the API tier.
