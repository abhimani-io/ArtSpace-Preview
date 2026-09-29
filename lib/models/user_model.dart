import 'package:cloud_firestore/cloud_firestore.dart';

/// This describes what a "User" looks like in our app's database.
/// It stores their basic profile and whether they are a buyer or a seller.
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'user' for normal buyers, or 'seller' for artists
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.createdAt,
  });

  /// Takes raw data from the database and builds a UserModel object out of it.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      // Always assume they are a normal user if no role is found (for security)
      role: json['role'] as String? ?? 'user', 
      // Convert the database timestamp into a normal Date
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Turns this object back into raw data so we can save it to the database.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      // If we don't have a creation date yet, tell the database to stamp it with the current time.
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  /// A quick way to make a copy of this user but change one specific detail (like their email).
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
