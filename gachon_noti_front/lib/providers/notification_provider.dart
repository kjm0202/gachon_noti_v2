import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/appwrite_service.dart';

class NotificationProvider with ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();

  List<NotificationItem> _notifications = [];
  bool _loading = false;
  bool _hasMore = true;
  String? _currentBoardId;
  String _errorMessage = '';

  List<NotificationItem> get notifications => _notifications;
  bool get loading => _loading;
  bool get hasMore => _hasMore;
  String? get currentBoardId => _currentBoardId;
  String get errorMessage => _errorMessage;

  // 게시글 목록 가져오기
  Future<void> fetchNotifications({
    bool refresh = false,
    String? boardId,
  }) async {
    if (_loading) return;

    if (refresh) {
      _notifications = [];
      _hasMore = true;
      _currentBoardId = boardId;
    }

    if (!_hasMore) return;

    _loading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final newItems = await _appwriteService.getNotifications(
        limit: 20,
        offset: _notifications.length,
        boardId: _currentBoardId,
      );

      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _notifications.addAll(newItems);
      }
    } catch (e) {
      _errorMessage = '게시글을 불러오는 중 오류가 발생했습니다: $e';
      print(_errorMessage);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // 게시판 필터 변경
  void changeBoardFilter(String? boardId) {
    if (_currentBoardId == boardId) return;

    _currentBoardId = boardId;
    fetchNotifications(refresh: true, boardId: boardId);
  }

  // 목록 새로고침
  Future<void> refreshNotifications() async {
    await fetchNotifications(refresh: true, boardId: _currentBoardId);
  }
}
