// test/transaksi_berulang_test.dart
//
// Transaksi berulang (issue #58): model (fromJson/toJson, helper jadwal
// murni), repository mock (create/update/stop/edit-template-nonaktif), kontrak
// REST lewat Dio dengan adapter palsu (pola yang sama dengan
// `kontrak_transaksi_test.dart`), dan pemetaan galat Supabase (pola yang sama
// dengan `supabase_mapping_test.dart`).
//
// Jalankan: flutter test test/transaksi_berulang_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:catatin/core/data/api_repositories.dart';
import 'package:catatin/core/data/mock_repositories.dart';
import 'package:catatin/core/network/api_client.dart';
import 'package:catatin/core/network/supabase_client.dart';
import 'package:catatin/core/utils/formatters.dart';
import 'package:catatin/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Contoh item `GET /recurring` — bentuknya mengikuti spesifikasi kontrak di
/// deskripsi issue #58 (belum ada di `wiki/arsitektur/backend-dan-api.md`
/// saat berkas ini ditulis).
const _sampleTemplate = {
  'id': 'rec_01',
  'business_id': 'biz_01',
  'type': 'EXPENSE',
  'amount': 1500000,
  'category': {
    'id': 'ec4',
    'name': 'Sewa Tempat',
    'type': 'EXPENSE',
    'tax_relevant': true,
    'is_cogs': false,
    'icon': '🏠',
    'color': '#F59E0B',
  },
  'description': 'Sewa ruko bulanan',
  'payment_method': 'TRANSFER',
  'frequency': 'MONTHLY',
  'start_date': '2026-09-01',
  'end_date': null,
  'next_date': '2026-10-01',
  'is_active': true,
  'created_at': '2026-09-01T03:00:00Z',
};

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final Object body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

RecurringDraft _draft({
  String type = 'EXPENSE',
  double amount = 500000,
  String categoryId = 'ec1',
  String frequency = RecurringFrequency.monthly,
  required String startDate,
  String? endDate,
}) =>
    RecurringDraft(
      type: type,
      amount: amount,
      categoryId: categoryId,
      paymentMethod: 'TRANSFER',
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
    );

void main() {
  group('RecurringTemplate — fromJson/toJson', () {
    test('membaca kategori tersemat dan tanggal nullable dari contoh kontrak', () {
      final tmpl = RecurringTemplate.fromJson(_sampleTemplate);
      expect(tmpl.id, 'rec_01');
      expect(tmpl.category.name, 'Sewa Tempat');
      expect(tmpl.category.isCogs, isFalse);
      expect(tmpl.frequency, 'MONTHLY');
      expect(tmpl.startDate, '2026-09-01');
      expect(tmpl.endDate, isNull);
      expect(tmpl.nextDate, '2026-10-01');
      expect(tmpl.isActive, isTrue);
    });

    test('round trip mempertahankan seluruh field, termasuk yang nullable', () {
      final tmpl = RecurringTemplate.fromJson(_sampleTemplate);
      final roundTripped = RecurringTemplate.fromJson(tmpl.toJson());
      expect(roundTripped.id, tmpl.id);
      expect(roundTripped.businessId, tmpl.businessId);
      expect(roundTripped.amount, tmpl.amount);
      expect(roundTripped.category.id, tmpl.category.id);
      expect(roundTripped.category.color, tmpl.category.color);
      expect(roundTripped.description, tmpl.description);
      expect(roundTripped.frequency, tmpl.frequency);
      expect(roundTripped.startDate, tmpl.startDate);
      expect(roundTripped.endDate, tmpl.endDate);
      expect(roundTripped.nextDate, tmpl.nextDate);
      expect(roundTripped.isActive, tmpl.isActive);
      expect(roundTripped.createdAt, tmpl.createdAt);
    });

    test('end_date terisi dan next_date null (template nonaktif) ikut round trip', () {
      final json = {
        ..._sampleTemplate,
        'end_date': '2027-03-01',
        'next_date': null,
        'is_active': false,
      };
      final tmpl = RecurringTemplate.fromJson(json);
      expect(tmpl.endDate, '2027-03-01');
      expect(tmpl.nextDate, isNull);
      expect(tmpl.isActive, isFalse);

      final roundTripped = RecurringTemplate.fromJson(tmpl.toJson());
      expect(roundTripped.endDate, '2027-03-01');
      expect(roundTripped.nextDate, isNull);
      expect(roundTripped.isActive, isFalse);
    });
  });

  group('recurringFirstOnOrAfter', () {
    test('MONTHLY: 31 Jan dijepit ke akhir bulan, selalu dihitung dari anchor', () {
      final anchor = DateTime(2026, 1, 31);
      expect(
        recurringFirstOnOrAfter(
            anchor, RecurringFrequency.monthly, DateTime(2026, 2, 1)),
        DateTime(2026, 2, 28),
      );
      expect(
        recurringFirstOnOrAfter(
            anchor, RecurringFrequency.monthly, DateTime(2026, 3, 1)),
        DateTime(2026, 3, 31),
      );
    });

    test('MONTHLY: tahun kabisat 2028 → 29 Februari', () {
      final anchor = DateTime(2028, 1, 31);
      expect(
        recurringFirstOnOrAfter(
            anchor, RecurringFrequency.monthly, DateTime(2028, 2, 1)),
        DateTime(2028, 2, 29),
      );
    });

    test('WEEKLY: kelipatan 7 hari dari anchor', () {
      final anchor = DateTime(2026, 9, 1);
      expect(
        recurringFirstOnOrAfter(
            anchor, RecurringFrequency.weekly, DateTime(2026, 9, 1)),
        DateTime(2026, 9, 1),
      );
      expect(
        recurringFirstOnOrAfter(
            anchor, RecurringFrequency.weekly, DateTime(2026, 9, 5)),
        DateTime(2026, 9, 8),
      );
      expect(
        recurringFirstOnOrAfter(
            anchor, RecurringFrequency.weekly, DateTime(2026, 9, 8)),
        DateTime(2026, 9, 8),
      );
    });

    test('tidak pernah mundur sebelum start_date, tanpa backfill', () {
      final anchor = DateTime(2026, 9, 10);
      expect(
        recurringFirstOnOrAfter(
            anchor, RecurringFrequency.monthly, DateTime(2026, 8, 1)),
        anchor,
      );
      expect(
        recurringFirstOnOrAfter(
            anchor, RecurringFrequency.weekly, DateTime(2020, 1, 1)),
        anchor,
      );
    });

    test('kejadian pertama pada atau setelah hari ini', () {
      final today = DateTime.now();
      final anchor =
          DateTime(today.year, today.month, today.day - 1);
      final next =
          recurringFirstOnOrAfter(anchor, RecurringFrequency.weekly, today);
      expect(next.isBefore(DateTime(today.year, today.month, today.day)),
          isFalse);
      expect(next.difference(anchor).inDays % 7, 0);
    });
  });

  group('MockRecurringRepository', () {
    final repo = MockRecurringRepository();

    test('create: next_date = kejadian pertama pada/setelah hari ini, aktif', () async {
      final start = DateTime.now().subtract(const Duration(days: 400));
      final tmpl = await repo.createTemplate(_draft(startDate: Tanggal.api(start)));
      final expectedNext =
          recurringFirstOnOrAfter(start, RecurringFrequency.monthly, DateTime.now());
      expect(tmpl.isActive, isTrue);
      expect(tmpl.nextDate, Tanggal.api(expectedNext));
    });

    test('create: start_date di masa depan tidak dimundurkan (tanpa backfill)', () async {
      final start = DateTime.now().add(const Duration(days: 10));
      final tmpl = await repo.createTemplate(_draft(startDate: Tanggal.api(start)));
      expect(tmpl.nextDate,
          Tanggal.api(DateTime(start.year, start.month, start.day)));
    });

    test('create: end_date sudah lewat sejak awal → nonaktif, next_date null', () async {
      final start = DateTime.now().subtract(const Duration(days: 400));
      final end = DateTime.now().subtract(const Duration(days: 5));
      final tmpl = await repo.createTemplate(
          _draft(startDate: Tanggal.api(start), endDate: Tanggal.api(end)));
      expect(tmpl.isActive, isFalse);
      expect(tmpl.nextDate, isNull);
    });

    test('update tanpa mengubah frekuensi/start_date mempertahankan next_date lama', () async {
      final start = DateTime.now().subtract(const Duration(days: 10));
      final created =
          await repo.createTemplate(_draft(startDate: Tanggal.api(start)));
      final updated = await repo.updateTemplate(
        created.id,
        _draft(startDate: created.startDate, amount: 999000),
      );
      expect(updated.nextDate, created.nextDate);
      expect(updated.isActive, isTrue);
      expect(updated.amount, 999000);
    });

    test('update mengganti start_date menghitung ulang next_date', () async {
      final start = DateTime.now().subtract(const Duration(days: 10));
      final created =
          await repo.createTemplate(_draft(startDate: Tanggal.api(start)));
      final newStart = DateTime.now().add(const Duration(days: 5));
      final updated = await repo.updateTemplate(
        created.id,
        _draft(startDate: Tanggal.api(newStart)),
      );
      expect(
        updated.nextDate,
        Tanggal.api(DateTime(newStart.year, newStart.month, newStart.day)),
      );
    });

    test(
        'update hanya mengubah end_date: end_date baru sebelum next_date lama → nonaktif',
        () async {
      final start = DateTime.now().subtract(const Duration(days: 10));
      final created = await repo.createTemplate(_draft(
        frequency: RecurringFrequency.weekly,
        startDate: Tanggal.api(start),
      ));
      expect(created.isActive, isTrue);
      final oldNext = DateTime.parse(created.nextDate!);
      final newEnd = oldNext.subtract(const Duration(days: 1));
      final updated = await repo.updateTemplate(
        created.id,
        _draft(
          frequency: created.frequency,
          startDate: created.startDate,
          endDate: Tanggal.api(newEnd),
        ),
      );
      expect(updated.isActive, isFalse);
      expect(updated.nextDate, isNull);
    });

    test(
        'update hanya mengubah end_date: end_date baru masih setelah next_date → tetap aktif, next_date sama',
        () async {
      final start = DateTime.now().subtract(const Duration(days: 10));
      final created = await repo.createTemplate(_draft(
        frequency: RecurringFrequency.weekly,
        startDate: Tanggal.api(start),
      ));
      final oldNext = created.nextDate;
      final newEnd = DateTime.parse(oldNext!).add(const Duration(days: 30));
      final updated = await repo.updateTemplate(
        created.id,
        _draft(
          frequency: created.frequency,
          startDate: created.startDate,
          endDate: Tanggal.api(newEnd),
        ),
      );
      expect(updated.isActive, isTrue);
      expect(updated.nextDate, oldNext);
    });

    test('mengedit template yang sudah nonaktif → ApiException 409', () async {
      final start = DateTime.now().subtract(const Duration(days: 400));
      final end = DateTime.now().subtract(const Duration(days: 5));
      final created = await repo.createTemplate(
          _draft(startDate: Tanggal.api(start), endDate: Tanggal.api(end)));
      expect(created.isActive, isFalse);
      expect(
        () => repo.updateTemplate(created.id, _draft(startDate: created.startDate)),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)),
      );
    });

    test('stop menonaktifkan template aktif', () async {
      final start = DateTime.now().subtract(const Duration(days: 10));
      final created =
          await repo.createTemplate(_draft(startDate: Tanggal.api(start)));
      final stopped = await repo.stopTemplate(created.id);
      expect(stopped.isActive, isFalse);
      expect(stopped.nextDate, isNull);
    });

    test('stop pada template yang sudah nonaktif mengembalikannya apa adanya', () async {
      final start = DateTime.now().subtract(const Duration(days: 400));
      final end = DateTime.now().subtract(const Duration(days: 5));
      final created = await repo.createTemplate(
          _draft(startDate: Tanggal.api(start), endDate: Tanggal.api(end)));
      final stopped = await repo.stopTemplate(created.id);
      expect(stopped.id, created.id);
      expect(stopped.isActive, isFalse);
      expect(stopped.nextDate, isNull);
    });

    test('getTemplates: aktif lebih dulu, lalu next_date makin dekat', () async {
      final now = DateTime.now();
      final near = await repo.createTemplate(_draft(
        frequency: RecurringFrequency.weekly,
        startDate: Tanggal.api(now.subtract(const Duration(days: 3))),
      ));
      final far = await repo.createTemplate(_draft(
        frequency: RecurringFrequency.weekly,
        startDate: Tanggal.api(now.add(const Duration(days: 20))),
      ));
      final inactive = await repo.createTemplate(_draft(
        startDate: Tanggal.api(now.subtract(const Duration(days: 400))),
        endDate: Tanggal.api(now.subtract(const Duration(days: 5))),
      ));

      final ids = (await repo.getTemplates()).map((t) => t.id).toList();
      expect(ids.indexOf(near.id), lessThan(ids.indexOf(far.id)));
      expect(ids.indexOf(far.id), lessThan(ids.indexOf(inactive.id)));
    });
  });

  group('ApiRecurringRepository (kontrak REST)', () {
    late _FakeAdapter adapter;

    void useFakeServer(Object body) {
      adapter = _FakeAdapter(body);
      ApiClient.instance = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
        ..httpClientAdapter = adapter;
    }

    tearDown(ApiClient.reset);

    test('GET /recurring membaca daftar template', () async {
      useFakeServer({
        'templates': [_sampleTemplate]
      });
      final list = await ApiRecurringRepository().getTemplates();
      final req = adapter.requests.single;
      expect(req.method, 'GET');
      expect(req.uri.path, '/api/v1/recurring');
      expect(list.single.id, 'rec_01');
      expect(list.single.category.name, 'Sewa Tempat');
    });

    test('POST /recurring mengirim draft persis, membaca template dari respons', () async {
      useFakeServer({'template': _sampleTemplate});
      final draft = RecurringDraft(
        type: 'EXPENSE',
        amount: 1500000,
        categoryId: 'ec4',
        paymentMethod: 'TRANSFER',
        frequency: RecurringFrequency.monthly,
        startDate: '2026-09-01',
      );
      final tmpl = await ApiRecurringRepository().createTemplate(draft);
      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.uri.path, '/api/v1/recurring');
      expect(req.data, draft.toJson());
      expect(tmpl.id, 'rec_01');
    });

    test('PATCH /recurring/{id} mengirim body penuh, sama bentuknya dengan POST', () async {
      useFakeServer({'template': _sampleTemplate});
      final draft = RecurringDraft(
        type: 'EXPENSE',
        amount: 1500000,
        categoryId: 'ec4',
        paymentMethod: 'TRANSFER',
        frequency: RecurringFrequency.monthly,
        startDate: '2026-09-01',
        endDate: '2027-01-01',
      );
      await ApiRecurringRepository().updateTemplate('rec_01', draft);
      final req = adapter.requests.single;
      expect(req.method, 'PATCH');
      expect(req.uri.path, '/api/v1/recurring/rec_01');
      expect(req.data, draft.toJson());
    });

    test('POST /recurring/{id}/stop tanpa body', () async {
      useFakeServer({'template': _sampleTemplate});
      final tmpl = await ApiRecurringRepository().stopTemplate('rec_01');
      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.uri.path, '/api/v1/recurring/rec_01/stop');
      expect(tmpl.id, 'rec_01');
    });
  });

  group('supabaseException — validasi transaksi berulang (#58)', () {
    ApiException map(String code, String message) => supabaseException(
          sb.PostgrestException(message: message, code: code),
          hasSession: true,
        )!;

    String check(String constraint) =>
        'new row for relation "recurring_templates" violates check '
        'constraint "$constraint"';
    String fk(String constraint) =>
        'insert or update on table "recurring_templates" violates foreign '
        'key constraint "$constraint"';

    test('nominal ≤ 0 → field amount', () {
      final e = map('23514', check('recurring_templates_amount_check'));
      expect(e.statusCode, 400);
      expect(e.errors, {'amount': 'Nominal harus lebih dari 0.'});
    });

    test('jenis dan metode pembayaran tidak dikenal', () {
      expect(map('23514', check('recurring_templates_type_check')).errors?.keys,
          ['type']);
      expect(
        map('23514', check('recurring_templates_payment_method_check'))
            .errors
            ?.keys,
        ['payment_method'],
      );
    });

    test('frekuensi harus mingguan atau bulanan', () {
      final e = map('23514', check('recurring_templates_frequency_check'));
      expect(e.errors, {'frequency': 'Frekuensi harus mingguan atau bulanan.'});
    });

    test('tanggal mulai dan berakhir di luar rentang 2000–2099', () {
      expect(
        map('23514', check('recurring_templates_start_date_check')).errors?.keys,
        ['start_date'],
      );
      expect(
        map('23514', check('recurring_templates_end_date_check')).userMessage,
        contains('2000'),
      );
    });

    test('tanggal berakhir sebelum tanggal mulai', () {
      final e =
          map('23514', check('recurring_templates_end_after_start_check'));
      expect(e.errors, {
        'end_date': 'Tanggal berakhir tidak boleh sebelum tanggal mulai.',
      });
    });

    test('kategori tidak ada dan kategori salah jenis dibedakan', () {
      final hilang = map('23503', fk('recurring_templates_category_id_fkey'));
      final salahJenis =
          map('23503', fk('recurring_templates_category_type_fkey'));
      expect(hilang.userMessage, 'Kategori tidak ditemukan.');
      expect(salahJenis.userMessage,
          'Kategori tidak cocok dengan jenis transaksi.');
      expect(salahJenis.errors?.keys, ['category_id']);
    });
  });

  group('TxData.recurringTemplateId', () {
    Map<String, dynamic> txJson({String? recurringId}) => {
          'id': 'trx_01',
          'business_id': 'biz_01',
          'date': '2026-09-05',
          'type': 'EXPENSE',
          'amount': 250000,
          'category': {
            'id': 'ec4',
            'name': 'Sewa Tempat',
            'type': 'EXPENSE',
            'tax_relevant': true,
            'is_cogs': false,
            'icon': '🏠',
            'color': '#F59E0B',
          },
          'description': 'Sewa bulanan',
          'payment_method': 'TRANSFER',
          'receipt_note': null,
          'created_at': '2026-09-05T01:00:00Z',
          'recurring_template_id': ?recurringId,
        };

    test('null kalau field tidak dikirim server', () {
      expect(TxData.fromJson(txJson()).recurringTemplateId, isNull);
    });

    test('terbaca kalau transaksi berasal dari template berulang', () {
      expect(
        TxData.fromJson(txJson(recurringId: 'rec_01')).recurringTemplateId,
        'rec_01',
      );
    });
  });
}
