# AGENTS.md

Orientation for AI agents working in this repo. Read this first.

## Stack

Jekyll 4.2 · Kramdown (GFM, `auto_ids`) · Rouge · permalink `/:title/`.
Plugins: `jekyll-seo-tag`, `jekyll-sitemap`, `jekyll-feed` (all on the GH Pages whitelist).
Deployed by GitHub Pages directly — no Actions workflow.

## Build & verify

- `docker compose up` — uses `jekyll/jekyll:4.2.2`, serves on `localhost:4000`. The `docker-compose.yaml` exists so agents can verify changes; do not delete it.

## Layout

- `_config.yml` — site config, plugins, post `defaults` (`author: tboeghk`, `image: /assets/social-card.png`).
- `_data/authors.yml` — handle-keyed authors. `jekyll-seo-tag` reads this automatically.
- `_data/footer.yml` — footer columns.
- `_layouts/` — `default.html`, `home.html`, `post.html`.
- `_includes/` — `site-header.html`, `site-footer.html`, `hero.html` (post-scoped, hosts JSON-LD), `toc.html`, `cta.html`.
- `_posts/YYYY-MM-DD-slug.md`.
- `assets/` — `css/`, `js/`, `favicon.svg`. `social-card.png` and `apple-touch-icon.png` referenced but not yet added.
- `index.html` uses `layout: home`.
- `robots.txt` points to `https://solr.cool/sitemap.xml`.

## Post frontmatter contract

Custom fields the includes depend on:

- `title` (plain) + `title_html` — `title_html` allows HTML/spans/`<br>` in the visible H1.
- `lede` — subtitle; HTML allowed.
- `description` — SEO; consumed by `jekyll-seo-tag`.
- `published`, `updated` — ISO dates.
- `reading_time` — string, e.g. `"~26&nbsp;min"`.
- `tags_display: [{text, style}]` — visual chips only. **Not** standard Jekyll `tags`.
- `toc: [{id, label}]` — manual TOC. `id` must match a kramdown `auto_ids` heading anchor; update both together.
- `author: <handle>` — optional; defaults to `tboeghk`. Must match a key in `_data/authors.yml`.
- `image:` — optional; defaults to `/assets/social-card.png` for OG/Twitter.

## Author model

Single source of truth: `_data/authors.yml`, keyed by handle.

- Post resolution: `{% assign post_author = site.data.authors[include.post.author] %}` in `_includes/hero.html`.
- Site-owner footer: `site.data.authors.tboeghk.name` in `_includes/site-footer.html`.
- Add a guest author: new key in `authors.yml`, then `author: <handle>` in that post's frontmatter.

## SEO

- `{% seo %}` in `_layouts/default.html` emits title, description, canonical, OG, Twitter card, generic JSON-LD.
- Richer `BlogPosting` JSON-LD lives in `_includes/hero.html`, guarded by `{% if include.post %}`.
- `/sitemap.xml` and `/feed.xml` are plugin-generated.

## Branches

- `main` — active development.
- `master` — historical "Solr Package Directory" content (see README). PR target.

## Don'ts

- Don't add Jekyll plugins outside the GH Pages whitelist — they won't build on deploy.
- Don't convert `tags_display` to standard Jekyll `tags`; templates iterate the `{text, style}` shape.
- Don't reintroduce `site.author` — it was deliberately moved to `_data/authors.yml`.
- Don't replace `{% seo %}` with hand-rolled `<title>`/`<meta>` — it now drives canonical, OG, Twitter, and JSON-LD.
- Don't rename a heading without updating the matching `toc[].id`.
