import 'package:equatable/equatable.dart';

/// How bank SMS reach the app on this device.
enum BankLinkMethod {
  /// iOS — a Shortcuts "Message" automation forwards each alert.
  shortcuts,

  /// Android — the app reads SMS from the chosen senders directly.
  sms,
}

/// What happens to a message once it has been read.
enum ImportMode {
  /// Everything waits in the inbox until the user confirms it.
  review,

  /// Fully-read messages become transactions straight away; unclear ones
  /// still wait for review.
  automatic,
}

/// The user's bank-SMS connection: whether it is live, which banks it reads
/// and how messages are imported.
class BankLink extends Equatable {
  const BankLink({
    this.isConnected = false,
    this.method,
    this.bankIds = const [],
    this.mode = ImportMode.review,
    this.connectedAt,
  });

  static const disconnected = BankLink();

  final bool isConnected;
  final BankLinkMethod? method;

  /// Banks whose alerts are read.
  final List<String> bankIds;
  final ImportMode mode;
  final DateTime? connectedAt;

  bool get isAutomatic => mode == ImportMode.automatic;

  BankLink copyWith({List<String>? bankIds, ImportMode? mode}) => BankLink(
        isConnected: isConnected,
        method: method,
        bankIds: bankIds ?? this.bankIds,
        mode: mode ?? this.mode,
        connectedAt: connectedAt,
      );

  @override
  List<Object?> get props => [isConnected, method, bankIds, mode, connectedAt];
}
