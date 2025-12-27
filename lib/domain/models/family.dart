import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'user_role.dart';

class Family extends Equatable {
  final String id;
  final String pairingCode;
  final String recoveryCode;
  final DateTime createdAt;

  const Family({
    required this.id,
    required this.pairingCode,
    required this.recoveryCode,
    required this.createdAt,
  });

  factory Family.fromMap(Map<String, dynamic> map, String id) {
    return Family(
      id: id,
      pairingCode: map['pairingCode'] as String,
      recoveryCode: map['recoveryCode'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pairingCode': pairingCode,
      'recoveryCode': recoveryCode,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object> get props => [id, pairingCode, recoveryCode, createdAt];
}

class FamilyMember extends Equatable {
  final String uid;
  final UserRole role;
  final String displayName;
  final DateTime joinedAt;

  const FamilyMember({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.joinedAt,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      uid: map['uid'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.user,
      ),
      displayName: map['displayName'] as String? ?? '',
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role.name,
      'displayName': displayName,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  @override
  List<Object> get props => [uid, role, displayName, joinedAt];
}

