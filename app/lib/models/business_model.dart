// lib/models/business_model.dart

class BusinessProfile {
  final String id;
  final String userId;
  final String businessName;
  final String? ownerName;
  final String? npwp;
  final String businessType;
  final bool pkpStatus;
  final int employeeCount;
  final bool isActive;
  final DateTime createdAt;

  const BusinessProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    this.ownerName,
    this.npwp,
    required this.businessType,
    required this.pkpStatus,
    required this.employeeCount,
    required this.isActive,
    required this.createdAt,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? '',
        businessName: json['business_name'] as String,
        ownerName: json['owner_name'] as String?,
        npwp: json['npwp'] as String?,
        businessType: json['business_type'] as String? ?? '',
        pkpStatus: json['pkp_status'] as bool? ?? false,
        employeeCount: json['employee_count'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'business_name': businessName,
        'owner_name': ownerName,
        'npwp': npwp,
        'business_type': businessType,
        'pkp_status': pkpStatus,
        'employee_count': employeeCount,
      };
}

// ── Input profil usaha ────────────────────────────────────────────────────────

/// Data yang dikirim saat membuat/mengubah profil usaha.
///
/// Dipakai bersama oleh service, repository mock, dan repository API supaya
/// daftar field-nya cuma ditulis di satu tempat.
class BusinessDraft {
  final String businessName;
  final String? ownerName;
  final String? npwp;
  final String businessType;
  final bool pkpStatus;
  final int employeeCount;

  const BusinessDraft({
    required this.businessName,
    this.ownerName,
    this.npwp,
    required this.businessType,
    required this.pkpStatus,
    required this.employeeCount,
  });

  Map<String, dynamic> toJson() => {
        'business_name': businessName,
        'owner_name': ownerName,
        'npwp': npwp,
        'business_type': businessType,
        'pkp_status': pkpStatus,
        'employee_count': employeeCount,
      };
}
