import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/screen_utils.dart';

class AppNotification {
  final String id;
  final String message;
  final bool isError;

  AppNotification({required this.message, this.isError = false})
      : id = Random().nextInt(1 << 32).toString();
}

class NotificationStackNotifier extends Notifier<List<AppNotification>> {
  static const int maxVisible = 3;
  final List<AppNotification> _queue = [];

  @override
  List<AppNotification> build() => [];

  void show(String message, {bool isError = false}) {
    final notification = AppNotification(message: message, isError: isError);
    if (state.length < maxVisible) {
      state = [...state, notification];
      _scheduleRemove(notification);
    } else {
      _queue.add(notification);
    }
  }

  void _scheduleRemove(AppNotification notification) {
    Future.delayed(const Duration(seconds: 4), () {
      if (state.contains(notification)) {
        _remove(notification);
      }
    });
  }

  void _remove(AppNotification notification) {
    state = state.where((n) => n.id != notification.id).toList();
    if (_queue.isNotEmpty && state.length < maxVisible) {
      final next = _queue.removeAt(0);
      state = [...state, next];
      _scheduleRemove(next);
    }
  }

  void dismiss(AppNotification notification) {
    if (state.contains(notification)) {
      state = state.where((n) => n.id != notification.id).toList();
      if (_queue.isNotEmpty && state.length < maxVisible) {
        final next = _queue.removeAt(0);
        state = [...state, next];
        _scheduleRemove(next);
      }
    }
  }
}

final notificationStackProvider =
    NotifierProvider<NotificationStackNotifier, List<AppNotification>>(
  NotificationStackNotifier.new,
);

class StackedNotificationOverlay extends ConsumerWidget {
  const StackedNotificationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationStackProvider);
    final cs = Theme.of(context).colorScheme;

    if (notifications.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: context.h(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final notification in notifications)
            Padding(
              padding: EdgeInsets.only(top: context.h(8)),
              child: _NotificationCard(
                key: ValueKey(notification.id),
                notification: notification,
                cs: cs,
                onDismiss: () {
                  ref
                      .read(notificationStackProvider.notifier)
                      .dismiss(notification);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final AppNotification notification;
  final ColorScheme cs;
  final VoidCallback onDismiss;

  const _NotificationCard({
    super.key,
    required this.notification,
    required this.cs,
    required this.onDismiss,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: context.w(20)),
            padding: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(14)),
            decoration: BoxDecoration(
              color: widget.notification.isError
                  ? widget.cs.error
                  : AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(AppTheme.smRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: context.w(12),
                  offset: Offset(0, context.h(4)),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  widget.notification.isError
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                  color: Colors.white,
                  size: context.f(20),
                ),
                SizedBox(width: context.w(12)),
                Expanded(
                  child: Text(
                    widget.notification.message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.f(14),
                      height: 1.3,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Icon(Icons.close, color: Colors.white70, size: context.f(18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
