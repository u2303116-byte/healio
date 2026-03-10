import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/medication.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Initialize ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Set up timezone correctly
    tz.initializeTimeZones();
    String localTimezone = await FlutterTimezone.getLocalTimezone();
    const Map<String, String> timezoneAliases = {
      'Asia/Calcutta': 'Asia/Kolkata',
      'Asia/Katmandu': 'Asia/Kathmandu',
      'Asia/Rangoon': 'Asia/Yangon',
      'Atlantic/Faeroe': 'Atlantic/Faroe',
      'Pacific/Ponape': 'Pacific/Pohnpei',
      'Pacific/Truk': 'Pacific/Chuuk',
    };
    localTimezone = timezoneAliases[localTimezone] ?? localTimezone;
    tz.setLocalLocation(tz.getLocation(localTimezone));

    // 2. Android: create the notification channel with lock-screen visibility
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Main medication reminder channel — shows on lock screen
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'medication_reminders',
          'Medication Reminders',
          description: 'Reminds you to take your medications on time',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );

      // Missed medication channel
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'missed_medications',
          'Missed Medications',
          description: 'Alerts for missed medication doses',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
    }

    // 3. Initialise the plugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse r) {},
      onDidReceiveBackgroundNotificationResponse: _bgHandler,
    );

    _initialized = true;
  }

  // ── Request all required permissions ──────────────────────────────────────

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // POST_NOTIFICATIONS (Android 13+)
      await androidPlugin?.requestNotificationsPermission();

      // SCHEDULE_EXACT_ALARM (Android 12+) — ask user to grant in Settings
      await androidPlugin?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
          alert: true, badge: true, sound: true);
    }
  }

  // ── Notification detail builders ───────────────────────────────────────────

  NotificationDetails _reminderDetails(Medication med) {
    final body = 'Take ${med.dose} now'
        '${med.instructions != null ? ' · ${med.instructions}' : ''}';
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Reminds you to take your medications on time',
        importance: Importance.max,
        priority: Priority.high,
        // KEY: show full content on lock screen
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF20B2AA),
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
        // Keep heads-up notification on screen longer
        timeoutAfter: 60000,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  // ── Schedule a single medication reminder ──────────────────────────────────

  Future<void> scheduleMedicationReminder(
      Medication medication, String time) async {
    await initialize();

    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final notifId = medication.id.hashCode.abs() % 2147483647;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // If saved within same minute, fire immediately
    final diffSeconds = now.difference(scheduled).inSeconds;
    if (diffSeconds >= 0 && diffSeconds <= 120) {
      await _notifications.show(
        notifId,
        '💊 Time for ${medication.name}',
        'Take ${medication.dose} now'
            '${medication.instructions != null ? ' · ${medication.instructions}' : ''}',
        _reminderDetails(medication),
        payload: '${medication.id}:$time',
      );
      return;
    }

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Use exactAllowWhileIdle so alarms fire even in Doze / lock screen.
    // requestExactAlarmsPermission() is called at startup to make this work.
    await _notifications.zonedSchedule(
      notifId,
      '💊 Time for ${medication.name}',
      'Take ${medication.dose} now'
          '${medication.instructions != null ? ' · ${medication.instructions}' : ''}',
      scheduled,
      _reminderDetails(medication),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      payload: '${medication.id}:$time',
    );
  }

  Future<void> scheduleAllMedications(List<Medication> medications) async {
    await initialize();
    await cancelAllNotifications();
    for (final med in medications) {
      for (final time in med.times) {
        try {
          await scheduleMedicationReminder(med, time);
        } catch (_) {}
      }
    }
  }

  // ── Instant notifications (missed / upcoming) ─────────────────────────────

  Future<void> showMissedMedicationNotification(MedicationDose dose) async {
    await initialize();
    await _notifications.show(
      (dose.medicationId.hashCode + dose.time.hashCode).abs() % 2147483647,
      '⚠️ Missed: ${dose.medicationName}',
      'You missed your ${dose.dose} at ${dose.time}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'missed_medications', 'Missed Medications',
          channelDescription: 'Alerts for missed medication doses',
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          color: const Color(0xFFFF6B6B),
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: '${dose.medicationId}:missed',
    );
  }

  Future<void> showUpcomingReminder(MedicationDose dose) async {
    await initialize();
    await _notifications.show(
      (dose.medicationId.hashCode + dose.time.hashCode + 1000).abs() % 2147483647,
      '🔔 Upcoming: ${dose.medicationName}',
      'Reminder: Take ${dose.dose} at ${dose.time}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders', 'Medication Reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          visibility: NotificationVisibility.public,
          color: const Color(0xFF20B2AA),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: '${dose.medicationId}:upcoming',
    );
  }

  // ── Cancel helpers ─────────────────────────────────────────────────────────

  Future<void> cancelAllNotifications() async =>
      _notifications.cancelAll();

  /// Cancel a single dose notification by medication ID + time.
  Future<void> cancelDoseNotification(String medicationId, String time) async {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final id = (medicationId.hashCode.abs() + hour * 60 + minute) % 2147483647;
    await _notifications.cancel(id);
  }

  Future<void> cancelMedicationNotifications(Medication medication) async {
    final id = medication.id.hashCode.abs() % 2147483647;
    await _notifications.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() =>
      _notifications.pendingNotificationRequests();
}

// Top-level handler required by flutter_local_notifications for background
@pragma('vm:entry-point')
void _bgHandler(NotificationResponse response) {}
