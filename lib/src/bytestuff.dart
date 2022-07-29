import 'dart:typed_data';

class Uint28 {
  final int _n;
  Uint28(this._n);

  static Uint28 fromInt(int n) {
    return Uint28((n << 3) & 0x7f000000 |
        (n << 2) & 0x007f0000 |
        (n << 1) & 0x00007f00 |
        n & 0x0000007f);
  }

  Uint8List get bytes =>
      Uint8List.fromList([_n >>> 24, _n >>> 16, _n >>> 8, _n]);

  int get raw => _n;

  String toRadixString(int n) {
    return _n.toRadixString(n);
  }
}

Uint8List numberToBytes(int n) {
  final bytes = Uint8List(4);
  bytes.setAll(0, [
    n >>> 24,
    n >>> 16,
    n >>> 8,
    n,
  ]);
  return bytes;
}