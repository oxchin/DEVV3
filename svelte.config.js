import adapterVercel from '@sveltejs/adapter-vercel';
// Use adapter-static for Capacitor mobile builds so we get an index.html in build/
// Note: you must install it: npm i -D @sveltejs/adapter-static
import adapterStatic from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://svelte.dev/docs/kit/integrations
	// for more information about preprocessors
	preprocess: vitePreprocess(),
	kit: {
		adapter:
			process.env.MOBILE_BUILD === 'true'
				? adapterStatic({
					pages: 'build',
					assets: 'build',
					fallback: 'index.html', // SPA fallback for client-side routing in Capacitor
					precompress: false
				})
				: adapterVercel({ runtime: 'nodejs22.x' }),
		// When building for mobile SPA, disable prerendering entries so adapter-static writes a single-page app
		prerender:
			process.env.MOBILE_BUILD === 'true'
				? { entries: [] }
				: undefined
	}
};

export default config;
