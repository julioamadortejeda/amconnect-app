import 'package:flutter/material.dart';

class AmIcons {
  // Source / content-type icons — change here to update everywhere
  static const IconData pdf      = Icons.description_outlined;
  static const IconData audio    = Icons.graphic_eq;
  static const IconData image    = Icons.image_outlined;
  static const IconData text     = Icons.edit_note_outlined;
  static const IconData whatsapp = Icons.chat_bubble_outline;
  static const IconData camera   = Icons.camera_alt_outlined;
  static const IconData document = Icons.picture_as_pdf_outlined;

  static IconData forSourceType(String type) => switch (type) {
    'pdf' || 'doc' || 'document' => pdf,
    'audio' || 'wave'            => audio,
    'image' || 'photo'           => image,
    'text'                       => text,
    _                            => whatsapp,
  };
}
