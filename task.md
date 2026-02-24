# RPG Redesign Plan — Shadowfall Chronicles

## Context

The current RPG is a 2D side-scrolling platformer with 2 bosses, pixel-art sprites that don't read well,
clunky platformer controls on mobile, shallow combat (basic attack + fireball + time slow), and no
real story. The goal is a full rewrite that keeps only the file structure — producing a top-down 2D
action RPG with best-in-class boss fights, a dark fantasy boss-hunting narrative, and satisfying power
progression from weak survivor to unstoppable force.

---

## Design Summary (all 30 decisions)

| # | Decision | Choice |
|---|----------|--------|
| 1 | Combat style | Real-time action (dodge, react) |
| 2 | Game structure | Linear story progression |
| 3 | Player fantasy | Power fantasy — become unstoppable |
| 4 | RPG depth | Medium: skill tree + equipment |
| 5 | Setting | Dark fantasy (demons, ruins, corruption) |
| 6 | Camera | **2D top-down (bird's eye)** — full departure from current platformer |
| 7 | Story delivery | Environmental storytelling only, no dialogue |
| 8 | Content scope | 3 chapters + final boss = **4 bosses total** |
| 9 | Classes | Single hero, grows over story |
| 10 | Combo system | 3-hit tap sequence (light → light → heavy finisher) |
| 11 | Equipment slots | Weapon + Armor (2 slots) |
| 12 | Upgrade loop | Level up after each boss defeat, pick stat node |
| 13 | Visual style | Pixel art upscaled to 16-bit era quality |
| 14 | Enemy variety | Boss-only — no trash mobs |
| 15 | Touch controls | Left joystick + 3 action buttons |
| 16 | Action buttons | **Attack** / **Dodge** / **Ultimate** |
| 17 | Boss design | Phase-based + learnable patterns per phase |
| 18 | Boss scope | 4 bosses: Warden, Shaman, Hollow King, Shadowlord |
| 19 | Skill tree | Stat + passive nodes (ATK, stamina cap, dodge CD, ultimate rate) |
| 20 | Ultimate | Screen-wide AOE blast |
| 21 | Arena shape | Medium open arena (balanced dodge space) |
| 22 | Equipment source | Boss drops (guaranteed, themed per boss) |
| 23 | World map | Boss select screen only |
| 24 | Dodge system | Stamina-based (pip bar, passive regen) |
| 25 | Ultimate charge | Builds from hitting the boss AND from taking damage |
| 26 | Difficulty | One well-tuned difficulty |
| 27 | Endgame | None — focus entirely on the main run |
| 28 | Core hook | **The bosses** — best-designed fights in the whole app |
| 29 | Code reuse | Full rewrite — keep file structure only |
| 30 | Story hook | Boss-hunting narrative (you seek out powerful enemies) |

---

## The Four Bosses

### Chapter 1 — The Warden
- Setting: Broken stone courtyard, abandoned weapons scattered, cracks glowing red
- Fantasy: Corrupted knight who sealed the ruins after the Shadowfall
- HP: ~300 | Phases: 2
- Phase 0 (100–50%): Slow charge + overhead slam (telegraphed, learnable)
- Phase 1 (≤50%): Gains shield bash + sweeping spin attack
- Teaching role: introduces dodge timing, stamina management, combo window
- Drop: Warden's Sword (weapon)

### Chapter 2 — The Plague Shaman
- Setting: Swamp clearing, dead trees, creeping toxic mist on ground
- Fantasy: Witch who turned the forest into a death zone after the Shadowfall
- HP: ~450 | Phases: 2
- Phase 0: Pools of poison on arena floor + projectile tosses
- Phase 1 (≤50%): Summons 2 stationary tendrils (hazards, not enemies) + faster casts
- Teaching role: introduces arena awareness, positioning, ultimate usage
- Drop: Shaman's Cloak (armor)

### Chapter 3 — The Hollow King
- Setting: Throne room ruins, shattered crown on floor, pale blue candlelight
- Fantasy: Undead king who refused to die after the Shadowfall, corrupted by it
- HP: ~600 | Phases: 3
- Phase 0 (100–66%): Sword dash patterns (cardinal + diagonal)
- Phase 1 (66–33%): Adds ground slam with shockwave
- Phase 2 (≤33%): Enraged — attacks faster, leaves lingering blade trails on arena
- Drop: Hollow Crown (armor variant / helm visual only, counts as armor slot)

### Final Boss — The Shadowlord
- Setting: The Shadowfall itself — void, falling debris, pitch-black sky
- Fantasy: The entity you've been hunting — the source of all corruption
- HP: ~900 | Phases: 3
- Phase 0: Combines Warden slam + Shaman poison pools (calls back earlier bosses)
- Phase 1: Adds Hollow King dash patterns, arena fills with shadow zones
- Phase 2 (≤33%): Full chaos — all previous patterns at once + ultimate sweep attack
- No drop — just victory

---

## Combat System (Top-Down)

### Movement
- Left joystick: 8-directional movement (top-down, no gravity)
- Player speed base: 180 px/s, upgradeable to 220 px/s via skill tree
- Player stays on flat arena floor (no platforms, no jumping)

### Attack Button (3-hit auto chain)
- Tap 1: Light slash (damage = ATK)
- Tap 2: Light slash (damage = ATK)
- Tap 3: Heavy finisher (damage = ATK × 1.8, slight knockback)
- Combo window: 0.6s between taps (miss window = reset to tap 1)
- Attack direction: faces joystick direction (or last moved direction if joystick neutral)
- Melee range: short (must be close to boss)

### Dodge Button (Stamina-gated)
- Direction: joystick direction (or away from boss if joystick neutral)
- Invincibility frames: 0.3s
- Stamina cost: 1 pip per dodge
- Stamina: 3 pips, regens 1 pip every 2s
- Visual: stamina shown as 3 dots below player HP bar
- Stamina upgradeable to 4 pips via skill tree

### Ultimate Button (Gauge-gated)
- Gauge fills from: hitting the boss (5% per hit) + taking damage (10% per hit taken)
- When gauge = 100%: button lights up, tap to activate
- Effect: full-screen pixel flash → massive AOE centered on player → all enemies/hazards on screen take 3× ATK damage, player is invincible during animation (0.8s)
- Visual: screen-wide particle burst, screen shake 0.5s, chromatic aberration flash
- After use: gauge resets to 0

### Game Feel (non-negotiable, highest priority)
- **Hitstop**: every hit pauses 3 frames (0.05s). Makes each hit feel crunchy.
- **Screen shake**: camera shakes 0.2s when player takes damage
- **Hit particles**: pixel particle burst on every hit landed on boss
- **Ultimate**: biggest screen shake (0.5s) + full-screen white flash + particle explosion
- **Boss hurt flash**: boss sprite flashes white on damage

---

## Skill Tree (Post-Boss Level-Ups)

4 level-ups total (one after each boss, no level-up after final boss).
Each level-up shows 3 random nodes from the pool — player picks 1.

### Stat Node Pool (12 nodes, 1 chosen per boss):
1. +15 Max HP
2. +5 ATK
3. +1 Stamina pip (max 4 total)
4. Dodge cooldown -0.3s
5. Combo window +0.2s (more forgiving tap timing)
6. Ultimate charge rate +20% (from hits)
7. Ultimate charge rate +20% (from taking damage)
8. Heavy finisher damage +30%
9. Movement speed +20 px/s
10. Stamina regen speed +30% faster
11. Hitstop duration +1 frame (more satisfying hits)
12. Boss poison/hazard damage -30%

---

## Equipment System

2 slots: Weapon + Armor
Gear dropped by bosses, passive stat bonuses.

| Boss | Drop | Bonus |
|------|------|-------|
| Warden | Warden's Sword | +8 ATK |
| Shaman | Shaman's Cloak | +25 Max HP + poison resistance |
| Hollow King | Hollow Crown | +10 ATK + ultimate starts 20% charged |
| Shadowlord | — (no drop) | — |

Default gear: Rusted Blade (0 ATK bonus), Torn Cloth (0 HP bonus)

---

## Story (Environmental Only, No Dialogue)

### Narrative: The Shadowfall
A corruption event broke the world. Powerful beings absorbed it and became monsters.
You are a hunter tracking them down. The arenas tell their stories — no words needed.

### Story beats told through arena design:
- **Chapter 1 arena**: weapons and armor left by previous hunters who failed. Cracks in the courtyard floor glow the same color as the Warden's eyes.
- **Chapter 2 arena**: tombstones half-submerged in swamp water. The Shaman used to be a healer (medicine pouches rotting in the mud).
- **Chapter 3 arena**: an enormous throne, small enough for a human king. Crown shattered on the floor before the fight starts.
- **Final arena**: falling architecture from all 3 previous chapters drifts in the void. The Shadowlord is made of all of them.

### Chapter transitions:
- After boss dies: screen fades to black, 1 line of ambient text (e.g. "The ruins breathe again.")
- Boss select screen: boss portraits, crossed out when defeated, corrupted silhouette before defeated

---

## Architecture — Full Rewrite Plan

### Keep (structure only)
- `/lib/games/rpg/` directory layout
- Riverpod `NotifierProvider.autoDispose` pattern
- `GameStatsMixin` for Firebase score saving
- Route: `/play/rpg` + `/play/rpg/boss_select`
- `rpg_game_definition.dart` entry

### Rewrite completely
All Dart files are rewritten. New models, new logic, new Flame components.

### New file structure

```
lib/games/rpg/
├── models/
│   ├── rpg_enums.dart           — BossId (warden/shaman/hollowKing/shadowlord), GamePhase,
│   │                              AttackType, PlayerAnim, BossAnim
│   ├── player_stats.dart        — HP, ATK, speed, stamina pips, equipment slots
│   ├── equipment.dart           — Equipment model (weapon/armor with stat bonuses)
│   ├── stamina_system.dart      — current pips, max pips, regen timer
│   ├── ultimate_gauge.dart      — current charge (0.0–1.0), charge rates
│   ├── boss_config.dart         — BossConfig for all 4 bosses (phases, patterns, HP)
│   └── attack_data.dart         — AttackData (type, damage, range, direction, lifetime)
├── logic/
│   ├── combat_calculator.dart   — damage formula, hitstop duration, crit (keep formula)
│   ├── progression_engine.dart  — level-up node pool, equipment application
│   ├── skill_tree.dart          — node definitions (12 nodes), random pick-3 logic
│   └── boss_ai/
│       ├── boss_ai.dart         — abstract BossAI interface (top-down)
│       ├── warden_ai.dart       — GolemAI replacement: charge + slam state machine
│       ├── shaman_ai.dart       — poison pool placement + projectile AI
│       ├── hollow_king_ai.dart  — dash pattern AI (cardinal/diagonal routing)
│       └── shadowlord_ai.dart   — final boss AI (combines all 3 patterns)
├── providers/
│   ├── rpg_notifier.dart        — RpgState + RpgNotifier (progression, equipment, saves)
│   └── rpg_ui_notifier.dart     — UI overlay states
├── game/
│   └── rpg_flame_game.dart      — RpgFlameGame (top-down, no gravity, HasCollisionDetection)
├── components/
│   ├── player_component.dart    — top-down movement (360°), combo system, stamina, ultimate
│   ├── boss_component.dart      — top-down boss, phase tracking, AI delegation
│   ├── attack_component.dart    — projectiles/AOE in top-down space
│   └── arena_component.dart     — top-down tiled floor, environmental decorations
├── sprites/
│   ├── pixel_sprite.dart        — keep renderer, increase resolution
│   ├── player_sprites.dart      — 16×16 hero (idle, walk-4dir, attack-3hit, dodge, ultimate)
│   ├── warden_sprites.dart      — 24×24 boss sprite
│   ├── shaman_sprites.dart      — 24×24 boss sprite
│   ├── hollow_king_sprites.dart — 24×24 boss sprite
│   └── shadowlord_sprites.dart  — 32×32 final boss sprite
├── screens/
│   ├── boss_select_screen.dart  — 4 boss cards, chapter labels, defeat markers
│   └── rpg_game_screen.dart     — game widget + overlays + joystick + 3 buttons
└── widgets/
    ├── rpg_hud.dart             — HP bar (player + boss), stamina pips, ultimate gauge
    ├── boss_intro_overlay.dart  — keep 2.2s intro (reuse pattern)
    ├── level_up_overlay.dart    — post-boss: show 3 stat nodes, pick 1
    ├── equipment_overlay.dart   — show new gear drop on boss defeat
    ├── rpg_action_buttons.dart  — 3 circular buttons: ATK / DODGE / ULTIMATE
    └── rpg_joystick.dart        — keep as-is (already works well)
```

---

## HUD Layout (Top-Down Screen)

```
[Player HP ▓▓▓▓▓▓░░░░]        [Boss HP ░░░░▓▓▓▓▓▓]
[● ● ●] stamina pips          [PHASE 1] badge

                ARENA (top-down)

[Joystick]          [DODGE] [ATK] [ULTIMATE⚡]
```

Ultimate button glows when charged. Stamina pips dim as used, refill as they regen.

---

## Flame Game — Top-Down Specifics

### RpgFlameGame changes from current
- Remove: gravity constant, jump force, platform Rects, platformer physics
- Remove: landscape lock → keep landscape (good for top-down)
- Add: top-down movement (velocity applied in XY, no Y gravity)
- Add: arena boundary (player cannot leave arena bounds)
- Camera: fixed on arena center (no scrolling for medium arena)
- Collision: boss + player are circles (radius-based), attacks are circles or rectangles

### PlayerComponent (top-down)
```dart
// Movement
velocity = joystickInput.normalized() * speed;
position += velocity * dt;

// Combo
_comboStep (0, 1, 2) — resets after 0.6s idle
onAttackPressed() → spawn attack in facing direction, advance _comboStep

// Stamina
_staminaPips: int (0–maxPips)
onDodgePressed() → if _staminaPips > 0: trigger dodge, _staminaPips--, start regen timer

// Ultimate
_ultimateCharge: double (0.0–1.0)
onHitLanded() → _ultimateCharge += 0.05
onHitTaken() → _ultimateCharge += 0.10
onUltimatePressed() → if _ultimateCharge >= 1.0: trigger AOE blast, reset to 0.0
```

---

## Deliverables Before Coding

1. Create `rpg.md` at repo root with this design document (gitignored)
2. Add `rpg.md` to `.gitignore`

---

## Implementation Phases (Task Breakdown)

### Phase 1 — Foundation (rewrite engine, top-down core)
**Goal:** Playable movement + attack in a flat top-down arena. No real boss yet.

Tasks:
- [ ] P1-1: New `RpgFlameGame` — top-down (remove gravity, platformer code), keep event stream
- [ ] P1-2: New `PlayerComponent` — 360° joystick movement, facing direction, arena boundary
- [ ] P1-3: Combo system — 3-hit chain, combo window timer, attack arc spawning
- [ ] P1-4: Stamina system — `StaminaSystem` model + dodge with pip consumption + regen
- [ ] P1-5: Ultimate gauge — `UltimateGauge` model + charge from hits/damage taken + AOE trigger
- [ ] P1-6: `AttackComponent` — melee arc (short range), AOE (full screen), projectile (boss attacks)
- [ ] P1-7: `ArenaComponent` — flat floor, boundary walls, placeholder visual per arena
- [ ] P1-8: HUD — HP bars, stamina pips, ultimate gauge ring
- [ ] P1-9: Placeholder boss — moves toward player, takes damage, dies → fires `bossDefeated` event
- [ ] P1-10: Game feel basics — hitstop (3 frames), screen shake, hit particles

**Done when:** You can enter a fight, combo the boss, dodge using stamina, charge and fire Ultimate.

---

### Phase 2 — All Four Boss Fights
**Goal:** Each boss is distinct, challenging, has 2–3 phases, learnable patterns.

Tasks:
- [ ] P2-1: `BossComponent` — phase detection, AI delegation, hurt flash, enrage badge
- [ ] P2-2: `WardenAI` — charge + overhead slam, 2 phases, enrage at 50% HP
- [ ] P2-3: `ShamanAI` — poison pool spawning + projectile tosses, 2 phases
- [ ] P2-4: `HollowKingAI` — dash patterns (cardinal/diagonal), blade trails at phase 3, 3 phases
- [ ] P2-5: `ShadowlordAI` — combines all 3 patterns, 3 phases, progressive escalation
- [ ] P2-6: Boss sprites — 16-bit pixel art for all 4 bosses (readable silhouettes, idle + attack anim)
- [ ] P2-7: Player sprites — 16-bit (idle, walk 4-dir, attack 3-hit, dodge, ultimate)
- [ ] P2-8: Arena visuals — environmental storytelling art for each of the 4 arenas

**Done when:** All 4 bosses are playable, phased, and challenging but fair.

---

### Phase 3 — Progression & Story
**Goal:** Full game loop: defeat boss → level up → equipment drop → select next boss.

Tasks:
- [ ] P3-1: `RpgNotifier` rewrite — 4 bosses, equipment slots, linear chapter unlock
- [ ] P3-2: `SkillTree` — 12-node pool, random pick-3 on level-up, no duplicates
- [ ] P3-3: `LevelUpOverlay` — show 3 nodes after boss death, pick 1, apply to stats
- [ ] P3-4: `EquipmentOverlay` — show boss gear drop after level-up
- [ ] P3-5: `ProgressionEngine` rewrite — equipment bonuses applied to PlayerStats
- [ ] P3-6: Boss select screen — 4 chapters, portraits, defeat state, chapter labels
- [ ] P3-7: Chapter transition — fade to black + 1 ambient sentence between chapters
- [ ] P3-8: Persistence — save/load progress (SharedPreferences, JSON serializable models)

**Done when:** Defeating Warden unlocks Shaman, etc. Equipment persists. Stats persist.

---

### Phase 4 — Polish & Game Feel (highest priority for "memorable bosses")
**Goal:** Every hit feels satisfying. The Ultimate feels epic. Bosses feel weighty.

Tasks:
- [ ] P4-1: Hitstop — verify 3-frame pause fires on every attack hit landed
- [ ] P4-2: Screen shake — camera offset on player damage + Ultimate activation
- [ ] P4-3: Hit particles — pixel burst on boss damage, different color per attack type
- [ ] P4-4: Ultimate animation — full-screen white flash + chromatic aberration + pixel explosion
- [ ] P4-5: Boss phase transition — brief visual pause + arena color shift on phase change
- [ ] P4-6: Boss death — satisfying death animation (shatter/dissolve in pixels)
- [ ] P4-7: Boss intro overlay — reuse current 2.2s pattern, update for each boss name/title
- [ ] P4-8: Sound hooks — attack SFX, dodge SFX, ultimate SFX, boss hurt, boss death, level-up

**Done when:** Blind-playtesting someone says "the hits feel great."

---

### Phase 5 — Tests & Cleanup
Tasks:
- [ ] P5-1: `combat_calculator_test.dart` — damage formula, hitstop, crit
- [ ] P5-2: `progression_engine_test.dart` — equipment bonuses, node application
- [ ] P5-3: `skill_tree_test.dart` — pick-3 random, no duplicates, all 12 nodes
- [ ] P5-4: `stamina_system_test.dart` — pip consumption, regen timer
- [ ] P5-5: `ultimate_gauge_test.dart` — charge from hits, charge from damage, fire + reset
- [ ] P5-6: `warden_ai_test.dart` — state machine: idle→charge→slam→cooldown
- [ ] P5-7: `shaman_ai_test.dart` — poison pool targeting, projectile timing
- [ ] P5-8: `flutter analyze` full project — zero warnings before any commit

---

## Critical Files to Modify (non-RPG)

- `lib/games/rpg/rpg_game_definition.dart` — update description text
- `lib/config/service_locator.dart` — no change needed (autoDispose pattern)
- `lib/core/game_registry.dart` — no change needed (already registered)

---

## Tests to Write

- `test/games/rpg/combat_calculator_test.dart` — damage formula, hitstop, crit (keep existing)
- `test/games/rpg/progression_engine_test.dart` — node pool, equipment bonuses
- `test/games/rpg/skill_tree_test.dart` — 3-node random pick, no duplicates
- `test/games/rpg/stamina_system_test.dart` — pip consumption, regen timing
- `test/games/rpg/ultimate_gauge_test.dart` — charge from hits, charge from damage, reset
- `test/games/rpg/boss_ai/warden_ai_test.dart` — state machine transitions
- `test/games/rpg/boss_ai/shaman_ai_test.dart` — poison pool targeting
- Keep existing 16 tests where logic is reusable, rewrite the rest

## Verification

1. `flutter analyze` — zero warnings (run full project, not scoped)
2. `flutter test` — all tests pass
3. Manual: launch game → boss select shows 4 bosses → enter Warden fight → combo registers → dodge costs stamina → ultimate charges → boss phases trigger → defeat → level-up overlay → equipment shown → back to select → next boss unlocked
4. Check: hitstop fires on every hit (visible pause), screen shake on player damage, ultimate flash covers full screen
