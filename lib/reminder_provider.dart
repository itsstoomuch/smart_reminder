import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class ReminderProvider extends ChangeNotifier {
  final List<String> _reminders = [];
  late Box reminderBox; // 👈 late instead of final so we can set it later

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ✅ Constructor - only initializes notifications here
  ReminderProvider() {
    initializeNotifications();
  }

  // ✅ 🔁 This is the `init()` method you asked for
  Future<void> init() async {
    reminderBox = Hive.box('reminders');
    loadReminders();
  }

  void initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  List<String> get reminders => _reminders;

  void loadReminders() {
    final storedReminders = reminderBox.get('list', defaultValue: <String>[]);
    _reminders.clear();
    _reminders.addAll(List<String>.from(storedReminders));
    notifyListeners();
  }

  void saveReminders() {
    reminderBox.put('list', _reminders);
  }

  void addReminder(String text) {
    _reminders.add(text);
    saveReminders();
    notifyListeners();

    if (text.toLowerCase().contains("at")) {
      final parts = text.split("at");
      if (parts.length >= 2) {
        final task = parts[0].replaceAll("Remind me to", "").trim();
        final time = parts[1].trim();
        scheduleNotification(task, time);
      }
    }
  }

  void removeReminder(int index) {
    _reminders.removeAt(index);
    saveReminders();
    notifyListeners();
  }

  void clearAll() {
    _reminders.clear();
    saveReminders();
    notifyListeners();
  }

  void scheduleNotification(String task, String timeString) async {
    try {
      final now = DateTime.now();
      final parsedTime = DateFormat.jm().parseStrict(timeString);

      DateTime scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Scheduled reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.hashCode,
        'Reminder',
        task,
        tzTime,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('❌ Notification scheduling error: $e');
    }
  }
}
