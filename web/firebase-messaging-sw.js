// Stub service worker for optional Firebase Cloud Messaging on web.
// Replace with generated Firebase config when enabling push in production.

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));
