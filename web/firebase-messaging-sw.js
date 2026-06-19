importScripts('https://www.gstatic.com/firebasejs/10.12.4/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.4/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDz4omU1bqZ5mvMjsyfJP7AhLajf3jCWRE',
  appId: '1:618367534949:web:cd1137aba539770a18438c',
  messagingSenderId: '618367534949',
  projectId: 'arptc-connect',
  authDomain: 'arptc-connect.firebaseapp.com',
  storageBucket: 'arptc-connect.appspot.com',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const data = payload.data || {};

  // FCM automatically displays messages that contain a notification payload.
  // Manually showing those again creates duplicate browser notifications.
  if (notification.title || notification.body) {
    return;
  }

  const title = data.title || 'ARPTC Connect';
  const options = {
    body: data.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: {
      ...data,
      handledByArptcServiceWorker: 'true',
    },
  };

  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const directData = event.notification.data || {};
  if (directData.handledByArptcServiceWorker !== 'true') {
    return;
  }

  const fcmData =
    directData.FCM_MSG && directData.FCM_MSG.data
      ? directData.FCM_MSG.data
      : {};
  const route = directData.route || fcmData.route || '/home';
  const url = new URL(toClientRouteUrl(route), self.location.origin).href;

  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        const appClient = clientList.find((client) => {
          return new URL(client.url).origin === self.location.origin;
        });

        if (appClient) {
          return appClient
            .navigate(url)
            .then((client) => (client || appClient).focus());
        }

        return clients.openWindow(url);
      }),
  );
});

function toClientRouteUrl(route) {
  let normalizedRoute = route || '/home';

  if (normalizedRoute.startsWith('/#/')) {
    normalizedRoute = normalizedRoute.substring(2);
  } else if (normalizedRoute.startsWith('#/')) {
    normalizedRoute = normalizedRoute.substring(1);
  }

  if (!normalizedRoute.startsWith('/')) {
    normalizedRoute = `/${normalizedRoute}`;
  }

  return `/#${normalizedRoute}`;
}
