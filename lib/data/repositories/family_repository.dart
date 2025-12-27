import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/family.dart';
import '../../domain/models/user_role.dart';

class FamilyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a short, human-readable pairing code (6-8 characters)
  String _generatePairingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude confusing chars
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate a recovery code (12-16 characters)
  String _generateRecoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(14, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a new family and add the user as a member
  Future<Family?> createFamily({
    required String userId,
    required String displayName,
    UserRole role = UserRole.user,
  }) async {
    try {
      final pairingCode = _generatePairingCode();
      final recoveryCode = _generateRecoveryCode();
      final now = DateTime.now();

      // Create family document
      final familyRef = _firestore.collection('families').doc();
      final family = Family(
        id: familyRef.id,
        pairingCode: pairingCode,
        recoveryCode: recoveryCode,
        createdAt: now,
      );

      await familyRef.set(family.toMap());

      // Add user as member
      await familyRef
          .collection('members')
          .doc(userId)
          .set(FamilyMember(
            uid: userId,
            role: role,
            displayName: displayName,
            joinedAt: now,
          ).toMap());

      return family;
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }

  /// Join a family using a pairing code
  Future<Family?> joinFamilyWithCode({
    required String pairingCode,
    required String userId,
    required String displayName,
    UserRole role = UserRole.caregiver,
  }) async {
    try {
      // Find family by pairing code
      final familiesQuery = await _firestore
          .collection('families')
          .where('pairingCode', isEqualTo: pairingCode.toUpperCase())
          .limit(1)
          .get();

      if (familiesQuery.docs.isEmpty) {
        return null; // Invalid pairing code
      }

      final familyDoc = familiesQuery.docs.first;
      final familyRef = familyDoc.reference;

      // Check if user is already a member
      final memberDoc = await familyRef.collection('members').doc(userId).get();
      if (memberDoc.exists) {
        // User already a member, return existing family
        return Family.fromMap(familyDoc.data(), familyDoc.id);
      }

      // Add user as member
      await familyRef.collection('members').doc(userId).set(
            FamilyMember(
              uid: userId,
              role: role,
              displayName: displayName,
              joinedAt: DateTime.now(),
            ).toMap(),
          );

      return Family.fromMap(familyDoc.data(), familyDoc.id);
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }

  /// Restore access using a recovery code
  Future<Family?> restoreFamilyWithRecoveryCode({
    required String recoveryCode,
    required String userId,
    required String displayName,
    UserRole role = UserRole.user,
  }) async {
    try {
      // Find family by recovery code
      final familiesQuery = await _firestore
          .collection('families')
          .where('recoveryCode', isEqualTo: recoveryCode.toUpperCase())
          .limit(1)
          .get();

      if (familiesQuery.docs.isEmpty) {
        return null; // Invalid recovery code
      }

      final familyDoc = familiesQuery.docs.first;
      final familyRef = familyDoc.reference;

      // Check if user is already a member
      final memberDoc = await familyRef.collection('members').doc(userId).get();
      if (memberDoc.exists) {
        // User already a member, return existing family
        return Family.fromMap(familyDoc.data(), familyDoc.id);
      }

      // Add user as member (restoring access)
      await familyRef.collection('members').doc(userId).set(
            FamilyMember(
              uid: userId,
              role: role,
              displayName: displayName,
              joinedAt: DateTime.now(),
            ).toMap(),
          );

      return Family.fromMap(familyDoc.data(), familyDoc.id);
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }

  /// Get family ID for a user
  Future<String?> getFamilyId(String userId) async {
    try {
      // Search all families for this user as a member
      final familiesSnapshot = await _firestore.collection('families').get();

      for (final familyDoc in familiesSnapshot.docs) {
        final memberDoc =
            await familyDoc.reference.collection('members').doc(userId).get();
        if (memberDoc.exists) {
          return familyDoc.id;
        }
      }

      return null;
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }

  /// Get family document by ID
  Future<Family?> getFamily(String familyId) async {
    try {
      final familyDoc = await _firestore.collection('families').doc(familyId).get();
      if (!familyDoc.exists) {
        return null;
      }
      final data = familyDoc.data();
      if (data == null) return null;
      return Family.fromMap(data, familyDoc.id);
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }

  /// Get family member info
  Future<FamilyMember?> getFamilyMember(String familyId, String userId) async {
    try {
      final memberDoc = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('members')
          .doc(userId)
          .get();

      if (!memberDoc.exists) {
        return null;
      }

      return FamilyMember.fromMap(memberDoc.data()!);
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }

  /// Get all members of a family
  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    try {
      final membersSnapshot = await _firestore
          .collection('families')
          .doc(familyId)
          .collection('members')
          .get();

      return membersSnapshot.docs
          .map((doc) => FamilyMember.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // TODO: Handle error properly
      return [];
    }
  }
}
