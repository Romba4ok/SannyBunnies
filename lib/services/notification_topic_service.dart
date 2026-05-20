import 'package:shared_preferences/shared_preferences.dart';
import 'package:sannybunnies/services/notification_service.dart';

class NotificationTopicService {
  NotificationTopicService._();
  static final NotificationTopicService instance = NotificationTopicService._();

  static const String _prefsKey = 'subscribed_notification_topics';
  static const String generalTopic = 'general';
  static const String parentsTopic = 'parents';
  static const String teachersTopic = 'teachers';

  final NotificationService _notificationService = NotificationService.instance;

  static String userTopic(String uid) => 'user_$uid';
  static String groupTopic(String groupId) => 'group_$groupId';

  Future<Set<String>> _loadPersistedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final topics = prefs.getStringList(_prefsKey) ?? [];
    return topics.toSet();
  }

  Future<void> _savePersistedTopics(Set<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, topics.toList());
  }

  Future<void> updateSubscriptions({
    required String uid,
    required String role,
    List<String> groupIds = const [],
  }) async {
    print(
      '[NotificationTopicService] Обновление подписок: uid=$uid, role=$role, groupIds=$groupIds',
    );

    
    await _notificationService.getToken();

    final normalizedGroupTopics = groupIds
        .where((id) => id.isNotEmpty)
        .map(groupTopic)
        .toSet();

    final desiredTopics = <String>{};
    desiredTopics.add(generalTopic);
    desiredTopics.add(role == 'teacher' ? teachersTopic : parentsTopic);
    desiredTopics.add(userTopic(uid));
    desiredTopics.addAll(normalizedGroupTopics);

    print('[NotificationTopicService] Желаемые топики: $desiredTopics');

    final currentTopics = await _loadPersistedTopics();
    print('[NotificationTopicService] Текущие локальные подписки: $currentTopics');

    
    final topicsToUnsubscribe = currentTopics.difference(desiredTopics);
    final topicsToSubscribe = desiredTopics;

    if (topicsToUnsubscribe.isNotEmpty) {
      print('[NotificationTopicService] Отписка от: $topicsToUnsubscribe');
      for (final topic in topicsToUnsubscribe) {
        try {
          await _notificationService.unsubscribeFromTopic(topic);
          print('[✓] Отписка от $topic успешна');
        } catch (e) {
          print('[✗] Ошибка отписки от $topic: $e');
        }
      }
    }

    print('[NotificationTopicService] Подписка на: $desiredTopics');
    for (final topic in topicsToSubscribe) {
      try {
        await _notificationService.subscribeToTopic(topic);
        print('[✓] Подписка на $topic успешна');
      } catch (e) {
        print('[✗] Ошибка подписки на $topic: $e');
      }
    }

    await _savePersistedTopics(desiredTopics);
    print('[NotificationTopicService] Процесс обновления подписок завершен');
  }

  Future<void> clearSubscriptions() async {
    print('[NotificationTopicService] Очистка всех подписок');
    final currentTopics = await _loadPersistedTopics();
    for (final topic in currentTopics) {
      try {
        await _notificationService.unsubscribeFromTopic(topic);
      } catch (e) {}
    }
    await _savePersistedTopics(<String>{});
    print('[NotificationTopicService] Все подписки очищены');
  }
}
