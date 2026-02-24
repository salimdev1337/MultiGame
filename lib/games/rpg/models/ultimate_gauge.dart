/// Manages the player's ultimate ability charge gauge (0.0 – 1.0).
/// Charges from landing hits and from taking damage.
/// Mutable — updated each frame by PlayerComponent.
class UltimateGauge {
  UltimateGauge({
    double hitChargeRate = 0.05,
    double damageChargeRate = 0.10,
    double startCharge = 0.0,
  })  : _hitChargeRate = hitChargeRate,
        _damageChargeRate = damageChargeRate,
        _charge = startCharge.clamp(0.0, 1.0);

  final double _hitChargeRate;
  final double _damageChargeRate;
  double _charge;

  double get charge => _charge;
  bool get isReady => _charge >= 1.0;

  void onHitLanded() {
    _charge = (_charge + _hitChargeRate).clamp(0.0, 1.0);
  }

  void onHitTaken() {
    _charge = (_charge + _damageChargeRate).clamp(0.0, 1.0);
  }

  /// Fires the ultimate and resets the gauge.
  void fire() {
    _charge = 0.0;
  }

  void reset(double startCharge) {
    _charge = startCharge.clamp(0.0, 1.0);
  }
}
