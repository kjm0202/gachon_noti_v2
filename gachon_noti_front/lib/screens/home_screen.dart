import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification_item.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedBoardId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    Future.microtask(() {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications(refresh: true, boardId: _selectedBoardId);
    });
  }

  void _onBoardChanged(String? boardId) {
    setState(() {
      _selectedBoardId = boardId;
    });
    Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).changeBoardFilter(boardId);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('가천 알림'),
        actions: [
          IconButton(
            onPressed: _showBoardFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: '게시판 필터',
          ),
          IconButton(
            onPressed: _showSettingsBottomSheet,
            icon: const Icon(Icons.settings),
            tooltip: '설정',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await notificationProvider.refreshNotifications();
        },
        child:
            notificationProvider.loading &&
                    notificationProvider.notifications.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : notificationProvider.notifications.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedBoardId == null
                            ? '게시글이 없습니다.'
                            : '${AppConstants.boardNames[_selectedBoardId]} 게시판에 게시글이 없습니다.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  itemCount:
                      notificationProvider.notifications.length +
                      (notificationProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= notificationProvider.notifications.length) {
                      // 더 불러오기
                      Future.microtask(() {
                        notificationProvider.fetchNotifications(
                          boardId: _selectedBoardId,
                        );
                      });

                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final notification =
                        notificationProvider.notifications[index];
                    return _buildNotificationItem(notification);
                  },
                ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    // 게시일 형식 변환
    DateTime publishDate;
    try {
      publishDate = DateTime.parse(notification.pubDate.replaceAll('.', '-'));
    } catch (e) {
      publishDate = DateTime.now();
    }

    timeago.setLocaleMessages('ko', timeago.KoMessages());
    final formattedDate = timeago.format(publishDate, locale: 'ko');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        title: Text(
          notification.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${notification.getBoardName()} · $formattedDate · ${notification.author}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                notification.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        contentPadding: const EdgeInsets.all(12),
        onTap: () => _openLink(notification.link),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  void _showBoardFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('게시판 필터'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('전체 게시판'),
                  selected: _selectedBoardId == null,
                  onTap: () {
                    Navigator.pop(context);
                    _onBoardChanged(null);
                  },
                ),
                const Divider(),
                ...AppConstants.boardNames.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.value),
                    selected: _selectedBoardId == entry.key,
                    onTap: () {
                      Navigator.pop(context);
                      _onBoardChanged(entry.key);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsBottomSheet() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                child: user?.photoUrl == null ? const Icon(Icons.person) : null,
              ),
              title: Text(user?.name ?? '사용자'),
              subtitle: Text(user?.email ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('알림 설정'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/subscription');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('앱 정보'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('로그아웃'),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: '가천 알림',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset(
        'assets/images/logo.png',
        width: 48,
        height: 48,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.school, size: 48);
        },
      ),
      children: [
        const Text('가천대학교 공지사항 알림 서비스'),
        const SizedBox(height: 8),
        const Text('이 앱은 가천대학교의 공식 앱이 아닙니다.'),
      ],
    );
  }
}
