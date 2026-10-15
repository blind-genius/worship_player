import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';

/// دیالوگ انتخاب سرعت پخش صوت با پشتیبانی کامل از صفحه‌خوان تاک‌بک (TalkBack)
class SpeedSelectorDialog extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedSelected;

  const SpeedSelectorDialog({
    super.key,
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required double currentSpeed,
    required ValueChanged<double> onSpeedSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SpeedSelectorDialog(
        currentSpeed: currentSpeed,
        onSpeedSelected: onSpeedSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              label: 'انتخاب سرعت پخش صوت',
              child: Row(
                children: [
                  const Icon(Icons.speed_rounded, color: Color(0xFF0D9488)),
                  const SizedBox(width: 8),
                  Text(
                    'سرعت پخش',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppConstants.playbackSpeeds.map((speed) {
                final isSelected = (speed - currentSpeed).abs() < 0.05;
                final label = speed == 1.0
                    ? '۱.۰x (عادی)'
                    : '${AppFormatters.toPersianDigits(speed.toString())}x';

                final semanticText = isSelected
                    ? 'سرعت $label، انتخاب شده است.'
                    : 'سرعت $label، برای انتخاب دو بار ضربه بزنید.';

                return Semantics(
                  label: semanticText,
                  button: true,
                  selected: isSelected,
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onSpeedSelected(speed);
                        Navigator.pop(context);
                      }
                    },
                    selectedColor: const Color(0xFF0D9488),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
