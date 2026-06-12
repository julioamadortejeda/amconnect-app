import 'package:flutter/material.dart';

IconData reminderIcon(String type) => switch (type) {
      'PAYMENT'      => Icons.payments_outlined,
      'RENEWAL'      => Icons.autorenew,
      'CANCELLATION' => Icons.block,
      'FOLLOW_UP'    => Icons.flag_outlined,
      'CALL'         => Icons.phone_outlined,
      'APPOINTMENT'  => Icons.event_outlined,
      'ANNIVERSARY'  => Icons.cake,
      _              => Icons.notifications_outlined,
    };
