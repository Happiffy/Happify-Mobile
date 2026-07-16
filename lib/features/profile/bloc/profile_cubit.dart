import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_services.dart';
import '../data/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required this.repository}) : super(const ProfileState());

  final ProfileRepository repository;
  bool _loadingProfile = false;
  bool _loadingPreference = false;

  Future<void> load() async {
    await Future.wait([loadProfile(), loadPreference()]);
  }

  Future<void> loadProfile() async {
    if (_loadingProfile) return;
    _loadingProfile = true;
    emit(
      state.copyWith(
        profileStatus: ProfileLoadStatus.loading,
        profileError: null,
      ),
    );
    try {
      final profile = await repository.loadProfile();
      if (!isClosed) {
        emit(
          state.copyWith(
            profileStatus: ProfileLoadStatus.success,
            profile: profile,
            profileError: null,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            profileStatus: ProfileLoadStatus.failure,
            profileError: failureMessage(error),
          ),
        );
      }
    } finally {
      _loadingProfile = false;
    }
  }

  Future<void> loadPreference() async {
    if (_loadingPreference) return;
    _loadingPreference = true;
    emit(
      state.copyWith(
        preferenceStatus: ProfileLoadStatus.loading,
        preferenceError: null,
      ),
    );
    try {
      final preference = await repository.loadPreference();
      if (!isClosed) {
        emit(
          state.copyWith(
            preferenceStatus: ProfileLoadStatus.success,
            preference: preference,
            preferenceError: null,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            preferenceStatus: ProfileLoadStatus.failure,
            preferenceError: failureMessage(error),
          ),
        );
      }
    } finally {
      _loadingPreference = false;
    }
  }

  static String? validateDisplayName(String value) {
    final name = value.trim();
    if (name.isEmpty) return 'Enter a display name.';
    if (name.length > 120) return 'Use 120 characters or fewer.';
    return null;
  }

  static String? validateBio(String value) {
    if (value.trim().length > 500) return 'Use 500 characters or fewer.';
    return null;
  }

  static String? validateFullName(String value) {
    final name = value.trim();
    if (name.isEmpty) return 'Enter your full name.';
    if (name.length > 120) return 'Use 120 characters or fewer.';
    return null;
  }

  static String? validateLicenseNumber(String value) {
    final license = value.trim();
    if (license.length < 3) return 'Use at least 3 characters.';
    if (license.length > 120) return 'Use 120 characters or fewer.';
    return null;
  }

  static String? validateCertificateUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Enter a valid certificate URL.';
    }
    if (value.trim().length > 2000) return 'Use 2000 characters or fewer.';
    return null;
  }

  static String? validateInstitution(String value) {
    if (value.trim().length > 160) return 'Use 160 characters or fewer.';
    return null;
  }

  static String? validateReason(String value) {
    if (value.trim().length > 800) return 'Use 800 characters or fewer.';
    return null;
  }

  Future<bool> saveProfile({
    required String displayName,
    required String bio,
  }) async {
    if (state.isSaving) return false;
    final displayNameError = validateDisplayName(displayName);
    final bioError = validateBio(bio);
    if (displayNameError != null || bioError != null) {
      emit(
        state.copyWith(
          saveStatus: ProfileSaveStatus.validating,
          displayNameError: displayNameError,
          bioError: bioError,
          saveError: null,
        ),
      );
      return false;
    }
    emit(
      state.copyWith(
        saveStatus: ProfileSaveStatus.saving,
        displayNameError: null,
        bioError: null,
        saveError: null,
      ),
    );
    try {
      final profile = await repository.saveProfile(
        displayName: displayName.trim(),
        bio: bio.trim(),
      );
      if (isClosed) return false;
      emit(
        state.copyWith(
          profileStatus: ProfileLoadStatus.success,
          saveStatus: ProfileSaveStatus.success,
          profile: profile,
          profileError: null,
        ),
      );
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            saveStatus: ProfileSaveStatus.failure,
            saveError: failureMessage(error),
          ),
        );
      }
      return false;
    }
  }

  Future<bool> applyPsychologist({
    required String fullName,
    required String licenseNumber,
    required String certificateUrl,
    String institution = '',
    String reason = '',
  }) async {
    if (state.isApplying) return false;
    final errors = {
      'fullName': validateFullName(fullName),
      'licenseNumber': validateLicenseNumber(licenseNumber),
      'certificateUrl': validateCertificateUrl(certificateUrl),
      'institution': validateInstitution(institution),
      'reason': validateReason(reason),
    };
    if (errors.values.any((error) => error != null)) {
      emit(
        state.copyWith(
          applicationStatus: ProfileSaveStatus.validating,
          applicationError: null,
          fullNameError: errors['fullName'],
          licenseNumberError: errors['licenseNumber'],
          certificateUrlError: errors['certificateUrl'],
          institutionError: errors['institution'],
          reasonError: errors['reason'],
        ),
      );
      return false;
    }
    emit(
      state.copyWith(
        applicationStatus: ProfileSaveStatus.saving,
        applicationError: null,
        fullNameError: null,
        licenseNumberError: null,
        certificateUrlError: null,
        institutionError: null,
        reasonError: null,
      ),
    );
    try {
      final application = await repository.applyPsychologist(
        fullName: fullName.trim(),
        licenseNumber: licenseNumber.trim(),
        certificateUrl: certificateUrl.trim(),
        institution: institution.trim().isEmpty ? null : institution.trim(),
        reason: reason.trim().isEmpty ? null : reason.trim(),
      );
      if (isClosed) return false;
      final current = state.profile;
      emit(
        state.copyWith(
          applicationStatus: ProfileSaveStatus.success,
          profile: current == null
              ? ProfileData(psychologistApplication: application)
              : ProfileData(
                  id: current.id,
                  email: current.email,
                  displayName: current.displayName,
                  role: current.role,
                  avatarUrl: current.avatarUrl,
                  bio: current.bio,
                  psychologistApplication: application,
                ),
        ),
      );
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            applicationStatus: ProfileSaveStatus.failure,
            applicationError: failureMessage(error),
          ),
        );
      }
      return false;
    }
  }
}
