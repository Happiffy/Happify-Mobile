import 'package:equatable/equatable.dart';

import '../data/profile_repository.dart';

enum ProfileLoadStatus { initial, loading, success, failure }

enum ProfileSaveStatus { initial, validating, saving, success, failure }

const _unset = Object();

class ProfileState extends Equatable {
  const ProfileState({
    this.profileStatus = ProfileLoadStatus.initial,
    this.preferenceStatus = ProfileLoadStatus.initial,
    this.saveStatus = ProfileSaveStatus.initial,
    this.profile,
    this.preference,
    this.profileError,
    this.preferenceError,
    this.saveError,
    this.displayNameError,
    this.bioError,
    this.applicationStatus = ProfileSaveStatus.initial,
    this.applicationError,
    this.fullNameError,
    this.licenseNumberError,
    this.certificateUrlError,
    this.institutionError,
    this.reasonError,
  });

  final ProfileLoadStatus profileStatus;
  final ProfileLoadStatus preferenceStatus;
  final ProfileSaveStatus saveStatus;
  final ProfileData? profile;
  final PreferenceData? preference;
  final String? profileError;
  final String? preferenceError;
  final String? saveError;
  final String? displayNameError;
  final String? bioError;
  final ProfileSaveStatus applicationStatus;
  final String? applicationError;
  final String? fullNameError;
  final String? licenseNumberError;
  final String? certificateUrlError;
  final String? institutionError;
  final String? reasonError;

  bool get isSaving => saveStatus == ProfileSaveStatus.saving;
  bool get isApplying => applicationStatus == ProfileSaveStatus.saving;

  ProfileState copyWith({
    ProfileLoadStatus? profileStatus,
    ProfileLoadStatus? preferenceStatus,
    ProfileSaveStatus? saveStatus,
    Object? profile = _unset,
    Object? preference = _unset,
    Object? profileError = _unset,
    Object? preferenceError = _unset,
    Object? saveError = _unset,
    Object? displayNameError = _unset,
    Object? bioError = _unset,
    ProfileSaveStatus? applicationStatus,
    Object? applicationError = _unset,
    Object? fullNameError = _unset,
    Object? licenseNumberError = _unset,
    Object? certificateUrlError = _unset,
    Object? institutionError = _unset,
    Object? reasonError = _unset,
  }) {
    return ProfileState(
      profileStatus: profileStatus ?? this.profileStatus,
      preferenceStatus: preferenceStatus ?? this.preferenceStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      profile: identical(profile, _unset)
          ? this.profile
          : profile as ProfileData?,
      preference: identical(preference, _unset)
          ? this.preference
          : preference as PreferenceData?,
      profileError: identical(profileError, _unset)
          ? this.profileError
          : profileError as String?,
      preferenceError: identical(preferenceError, _unset)
          ? this.preferenceError
          : preferenceError as String?,
      saveError: identical(saveError, _unset)
          ? this.saveError
          : saveError as String?,
      displayNameError: identical(displayNameError, _unset)
          ? this.displayNameError
          : displayNameError as String?,
      bioError: identical(bioError, _unset)
          ? this.bioError
          : bioError as String?,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      applicationError: identical(applicationError, _unset)
          ? this.applicationError
          : applicationError as String?,
      fullNameError: identical(fullNameError, _unset)
          ? this.fullNameError
          : fullNameError as String?,
      licenseNumberError: identical(licenseNumberError, _unset)
          ? this.licenseNumberError
          : licenseNumberError as String?,
      certificateUrlError: identical(certificateUrlError, _unset)
          ? this.certificateUrlError
          : certificateUrlError as String?,
      institutionError: identical(institutionError, _unset)
          ? this.institutionError
          : institutionError as String?,
      reasonError: identical(reasonError, _unset)
          ? this.reasonError
          : reasonError as String?,
    );
  }

  @override
  List<Object?> get props => [
    profileStatus,
    preferenceStatus,
    saveStatus,
    profile,
    preference,
    profileError,
    preferenceError,
    saveError,
    displayNameError,
    bioError,
    applicationStatus,
    applicationError,
    fullNameError,
    licenseNumberError,
    certificateUrlError,
    institutionError,
    reasonError,
  ];
}
