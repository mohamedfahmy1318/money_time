import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'package:mony_time/src/config/api/api_interceptors.dart';
import 'package:mony_time/src/config/api/api_session.dart';
import 'package:mony_time/src/config/app_config.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_link_model.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_message_model.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_model.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_sync_result_models.dart';
import 'package:mony_time/src/features/bank_sync/data/models/bank_sync_summary_model.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_link.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_message.dart';
import 'package:mony_time/src/features/bank_sync/domain/entities/bank_sync_results.dart';
import 'package:mony_time/src/shared/enums/transaction_type.dart';

/// Totals of one `POST /bank-sync/messages/batch` call.
typedef BatchUpload = ({
  int created,
  int duplicates,
  int rejected,
  int pendingCreated,
});

/// Raw calls to the live `/bank-sync/*` API.
///
/// Throws on failure — error mapping happens in the repository via `runTask`.
/// Mutating POSTs carry an `Idempotency-Key` and a body encoded once, so a
/// retry of the same intent sends byte-identical bytes (the server replays
/// the stored response instead of acting twice).
class BankSyncRemoteDataSource {
  BankSyncRemoteDataSource({Dio? dio, ApiSession? session})
      : _dio = dio ?? AppConfig.dio,
        _session = session ?? ApiSession.instance;

  final Dio _dio;
  final ApiSession _session;

  static const _uuid = Uuid();

  bool get hasSession => _session.hasSession;

  /// One key per user intent (tap, pasted SMS, batch chunk).
  static String newIdempotencyKey() => _uuid.v4();

  Future<List<BankModel>> getBanks() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/bank-sync/banks',
      options: Options(extra: {kSkipAuth: true}),
    );
    return [
      for (final item in (response.data!['data'] as List<dynamic>))
        BankModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<BankLinkModel> getLink() async {
    final response = await _dio.get<Map<String, dynamic>>('/bank-sync/link');
    return BankLinkModel.fromJson(response.data!);
  }

  /// Returns the live link and its one-time ingest token.
  Future<(BankLinkModel, String)> connect({
    required BankLinkMethod method,
    required List<String> bankIds,
    required ImportMode mode,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/bank-sync/link',
      data: {
        'method': method.name,
        'bank_ids': bankIds,
        'mode': mode.name,
      },
    );
    final body = response.data!;
    return (BankLinkModel.fromJson(body), body['ingest_token'] as String);
  }

  Future<BankLinkModel> updateLink({
    required List<String> bankIds,
    required ImportMode mode,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/bank-sync/link',
      data: {'bank_ids': bankIds, 'mode': mode.name},
    );
    return BankLinkModel.fromJson(response.data!);
  }

  Future<void> disconnect() async {
    await _dio.delete<void>('/bank-sync/link');
  }

  /// Revokes every previous ingest token of the user and returns a new one.
  Future<String> reissueIngestToken() async {
    final response =
        await _dio.post<Map<String, dynamic>>('/bank-sync/link/ingest-token');
    return response.data!['ingest_token'] as String;
  }

  Future<BankSyncSummaryModel> getSummary() async {
    final response = await _dio.get<Map<String, dynamic>>('/bank-sync/summary');
    return BankSyncSummaryModel.fromJson(response.data!);
  }

  Future<BankMessagePage> getMessages({
    required BankMessageStatus status,
    String? cursor,
    int limit = 100,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/bank-sync/messages',
      queryParameters: {
        'status': BankMessageModel.statusToWire(status),
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return BankSyncResultModels.page(response.data!);
  }

  Future<BankMessageModel> getMessage(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/bank-sync/messages/$id');
    return BankMessageModel.fromJson(response.data!);
  }

  /// A pasted SMS: `received_at` is "now" — the date inside the SMS still
  /// drives when the money moved.
  Future<SubmittedBankMessage> createMessage({
    required String sender,
    required String body,
    required DateTime receivedAt,
  }) async {
    final response = await _post(
      '/bank-sync/messages',
      {
        'sender': sender,
        'body': body,
        'received_at': BankMessageModel.instantToWire(receivedAt),
        'channel': 'paste',
      },
    );
    return BankSyncResultModels.submitted(response);
  }

  /// One chunk of the 30-day scan, already encoded so a retry resends the
  /// same bytes under the same key.
  Future<BatchUpload> uploadBatch({
    required String encodedBody,
    required String idempotencyKey,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/bank-sync/messages/batch',
      data: encodedBody,
      options: Options(
        headers: {'Idempotency-Key': idempotencyKey},
        // Up to 500 messages are parsed and stored in one go.
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    final body = response.data!;
    final created = (body['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    return (
      created: (body['created'] as num?)?.toInt() ?? 0,
      duplicates: (body['duplicates'] as num?)?.toInt() ?? 0,
      rejected: (body['rejected'] as num?)?.toInt() ?? 0,
      pendingCreated: created.where((m) => m['status'] == 'pending').length,
    );
  }

  /// Ids that didn't qualify (wrong status, unknown) are silently skipped;
  /// only the messages that moved come back.
  Future<List<BankMessageModel>> setStatus(
    List<String> ids,
    BankMessageStatus status,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/bank-sync/messages',
      data: {'ids': ids, 'status': BankMessageModel.statusToWire(status)},
    );
    return [
      for (final item in (response.data!['data'] as List<dynamic>))
        BankMessageModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Only changed fields are sent: an omitted field keeps the parsed value
  /// (and an omitted `note` keeps the merchant).
  Future<BankImportResult> importMessage(
    String id,
    ImportOverrides overrides,
  ) async {
    final response = await _post('/bank-sync/messages/$id/import', {
      if (overrides.type != null)
        'type': BankMessageModel.typeToWire(overrides.type!),
      if (overrides.amount != null) 'amount': overrides.amount,
      if (overrides.categoryId != null) 'category_id': overrides.categoryId,
      if (overrides.date != null)
        'date': BankMessageModel.instantToWire(overrides.date!),
      if (overrides.note != null) 'note': overrides.note,
    });
    return BankSyncResultModels.importResult(response);
  }

  /// At most 200 ids per call — the repository chunks.
  Future<BulkImportResult> importMessages(List<String> ids) async {
    final response = await _post('/bank-sync/messages/import', {'ids': ids});
    return BankSyncResultModels.bulkImport(response);
  }

  Future<List<BankCategory>> getCategories(TransactionType type) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/categories',
      queryParameters: {'type': BankMessageModel.typeToWire(type)},
    );
    return [
      for (final item in (response.data!['data'] as List<dynamic>))
        BankSyncResultModels.category(item as Map<String, dynamic>),
    ];
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: jsonEncode(body),
      options: Options(headers: {'Idempotency-Key': newIdempotencyKey()}),
    );
    return response.data!;
  }
}
