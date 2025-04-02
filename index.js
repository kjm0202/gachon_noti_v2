require('dotenv').config();
const axios = require('axios');
const xml2js = require('xml2js');
const { Client, Databases, Query } = require('node-appwrite');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Appwrite 클라이언트 설정
const appwrite = new Client()
  .setEndpoint(process.env.APPWRITE_ENDPOINT)
  .setProject(process.env.APPWRITE_PROJECT_ID)
  .setKey(process.env.APPWRITE_API_KEY);

const databases = new Databases(appwrite);

// Firebase 설정
try {
  // 환경 변수로 Firebase 초기화 (우선)
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      }),
    });
    console.log('Firebase 초기화 완료 (환경변수 방식)');
  } 
  // 파일로 초기화 (대체 방식)
  else if (process.env.FIREBASE_CREDENTIALS_PATH && fs.existsSync(process.env.FIREBASE_CREDENTIALS_PATH)) {
    admin.initializeApp({
      credential: admin.credential.cert(process.env.FIREBASE_CREDENTIALS_PATH)
    });
    console.log('Firebase 초기화 완료 (인증 파일 방식)');
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
    const parser = new xml2js.Parser({ explicitArray: false });
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
        process.env.APPWRITE_DATABASE_ID,
        process.env.APPWRITE_COLLECTION_ID,
        [
          Query.equal('articleId', articleId),
          Query.equal('boardId', boardId)
        ]
      );
      
      // 새 게시글인 경우 저장
      if (existingArticles.total === 0) {
        const documentId = `${boardId}_${articleId}`;
        
        await databases.createDocument(
          process.env.APPWRITE_DATABASE_ID,
          process.env.APPWRITE_COLLECTION_ID,
          documentId,
          {
            boardId,
            articleId,
            title: article.title,
            link: article.link,
            pubDate: article.pubDate,
            author: article.author,
            description: article.description,
            createdAt: new Date().toISOString(),
          }
        );
        
        newArticles.push(article);
        console.log(`새 게시글 저장: ${boardId} - ${article.title}`);
      }
    } catch (error) {
      console.error(`게시글 처리 오류 (${boardId}, ${articleId}):`, error.message);
    }
  }
  
  return newArticles;
}

// FCM 알림 전송 함수
async function sendNotifications(boardId, newArticles) {
  if (newArticles.length === 0 || !admin.messaging) return;
  
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
      const message = {
        topic: process.env.FIREBASE_TOPIC,
        notification: {
          title: `[${boardName}] ${article.title}`,
          body: article.description.substring(0, 100) + (article.description.length > 100 ? '...' : '')
        },
        data: {
          boardId,
          articleId: extractArticleId(article.link),
          link: article.link
        }
      };
      
      await admin.messaging().send(message);
      console.log(`알림 전송 완료: ${boardId} - ${article.title}`);
    } catch (error) {
      console.error('알림 전송 오류:', error.message);
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

// 실행
crawlBoards().catch(error => {
  console.error('크롤링 오류:', error);
  process.exit(1);
}); 