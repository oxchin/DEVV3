/* Basic offline-first service worker for SvelteKit app (Vite 7 compatible)
   - Caches core shell on install
   - Cleans old caches on activate
   - Network-first for HTML, stale-while-revalidate for assets, cache-first for images/fonts
*/

const CACHE_VERSION = 'v1';
const HTML_CACHE = `html-cache-${CACHE_VERSION}`;
const ASSET_CACHE = `asset-cache-${CACHE_VERSION}`;
const STATIC_CACHE = `static-cache-${CACHE_VERSION}`;

const CORE_ASSETS = [
  '/',
  '/manifest.webmanifest',
  // Keep core assets minimal and existing to avoid install failures
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(ASSET_CACHE).then((cache) => cache.addAll(CORE_ASSETS)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter((k) => ![HTML_CACHE, ASSET_CACHE, STATIC_CACHE].includes(k))
          .map((k) => caches.delete(k))
      );
      await self.clients.claim();
    })()
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);

  // Only handle same-origin requests
  if (url.origin !== self.location.origin) return;

  // HTML: Network-first
  if (req.mode === 'navigate' || (req.headers.get('accept') || '').includes('text/html')) {
    event.respondWith(
      (async () => {
        try {
          const fresh = await fetch(req);
          const cache = await caches.open(HTML_CACHE);
          cache.put(req, fresh.clone());
          return fresh;
        } catch {
          const cached = await caches.match(req);
          return cached || caches.match('/');
        }
      })()
    );
    return;
  }

  // Static assets: stale-while-revalidate
  if (['script', 'style', 'worker'].includes(req.destination)) {
    event.respondWith(
      (async () => {
        const cache = await caches.open(ASSET_CACHE);
        const cached = await cache.match(req);
        const fetchPromise = fetch(req)
          .then((res) => {
            cache.put(req, res.clone());
            return res;
          })
          .catch(() => undefined);
        return cached || fetchPromise || fetch(req);
      })()
    );
    return;
  }

  // Images/fonts: cache-first
  if (['image', 'font'].includes(req.destination)) {
    event.respondWith(
      (async () => {
        const cache = await caches.open(STATIC_CACHE);
        const cached = await cache.match(req);
        if (cached) return cached;
        try {
          const res = await fetch(req);
          cache.put(req, res.clone());
          return res;
        } catch {
          return fetch(req);
        }
      })()
    );
  }
});
