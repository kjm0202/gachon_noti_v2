// Firebase 메시징 서비스 워커
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-messaging-compat.js");

// Firebase 초기화 - 오류 처리 추가
try {
  firebase.initializeApp({
    apiKey: "AIzaSyAi-sZCFQWMR0k1tT4Z2Y_WaW2fWtvpR_s",
    authDomain: "gachon-noti-v2-fc11a.firebaseapp.com",
    projectId: "gachon-noti-v2-fc11a",
    storageBucket: "gachon-noti-v2-fc11a.firebasestorage.app",
    messagingSenderId: "606642618462",
    appId: "1:606642618462:web:775a687fda4c615dc9f4cf",
    measurementId: "G-ST627Z69RV"
  });
  
  console.log('Firebase 서비스 워커 초기화 성공');
} catch (e) {
  console.error('Firebase 서비스 워커 초기화 오류:', e);
}

// Firebase 메시징 인스턴스 생성
const messaging = firebase.messaging();

// 백그라운드 메시지 처리
messaging.onBackgroundMessage(function(payload) {
  console.log('백그라운드 메시지 수신:', payload);
  
  try {
    const notificationTitle = payload.notification.title || '가천알림';
    const notificationOptions = {
      body: payload.notification.body || '새로운 알림이 있습니다',
      icon: '/icons/Icon-192.png',
      data: payload.data || {},
      actions: [
        {
          action: 'open_url',
          title: '게시글 보기'
        }
      ]
    };
  
    return self.registration.showNotification(notificationTitle, notificationOptions);
  } catch (e) {
    console.error('알림 표시 오류:', e);
  }
});

// 알림 클릭 이벤트 처리
self.addEventListener('notificationclick', function(event) {
  console.log('알림 클릭 이벤트:', event);
  
  event.notification.close();
  
  try {
    if (event.action === 'open_url' && event.notification.data && event.notification.data.link) {
      // 원본 게시글 링크로 이동
      event.waitUntil(clients.openWindow(event.notification.data.link));
    } else {
      // 기본적으로 앱 화면 열기
      event.waitUntil(
        clients.matchAll({type: 'window'}).then((clientList) => {
          // 이미 열린 창이 있는지 확인
          for (const client of clientList) {
            if (client.url === '/' && 'focus' in client) {
              return client.focus();
            }
          }
          // 열린 창이 없으면 새 창 열기
          if (clients.openWindow) {
            return clients.openWindow('/');
          }
        })
      );
    }
  } catch (e) {
    console.error('알림 클릭 처리 오류:', e);
    // 오류 시 기본 URL로 이동
    event.waitUntil(clients.openWindow('/'));
  }
}); 