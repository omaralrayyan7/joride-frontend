import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/auth_models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color joRideAccent = Color(0xFF13366B);
  static const Color scaffoldBg = Color(0xFFF8F9FD);

  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getNotifications();
      if (mounted) setState(() => _notifications = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await ApiService.markAllNotificationsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications
              .map((n) => AppNotification(
                    id: n.id,
                    userId: n.userId,
                    title: n.title,
                    body: n.body,
                    type: n.type,
                    isRead: true,
                    createdAt: n.createdAt,
                  ))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _markOneRead(AppNotification notif) async {
    if (notif.isRead) return;
    try {
      await ApiService.markNotificationRead(notif.id);
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == notif.id);
          if (idx != -1) {
            _notifications[idx] = AppNotification(
              id: notif.id,
              userId: notif.userId,
              title: notif.title,
              body: notif.body,
              type: notif.type,
              isRead: true,
              createdAt: notif.createdAt,
            );
          }
        });
      }
    } catch (_) {
      // نتجاهل الخطأ هنا بصمت — الإشعار سيظل مرئياً
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking':
        return Icons.event_note_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'promo':
        return Icons.campaign_outlined;
      case 'system':
      default:
        return Icons.info_outline;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue.shade600;
      case 'payment':
        return Colors.green.shade600;
      case 'promo':
        return Colors.orange.shade600;
      case 'system':
      default:
        return joRideAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: joRideAccent,
        foregroundColor: Colors.white,
        title: const Text('Notifications'),
        // Brand-coloured back arrow on white
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            _markingAll
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _markAllRead,
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _notifications.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(_notifications[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(backgroundColor: joRideAccent),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.black12),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notif) {
    final unreadBg = const Color(0xFFEEF3FA);
    final iconColor = _colorForType(notif.type);

    return GestureDetector(
      onTap: () => _markOneRead(notif),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : unreadBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // أيقونة النوع
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconForType(notif.type), color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              // المحتوى
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: notif.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(notif.createdAt),
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}
