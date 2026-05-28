# solr.cool — Design System

Field notes / risograph aesthetic for a Jekyll blog on open-source search. This document is the human-readable reference for the design encoded in [assets/css/main.css](assets/css/main.css). When the two disagree, the CSS is the source of truth — update this file to match.

## 1. Design Principles

- **Warm paper, hard ink.** A warm-beige background (`--bg`) with near-black ink for text and borders. Off-white "paper" panels float on top.
- **Bold display type.** Headlines use Archivo Black at large sizes with tight negative letter-spacing.
- **Monospace as voice of the machine.** Metadata, labels, tags, code, and table headers are JetBrains Mono, uppercase, widely letter-spaced.
- **Hard offset shadows, no blur.** Cards, quotes, code, tables and buttons cast solid `6/8/10px` shadows in ink or red — never soft drop shadows.
- **Playful rotation & stamps.** Tags, the post-stamp, and highlights tilt a degree or two off axis for a printed-by-hand feel.
- **No rounded corners.** Everything is square except true circles (`border-radius: 50%`) used for dots/avatars.
- **No CSS framework.** A single hand-written stylesheet (~1268 lines), CSS custom properties, CSS grid for layout.

## 2. Color Tokens

Defined as `:root` custom properties at [main.css:1-12](assets/css/main.css#L1-L12).

| Token | Value | Role |
|-------|-------|------|
| `--bg` | `#F4EFE6` | Primary page background (warm beige) |
| `--bg-2` | `#ECE4D2` | Secondary fill — alt table rows, inline code, badges, aside |
| `--ink` | `#0A0A0A` | Text, borders, dark panels |
| `--ink-soft` | `#2A2A2A` | Secondary / muted text |
| `--paper` | `#FFFDF6` | Off-white panels, text on dark |
| `--red` | `#FF2D2D` | Primary accent — active states, shadows, highlights, brand mark |
| `--red-deep` | `#C8101A` | "bad" status text in tables |
| `--yellow` | `#FAFE56` | Highlight, hover background, "soon" badge |
| `--rule` | `#0A0A0A` | Divider color (alias of ink) |
| `--line` | `3px` | Standard border/divider width |

**Usage rules**
- Red is the only "loud" color: active nav, link selection, shadows on cards/quotes/code, the favicon crosshair, drop-cap and ordered-list markers.
- Yellow signals interactivity (link/button hover background) and gentle highlight (`.hl`, `.mark`, text underline gradients).
- Ink is both type and structure — borders and dark panels share the same near-black.

**One-off colors** (not tokenized)
- `#B5631A` — table `.warn` text ([main.css:742](assets/css/main.css#L742)).
- `rgba(255,45,45,0.38)` — red highlighter gradient behind `.hero__lede strong` ([main.css:237](assets/css/main.css#L237)).
- `#FFFFFF` / `rgba(255,255,255,0.42)` — footer wordmark and its dim slash ([main.css:1190-1191](assets/css/main.css#L1190-L1191)).

## 3. Typography

Three Google Fonts, loaded in [_layouts/default.html:9](_layouts/default.html#L9):

```
Space Grotesk  (400, 500, 600, 700)
JetBrains Mono (400, 500, 700)
Archivo Black  (single weight, used as 900)
```

| Family | Role |
|--------|------|
| **Archivo Black** | Display — hero title, h2, brand, buttons, blockquotes, drop cap, stamps, footer wordmark |
| **Space Grotesk** | Body — base text, h3, footer links. Base: `18px / 1.55`, `Helvetica, Arial` fallback |
| **JetBrains Mono** | Machine voice — labels, tags, metadata, h4 chip, code, table headers, badges. Uppercase + letter-spacing |

### Type scale

| Element | Size | Weight / family | Notes |
|---------|------|-----------------|-------|
| Hero title | `clamp(48px, 6.2vw, 96px)` | Archivo Black | line-height 0.95, letter-spacing -0.035em |
| Article `h2` | `clamp(32px, 3.4vw, 44px)` | Archivo Black | `§` red prefix; 32px on mobile |
| CTA title | `clamp(36px, 4vw, 56px)` | Archivo Black | |
| Footer brand | `56px` (40px mobile) | Archivo Black | |
| Article `h3` | `26px` | Space Grotesk 700 | 2px ink bottom border |
| Lead paragraph | `22px / 1.4` | Space Grotesk 500 | first paragraph; gets drop cap |
| Drop cap | `80px` | Archivo Black | white on red, floated left |
| Body | `18px / 1.55` | Space Grotesk | |
| Article `h4` | `14px` | JetBrains Mono 700 | uppercase chip, ink bg, paper text |
| Tag | `12px` | JetBrains Mono | letter-spacing 0.04em, lowercase |
| Eyebrow / label | `11px` | JetBrains Mono | uppercase, letter-spacing 0.1–0.16em |
| Status badge | `11px` | JetBrains Mono | uppercase |

### Links
Body links are underlined (`2px` thickness, `3px` offset) in ink, with a yellow background on hover ([main.css:22-23](assets/css/main.css#L22-L23)). `::selection` is red on paper ([main.css:24](assets/css/main.css#L24)).

## 4. Spacing & Layout

**Spacing rhythm** (px, recurring throughout): `3 · 6 · 8 · 10 · 12 · 14 · 16 · 18 · 22 · 24 · 28 · 36 · 48 · 56 · 64`. Section padding is typically `56px` desktop, dropping to `28px` on mobile.

**Container:** `max-width: 1400px; margin: 0 auto` on every major band (header, hero, article, cta, more, footer).

**Key grids**

| Region | Columns | Source |
|--------|---------|--------|
| Site header | `auto 1fr auto` | [main.css:37](assets/css/main.css#L37) |
| Hero | `minmax(0,1fr) 320px` | [main.css:181](assets/css/main.css#L181) |
| Article wrap | `220px minmax(0,1fr)` (TOC + article) | [main.css:364](assets/css/main.css#L364) |
| CTA | `1.4fr 1fr` | [main.css:848](assets/css/main.css#L848) |
| Blog cards | `repeat(3, 1fr)` | [main.css:1079](assets/css/main.css#L1079) |
| Footer | `2fr 1fr 1fr` | [main.css:1138](assets/css/main.css#L1138) |

Internal structure leans on full-width `3px` ink borders between grid cells rather than gaps.

**Breakpoints**
- `≤1180px` — drop the TOC sidebar; article goes full width.
- `≤920px` — main mobile reflow: hero/cta/footer collapse to single/two columns, section padding → `28px`, site-meta hidden.
- `≤560px` — single-column footer & hero side, extra nav links hidden, footer brand → 40px.

## 5. Signature Visual Treatments

- **Hard offset shadows** (no blur): `box-shadow: Npx Npx 0 <color>`. Conventions: buttons `6px` ink, code/tables `8px` red, blockquotes/process-note `8–10px` (red or ink). Hover grows/shifts the shadow.
- **3px ink borders** everywhere structural (`--line`). Secondary borders are `2px`; dashed `2px` for signatures/empty states.
- **Rotation** for a printed feel: tags `--rot1 -2deg / --rot2 1.5deg / --rot3 -1deg` ([main.css:261-263](assets/css/main.css#L261-L263)), post-stamp `-3deg`, `.hl` highlight `-1.2deg`.
- **No border-radius** except `50%` circles (pulse dot, avatar, crosshair center).
- **Highlighter gradients** — text "marked" with a partial linear-gradient (red at 58%, or yellow at 62%) rather than a flat background.

## 6. Components

| Component | Class | Key spec |
|-----------|-------|----------|
| Button | `.btn` | pad `14px 22px`, `3px` ink border, Archivo Black 16px, `6px` ink shadow; hover translates `-2,-2` → `8px` shadow + yellow bg |
| Button (dark) | `.btn--ink` | ink bg / paper text; hover → yellow/ink |
| Tag | `.tag` + `--red`/`--yellow`/`--ink` | mono 12px, `2px` border, lowercase; rotation modifiers |
| Blog card | `.more__card` | paper, `3px` right border, min-height 220px, flex column |
| Card status | `.status` + `.is-soon` / `.is-draft` | mono 11px chip; soon=yellow, draft=red/paper |
| Blockquote | `blockquote` + `.is-red` | ink panel, paper text, Archivo Black 22px, `10px` red shadow, red left bar; `strong` and `a` use yellow accent (hover: yellow bg / ink text); `.is-red` inverts panel + bar |
| Code block | `pre` | ink/paper, `3px` border, `8px` red shadow, mono 12px, `▶ ASCII / DIAGRAM` label tab (`.is-json` → `▶ QUERY-IR JSON`) |
| Inline code | `code` | mono 0.86em, `--bg-2` bg, `1.5px` border |
| Table | `.table-wrap` + `table` | `3px` border + `8px` red shadow; ink header row (mono uppercase), even rows `--bg-2`; status text `.ok` red / `.warn` `#B5631A` / `.bad` `--red-deep` |
| Navbar | `.site-header` / `.brand` / `.top-nav` | sticky, ink bg, z-index 50; brand Archivo Black 22px (hover red); nav links mono uppercase, active = red |
| Footer | `.site-footer` | ink bg, paper text, `56px` Archivo Black wordmark + CSS crosshair |
| Reader map | `.reader-map` | yellow callout, `3px` border, ink/yellow h4 |
| Process note | `.process-note` | bg panel, `8px` ink shadow, red label tab, dashed signature row |
| Status line | `.status-line` | mono 13px, `--bg-2` bg, `6px` red left border |
| Highlight / underline | `.hl` / `.ul` | red bg chip (rotated, ink shadow) / thick (`8px`) red underline |

## 7. Motion

- **`.pulse`** — 8px red dot, `pulse 1.4s ease-in-out infinite` (opacity 1→0.35, scale 1→0.7). [main.css:129-137](assets/css/main.css#L129-L137)
- **Marquee** — `.marquee__track` scrolls `35s linear infinite` (translateX 0 → -50%). [main.css:155](assets/css/main.css#L155)
- **Button** — `transform 80ms ease, box-shadow 80ms ease`. [main.css:914](assets/css/main.css#L914)
- **Anchors** — smooth-scroll + active-TOC highlighting handled in [assets/js/main.js](assets/js/main.js).

Motion is otherwise minimal; the design relies on static contrast, not transitions.

## 8. Branding Assets

**Favicon** — [assets/favicon.svg](assets/favicon.svg): a red (`#FF2D2D`) crosshair on a 56×56 canvas — a `3px` horizontal bar, a `3px` vertical bar, and a `r=10` center circle. Referenced as the site icon and `_config.yml` logo.

**CSS crosshair variants** reproduce the mark without an image:
- `.brand__dot` — 22px, `2px` bars + 8px center dot, in the header ([main.css:55-91](assets/css/main.css#L55-L91)).
- `.footer__crosshair` — 56px, `3px` bars + 20px center dot ([main.css:1156-1189](assets/css/main.css#L1156-L1189)).

**Wordmark** — `SOLR.COOL` with a dimmed `//` slash, followed by a mono tagline ("FIELD NOTES" in the header, the site tagline in the footer). Tagline copy lives in `_config.yml`.

## 9. Source of Truth

- **Tokens & all component values:** [assets/css/main.css](assets/css/main.css) — custom properties in the `:root` block at the top.
- **Fonts:** the Google Fonts `<link>` in [_layouts/default.html:9](_layouts/default.html#L9).
- **Brand mark:** [assets/favicon.svg](assets/favicon.svg).
- **Page structure:** `_layouts/` (`default`, `home`, `post`) and `_includes/` (`site-header`, `site-footer`, `hero`, `cta`, `toc`).

To extend the system, add a token to `:root` and reference it via `var(--…)` rather than hard-coding values, and keep the tables above in sync.
