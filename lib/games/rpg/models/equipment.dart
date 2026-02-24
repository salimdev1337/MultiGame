enum EquipmentSlot { weapon, armor }

class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.slot,
    this.atkBonus = 0,
    this.hpBonus = 0,
    this.ultimateStartCharge = 0.0,
    this.poisonResistance = false,
  });

  final String id;
  final String name;
  final EquipmentSlot slot;
  final int atkBonus;
  final int hpBonus;
  final double ultimateStartCharge;
  final bool poisonResistance;

  static const Equipment rustedBlade = Equipment(
    id: 'rusted_blade',
    name: 'Rusted Blade',
    slot: EquipmentSlot.weapon,
  );

  static const Equipment tornCloth = Equipment(
    id: 'torn_cloth',
    name: 'Torn Cloth',
    slot: EquipmentSlot.armor,
  );

  static const Equipment wardenSword = Equipment(
    id: 'warden_sword',
    name: "Warden's Sword",
    slot: EquipmentSlot.weapon,
    atkBonus: 8,
  );

  static const Equipment shamanCloak = Equipment(
    id: 'shaman_cloak',
    name: "Shaman's Cloak",
    slot: EquipmentSlot.armor,
    hpBonus: 25,
    poisonResistance: true,
  );

  static const Equipment hollowCrown = Equipment(
    id: 'hollow_crown',
    name: 'Hollow Crown',
    slot: EquipmentSlot.armor,
    atkBonus: 10,
    ultimateStartCharge: 0.20,
  );

  static Equipment? fromId(String id) {
    switch (id) {
      case 'rusted_blade':
        return rustedBlade;
      case 'torn_cloth':
        return tornCloth;
      case 'warden_sword':
        return wardenSword;
      case 'shaman_cloak':
        return shamanCloak;
      case 'hollow_crown':
        return hollowCrown;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() => {'id': id};
}
