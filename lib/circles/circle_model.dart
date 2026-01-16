import 'package:cloud_firestore/cloud_firestore.dart';

class Circle {
  final String id;
  final String name;
  final String inviteCode;
  final String createdBy;
  final List<String> members;
  final List<String> admins;
  final DateTime createdAt;

  Circle({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdBy,
    required this.members,
    required this.admins,
    required this.createdAt,
  });

  factory Circle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Circle(
      id: doc.id,
      name: data['name'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      createdBy: data['createdBy'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      admins: List<String>.from(data['admins'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'createdBy': createdBy,
      'members': members,
      'admins': admins,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Circle copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? createdBy,
    List<String>? members,
    List<String>? admins,
    DateTime? createdAt,
  }) {
    return Circle(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
