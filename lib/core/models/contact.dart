import 'package:flutter/material.dart';

class Contact {
  const Contact({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.occupation,
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
  final String? address;
  final String? birthdate;
  final String? notes;
  final String? createdAt;

  String get inicial {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
  }

  Color get color {
    final hue = (id.hashCode.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.60, 0.40).toColor();
  }

  String get desde {
    final year = createdAt != null ? DateTime.tryParse(createdAt!)?.year : null;
    return year != null ? 'Cliente $year' : 'Cliente';
  }

  int get diasSinContacto => 0;

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        occupation: json['occupation'] as String?,
        address: json['address'] as String?,
        birthdate: json['birthdate'] as String?,
        notes: json['notes'] as String?,
        createdAt: json['createdAt'] as String?,
      );
}
