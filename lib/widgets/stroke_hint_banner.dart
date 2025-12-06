import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/stroke_grader.dart';

class StrokeHintBanner extends StatelessWidget {
  final FailureReason failureReason;

  const StrokeHintBanner({
    super.key,
    required this.failureReason,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, message) = _getIconAndMessage();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: Colors.amber.shade400, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber.shade800, size: 24),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String) _getIconAndMessage() {
    switch (failureReason) {
      case FailureReason.strokeCount:
        return (Icons.format_list_numbered, '画数を確認しよう');
      case FailureReason.strokeOrder:
        return (Icons.sort, '書き順を確認しよう');
      case FailureReason.strokeShape:
        return (Icons.gesture, '形を確認しよう');
    }
  }
}
