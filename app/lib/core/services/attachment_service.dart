// lib/core/services/attachment_service.dart

import 'dart:typed_data';

import '../../models/models.dart';
import '../data/repositories.dart';

export '../../models/attachment_model.dart';

/// Fasad tipis di atas [Repos.attachment] — layar tidak pernah menyentuh
/// [AttachmentRepository] langsung, sama seperti [RecurringService] untuk
/// transaksi berulang.
class AttachmentService {
  AttachmentService._();

  static Future<List<TxAttachment>> getAttachments(String transactionId) =>
      Repos.attachment.getAttachments(transactionId);

  static Future<TxAttachment> uploadAttachment(
    String transactionId, {
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) => Repos.attachment.uploadAttachment(
    transactionId,
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );

  static Future<void> deleteAttachment(
    String transactionId,
    String attachmentId,
  ) => Repos.attachment.deleteAttachment(transactionId, attachmentId);
}
