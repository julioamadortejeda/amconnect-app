import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/theme/am_theme.dart';
import 'package:amconnect/core/mock/mock_data.dart';
import 'package:amconnect/core/widgets/am_avatar.dart';
import 'package:amconnect/core/widgets/am_back_bar.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/l10n/app_localizations.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  const CreateReminderScreen({super.key, this.clienteId});
  final String? clienteId;

  @override
  ConsumerState<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen> {
  String _tipo = 'llamada';
  String _clienteId = '';
  final String _titulo = 'Llamar a Mariana Torres';
  bool _saved = false;

  final _tipos = [
    ('llamada', Icons.phone_outlined),
    ('pago',    Icons.payments_outlined),
    ('renovacion', Icons.autorenew),
    ('otro',    Icons.notifications_outlined),
  ];

  String _tipoLabel(String key, AppLocalizations l10n) => switch (key) {
    'llamada'    => l10n.reminderTypeCall,
    'pago'       => l10n.reminderTypePayment,
    'renovacion' => l10n.reminderTypeRenewal,
    _            => l10n.reminderTypeOther,
  };

  @override
  void initState() {
    super.initState();
    _clienteId = widget.clienteId ?? mockClients.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 90, 18, 40),
              children: [
                // AI natural language box
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2AB5FF), Color(0xFF007AC0), Color(0xFF005580)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AmColors.accent.withValues(alpha: 0.26),
                          blurRadius: 26, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 17),
                        const SizedBox(width: 8),
                        Text(l10n.remindersVoiceHint,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.92), letterSpacing: 0.03)),
                      ]),
                      const SizedBox(height: 11),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('"${l10n.remindersVoicePlaceholder}"',
                                  style: TextStyle(fontSize: 14.5, color: Colors.white.withValues(alpha: 0.7))),
                            ),
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.mic_none_outlined, color: AmColors.accent, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                _Field(
                  label: l10n.remindersFieldTitle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 22)],
                    ),
                    child: Text(_titulo,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                            color: cs.onSurface)),
                  ),
                ),
                const SizedBox(height: 16),

                // Type grid
                _Field(
                  label: l10n.remindersFieldType,
                  child: Row(
                    children: _tipos.map((t) {
                      final (key, icon) = t;
                      final label = _tipoLabel(key, l10n);
                      final active = _tipo == key;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AmPress(
                            onTap: () => setState(() => _tipo = key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: active ? AmColors.accent : Colors.white,
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: [
                                  BoxShadow(
                                    color: active ? AmColors.accent.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.055),
                                    blurRadius: active ? 12 : 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Icon(icon, size: 19, color: active ? Colors.white : cs.onSurfaceVariant),
                                  const SizedBox(height: 6),
                                  Text(label,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                                          color: active ? Colors.white : cs.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Client selector
                _Field(
                  label: l10n.remindersFieldClient,
                  child: SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: mockClients.map((c) {
                        final active = c.id == _clienteId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AmPress(
                            onTap: () => setState(() => _clienteId = c.id),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(7, 7, 13, 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: active ? AmColors.accent : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 8)],
                              ),
                              child: Row(
                                children: [
                                  AmAvatar(inicial: c.inicial, color: c.color, size: 30, radius: 9),
                                  const SizedBox(width: 8),
                                  Text(c.nombre.split(' ').first,
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500,
                                          color: cs.onSurface)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date + time row
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: l10n.remindersFieldDate,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 8)],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 17, color: cs.onPrimaryContainer),
                              const SizedBox(width: 9),
                              Text('Mañana · Jue 5 jun',
                                  style: TextStyle(fontSize: 13.5, color: cs.onSurface)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 118,
                      child: _Field(
                        label: l10n.remindersFieldTime,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 8)],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 17, color: cs.onPrimaryContainer),
                              const SizedBox(width: 8),
                              Text('15:00',
                                  style: TextStyle(fontSize: 15, color: cs.onSurface)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Repeat toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.autorenew, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l10n.remindersRepeatYearly,
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600,
                                color: cs.onSurface)),
                      ),
                      _Toggle(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                AmPress(
                  onTap: () {
                    setState(() => _saved = true);
                    Future.delayed(const Duration(milliseconds: 1100), () {
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      color: AmColors.accent,
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: [BoxShadow(color: AmColors.accent.withValues(alpha: 0.3),
                          blurRadius: 18, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_outlined, size: 19, color: Colors.white),
                        const SizedBox(width: 9),
                        Text(l10n.remindersCreateBtn,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Back bar
          AmBackBar(title: l10n.remindersNewTitle),
          // Success overlay
          if (_saved)
            Container(
              color: Colors.black.withValues(alpha: 0.34),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(34, 30, 34, 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 48)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: am.greenWash,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, size: 38, color: am.green),
                      ),
                      const SizedBox(height: 14),
                      Text(l10n.remindersCreated,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label.toUpperCase(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  letterSpacing: 0.08 * 12, color: cs.tertiary)),
        ),
        child,
      ],
    );
  }
}

class _Toggle extends StatefulWidget {
  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _on = !_on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50, height: 30,
        decoration: BoxDecoration(
          color: _on ? AmColors.accent : cs.outline,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.all(3),
        alignment: _on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}
