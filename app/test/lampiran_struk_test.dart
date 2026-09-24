// test/lampiran_struk_test.dart
//
// Lampiran struk (issue #59): model (fromJson/toJson), validasi murni
// `checkAttachmentUpload`, repository mock (upload/list/delete + 404),
// `newUuidV4` (format RFC 4122 v4, keunikan, kecocokan dengan `isUuid`),
// kontrak REST lewat Dio dengan adapter palsu (pola yang sama dengan
// `kontrak_transaksi_test.dart`), dan pemetaan galat Supabase — termasuk
// `StorageException` — (pola yang sama dengan `supabase_mapping_test.dart`).
//
// Jalankan: flutter test test/lampiran_struk_test.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:catatin/core/data/api_repositories.dart';
import 'package:catatin/core/data/mock_repositories.dart';
import 'package:catatin/core/data/supabase_repositories.dart';
import 'package:catatin/core/network/api_client.dart';
import 'package:catatin/core/network/supabase_client.dart';
import 'package:catatin/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Contoh item `GET /transactions/{id}/attachments` mengikuti kontrak di
/// deskripsi issue #59.
const _sampleAttachment = {
  'id': 'att_01',
  'transaction_id': 'trx_01',
  'file_name': 'struk-warung.jpg',
  'mime_type': 'image/jpeg',
  'size_bytes': 204800,
  'url': 'https://signed.example/att_01.jpg?token=abc',
  'url_expires_at': '2026-09-21T13:00:00Z',
  'created_at': '2026-09-21T12:00:00Z',
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
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('TxAttachment — fromJson/toJson', () {
    test('membaca contoh kontrak', () {
      final att = TxAttachment.fromJson(_sampleAttachment);
      expect(att.id, 'att_01');
      expect(att.transactionId, 'trx_01');
      expect(att.fileName, 'struk-warung.jpg');
      expect(att.mimeType, 'image/jpeg');
      expect(att.sizeBytes, 204800);
      expect(att.url, _sampleAttachment['url']);
    });

    test('round trip mempertahankan seluruh field', () {
      final att = TxAttachment.fromJson(_sampleAttachment);
      final roundTripped = TxAttachment.fromJson(att.toJson());
      expect(roundTripped.id, att.id);
      expect(roundTripped.transactionId, att.transactionId);
      expect(roundTripped.fileName, att.fileName);
      expect(roundTripped.mimeType, att.mimeType);
      expect(roundTripped.sizeBytes, att.sizeBytes);
      expect(roundTripped.url, att.url);
      expect(roundTripped.urlExpiresAt, att.urlExpiresAt);
      expect(roundTripped.createdAt, att.createdAt);
    });
  });

  group('checkAttachmentUpload', () {
    test('berkas kosong -> 400 "Foto kosong."', () {
      expect(
        () =>
            checkAttachmentUpload(bytes: Uint8List(0), mimeType: 'image/jpeg'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.errors, 'errors', {'file': 'Foto kosong.'}),
        ),
      );
    });

    test('lebih dari 5 MB (5242881 byte) ditolak', () {
      final bytes = Uint8List(kAttachmentMaxBytes + 1);
      expect(
        () => checkAttachmentUpload(bytes: bytes, mimeType: 'image/png'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.errors?['file'],
                'errors.file',
                contains('5 MB'),
              ),
        ),
      );
    });

    test('persis 5242880 byte (batas atas) tidak ditolak', () {
      final bytes = Uint8List(kAttachmentMaxBytes);
      expect(
        () => checkAttachmentUpload(bytes: bytes, mimeType: 'image/webp'),
        returnsNormally,
      );
    });

    test('tipe di luar JPEG/PNG/WebP (mis. GIF) ditolak', () {
      expect(
        () => checkAttachmentUpload(
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/gif',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.errors?['file'],
                'errors.file',
                contains('JPEG'),
              ),
        ),
      );
    });
  });

  group('MockAttachmentRepository', () {
    final repo = MockAttachmentRepository();

    test('upload lalu list: url data URI, kedaluwarsa sekitar 1 jam', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final before = DateTime.now();
      final att = await repo.uploadAttachment(
        'tx-a',
        bytes: bytes,
        fileName: 'struk.jpg',
        mimeType: 'image/jpeg',
      );
      expect(att.transactionId, 'tx-a');
      expect(att.fileName, 'struk.jpg');
      expect(att.mimeType, 'image/jpeg');
      expect(att.sizeBytes, bytes.length);
      expect(att.url, startsWith('data:image/jpeg;base64,'));
      expect(att.urlExpiresAt.difference(before).inMinutes, closeTo(60, 1));

      final list = await repo.getAttachments('tx-a');
      expect(list.single.id, att.id);
    });

    test('upload menolak berkas tidak valid sebelum tersimpan', () async {
      await expectLater(
        repo.uploadAttachment(
          'tx-b',
          bytes: Uint8List(0),
          fileName: 'x.jpg',
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(await repo.getAttachments('tx-b'), isEmpty);
    });

    test('delete id yang tidak dikenal -> 404', () async {
      expect(
        () => repo.deleteAttachment('tx-a', 'id-tidak-ada'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('delete menghapus lampiran yang ada', () async {
      final att = await repo.uploadAttachment(
        'tx-c',
        bytes: Uint8List.fromList([9, 9, 9]),
        fileName: 'a.png',
        mimeType: 'image/png',
      );
      await repo.deleteAttachment('tx-c', att.id);
      expect(await repo.getAttachments('tx-c'), isEmpty);
    });
  });

  group('newUuidV4', () {
    test(
      'formatnya memenuhi isUuid, dengan nibble versi 4 dan varian RFC 4122',
      () {
        final id = newUuidV4();
        expect(isUuid(id), isTrue);
        expect(id[14], '4');
        expect(['8', '9', 'a', 'b'], contains(id[19].toLowerCase()));
      },
    );

    test('tidak menghasilkan id yang sama berulang kali', () {
      final ids = {for (var i = 0; i < 500; i++) newUuidV4()};
      expect(ids, hasLength(500));
    });
  });

  group('ApiAttachmentRepository (kontrak REST)', () {
    late _FakeAdapter adapter;

    void useFakeServer(Object body) {
      adapter = _FakeAdapter(body);
      ApiClient.instance = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
        ..httpClientAdapter = adapter;
    }

    tearDown(ApiClient.reset);

    test(
      'GET /transactions/{id}/attachments membaca daftar lampiran',
      () async {
        useFakeServer({
          'attachments': [_sampleAttachment],
        });
        final list = await ApiAttachmentRepository().getAttachments('trx_01');
        final req = adapter.requests.single;
        expect(req.method, 'GET');
        expect(req.uri.path, '/api/v1/transactions/trx_01/attachments');
        expect(list.single.id, 'att_01');
      },
    );

    test(
      'POST mengirim multipart dengan part "file" dan nama berkas',
      () async {
        useFakeServer({'attachment': _sampleAttachment});
        final bytes = Uint8List.fromList([1, 2, 3]);
        final att = await ApiAttachmentRepository().uploadAttachment(
          'trx_01',
          bytes: bytes,
          fileName: 'struk.jpg',
          mimeType: 'image/jpeg',
        );
        final req = adapter.requests.single;
        expect(req.method, 'POST');
        expect(req.uri.path, '/api/v1/transactions/trx_01/attachments');
        final form = req.data as FormData;
        expect(form.files, hasLength(1));
        expect(form.files.single.key, 'file');
        expect(form.files.single.value.filename, 'struk.jpg');
        expect(att.id, 'att_01');
      },
    );

    test('upload berkas tidak valid ditolak tanpa mengirim request', () async {
      useFakeServer({'attachment': _sampleAttachment});
      await expectLater(
        ApiAttachmentRepository().uploadAttachment(
          'trx_01',
          bytes: Uint8List(0),
          fileName: 'x.jpg',
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests, isEmpty);
    });

    test('DELETE /transactions/{id}/attachments/{attachmentId}', () async {
      useFakeServer(<String, Object?>{});
      await ApiAttachmentRepository().deleteAttachment('trx_01', 'att_01');
      final req = adapter.requests.single;
      expect(req.method, 'DELETE');
      expect(req.uri.path, '/api/v1/transactions/trx_01/attachments/att_01');
    });
  });

  group('supabaseException — StorageException (#59)', () {
    ApiException map(sb.StorageException e, {bool hasSession = true}) =>
        supabaseException(e, hasSession: hasSession)!;

    test('statusCode 413 -> 400 ukuran foto', () {
      final e = map(
        const sb.StorageException('Payload too large', statusCode: '413'),
      );
      expect(e.statusCode, 400);
      expect(e.errors, {'file': 'Ukuran foto maksimal 5 MB.'});
    });

    test('pesan menyebut "size" tanpa statusCode baku -> 400 ukuran foto', () {
      final e = map(
        const sb.StorageException(
          'The object exceeded the maximum allowed size',
        ),
      );
      expect(e.statusCode, 400);
      expect(e.errors, {'file': 'Ukuran foto maksimal 5 MB.'});
    });

    test('statusCode 415 -> 400 format foto', () {
      final e = map(
        const sb.StorageException('Unsupported media', statusCode: '415'),
      );
      expect(e.statusCode, 400);
      expect(e.errors, {'file': 'Format foto harus JPEG, PNG, atau WebP.'});
    });

    test(
      'pesan menyebut "mime type" tanpa statusCode baku -> 400 format foto',
      () {
        final e = map(const sb.StorageException('invalid mime type'));
        expect(e.statusCode, 400);
        expect(e.errors, {'file': 'Format foto harus JPEG, PNG, atau WebP.'});
      },
    );

    test('statusCode 401 -> sesi berakhir', () {
      final e = map(const sb.StorageException('x', statusCode: '401'));
      expect(e.statusCode, 401);
    });

    test('statusCode 403: 403 kalau ada sesi, 401 kalau tidak', () {
      expect(
        map(const sb.StorageException('x', statusCode: '403')).statusCode,
        403,
      );
      expect(
        map(
          const sb.StorageException('x', statusCode: '403'),
          hasSession: false,
        ).statusCode,
        401,
      );
    });

    test('statusCode 404 -> data tidak ditemukan', () {
      final e = map(const sb.StorageException('x', statusCode: '404'));
      expect(e.statusCode, 404);
    });

    test('statusCode 409 -> berkas yang sama sudah ada', () {
      final e = map(const sb.StorageException('x', statusCode: '409'));
      expect(e.statusCode, 409);
      expect(e.message, 'Berkas yang sama sudah ada.');
    });

    test('statusCode lain -> 500', () {
      final e = map(const sb.StorageException('x', statusCode: '500'));
      expect(e.statusCode, 500);
    });
  });

  group('supabaseException — validasi lampiran struk (#59)', () {
    ApiException map(String code, String message) => supabaseException(
      sb.PostgrestException(message: message, code: code),
      hasSession: true,
    )!;

    String check(String constraint) =>
        'new row for relation "transaction_attachments" violates check '
        'constraint "$constraint"';

    test('mime_type di luar JPEG/PNG/WebP', () {
      final e = map('23514', check('transaction_attachments_mime_type_check'));
      expect(e.statusCode, 400);
      expect(e.errors, {'file': 'Format foto harus JPEG, PNG, atau WebP.'});
    });

    test('ukuran di luar batas', () {
      final e = map('23514', check('transaction_attachments_size_bytes_check'));
      expect(e.errors, {'file': 'Ukuran foto maksimal 5 MB.'});
    });

    test('nama berkas tidak valid', () {
      final e = map('23514', check('transaction_attachments_file_name_check'));
      expect(e.errors, {'file': 'Nama berkas tidak valid.'});
    });

    test('lokasi berkas tidak valid', () {
      final e = map('23514', check('transaction_attachments_path_check'));
      expect(e.errors, {'file': 'Lokasi berkas tidak valid.'});
    });
  });
}
