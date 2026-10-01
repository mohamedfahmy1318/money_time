import 'package:dio/dio.dart';

import 'package:mony_time/src/config/app_config.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_link_model.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_message_model.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_model.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/parsing/bank_sms_parser.dart';

/// Raw API calls for the bank-SMS link: the connection settings and the
/// message inbox the device syncs up.
///
/// Throws on failure — error mapping happens in the repository via `runTask`.
/// While [AppConfig.useMockData] is `true` the class works against an
/// in-memory store; connecting seeds a realistic recent inbox (English and
/// Arabic alerts from the chosen banks) so the whole review flow is walkable.
/// The native capture (Android SMS reader / iOS Shortcut intent) is not wired
/// yet — it will feed `saveMessage`.
class BankSyncRemoteDataSource {
  BankSyncRemoteDataSource({Dio? dio}) : _dio = dio ?? AppConfig.dio;

  final Dio _dio;

  static const _mockDelay = Duration(milliseconds: 350);

  Future<List<BankModel>> getSupportedBanks() async {
    if (AppConfig.useMockData) return _banks;
    final response = await _dio.get<List<dynamic>>('/bank-sync/banks');
    return (response.data ?? const [])
        .map((e) => BankModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BankLinkModel> getLink() async {
    if (AppConfig.useMockData) return _link;
    final response = await _dio.get<Map<String, dynamic>>('/bank-sync/link');
    return BankLinkModel.fromJson(response.data!);
  }

  Future<BankLinkModel> connect({
    required BankLinkMethod method,
    required List<String> bankIds,
    required ImportMode mode,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      _link = BankLinkModel(
        isConnected: true,
        method: method,
        bankIds: bankIds,
        mode: mode,
        connectedAt: DateTime.now(),
      );
      if (_messages.isEmpty) _messages.addAll(_seed(bankIds));
      return _link;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/bank-sync/link',
      data: {'method': method.name, 'bank_ids': bankIds, 'mode': mode.name},
    );
    return BankLinkModel.fromJson(response.data!);
  }

  Future<BankLinkModel> updateLink(BankLinkModel link) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      _link = link;
      return _link;
    }
    final response = await _dio.put<Map<String, dynamic>>(
      '/bank-sync/link',
      data: link.toJson(),
    );
    return BankLinkModel.fromJson(response.data!);
  }

  Future<void> disconnect() async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      _link = const BankLinkModel();
      return;
    }
    await _dio.delete<void>('/bank-sync/link');
  }

  Future<List<BankMessageModel>> getMessages() async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      return List.of(_messages);
    }
    final response = await _dio.get<List<dynamic>>('/bank-sync/messages');
    return (response.data ?? const [])
        .map((e) => BankMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BankMessageModel> saveMessage(BankMessageModel message) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      final stored = BankMessageModel(
        id: 'sms-${DateTime.now().microsecondsSinceEpoch}',
        bankId: _bankIdFor(message.sender),
        sender: message.sender,
        body: message.body,
        receivedAt: message.receivedAt,
        status: message.status,
        parsed: message.parsed,
      );
      _messages.add(stored);
      return stored;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/bank-sync/messages',
      data: message.toJson(),
    );
    return BankMessageModel.fromJson(response.data!);
  }

  Future<List<BankMessageModel>> setMessageStatus(
    List<String> ids,
    BankMessageStatus status,
  ) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(_mockDelay);
      final updated = <BankMessageModel>[];
      for (var i = 0; i < _messages.length; i++) {
        if (!ids.contains(_messages[i].id)) continue;
        _messages[i] = _messages[i].withStatus(status);
        updated.add(_messages[i]);
      }
      return updated;
    }
    final response = await _dio.patch<List<dynamic>>(
      '/bank-sync/messages',
      data: {'ids': ids, 'status': status.name},
    );
    return (response.data ?? const [])
        .map((e) => BankMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Mock store ─────────────────────────────────────────────────────────────

  static BankLinkModel _link = const BankLinkModel();
  static final List<BankMessageModel> _messages = [];

  static String _bankIdFor(String sender) {
    for (final bank in _banks) {
      if (bank.matchesSender(sender)) return bank.id;
    }
    return '';
  }

  static const _banks = <BankModel>[
    BankModel(
      id: 'cib',
      name: 'CIB',
      nameAr: 'البنك التجاري الدولي',
      shortName: 'CIB',
      senderIds: ['CIB'],
      brandColor: 0xFF1C4E9A,
    ),
    BankModel(
      id: 'nbe',
      name: 'National Bank of Egypt',
      nameAr: 'البنك الأهلي المصري',
      shortName: 'NBE',
      senderIds: ['NBE', 'AlAhlyBank'],
      brandColor: 0xFF00704A,
    ),
    BankModel(
      id: 'bm',
      name: 'Banque Misr',
      nameAr: 'بنك مصر',
      shortName: 'BM',
      senderIds: ['BanqueMisr', 'BM'],
      brandColor: 0xFFA31F34,
    ),
    BankModel(
      id: 'qnb',
      name: 'QNB Egypt',
      nameAr: 'QNB مصر',
      shortName: 'QNB',
      senderIds: ['QNB', 'QNBAA'],
      brandColor: 0xFF5E2A84,
    ),
    BankModel(
      id: 'instapay',
      name: 'InstaPay',
      nameAr: 'إنستاباي',
      shortName: 'IP',
      senderIds: ['InstaPay', 'IPN'],
      brandColor: 0xFF3F2B96,
    ),
    BankModel(
      id: 'bdc',
      name: 'Banque du Caire',
      nameAr: 'بنك القاهرة',
      shortName: 'BdC',
      senderIds: ['BDC', 'BanqueDuCaire'],
      brandColor: 0xFF1D6FB8,
    ),
    BankModel(
      id: 'aaib',
      name: 'AAIB',
      nameAr: 'البنك العربي الأفريقي',
      shortName: 'AAIB',
      senderIds: ['AAIB'],
      brandColor: 0xFFC4122F,
    ),
    BankModel(
      id: 'hsbc',
      name: 'HSBC Egypt',
      nameAr: 'HSBC مصر',
      shortName: 'HSBC',
      senderIds: ['HSBC'],
      brandColor: 0xFFDB0011,
    ),
  ];

  /// A recent inbox relative to "now": clear alerts to review, one that needs
  /// attention, a couple already imported and an OTP filed as ignored. Only
  /// messages from [bankIds] are kept, as a real capture would.
  static List<BankMessageModel> _seed(List<String> bankIds) {
    final now = DateTime.now();
    var n = 0;

    String dmy(DateTime d) =>
        '${_two(d.day)}/${_two(d.month)}/${d.year}';
    String hm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

    BankMessageModel msg(
      String bankId,
      String sender,
      Duration ago,
      String Function(DateTime at) body, {
      BankMessageStatus? status,
    }) {
      final at = now.subtract(ago);
      final text = body(at);
      final parsed = BankSmsParser.parse(text, receivedAt: at);
      return BankMessageModel(
        id: 'seed-sms-${++n}',
        bankId: bankId,
        sender: sender,
        body: text,
        receivedAt: at,
        parsed: parsed,
        status: status ??
            (parsed == null
                ? BankMessageStatus.ignored
                : BankMessageStatus.pending),
      );
    }

    final all = [
      msg('cib', 'CIB', const Duration(minutes: 25), (at) =>
          'Your CIB card ending 4821 was charged EGP 245.50 at CARREFOUR '
          'MAADI on ${dmy(at)} ${hm(at)}. Available limit EGP 12,450.00'),
      msg('nbe', 'NBE', const Duration(hours: 5, minutes: 10), (at) =>
          'تم خصم مبلغ 350.00 جنيه من حسابكم رقم ****7812 لدى TALABAT '
          'بتاريخ ${dmy(at)}. الرصيد المتاح 8,240.15 جنيه'),
      msg('qnb', 'QNB', const Duration(days: 1, hours: 2), (at) =>
          'QNB: Purchase of EGP 89.00 from UBER *TRIP with card ending 3390 '
          'on ${dmy(at)} ${hm(at)}. Avl bal EGP 5,210.00'),
      msg('cib', 'CIB', const Duration(days: 1, hours: 4), (_) =>
          'Your CIB OTP is 482913. Do not share it with anyone.'),
      msg('bm', 'BanqueMisr', const Duration(days: 2, hours: 3), (_) =>
          'تم إيداع مبلغ 12,000.00 ج.م في حسابكم رقم ***5521 - تحويل راتب. '
          'الرصيد 20,340.00 ج.م'),
      msg('cib', 'CIB', const Duration(days: 2, hours: 6), (at) =>
          'CIB: A transaction of 1,250.00 was made on your card ending 4821 '
          'on ${dmy(at)}.'),
      msg('cib', 'CIB', const Duration(days: 3, hours: 1), (at) =>
          'Your CIB card ending 4821 was charged EGP 120.50 at SPINNEYS '
          'ARKAN on ${dmy(at)} ${hm(at)}. Available limit EGP 12,695.50',
          status: BankMessageStatus.imported),
      msg('instapay', 'InstaPay', const Duration(days: 4, hours: 5), (_) =>
          'InstaPay: تم تحويل 500 جنيه إلى AHMED M. رقم مرجعي 88213',
          status: BankMessageStatus.imported),
    ];

    return all.where((m) => bankIds.contains(m.bankId)).toList();
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
