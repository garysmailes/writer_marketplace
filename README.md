# README


---

## Open Props (CSS Design Tokens)

This app uses **Open Props** as a set of CSS custom properties (design tokens) for spacing, typography, colors, shadows, etc. It is set up as a **self-hosted CSS file** so the app has **no runtime dependency on a CDN** and works cleanly with **Rails 8 + Propshaft**.

### Where it lives

Open Props is stored locally at:

```
app/assets/stylesheets/open-props.css
```

### How it’s loaded

Open Props is imported at the top of the main stylesheet:

```
app/assets/stylesheets/application.css
```

Example:

```css
/* Import Open Props tokens */
@import "open-props.css";

/* App styles can now use Open Props variables */
body {
  font-family: var(--font-sans);
  background: var(--surface-1);
  color: var(--text-1);
}
```

Rails loads `application.css` via the default layout:

```erb
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
```

### Usage

Once imported, you can use Open Props variables anywhere in your CSS, e.g.

```css
.card {
  padding: var(--size-4);
  border-radius: var(--radius-3);
  background: var(--surface-2);
  box-shadow: var(--shadow-3);
}
```

### Updating Open Props

We **pin a version** when downloading Open Props so updates are intentional.

To update:

1. Check the latest Open Props version (release notes / npm/unpkg).
2. Download the new pinned version over the existing file:

```bash
curl -L -o app/assets/stylesheets/open-props.css \
https://unpkg.com/open-props@1.7.17/open-props.min.css
```

3. Commit the change:

```bash
git add app/assets/stylesheets/open-props.css
git commit -m "Update Open Props to v1.7.17"
```

#### Important notes

* The `-L` flag is required for `curl` because unpkg may redirect.
* Updating Open Props can cause visual changes if tokens change. After updating, quickly sanity-check key pages/components.
* Prefer using a small semantic layer (our own variables like `--space-md`, `--brand-bg`) for long-term stability, so we don’t rely on raw Open Props names everywhere.

### Troubleshooting

If variables appear “not to work”:

* Confirm Open Props is imported **before** CSS that references its variables.
* Hard refresh the browser cache (`Ctrl + Shift + R`).
* Verify the Open Props file isn’t a redirect stub (it should be far larger than ~50 bytes).

---

CSS Layout

A solid structure is: **tokens → base → layout → components → utilities → pages**. Keep the early set small, but put it on rails (no pun intended) so it scales cleanly.

Here’s a good Rails-friendly layout given you already have `reset.css` + `open-props.css`.

## Recommended file structure

```
app/assets/stylesheets/
  application.css
  reset.css
  open-props.css

  01-settings/
    theme.css          # your semantic tokens + theme overrides (brand colors, spacing aliases)

  02-base/
    base.css           # html/body defaults, typography, links, forms baseline
    accessibility.css  # focus states, skip links, reduced motion rules

  03-layout/
    layout.css         # page shell: header/main/footer, grid wrappers, containers
    header.css
    footer.css

  04-components/
    button.css
    card.css
    form.css
    nav.css
    modal.css
    badge.css
    alert.css

  05-utilities/
    utilities.css      # small helper classes (visually-hidden, stack, container, etc.)

  06-pages/
    pages-home.css     # only if a page needs special layout that shouldn't be a component
```

You don’t need all of these on day one — but **this naming/ordering scales**.

---

## How to wire it in `application.css`

Make `application.css` a simple “import list” in a predictable order:

```css
/* Vendor / foundations */
@import "reset.css";
@import "open-props.css";

/* Your design system */
@import "01-settings/theme.css";

/* Base styles */
@import "02-base/base.css";
@import "02-base/accessibility.css";

/* Layout */
@import "03-layout/layout.css";
@import "03-layout/header.css";
@import "03-layout/footer.css";

/* Components */
@import "04-components/button.css";
@import "04-components/card.css";
@import "04-components/form.css";

/* Utilities (last so they can win when needed) */
@import "05-utilities/utilities.css";

/* Pages (optional, last) */
@import "06-pages/pages-home.css";
```

That order matters:

* **tokens first** (open props + your theme)
* **base next**
* **components**
* **utilities last** (so helpers can override without specificity wars)

---

## The “theme.css” file is the secret sauce

This keeps Open Props stable even if you update it later.

`01-settings/theme.css`:

```css
:root {
  /* semantic spacing */
  --space-xs: var(--size-2);
  --space-sm: var(--size-3);
  --space-md: var(--size-4);
  --space-lg: var(--size-6);

  /* semantic radii */
  --radius: var(--radius-3);

  /* semantic brand */
  --brand: var(--indigo-6);
  --brand-contrast: white;
}
```

Then components use **your** tokens (`--space-md`) instead of raw `--size-4`.

---

## Rule of thumb for “where should this CSS go?”

* **Base**: element defaults (`body`, `a`, `h1`, `input`)
* **Layout**: structural wrappers (header grid, main container, sidebar)
* **Component**: reusable UI pieces (`.btn`, `.card`, `.nav`)
* **Utility**: tiny single-purpose helpers (`.stack`, `.sr-only`)
* **Page**: only if it’s truly one-off and not reusable
