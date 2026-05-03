# Class 01 — The Single-File Emergency

## The Scenario

The John Casablancas Centre director has a board meeting tomorrow at 9 AM. She needs to
demonstrate the applicant portal to the board: three programmes on screen, a working
application form, and submitted entries visible immediately. There is no development team,
no server, no hosting account — just you, your laptop, and tonight. The board room has
unreliable Wi-Fi, so the demo must run entirely offline.

## The Problem

Nothing exists. There is a domain name and a dream. The director can describe what the
portal should do, but there is no code, no database, no deployment pipeline. You have
roughly four hours. If the demo fails, the funding conversation fails with it.

You need something a non-technical director can open by double-clicking a file. It must
look credible, accept real input, and not lose submitted data if she accidentally refreshes
the browser mid-presentation.

## Your Mission

- The file `index.html` must open in any modern browser by double-clicking — no terminal,
  no `npm install`, no server command required.
- The application must display exactly three John Casablancas Centre programmes (names and
  short descriptions of your choice).
- The application form must validate inputs before submission: `name` is required, `email`
  must be a valid email address, a programme must be selected. Submitting an invalid form
  must show a clear inline error — not a browser alert.
- Submitted applications must appear on screen immediately after submission without a page
  reload.
- Submitted applications must survive a browser page refresh (the director WILL hit F5
  during the presentation).
- The entire solution must live in a single file. No external CSS files, no external JS
  files, no CDN imports, no `<script src="...">`, no `<link href="...">` pointing anywhere
  external.

## What You Need to Know First

- **HTML forms** — `<form>`, `<input>`, `<select>`, `<button>` and how the browser handles
  form submission by default (hint: it navigates away; you will need to prevent that).
- **DOM manipulation** — `document.querySelector`, `createElement`, `appendChild`,
  `innerHTML`. How JavaScript reads form field values and writes content into the page.
- **Event listeners** — `addEventListener('submit', ...)` and `event.preventDefault()`.
- **`localStorage`** — a browser API (`localStorage.setItem`, `getItem`, `JSON.stringify`,
  `JSON.parse`) that persists string data between page reloads for the same origin. Data
  is stored on the user's device and never leaves it.
- **Inline `<style>` and `<script>` tags** — how to embed CSS and JavaScript directly
  inside an HTML file so the file is self-contained.

## Constraints

- One file only. The marker will open `index.html` directly in the browser. No other files
  will be present in the directory. If your solution references any external resource, it
  will fail.
- No frameworks. No React, Vue, Angular, jQuery, Bootstrap, Tailwind, or any library —
  not even via CDN. Everything must be hand-written vanilla HTML, CSS, and JavaScript.
- No `alert()` or `confirm()` for validation feedback. Errors must appear inline in the
  page next to the relevant field.
- The solution must work in both Chrome and Firefox without modification.

## Verification

Open `index.html` in a browser. Run through each check manually:

```bash
# There must be exactly one file in your submission directory
ls -1 | wc -l   # must output: 1

# The file must be valid HTML (install html-validate if needed)
npx html-validate index.html   # must exit 0 with no errors
```

Manual checks (examiner will run these):

1. Open the file offline (disable Wi-Fi first). The page must load fully.
2. Submit the form with an empty name — an error must appear next to the name field.
3. Submit the form with `not-an-email` in the email field — an error must appear next to
   the email field.
4. Submit a valid application — it must appear in the applicants section immediately.
5. Refresh the page — the submitted application must still be visible.
6. Submit a second application — both must be visible simultaneously.

## Stretch Challenge

Add a live countdown timer that displays "Application deadline: X hours Y minutes" counting
down from exactly 48 hours after the page first loads. The deadline must be stored in
`localStorage` so it continues counting from the same endpoint even after a page refresh —
it must not reset to 48:00 every time the user refreshes.

## Instructor Notes

This class exists to establish the baseline: what is the absolute minimum you need to
deliver a working user interface? A browser needs exactly one thing — an HTML file. That
is it. No Node.js, no webpack, no cloud account.

The constraint of a single file is not cruelty. It forces students to understand what
browsers actually do: parse HTML, apply CSS, execute JavaScript. Everything else in this
course is infrastructure built on top of that foundation.

**Common wrong approaches:**

- Reaching for `create-react-app` immediately — results in a 200 MB project that cannot
  be opened by double-clicking a file.
- Using `fetch()` to call an API that doesn't exist yet — there is no server in this class.
- Storing data in a JavaScript variable — refreshing the page wipes all variables.

**What `localStorage` limitation teaches:** When a second staff member opens the same file
on a different machine, their `localStorage` is empty. The submitted applications exist only
on the original machine. This is not a bug to fix in this class — it is the exact pain that
motivates Class 02.
