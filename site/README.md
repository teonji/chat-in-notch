# Landing page

SvelteKit + Tailwind CSS v4, exported as a static site (`@sveltejs/adapter-static`).

```sh
cd site
npm install
npm run dev        # http://localhost:5173
npm run build      # static output in site/build
```

- The hero shows a looping illustration drawn in HTML and CSS (`src/lib/NotchDemo.svelte`). To use a real
  recording instead, save it as `site/static/demo.gif` (16:10): it replaces the illustration automatically.
- Copy lives in `src/lib/content.ts`; the page is `src/lib/Landing.svelte`.
- SEO: meta tags, Open Graph / Twitter cards and JSON-LD live in `src/lib/Landing.svelte` and `src/lib/seo.ts`.
  `robots.txt` and `sitemap.xml` are generated at build time. The social image is `static/og.png` (1200 x 630).
- The public address is `https://<user>.github.io/<repo>` by default. For a custom domain set `VITE_SITE_URL`
  (and `BASE_PATH` if it is served from a sub-path) when building; canonical URLs, the sitemap and image links follow it.
- Deployed to GitHub Pages by `.github/workflows/pages.yml` (it sets `BASE_PATH` to `/<repo-name>`).
