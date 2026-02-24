import 'package:flutter/material.dart';
import 'package:multigame/games/rpg/models/equipment.dart';

class EquipmentOverlay extends StatelessWidget {
  const EquipmentOverlay({
    super.key,
    required this.equipment,
    required this.onEquip,
    required this.onSkip,
  });

  final Equipment equipment;
  final VoidCallback onEquip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ITEM FOUND',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1408),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFAA8800),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        equipment.name,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        equipment.slot == EquipmentSlot.weapon
                            ? 'Weapon'
                            : 'Armor',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (equipment.atkBonus > 0)
                        _StatLine('+${equipment.atkBonus} Attack'),
                      if (equipment.hpBonus > 0)
                        _StatLine('+${equipment.hpBonus} Max HP'),
                      if (equipment.ultimateStartCharge > 0)
                        _StatLine(
                          '+${(equipment.ultimateStartCharge * 100).round()}% Ultimate on fight start',
                        ),
                      if (equipment.poisonResistance)
                        _StatLine('Poison resistance'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: onSkip,
                        child: const Text('SKIP'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFAA8800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: onEquip,
                        child: const Text(
                          'EQUIP',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFFFD700))),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}
