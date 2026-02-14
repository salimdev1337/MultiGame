import 'package:flutter/material.dart';
import 'package:multigame/design_system/design_system.dart';

enum TimePeriod {
  daily('Daily', 'day'),
  weekly('Weekly', 'week'),
  allTime('All Time', 'all');

  final String label;
  final String value;
  const TimePeriod(this.label, this.value);
}

class TimePeriodSelector extends StatefulWidget {
  final TimePeriod selectedPeriod;
  final ValueChanged<TimePeriod> onPeriodChanged;

  const TimePeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  State<TimePeriodSelector> createState() => _TimePeriodSelectorState();
}

class _TimePeriodSelectorState extends State<TimePeriodSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: DSSpacing.paddingMD,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DSColors.surface,
        borderRadius: DSSpacing.borderRadiusLG,
        border: Border.all(
          color: DSColors.textTertiary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: TimePeriod.values.map((period) {
          final isSelected = period == widget.selectedPeriod;
          return Expanded(
            child: AnimatedContainer(
              duration: DSAnimations.fast,
              curve: Curves.easeOutCubic,
              child: Material(
                color: Colors.transparent,
                child: Semantics(
                  label:
                      '${period.label} time period${isSelected ? ", selected" : ""}',
                  button: true,
                  selected: isSelected,
                  child: InkWell(
                    onTap: () => widget.onPeriodChanged(period),
                    borderRadius: DSSpacing.borderRadiusMD,
                    child: Container(
                      padding: DSSpacing.paddingSM,
                      decoration: BoxDecoration(
                        gradient: isSelected ? DSColors.gradientPrimary : null,
                        borderRadius: DSSpacing.borderRadiusMD,
                        boxShadow: isSelected ? DSShadows.shadowPrimary : null,
                      ),
                      child: Text(
                        period.label,
                        style: DSTypography.labelMedium.copyWith(
                          color: isSelected
                              ? Colors.black
                              : DSColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
