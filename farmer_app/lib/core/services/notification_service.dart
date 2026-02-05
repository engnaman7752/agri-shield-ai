import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification Service for Farmer App
/// Handles local push notifications for claim updates and verification status
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to appropriate screen
    // This can be extended to parse payload and navigate
  }

  /// Show a notification for claim status update
  Future<void> showClaimStatusNotification({
    required String claimId,
    required String status,
    String? diseaseDetected,
    double? damagePercentage,
  }) async {
    String title;
    String body;

    switch (status.toUpperCase()) {
      case 'APPROVED':
        title = '✅ Claim Approved!';
        body = diseaseDetected != null
            ? 'AI detected: $diseaseDetected (${damagePercentage?.toStringAsFixed(1)}% damage). Payout processing...'
            : 'Your claim has been approved. Payout will be processed soon.';
        break;
      case 'REJECTED':
        title = '❌ Claim Rejected';
        body = 'Your claim could not be processed. Please check the app for details.';
        break;
      case 'PROCESSING':
        title = '🔄 Claim Under Review';
        body = 'AI is analyzing your crop images. Results coming soon!';
        break;
      default:
        title = '📋 Claim Update';
        body = 'Your claim status has been updated to: $status';
    }

    await _showNotification(
      id: claimId.hashCode,
      title: title,
      body: body,
      payload: 'claim:$claimId',
    );
  }

  /// Show a notification for verification status
  Future<void> showVerificationNotification({
    required String policyNumber,
    required bool isApproved,
    String? sensorAssigned,
  }) async {
    final title = isApproved
        ? '🎉 Insurance Verified!'
        : '⚠️ Verification Update';

    final body = isApproved
        ? 'Policy $policyNumber is now ACTIVE.${sensorAssigned != null ? ' Sensor $sensorAssigned assigned to your farm.' : ''}'
        : 'Policy $policyNumber verification needs attention. Please check the app.';

    await _showNotification(
      id: policyNumber.hashCode,
      title: title,
      body: body,
      payload: 'policy:$policyNumber',
    );
  }

  /// Show a notification for payment confirmation
  Future<void> showPaymentNotification({
    required String policyNumber,
    required double amount,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '💳 Payment Successful!',
      body: '₹${amount.toStringAsFixed(0)} paid for policy $policyNumber. Awaiting Patwari verification.',
      payload: 'policy:$policyNumber',
    );
  }

  /// Generic notification display method
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'farmer_shield_channel',
      'Farmer Shield Notifications',
      channelDescription: 'Notifications for insurance claims and policy updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Request notification permissions (for iOS)
  Future<bool> requestPermissions() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }
}
