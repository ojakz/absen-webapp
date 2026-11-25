/* Presensi service worker — app shell only.
   Caches just the local shell (/, favicon, manifest) so the app can be
   installed and open fullscreen. Everything else — Supabase auth/data/
   storage, Google Fonts, CDN, and all POSTs — always goes to the network
   and is never cached, so login, selfie upload and attendance can never
   serve a stale or offline copy. */
const CACHE = 'presensi-v1';
const SHELL = ['/', '/favicon.png', '/manifest.webmanifest'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE).then((cache) => cache.addAll(SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);
  // Only same-origin GETs, only the shell files. Anything else (Supabase,
  // fonts, CDN, POST/PUT/DELETE) falls through to the network untouched.
  if (event.request.method !== 'GET') return;
  if (url.origin !== self.location.origin) return;
  if (!SHELL.includes(url.pathname)) return;
  event.respondWith(
    caches.match(event.request).then((hit) => {
      if (hit) return hit;
      return fetch(event.request).then((res) => {
        const copy = res.clone();
        caches.open(CACHE).then((cache) => cache.put(event.request, copy));
        return res;
      });
    })
  );
});
