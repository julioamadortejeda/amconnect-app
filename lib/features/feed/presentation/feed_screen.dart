import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_badge.dart';
import 'package:amconnect/core/widgets/am_section_label.dart';
import 'package:amconnect/core/widgets/am_press.dart';

// ── Mock feed data ─────────────────────────────────────────────────────────────

final _feedTypes = [
  _InputType('doc',   Icons.description_outlined, AmColors.srcDoc,      'Póliza PDF',       'Sube la póliza y la leo completa'),
  _InputType('image', Icons.image_outlined,        AmColors.srcImage,    'Foto de póliza',   'Fotografía con tu cámara'),
  _InputType('wave',  Icons.graphic_eq,            AmColors.srcWave,     'Audio / nota voz', 'Transcribe y extrae datos'),
  _InputType('note',  Icons.note_outlined,         AmColors.srcNote,     'Texto / notas',    'Pega chats o notas escritas'),
];

final _recentDocs = [
  _DocItem('Póliza Auto Mariana', 'Mariana Torres', '245 KB', 'hoy', 'doc', 12),
  _DocItem('Audio cliente Javier', 'Javier Mendoza', '1.2 MB', 'ayer', 'wave', 8),
  _DocItem('GMM Captura', 'Javier Mendoza', '890 KB', 'lun', 'image', 6),
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  String? _processing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmColors.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Base de conocimiento',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
                            color: AmColors.mutedLight)),
                    const Text('Alimentar la app',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                            color: AmColors.inkLight, letterSpacing: -0.01)),
                  ],
                ),
                const SizedBox(height: 14),
                // Type label
                const AmSectionLabel(label: '¿Qué quieres agregar?'),
                const SizedBox(height: 11),
                // 2x2 grid of upload types
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: _feedTypes.map((t) => _TypeCard(t: t, onTap: () => setState(() => _processing = t.key))).toList(),
                ),
                const SizedBox(height: 12),
                // WhatsApp import row
                AmCard(
                  onTap: () => setState(() => _processing = 'whatsapp'),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(AmColors.srcWhatsApp.withValues(alpha: 0.14), Colors.white),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.chat_bubble_outline, size: 24, color: AmColors.srcWhatsApp),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Importar chat de WhatsApp',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                    color: AmColors.inkLight)),
                            SizedBox(height: 2),
                            Text('Exporta y sube la conversación',
                                style: TextStyle(fontSize: 12.5, color: AmColors.mutedLight)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AmColors.muted2Light, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Recent uploads
                AmSectionLabel(
                  label: 'Subido recientemente',
                  trailing: AmBadge(label: '${_recentDocs.length}', tone: AmBadgeTone.accent),
                ),
                const SizedBox(height: 10),
                AmCard(
                  noPad: true,
                  child: Column(
                    children: _recentDocs.asMap().entries.map((e) {
                      final d = e.value;
                      final isLast = e.key == _recentDocs.length - 1;
                      return _DocRow(doc: d, isLast: isLast);
                    }).toList(),
                  ),
                ),
              ],
            ),
            if (_processing != null)
              _ProcessingSheet(
                type: _processing!,
                onClose: () => setState(() => _processing = null),
                onChat: () {
                  setState(() => _processing = null);
                  context.push('/chat');
                },
                onAgenda: () {
                  setState(() => _processing = null);
                  context.push('/agenda');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.t, required this.onTap});
  final _InputType t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = Color.alphaBlend(t.color.withValues(alpha: 0.14), Colors.white);
    return AmCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(t.icon, size: 24, color: t.color),
          ),
          const SizedBox(height: 12),
          Text(t.label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: AmColors.inkLight)),
          const SizedBox(height: 3),
          Text(t.sub, style: const TextStyle(fontSize: 12.5, color: AmColors.mutedLight, height: 1.4)),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.doc, required this.isLast});
  final _DocItem doc;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (doc.tipo) {
      'doc'   => (Icons.description_outlined, AmColors.srcDoc),
      'wave'  => (Icons.graphic_eq, AmColors.srcWave),
      'image' => (Icons.image_outlined, AmColors.srcImage),
      _       => (Icons.note_outlined, AmColors.srcNote),
    };
    final bg = Color.alphaBlend(color.withValues(alpha: 0.14), Colors.white);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 13),
      decoration: isLast
          ? null
          : const BoxDecoration(border: Border(bottom: BorderSide(color: AmColors.lineSoftLight))),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.nombre,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AmColors.inkLight),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Text('${doc.cliente} · ${doc.tam} · ${doc.fecha}',
                    style: const TextStyle(fontSize: 12, color: AmColors.mutedLight)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AmBadge(label: '${doc.items} datos', tone: AmBadgeTone.green, icon: Icons.check_circle_outline),
        ],
      ),
    );
  }
}

// ── Processing Sheet ───────────────────────────────────────────────────────────

class _ProcessingSheet extends StatefulWidget {
  const _ProcessingSheet({required this.type, required this.onClose, required this.onChat, required this.onAgenda});
  final String type;
  final VoidCallback onClose;
  final VoidCallback onChat;
  final VoidCallback onAgenda;

  @override
  State<_ProcessingSheet> createState() => _ProcessingSheetState();
}

class _ProcessingSheetState extends State<_ProcessingSheet> {
  int _step = 0;
  bool _done = false;

  final _steps = [
    'Leyendo la póliza',
    'Identificando aseguradora y vigencia',
    'Extrayendo coberturas y participantes',
    'Detectando fechas clave',
    'Generando recordatorios',
    'Guardando en el cliente',
  ];

  @override
  void initState() {
    super.initState();
    _advance();
  }

  void _advance() {
    if (_step < _steps.length) {
      Future.delayed(const Duration(milliseconds: 760), () {
        if (!mounted) return;
        setState(() => _step++);
        _advance();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 480), () {
        if (mounted) setState(() => _done = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.34),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 34),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44, height: 5,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(color: AmColors.lineLight, borderRadius: BorderRadius.circular(99)),
              ),
              if (!_done) ...[
                // Animated logo
                Container(
                  width: 88, height: 88,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AmColors.accentWash,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: AmColors.accent.withValues(alpha: 0.18), blurRadius: 24)],
                  ),
                  child: Image.asset('assets/logo/logo_t.png', width: 50, height: 50),
                ),
                const Text('Procesando póliza',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AmColors.inkLight)),
                const SizedBox(height: 4),
                const Text('La IA está leyendo y organizando la información',
                    style: TextStyle(fontSize: 13.5, color: AmColors.mutedLight)),
                const SizedBox(height: 22),
                ..._steps.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: Opacity(
                      opacity: i <= _step ? 1 : 0.4,
                      child: Row(
                        children: [
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: i < _step ? AmColors.greenLight : i == _step ? AmColors.accentWash : AmColors.cardSunkenLight,
                              shape: BoxShape.circle,
                            ),
                            child: i < _step
                                ? const Icon(Icons.check, size: 15, color: Colors.white)
                                : i == _step
                                    ? const Icon(Icons.circle, size: 9, color: AmColors.accent)
                                    : const Icon(Icons.circle, size: 7, color: AmColors.muted2Light),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(s,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: i == _step ? FontWeight.w600 : FontWeight.w500,
                                  color: i <= _step ? AmColors.inkLight : AmColors.mutedLight,
                                )),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ] else ...[
                Container(
                  width: 52, height: 52,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AmColors.greenWashLight, shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 28, color: AmColors.greenLight),
                ),
                const Text('Póliza añadida',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AmColors.inkLight)),
                const SizedBox(height: 4),
                const Text('Auto · GNP · Mariana Torres',
                    style: TextStyle(fontSize: 13, color: AmColors.mutedLight)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: AmPress(
                      onTap: widget.onAgenda,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AmColors.lineLight, width: 1.5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Ver agenda',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                                color: AmColors.inkSoftLight)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: AmPress(
                      onTap: widget.onChat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AmColors.accent,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: AmColors.accent.withValues(alpha: 0.3), blurRadius: 12)],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.auto_awesome, size: 17, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Preguntar',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data models ────────────────────────────────────────────────────────────────

class _InputType {
  const _InputType(this.key, this.icon, this.color, this.label, this.sub);
  final String key;
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
}

class _DocItem {
  const _DocItem(this.nombre, this.cliente, this.tam, this.fecha, this.tipo, this.items);
  final String nombre;
  final String cliente;
  final String tam;
  final String fecha;
  final String tipo;
  final int items;
}
