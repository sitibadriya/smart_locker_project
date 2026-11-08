/* Firebase Messaging Service Worker - Smart Locker IoT
 *
 * Letakkan file ini di folder Flutter Web: web/firebase-messaging-sw.js
 * Sesuaikan apiKey, messagingSenderId, dan appId dengan Firebase Web App.
 */

importScripts(
  'https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js'
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js'
);

firebase.initializeApp({
  apiKey: "AIzaSyDLZr4hM-aYSckpFVSYZilsJAhgQqsK0yE",
  authDomain: "smart-locker-iot-10a0e.firebaseapp.com",
  projectId: "smart-locker-iot-10a0e",
  storageBucket: "smart-locker-iot-10a0e.firebasestorage.app",
  messagingSenderId: "651310592592",
  appId: "1:651310592592:web:d34f6f7012b9eb56251755"
});

const messaging = firebase.messaging();

function readValue(data, keys, fallback) {
  for (const key of keys) {
    const value = data && data[key];
    if (value !== undefined && value !== null && String(value).trim() !== '') {
      return String(value);
    }
  }
  return fallback;
}

messaging.onBackgroundMessage((payload) => {
  const data = payload.data || {};

  // FCM bisa berupa notification payload atau data-only payload.
  const title =
    payload.notification?.title ||
    readValue(data, ['title', 'judul'], 'Smart Locker');

  const body =
    payload.notification?.body ||
    readValue(
      data,
      ['body', 'message', 'pesan', 'description'],
      'Ada aktivitas pada Smart Locker.'
    );

  const level = readValue(data, ['level', 'severity'], 'info').toLowerCase();
  const lockerId = readValue(data, ['idLocker', 'locker_id', 'locker'], '');
  const eventId = readValue(data, ['event_id', 'eventId', 'id'], '');

  const options = {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: eventId || (lockerId ? `smart-locker-${lockerId}` : 'smart-locker'),
    renotify: level === 'danger' || level === 'critical',
    data: {
      url: '/',
      idLocker: lockerId,
      type: readValue(data, ['type', 'category'], 'locker_event'),
      level: level,
      ...data
    }
  };

  if (level === 'danger' || level === 'critical' || level === 'error') {
    options.requireInteraction = true;
  }

  return self.registration.showNotification(title, options);
});

// Saat notifikasi diklik, fokuskan tab aplikasi jika sudah terbuka,
// atau buka aplikasi jika belum ada tab aktif.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const targetUrl = event.notification.data?.url || '/';

  event.waitUntil(
    clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then((windowClients) => {
      for (const client of windowClients) {
        if ('focus' in client) {
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }

      return undefined;
    })
  );
});
