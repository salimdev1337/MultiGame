import 'package:flutter_riverpod/flutter_riverpod.dart';

class RpgUiState {
  const RpgUiState({
    this.showBossIntro = false,
    this.introText = '',
    this.showRewardDialog = false,
  });

  final bool showBossIntro;
  final String introText;
  final bool showRewardDialog;

  RpgUiState copyWith({
    bool? showBossIntro,
    String? introText,
    bool? showRewardDialog,
  }) {
    return RpgUiState(
      showBossIntro: showBossIntro ?? this.showBossIntro,
      introText: introText ?? this.introText,
      showRewardDialog: showRewardDialog ?? this.showRewardDialog,
    );
  }
}

final rpgUiProvider =
    NotifierProvider.autoDispose<RpgUiNotifier, RpgUiState>(RpgUiNotifier.new);

class RpgUiNotifier extends AutoDisposeNotifier<RpgUiState> {
  @override
  RpgUiState build() => const RpgUiState();

  void showBossIntro(String bossName) {
    state = state.copyWith(showBossIntro: true, introText: bossName);
  }

  void hideBossIntro() {
    state = state.copyWith(showBossIntro: false);
  }

  void showReward() {
    state = state.copyWith(showRewardDialog: true);
  }

  void hideReward() {
    state = state.copyWith(showRewardDialog: false);
  }
}
