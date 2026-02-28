import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../models/playing_card.dart';

const String _kSpriteAsset = 'assets/images/37631.jpg';

const Map<int, int> _suitToRow = {
  suitClubs: 0,
  suitSpades: 1,
  suitHearts: 2,
  suitDiamonds: 3,
};

class CardSpriteService {
  ui.Image? _sheet;
  double _cellW = 0;
  double _cellH = 0;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  ui.Image? get sheet => _sheet;
  double get cellWidth => _cellW;
  double get cellHeight => _cellH;

  Future<void> load() async {
    if (_loaded) {
      return;
    }
    final data = await rootBundle.load(_kSpriteAsset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _sheet = frame.image;
    _cellW = _sheet!.width / 13;
    _cellH = _sheet!.height / 4;
    _loaded = true;
  }

  ui.Rect sourceRect(PlayingCard card) {
    if (card.isJoker) {
      return _jokerRect();
    }
    final row = _suitToRow[card.suit] ?? 0;
    final col = card.rank - 1;
    return ui.Rect.fromLTWH(col * _cellW, row * _cellH, _cellW, _cellH);
  }

  ui.Rect _jokerRect() {
    return ui.Rect.fromLTWH(10 * _cellW, 2 * _cellH, _cellW, _cellH);
  }
}
