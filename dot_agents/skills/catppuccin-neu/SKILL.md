---
name: catppuccin-neu
description: >
  Use any time you style HTML: a new page, a component, a form, a fix for
  something that looks off, or a CSS pin bump. Everything gets styled with the
  catppuccin-neu design system unless the user says otherwise.
---

# catppuccin-neu

A dark-only, CSS-only design system in Catppuccin Mocha with neumorphic depth.
The full list of recipes, utilities, tokens, and live examples is the docs
site: https://catppuccin-neu.balajileninrajan.dev. Check it before writing any
CSS. `node_modules/catppuccin-neu/SPEC.md` has every rule and number.

## How to use it

1. Install one way, never vendor the CSS:
   - Bundler: `pnpm add github:BalajiLeninrajan/catppuccin-neu#vX.Y.Z` and
     `import "catppuccin-neu/css/index.css"` at the root.
   - No `package.json`: link
     `https://cdn.jsdelivr.net/gh/BalajiLeninrajan/catppuccin-neu@vX.Y.Z/css/index.css`.
   - Pin a full tag. Add the Google Fonts link (Inter, JetBrains Mono) to
     every page.
2. Build from recipes (`btn btn-primary`, `panel`, `well`, `field`,
   `table-neu`, `chip-tone`, `modal`, `drawer`, `toast`) and compose `cn-*`
   utilities on top for layout, spacing, type, color, and depth. Utilities
   beat recipes, and your own unlayered CSS beats both, so `!important` is
   never needed.
3. Re-key a subtree with the contract props: `--accent`, `--tone`
   (`cn-tone-*`), `--hard-offset`, `--hard-offset-color`. Set density once on
   an ancestor: `data-density="compact"` for forms, `"dense"` for tables.
4. Wrap the page as `body.app-shell` > `header.topbar` + `main.page-main` +
   `footer.footer-neu`. Prefer `dialog.modal` / `dialog.drawer` for overlays.
5. Write custom CSS only for what no class expresses (a bespoke animation, a
   one-off layout). Prefix it, keep it unlayered, use tokens, and say that it
   looks like a package gap if it restates a recipe.

## Corrections from earlier sessions

- There should be zero custom CSS for ordinary things. If you wrote a flex
  row, a truncation, a padded card, or a colored label by hand, replace it
  with the utility classes. Ask "can I combine classes instead?" first.
- Check the docs site before inventing anything. The answer is usually a
  class that already exists.
- Never introduce a color outside the Mocha palette, including on hover.
  A hover that changes to another palette color is fine.
- Don't stack decoration on a card. A spine plus a gradient plus an eyebrow
  reads as AI slop. One material cue per surface.
- Don't wrap everything in a panel. A top-level progress bar, a hero, a
  simple list can sit on the page ground.
- Buttons are not 100% width by default. Size them to their label, and
  space them with `cn-mt-*` rather than raw margins.
- Mono is for code, CLI names, paths, and ids (`cn-code`, `cn-code-meta`,
  `command`, `codeblock`). Not for prose, headings, or whole control sets.
- Links, project lists, and nav should use the system's own text-link and
  flat-button treatments, not restyled anchors.
- If glyph fonts (Nerd Fonts) are used for icons, import the font. Don't
  rely on the viewer having it installed, and check the glyphs are centered.
  Inline SVG is the system default.
- Vendored copies of the CSS are gone. If styling breaks on deploy, the fix
  is a correct, tag-pinned CDN link or node_modules import, plus the fonts.
- Bumping the design-system pin or changing only styling is a patch release
  of the consumer, never a minor.
- Hover and pointer states must actually work in the browser, not only on
  click. Verify in the running app before calling it done.
