import axios from 'axios';
import { Parser } from 'xml2js';
import { Client, Databases, Query } from 'node-appwrite';
import pkg from 'firebase-admin';
import { existsSync } from 'fs';

const { initializeApp, credential, messaging } = pkg;

// 환경 변수 설정
const APPWRITE_ENDPOINT = process.env.APPWRITE_ENDPOINT;
const APPWRITE_PROJECT_ID = process.env.APPWRITE_PROJECT_ID;
const APPWRITE_API_KEY = process.env.APPWRITE_API_KEY;
const APPWRITE_DATABASE_ID = process.env.APPWRITE_DATABASE_ID;
const APPWRITE_NOTIFICATIONS_COLLECTION_ID = process.env.APPWRITE_NOTIFICATIONS_COLLECTION_ID;
const APPWRITE_USERS_COLLECTION_ID = process.env.APPWRITE_USERS_COLLECTION_ID;

// 환경 변수 검증
if (!APPWRITE_ENDPOINT || !APPWRITE_PROJECT_ID || !APPWRITE_API_KEY || 
    !APPWRITE_DATABASE_ID || !APPWRITE_NOTIFICATIONS_COLLECTION_ID || !APPWRITE_USERS_COLLECTION_ID) {
  console.error('Appwrite 환경 변수가 누락되었습니다.');
  process.exit(1);
}

// Appwrite 클라이언트 설정
const appwrite = new Client()
  .setEndpoint(APPWRITE_ENDPOINT)
  .setProject(APPWRITE_PROJECT_ID)
  .setKey(APPWRITE_API_KEY);

const databases = new Databases(appwrite);

// Firebase 설정
let firebaseMessaging = null;
try {
  // 환경 변수로 Firebase 초기화 (우선)
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    const app = initializeApp({
      credential: credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      }),
    });
    console.log('Firebase 초기화 완료 (환경변수 방식)');
    firebaseMessaging = messaging();
  } 
  // 파일로 초기화 (대체 방식)
  else if (process.env.FIREBASE_CREDENTIALS_PATH && existsSync(process.env.FIREBASE_CREDENTIALS_PATH)) {
    const app = initializeApp({
      credential: credential.cert(process.env.FIREBASE_CREDENTIALS_PATH)
    });
    console.log('Firebase 초기화 완료 (인증 파일 방식)');
    firebaseMessaging = messaging();
  } else {
    console.error('Firebase 인증 정보가 없습니다. FCM 알림 기능이 비활성화됩니다.');
  }
} catch (error) {
  console.error('Firebase 초기화 오류:', error.message);
}

// 게시판 목록
const boards = [
  { boardId: 'bachelor', url: 'https://www.gachon.ac.kr/bbs/kor/475/rssList.do?row=50' },
  { boardId: 'scholarship', url: 'https://www.gachon.ac.kr/bbs/kor/478/rssList.do?row=50' },
  { boardId: 'student', url: 'https://www.gachon.ac.kr/bbs/kor/479/rssList.do?row=50' },
  { boardId: 'job', url: 'https://www.gachon.ac.kr/bbs/kor/480/rssList.do?row=50' },
  { boardId: 'extracurricular', url: 'https://www.gachon.ac.kr/bbs/kor/743/rssList.do?row=50' },
  { boardId: 'other', url: 'https://www.gachon.ac.kr/bbs/kor/740/rssList.do?row=50' },
  { boardId: 'dormGlobal', url: 'https://www.gachon.ac.kr/bbs/dormitory/330/rssList.do?row=50' },
  { boardId: 'dormMedical', url: 'https://www.gachon.ac.kr/bbs/dormitory/334/rssList.do?row=50' },
];

// RSS 피드 파싱 함수
async function parseRSS(url) {
  try {
    const response = await axios.get(url);
    const parser = new Parser({ explicitArray: false });
    const result = await parser.parseStringPromise(response.data);
    
    if (!result.rss || !result.rss.channel || !result.rss.channel.item) {
      return [];
    }
    
    // 단일 항목인 경우 배열로 변환
    const items = Array.isArray(result.rss.channel.item) 
      ? result.rss.channel.item 
      : [result.rss.channel.item];
    
    return items.map(item => ({
      title: item.title.trim(),
      link: item.link,
      pubDate: item.pubDate,
      author: item.author || '익명',
      description: item.description || '',
    }));
  } catch (error) {
    console.error(`RSS 파싱 오류 (${url}):`, error.message);
    return [];
  }
}

// 게시글 ID 추출 함수
function extractArticleId(url) {
  const matches = url.match(/\/(\d+)\/artclView\.do/);
  return matches ? matches[1] : null;
}

// 게시글 저장 및 새 게시글 확인 함수
async function processArticles(boardId, articles) {
  const newArticles = [];

  for (const article of articles) {
    const articleId = extractArticleId(article.link);
    if (!articleId) continue;
    
    try {
      // 기존 게시글 확인
      const existingArticles = await databases.listDocuments(
        APPWRITE_DATABASE_ID,
        APPWRITE_NOTIFICATIONS_COLLECTION_ID,
        [
          Query.equal('articleId', articleId),
          Query.equal('boardId', boardId)
        ]
      );
      
      // 새 게시글인 경우 저장
      if (existingArticles.total === 0) {
        const documentId = `${boardId}_${articleId}`;
        
        // 게시글 저장 시도
        try {
          const notificationData = {
            boardId,
            articleId,
            title: article.title,
            link: article.link,
            pubDate: article.pubDate,
            author: article.author,
            description: article.description,
            createdAt: new Date().toISOString(),
          };
          
          console.log(`게시글 저장 시도 (${boardId}, ${articleId}):`, JSON.stringify(notificationData));
          
          await databases.createDocument(
            APPWRITE_DATABASE_ID,
            APPWRITE_NOTIFICATIONS_COLLECTION_ID,
            documentId,
            notificationData
          );
          
          newArticles.push(article);
          console.log(`새 게시글 저장: [${boardId}] ${article.title}`);
        } catch (createError) {
          console.error(`게시글 저장 오류 (${boardId}, ${articleId}):`, createError.message);
          // 필드 에러인 경우 필수 필드만 저장 시도
          if (createError.message.includes('Unknown attribute')) {
            try {
              // 최소한의 필수 필드만 포함
              await databases.createDocument(
                APPWRITE_DATABASE_ID,
                APPWRITE_NOTIFICATIONS_COLLECTION_ID,
                documentId,
                {
                  boardId,
                  articleId,
                  title: article.title,
                  link: article.link,
                  pubDate: article.pubDate || new Date().toISOString(),
                  author: article.author || '익명',
                  description: article.description || '',
                  createdAt: new Date().toISOString(),
                }
              );
              
              newArticles.push(article);
              console.log(`필수 필드만으로 게시글 저장: [${boardId}] ${article.title}`);
            } catch (retryError) {
              console.error(`필수 필드 저장 시도 실패 (${boardId}, ${articleId}):`, retryError.message);
            }
          }
        }
      } else {
        // 이미 처리된 게시물이므로 중단
        console.log(`기존 게시글 발견: [${boardId}] ${article.title} - 나머지 건너뛰기`);
        break; // 가장 최근 게시물부터 확인하므로, 하나라도 있으면 나머지는 모두 이미 처리된 게시물
      }
    } catch (error) {
      console.error(`게시글 처리 오류 (${boardId}, 게시글ID ${articleId}):`, error.message);
    }
  }
  
  return newArticles;
}

// FCM 알림 전송 함수
async function sendNotifications(boardId, newArticles) {
  if (newArticles.length === 0 || !firebaseMessaging) return;
  
  const boardNames = {
    bachelor: '학사공지',
    scholarship: '장학공지',
    student: '학생공지',
    job: '취업공지',
    extracurricular: '교외활동',
    other: '기타공지',
    dormGlobal: '글로벌 기숙사',
    dormMedical: '메디컬 기숙사'
  };
  
  const boardName = boardNames[boardId] || boardId;
  
  for (const article of newArticles) {
    try {
      // 해당 게시판을 구독한 사용자 목록 조회
      const subscribers = await databases.listDocuments(
        APPWRITE_DATABASE_ID,
        APPWRITE_USERS_COLLECTION_ID,
        [
          Query.search('subscribedBoards', boardId)
        ]
      );

      if (subscribers.total === 0) {
        console.log(`게시판 ${boardId}에 구독자가 없습니다.`);
        continue;
      }

      console.log(`게시판 ${boardId}의 구독자 ${subscribers.total}명에게 알림 발송 시작`);

      // 각 구독자에게 알림 발송
      for (const subscriber of subscribers.documents) {
        const userId = subscriber.$id;
        const fcmToken = subscriber.fcmToken;
        
        // FCM 토큰이 없는 사용자는 건너뜀
        if (!fcmToken) {
          console.log(`사용자 ${userId}의 FCM 토큰이 없습니다.`);
          continue;
        }

        try {
          // FCM 메시지 구성
          const message = {
            notification: {
              title: `[${boardName}] ${article.title}`,
              body: article.description.substring(0, 100) + (article.description.length > 100 ? '...' : '')
            },
            data: {
              boardId,
              articleId: extractArticleId(article.link),
              link: article.link
            },
            token: fcmToken
          };
          
          // 개별 사용자에게 메시지 전송
          await firebaseMessaging.send(message);
          console.log(`사용자 ${userId}에게 알림 전송 완료: ${boardId} - ${article.title}`);
        } catch (error) {
          console.error(`사용자 ${userId}에게 알림 전송 오류:`, error.message);
          
          // 유효하지 않은 토큰인 경우 토큰 정보 삭제
          if (
            error.code === 'messaging/invalid-registration-token' || 
            error.code === 'messaging/registration-token-not-registered'
          ) {
            try {
              // fcmToken 필드만 비워서 업데이트
              await databases.updateDocument(
                APPWRITE_DATABASE_ID,
                APPWRITE_USERS_COLLECTION_ID,
                userId,
                { fcmToken: '' }
              );
              console.log(`사용자 ${userId}의 유효하지 않은 FCM 토큰을 제거했습니다.`);
            } catch (updateError) {
              console.error(`사용자 ${userId}의 FCM 토큰 제거 중 오류:`, updateError.message);
            }
          }
        }
      }
    } catch (error) {
      console.error(`게시판 ${boardId}의 알림 처리 중 오류:`, error.message);
    }
  }
}

// 크롤링 메인 함수
async function crawlBoards() {
  console.log(`크롤링 시작: ${new Date().toISOString()}`);
  
  for (const board of boards) {
    try {
      const articles = await parseRSS(board.url);
      console.log(`${board.boardId}: ${articles.length}개 게시글 파싱 완료`);
      
      const newArticles = await processArticles(board.boardId, articles);
      console.log(`${board.boardId}: ${newArticles.length}개 새 게시글 발견`);
      
      if (newArticles.length > 0) {
        await sendNotifications(board.boardId, newArticles);
      }
    } catch (error) {
      console.error(`${board.boardId} 처리 중 오류:`, error.message);
    }
  }
  
  console.log(`크롤링 완료: ${new Date().toISOString()}`);
}

// 메인 함수
async function main() {
  try {
    console.log('가천대학교 공지사항 크롤러 시작...');
    await crawlBoards();
    console.log('크롤링 작업 완료');
  } catch (error) {
    console.error('크롤링 실행 중 예상치 못한 오류 발생:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// 실행
main(); 