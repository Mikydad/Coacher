import 'dart:math';

class StableId {
  const StableId._();

  static final Random _random = Random();

  static String generate([String prefix = 'id']) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final entropy = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return '${prefix}_$ts$entropy';
  }
}
