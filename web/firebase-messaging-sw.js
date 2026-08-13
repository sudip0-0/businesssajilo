// Firebase Cloud Messaging service worker for Flutter web.
// Loads compat SDK + web/firebase-config.js (fill in for production).

importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js',
);
importScripts('firebase-config.js');

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) =>
  event.waitUntil(self.clients.claim()),
);

const config = self.FIREBASE_WEB_CONFIG || {};
const configured =
  typeof config.apiKey === 'string' &&
  config.apiKey.length > 0 &&
  typeof config.projectId === 'string' &&
  config.projectId.length > 0 &&
  typeof config.appId === 'string' &&
  config.appId.length > 0 &&
  typeof config.messagingSenderId === 'string' &&
  config.messagingSenderId.length > 0;

if (configured) {
  firebase.initializeApp(config);
  const messaging = firebase.messaging();
  messaging.onBackgroundMessage((payload) => {
    const title =
      (payload.notification && payload.notification.title) ||
      (payload.data && payload.data.title) ||
      'BusinessSajilo';
    const body =
      (payload.notification && payload.notification.body) ||
      (payload.data && payload.data.body) ||
      '';
    return self.registration.showNotification(title, {
      body: body,
      data: payload.data || {},
      icon: '/icons/Icon-192.png',
    });
  });
}
