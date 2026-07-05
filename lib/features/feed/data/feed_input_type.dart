import 'package:flutter/material.dart';

/// Descriptor de una opción de ingesta en el grid del Feed
/// (PDF de póliza, foto, audio, texto, etc.).
class FeedInputType {
  const FeedInputType(this.key, this.icon, this.color, this.label, this.sub,
      {this.onTap});

  final String key;
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  final VoidCallback? onTap;
}
