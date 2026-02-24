/// Manages the player's dodge stamina pip system.
/// Mutable — updated each frame by PlayerComponent.
class StaminaSystem {
  StaminaSystem({int maxPips = 3, double regenInterval = 2.0})
    : _maxPips = maxPips,
      _regenInterval = regenInterval,
      _currentPips = maxPips;

  int _maxPips;
  double _regenInterval;
  int _currentPips;
  double _regenTimer = 0;

  int get currentPips => _currentPips;
  int get maxPips => _maxPips;
  bool get hasPips => _currentPips > 0;

  void consumePip() {
    if (_currentPips > 0) {
      _currentPips--;
      _regenTimer = _regenInterval;
    }
  }

  void update(double dt) {
    if (_currentPips < _maxPips) {
      _regenTimer -= dt;
      if (_regenTimer <= 0) {
        _currentPips++;
        _regenTimer = _currentPips < _maxPips ? _regenInterval : 0;
      }
    }
  }

  void reset(int maxPips, double regenInterval) {
    _maxPips = maxPips;
    _regenInterval = regenInterval;
    _currentPips = maxPips;
    _regenTimer = 0;
  }
}
