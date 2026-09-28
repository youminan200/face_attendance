import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/utils/app_clock.dart';

/// 초 단위로 실시간 갱신되는 시계 카드 위젯
class RealTimeClockCard extends StatefulWidget {
  const RealTimeClockCard({super.key});

  @override
  State<RealTimeClockCard> createState() => _RealTimeClockCardState();
}

class _RealTimeClockCardState extends State<RealTimeClockCard> {
  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = AppClock.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = AppClock.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateText = AppClock.formatFullDate(_currentTime);
    final timeText = AppClock.formatTime(_currentTime);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.access_time_filled_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(180) ?? Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
