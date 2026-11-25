import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi pengaturan notifikasi untuk Android & iOS
  static Future<void> initNotification() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    // Menggunakan named parameter settings: settings
    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Logika saat notifikasi diklik pengguna (opsional)
      },
    );

    // Minta izin notifikasi untuk Android 13+ (API 33+)
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  /// Memicu notifikasi pengingat tagihan belum lunas
  static Future<void> showBillReminderNotification({
    required int id,
    required String billTitle,
    required int unpaidCount,
    required double totalUnpaidAmount,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'split_bill_reminders',
      'Pengingat Tagihan',
      channelDescription: 'Notifikasi pengingat untuk tagihan patungan yang belum lunas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Menggunakan named parameters id:, title:, body:, dan notificationDetails:
    await _notificationsPlugin.show(
      id: id,
      title: 'Pengingat Tagihan: $billTitle',
      body: 'Masih ada $unpaidCount peserta yang belum bayar (Total: Rp ${totalUnpaidAmount.toStringAsFixed(0)}).',
      notificationDetails: platformDetails,
    );
  }
}