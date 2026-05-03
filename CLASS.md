# Class 03 — Project Structure & Git Hygiene

## Objective
A working app is not the same as a well-organized project. In this class we apply the
most fundamental DevOps habit: making sure the repository itself is clean, navigable,
and trustworthy. We add a `.gitignore` to stop tracking generated files, move source
files to a logical directory layout, and write a `README.md` so that any developer
(or your future self) can understand and run the project in under two minutes.

## What You'll Learn
- Why committing `node_modules/` to git is a serious mistake
- How `.gitignore` patterns work and what belongs in one
- How to structure a Node.js project into logical directories
- How to write a README that is genuinely useful (not just a formality)
- The principle: the repository should be the source of truth, not a dumping ground

## What Changed in This Class
- Added `.gitignore` — excludes `node_modules/`, `.env`, `build/`, OS noise
- Added `README.md` — project overview, directory structure, setup instructions, API table
- Moved `index.html` → `public/index.html` (separating static assets from server code)
- Updated `server.js` — `express.static` now serves from `public/` directory

## Hands-On Exercise
1. Check what git was previously tracking: `git log --oneline --name-only`.
2. After this commit, run `git status` inside the project. Notice `node_modules/` no longer appears.
3. Run `npm install` to create `node_modules/`, then run `git status` again — git ignores it.
4. Try to force-add it: `git add node_modules/`. Git still respects `.gitignore`.
5. Inspect the directory: you should now see `public/index.html` instead of `index.html`.
6. Start the server (`npm start`) and confirm `http://localhost:3000` still works — the
   app is unchanged; only the layout changed.
7. Read the README out loud as if you are a new developer joining the project. Is anything
   unclear? That is your signal to improve it.

## Key Concepts

**`.gitignore` patterns**: Git reads `.gitignore` from the repo root (and any subdirectory).
A trailing slash (`node_modules/`) matches only directories. A leading slash (`/build`) anchors
the pattern to the root. An asterisk matches any string except `/`. You can override an
ignored pattern with `!` (e.g., `!important-build-artifact`).

**`node_modules/` in git**: The `node_modules/` directory can contain tens of thousands of
files and hundreds of megabytes. Committing it makes every `git clone` and `git pull`
drastically slower, bloats the repository history permanently, and creates merge conflicts
that are essentially impossible to resolve. The `package.json` + `package-lock.json` files
are the source of truth — `npm install` always recreates the exact same tree from them.

**Separation of concerns in directory layout**: Placing static frontend files in `public/`
and server code in the root (or a `src/` directory) makes it immediately clear what is
served to browsers versus what runs on the server. This distinction becomes critical when
we add a Dockerfile — we want to be intentional about what goes into the image.

## Next Class Preview
We introduce environment configuration so the server's port, database URL, and other
settings can be changed without editing source code.
