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

/// What `ensureCapture` left this device doing.
enum CaptureOutcome {
  /// Native capture holds a valid token for this link.
  armed,

  /// The link captures on a phone of the other platform (one live token per
  /// account): this device stands down.
  standingDown,

  /// This device's token was revoked — another phone took over, or the
  /// password changed. Capture waits for the user to claim it back.
  revoked,
}

/// What the iPhone Shortcuts automation did the last time it ran the
/// "Log Bank Message" intent — shown in the hub so "it never fired" and
/// "it fired but ignored sender +2010…" look different.
enum CaptureRunOutcome { delivered, queued, skipped, empty, error }

class CaptureRun extends Equatable {
  const CaptureRun({
    required this.at,
    required this.outcome,
    this.sender,
    this.detail,
  });

  final DateTime at;
  final CaptureRunOutcome outcome;

  /// The sender the automation passed (or the bank it was set to).
  final String? sender;

  /// The user-facing error text, for [CaptureRunOutcome.error] / `empty`.
  final String? detail;

  @override
  List<Object?> get props => [at, outcome, sender, detail];
}

/// [outcome] plus how many SMS the catch-up scan just delivered (messages
/// that arrived while the receiver was dead: force-stop, before first unlock)
/// and, on iPhone, the automation's last run.
typedef CaptureReport = ({
  CaptureOutcome outcome,
  int caughtUp,
  CaptureRun? lastRun,
});
