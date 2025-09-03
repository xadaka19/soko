importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyAqK2VYsRaBG4tgrz5rW2QIArC8JLzit1I",
  authDomain: "sokofiti-2d6ca.firebaseapp.com",
  projectId: "sokofiti-2d6ca",
  storageBucket: "sokofiti-2d6ca.firebasestorage.app",
  messagingSenderId: "288767792538",
  appId: "1:288767792538:web:e005df3bd503e76d2b5623",
  measurementId: "G-KXPME2LWQ6"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('Received background message: ', payload);
  const notificationTitle = payload.notification?.title || "New Notification";
  const notificationOptions = {
    body: payload.notification?.body || "You have a new message.",
    icon: payload.notification?.icon || "/icons/Icon-192.png"
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});

