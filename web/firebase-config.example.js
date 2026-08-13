// Copy to firebase-config.js and fill in the Firebase web app config.
// firebase-config.js is loaded by firebase-messaging-sw.js for web push.
self.FIREBASE_WEB_CONFIG = {
  apiKey: 'YOUR_FIREBASE_API_KEY',
  authDomain: 'YOUR_PROJECT.firebaseapp.com',
  projectId: 'YOUR_PROJECT_ID',
  storageBucket: 'YOUR_PROJECT.appspot.com',
  messagingSenderId: 'YOUR_SENDER_ID',
  appId: 'YOUR_APP_ID',
};
