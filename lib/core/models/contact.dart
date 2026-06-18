import 'package:flutter/material.dart';

class Contact {
  const Contact({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.occupation,
    this.city,
    this.address,
    this.birthdate,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? occupation;
  final String? city;
  final String? address;
  final String? birthdate;
  final String? notes;
  final String? createdAt;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
  }

  Color get color {
    final hue = (id.hashCode.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.60, 0.40).toColor();
  }

  int? get age {
    if (birthdate == null) return null;
    final dt = DateTime.tryParse(birthdate!);
    if (dt == null) return null;
    final now = DateTime.now();
    int years = now.year - dt.year;
    if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) {
      years--;
    }
    return years;
  }

  int? get memberSinceYear =>
      createdAt != null ? DateTime.tryParse(createdAt!)?.year : null;

  int get daysSinceContact => 0;

  bool matchesQuery(String q) {
    if (q.isEmpty) return true;
    final lower = q.toLowerCase();
    return fullName.toLowerCase().contains(lower) ||
        (email?.toLowerCase().contains(lower) ?? false) ||
        (phone?.contains(lower) ?? false) ||
        (occupation?.toLowerCase().contains(lower) ?? false) ||
        (address?.toLowerCase().contains(lower) ?? false);
  }

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        occupation: json['occupation'] as String?,
        city: json['city'] as String?,
        address: json['address'] as String?,
        birthdate: json['birthdate'] as String?,
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] as String?,
      );
}
