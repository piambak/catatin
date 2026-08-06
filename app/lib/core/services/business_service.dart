// lib/core/services/business_service.dart

import '../../models/models.dart';
import '../data/repositories.dart';
import 'storage_service.dart';

export '../../models/business_model.dart';

class BusinessService {
  BusinessService._();

  static Future<BusinessProfile?> getCurrent() => Repos.business.getCurrent();

  static Future<BusinessProfile> create({
    required String businessName,
    String? ownerName,
    String? npwp,
    required String businessType,
    required bool pkpStatus,
    required int employeeCount,
  }) async {
    final profile = await Repos.business.create(BusinessDraft(
      businessName: businessName,
      ownerName: ownerName,
      npwp: npwp,
      businessType: businessType,
      pkpStatus: pkpStatus,
      employeeCount: employeeCount,
    ));
    await StorageService.setBusinessId(profile.id);
    await StorageService.setOnboarded();
    return profile;
  }

  static Future<BusinessProfile> update({
    required String id,
    required String businessName,
    String? ownerName,
    String? npwp,
    required String businessType,
    required bool pkpStatus,
    required int employeeCount,
  }) =>
      Repos.business.update(
        id,
        BusinessDraft(
          businessName: businessName,
          ownerName: ownerName,
          npwp: npwp,
          businessType: businessType,
          pkpStatus: pkpStatus,
          employeeCount: employeeCount,
        ),
      );
}
