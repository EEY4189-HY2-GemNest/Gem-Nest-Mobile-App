// Firebase Cloud Messaging Service Worker
// This file should be placed in the public directory of the admin dashboard

importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging.js');

// Initialize Firebase in Service Worker
const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID",
};

firebase.initializeApp(firebaseConfig);

// Initialize Firebase Cloud Messaging and get a reference to the service
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);

    // Customize notification here
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/firebase-logo.png',
        badge: '/firebase-logo.png',
        tag: payload.data.notificationType || 'notification',
        data: payload.data,
        click_action: payload.data.actionUrl,
        actions: [
            {
                action: 'open',
                title: 'Open',
            },
            {
                action: 'close',
                title: 'Close',
            },
        ],
    };

    return self.registration.showNotification(
        notificationTitle,
        notificationOptions
    );
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
    console.log('[firebase-messaging-sw.js] Notification click received.');

    if (event.action === 'close') {
        event.notification.close();
        return;
    }

    event.notification.close();

    // Get the action URL from notification data
    const actionUrl = event.notification.data.actionUrl;

    // This looks to see if the current is already open and
    // focuses it if it is
    event.waitUntil(
        clients
            .matchAll({
                type: 'window',
                includeUncontrolled: true,
            })
            .then((clientList) => {
                // Let's see if we already have a window/tab open with the target URL
                for (let i = 0; i < clientList.length; i++) {
                    const client = clientList[i];
                    if (
                        client.url === actionUrl &&
                        'focus' in client
                    ) {
                        return client.focus();
                    }
                }
                // If not, we open a new window/tab with the target URL
                if (clients.openWindow) {
                    return clients.openWindow(actionUrl);
                }
            })
    );
});

// Handle notification close
self.addEventListener('notificationclose', (event) => {
    console.log('[firebase-messaging-sw.js] Notification closed.');
});
