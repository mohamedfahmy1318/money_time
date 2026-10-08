/// A bank SMS read from the device inbox, before upload.
class RawSms {
  const RawSms({
    required this.sender,
    required this.body,
    required this.timestampMs,
  });

  factory RawSms.fromMap(Map<Object?, Object?> map) => RawSms(
        sender: '${map['sender'] ?? ''}',
        body: '${map['body'] ?? ''}',
        timestampMs: (map['timestampMs'] as num?)?.toInt() ?? 0,
      );

  final String sender;
  final String body;

  /// Service-centre send time — the same source the live receiver uses, so
  /// the server's minute-level duplicate check matches both paths.
  final int timestampMs;

  Map<String, dynamic> toWire() => {
        'sender': sender,
        'body': body,
        'received_at': DateTime.fromMillisecondsSinceEpoch(
          timestampMs,
          isUtc: true,
        ).toIso8601String(),
      };
}
