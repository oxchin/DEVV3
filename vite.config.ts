import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
    plugins: [
        sveltekit()
    ],
    resolve: {
        conditions: ['browser']
    },
    test: {
        environment: 'jsdom',
        setupFiles: ['./src/test-setup.ts'],
        globals: true,
        deps: {
            optimizer: {
                web: {
                    include: ['svelte', '@testing-library/svelte']
                }
            }
        }
    }
});
