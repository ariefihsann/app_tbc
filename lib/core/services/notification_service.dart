import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Inisialisasi zona waktu
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta')); // Default WIB

    // 2. Setting logo notifikasi
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    // FIX 1: Hapus kata "settings:" karena sekarang dia positional argument
    await _notificationsPlugin.initialize(initSettings);

    // 3. Minta izin notifikasi
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Fungsi untuk memasang alarm setiap hari pada jam tertentu
  Future<void> scheduleDailyMedicationReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, time.hour, time.minute,
    );

    // Jika jamnya sudah lewat untuk hari ini, set untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_channel_id',
      'Pengingat Obat',
      channelDescription: 'Alarm untuk mengingatkan waktu minum obat TBC',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    // FIX 2: 5 Argumen pertama (id sampai notificationDetails) WAJIB ditulis tanpa nama parameter.
    // 'uiLocalNotificationDateInterpretation' WAJIB ADA di versi terbaru ini.
    await _notificationsPlugin.zonedSchedule(
      id,                   // Positional argumen 1
      title,                // Positional argumen 2
      body,                 // Positional argumen 3
      scheduledDate,        // Positional argumen 4
      notificationDetails,  // Positional argumen 5
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}