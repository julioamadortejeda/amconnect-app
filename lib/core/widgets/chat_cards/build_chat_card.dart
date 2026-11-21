import 'package:flutter/material.dart';
import 'policy_confirmed_card.dart';
import 'contact_created_card.dart';
import 'reminder_created_card.dart';
import 'contact_info_card.dart';
import 'contact_list_carousel.dart';
import 'reminder_list_card.dart';
import 'policy_list_card.dart';
import 'policy_info_card.dart';
import 'attachment_list_card.dart';


// ─── Factory ─────────────────────────────────────────────────────────────────

/// Returns a premium card widget if the [metadata] contains a known type,
/// otherwise returns null so the caller can fall back to a text bubble.
Widget? buildChatCard(Map<String, dynamic> metadata, BuildContext context) {
  final type = metadata['type'] as String?;
  switch (type) {
    case 'attachment_list':
      return AttachmentListCard(data: metadata);
    case 'policy_confirmed':
      return PolicyConfirmedCard(data: metadata);
    case 'policy_updated':
      return PolicyConfirmedCard(data: metadata, isUpdate: true);
    case 'contact_created':
      return ContactCreatedCard(data: metadata);
    case 'reminder_created':
      return ReminderCreatedCard(data: metadata);
    case 'contact_info':
      return ContactInfoCard(data: metadata);
    case 'contact_list':
      return ContactListCarousel(data: metadata);
    case 'reminder_list':
      return ReminderListCard(data: metadata);
    case 'policy_list':
      return PolicyListCard(data: metadata);
    case 'policy_info':
      return PolicyInfoCard(data: metadata);
    default:
      return null;
  }
}
