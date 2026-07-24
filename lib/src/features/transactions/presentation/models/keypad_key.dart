/// The role a key plays on the amount keypad — drives both its colour and the
/// action the screen takes when it is pressed.
enum KeypadKeyKind {
  /// A digit or the decimal point — appended to the amount.
  digit,

  /// An arithmetic operator (`+ − × ÷`) — decorative in the UI phase.
  operator,

  /// The `=` key — decorative in the UI phase.
  equals,

  /// The confirm key — commits the transaction.
  ok,
}

/// A single key on the amount keypad.
class KeypadKey {
  const KeypadKey(this.label, this.kind);

  final String label;
  final KeypadKeyKind kind;
}
