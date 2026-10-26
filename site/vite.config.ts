import adapter from '@sveltejs/adapter-static';
import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [
    tailwindcss(),
    sveltekit({
      adapter: adapter({ pages: 'build', assets: 'build', fallback: '404.html', strict: true }),
      // On GitHub Pages the site lives under /<repo-name>: the workflow sets BASE_PATH.
      paths: { base: (process.env.BASE_PATH ?? '') as '' | `/${string}` }
    })
  ]
});
