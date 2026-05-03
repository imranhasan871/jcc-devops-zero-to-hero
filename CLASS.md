# Class 01 — Plain HTML App (Zero DevOps)

## Objective
This class establishes our starting point: a fully functional applicant management interface
for John Casablancas Centers built entirely in a single HTML file with no build tools, no
server, and no DevOps infrastructure whatsoever. The goal is to feel the pain of this
approach so that every improvement we make in subsequent classes is motivated by real
problems, not abstract theory.

## What You'll Learn
- How a pure client-side app works (HTML + CSS + JavaScript in one file)
- How `localStorage` provides persistence without a server
- Why "it works on my machine" is a real and serious problem
- What the limitations of zero-infrastructure apps look like in practice

## What Changed in This Class
- Added `index.html` — the entire application: programs grid, application form, applicants list
- All data stored in browser `localStorage` — no backend, no database
- All logic in a single `<script>` block inside the HTML file

## Hands-On Exercise
1. Open `index.html` directly in your browser (`File → Open` or drag-and-drop).
2. You should see four program cards and an application form.
3. Submit an application for yourself. Notice the applicant appears immediately below.
4. Refresh the page — the applicant is still there (thanks to `localStorage`).
5. Open the same file in a **different browser** (e.g., Firefox if you used Chrome).
6. Notice: **the applicant list is empty**. Data does not travel between browsers.
7. Open DevTools → Application → Local Storage. Find the `jcc_applicants` key and inspect the raw JSON.
8. Delete the key and refresh. Data is gone forever.
9. Ask yourself: how would a second staff member at a different computer see the same applicants?

## Key Concepts

**localStorage**: A browser API that lets JavaScript persist key-value data across page
reloads for the same origin. It is device-local and browser-local, meaning data never
leaves the user's machine and is invisible to anyone else.

**Single-file app**: Putting HTML, CSS, and JavaScript in one file is convenient for
prototyping but creates a maintenance nightmare as complexity grows. There is no separation
of concerns, no reusability, and no way to test logic independently of the UI.

**Zero portability**: Without a server, there is no URL to share, no way to deploy, no
version running "in production." Everyone who wants the app must have the file on their
own machine — and their data stays isolated there.

## Next Class Preview
We introduce a Node.js/Express server so data lives in one place and multiple users can
share the same applicant list over HTTP.
