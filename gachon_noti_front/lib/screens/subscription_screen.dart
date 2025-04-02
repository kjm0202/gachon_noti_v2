import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late List<String> _subscribedBoards;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _subscribedBoards = List.from(user?.subscribedBoards ?? []);
  }

  Future<void> _saveSubscriptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).updateSubscribedBoards(_subscribedBoards);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('알림 구독 설정이 저장되었습니다')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 구독 설정')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '구독할 게시판을 선택하세요',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '선택한 게시판의 새 글이 등록되면 알림을 받을 수 있습니다.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children:
                          AppConstants.boardNames.entries.map((entry) {
                            final boardId = entry.key;
                            final boardName = entry.value;

                            return CheckboxListTile(
                              title: Text(boardName),
                              value: _subscribedBoards.contains(boardId),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    if (!_subscribedBoards.contains(boardId)) {
                                      _subscribedBoards.add(boardId);
                                    }
                                  } else {
                                    _subscribedBoards.remove(boardId);
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _saveSubscriptions,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('저장하기'),
                    ),
                  ),
                ],
              ),
    );
  }
}
