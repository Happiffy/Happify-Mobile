import 'package:equatable/equatable.dart';

import '../../../core/app_services.dart';
import '../../../core/happify_repository.dart';

enum PsychologistApplicationStatus { pending, approved, rejected }

class PsychologistApplicationData extends Equatable {
  const PsychologistApplicationData({
    required this.fullName,
    required this.licenseNumber,
    required this.certificateUrl,
    required this.status,
    this.institution,
    this.reason,
    this.reviewComment,
  });

  factory PsychologistApplicationData.fromMap(Map<String, dynamic> value) {
    final status = switch (value['status']?.toString()) {
      'APPROVED' => PsychologistApplicationStatus.approved,
      'REJECTED' => PsychologistApplicationStatus.rejected,
      _ => PsychologistApplicationStatus.pending,
    };
    return PsychologistApplicationData(
      fullName: value['fullName']?.toString() ?? '',
      licenseNumber: value['licenseNumber']?.toString() ?? '',
      certificateUrl: value['certificateUrl']?.toString() ?? '',
      institution: value['institution']?.toString(),
      reason: value['reason']?.toString(),
      status: status,
      reviewComment: value['reviewComment']?.toString(),
    );
  }

  final String fullName;
  final String licenseNumber;
  final String certificateUrl;
  final String? institution;
  final String? reason;
  final PsychologistApplicationStatus status;
  final String? reviewComment;

  @override
  List<Object?> get props => [
    fullName,
    licenseNumber,
    certificateUrl,
    institution,
    reason,
    status,
    reviewComment,
  ];
}

class ProfileData extends Equatable {
  const ProfileData({
    this.id = '',
    this.email = '',
    this.displayName = '',
    this.role = '',
    this.avatarUrl,
    this.bio = '',
    this.psychologistApplication,
  });

  factory ProfileData.fromMap(Map<String, dynamic> value) {
    return ProfileData(
      id: value['id']?.toString() ?? '',
      email: value['email']?.toString() ?? '',
      displayName: value['displayName']?.toString() ?? '',
      role: value['role']?.toString() ?? '',
      avatarUrl: value['avatarUrl']?.toString(),
      bio: value['bio']?.toString() ?? '',
      psychologistApplication: value['psychologistApplication'] is Map
          ? PsychologistApplicationData.fromMap(
              objectMap(value['psychologistApplication']),
            )
          : null,
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String role;
  final String? avatarUrl;
  final String bio;
  final PsychologistApplicationData? psychologistApplication;

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    role,
    avatarUrl,
    bio,
    psychologistApplication,
  ];
}

class PreferenceData extends Equatable {
  PreferenceData({
    required this.primaryGoal,
    required List<String> triggers,
    required this.supportTone,
    required this.highRiskAction,
    required List<String> accessibilityModes,
    required this.consentToAi,
  }) : triggers = List.unmodifiable(triggers),
       accessibilityModes = List.unmodifiable(accessibilityModes);

  factory PreferenceData.fromMap(Map<String, dynamic> value) {
    return PreferenceData(
      primaryGoal: value['primaryGoal']?.toString() ?? '',
      triggers: (value['triggers'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      supportTone: value['supportTone']?.toString() ?? '',
      highRiskAction: value['highRiskAction']?.toString() ?? '',
      accessibilityModes: (value['accessibilityMode'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      consentToAi: value['consentToAi'] == true,
    );
  }

  final String primaryGoal;
  final List<String> triggers;
  final String supportTone;
  final String highRiskAction;
  final List<String> accessibilityModes;
  final bool consentToAi;

  Map<String, dynamic> toMap() => {
    'primaryGoal': primaryGoal,
    'triggers': triggers,
    'supportTone': supportTone,
    'highRiskAction': highRiskAction,
    'accessibilityMode': accessibilityModes,
    'consentToAi': consentToAi,
  };

  @override
  List<Object?> get props => [
    primaryGoal,
    triggers,
    supportTone,
    highRiskAction,
    accessibilityModes,
    consentToAi,
  ];
}

abstract class ProfileRepository {
  Future<ProfileData> loadProfile();

  Future<PreferenceData?> loadPreference();

  Future<ProfileData> saveProfile({
    required String displayName,
    required String bio,
    String? avatarUrl,
  });

  Future<PsychologistApplicationData> applyPsychologist({
    required String fullName,
    required String licenseNumber,
    required String certificateUrl,
    String? institution,
    String? reason,
  });
}

class HappifyProfileRepository implements ProfileRepository {
  const HappifyProfileRepository(this._repository);

  final HappifyRepository _repository;

  @override
  Future<ProfileData> loadProfile() async {
    return ProfileData.fromMap(await _repository.profile());
  }

  @override
  Future<PreferenceData?> loadPreference() async {
    final value = await _repository.preference();
    return value == null ? null : PreferenceData.fromMap(objectMap(value));
  }

  @override
  Future<ProfileData> saveProfile({
    required String displayName,
    required String bio,
    String? avatarUrl,
  }) async {
    final value = await _repository.updateProfile(
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
    );
    return ProfileData.fromMap(value);
  }

  @override
  Future<PsychologistApplicationData> applyPsychologist({
    required String fullName,
    required String licenseNumber,
    required String certificateUrl,
    String? institution,
    String? reason,
  }) async {
    final value = await _repository.applyPsychologist(
      fullName: fullName,
      licenseNumber: licenseNumber,
      certificateUrl: certificateUrl,
      institution: institution,
      reason: reason,
    );
    return PsychologistApplicationData.fromMap(value);
  }
}
