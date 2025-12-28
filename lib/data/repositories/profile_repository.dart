import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/profile.dart';
import '../../domain/models/user_role.dart';
import '../../domain/models/time_window.dart';

/// Repository for managing user profiles stored at families/{familyId}/profiles/{uid}
class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the profile document reference for a user in a family
  DocumentReference<Map<String, dynamic>> _getProfileRef(
    String familyId,
    String uid,
  ) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('profiles')
        .doc(uid);
  }

  /// Get a user's profile
  /// Returns null if profile doesn't exist
  Future<Profile?> getProfile({
    required String familyId,
    required String uid,
  }) async {
    try {
      final profileDoc = await _getProfileRef(familyId, uid).get();

      if (!profileDoc.exists || profileDoc.data() == null) {
        return null;
      }

      return Profile.fromMap(profileDoc.data()!, uid);
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }

  /// Get a user's profile as a stream
  Stream<Profile?> getProfileStream({
    required String familyId,
    required String uid,
  }) {
    return _getProfileRef(familyId, uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return null;
          }
          return Profile.fromMap(snapshot.data()!, uid);
        });
  }

  /// Save or update a user's profile
  Future<bool> saveProfile({
    required String familyId,
    required Profile profile,
  }) async {
    try {
      await _getProfileRef(familyId, profile.uid).set(
        profile.toMap(),
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      // TODO: Handle error properly
      return false;
    }
  }

  /// Create or update a profile with required windows
  Future<bool> updateRequiredWindows({
    required String familyId,
    required String uid,
    required Set<TimeWindow> requiredWindows,
  }) async {
    try {
      // Get existing profile to preserve role and timeZone
      final existingProfile = await getProfile(familyId: familyId, uid: uid);
      
      final profile = existingProfile != null
          ? Profile(
              uid: uid,
              role: existingProfile.role,
              requiredWindows: requiredWindows,
              timeZone: existingProfile.timeZone,
            )
          : Profile.defaultProfile(uid: uid).copyWith(
              requiredWindows: requiredWindows,
            );

      await saveProfile(familyId: familyId, profile: profile);
      return true;
    } catch (e) {
      // TODO: Handle error properly
      return false;
    }
  }

  /// Create a default profile for a user
  Future<bool> createDefaultProfile({
    required String familyId,
    required String uid,
    UserRole role = UserRole.user,
  }) async {
    try {
      final profile = Profile.defaultProfile(uid: uid, role: role);
      return await saveProfile(familyId: familyId, profile: profile);
    } catch (e) {
      // TODO: Handle error properly
      return false;
    }
  }
}

