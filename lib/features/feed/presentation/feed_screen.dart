import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_badge.dart';
import 'package:amconnect/core/widgets/am_section_label.dart';
import 'package:amconnect/features/feed/providers/ingest_provider.dart';
import 'ingest_chat_sheet.dart';

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
  Future<void> _pickAndProcessPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    await ref.read(ingestProvider.notifier).process(file, fileName);
  }

  void _handleSuccess() {
    ref.read(ingestProvider.notifier).reset();
    context.push('/chat');
  }

  void _handleClose() {
    ref.read(ingestProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final ingest = ref.watch(ingestProvider);

    return Scaffold(
      backgroundColor: AmColors.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
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
                const AmSectionLabel(label: '¿Qué quieres agregar?'),
                const SizedBox(height: 11),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: _feedTypes.map((t) => _TypeCard(
                    t: t,
                    onTap: t.key == 'doc' ? _pickAndProcessPdf : () {},
                  )).toList(),
                ),
                const SizedBox(height: 12),
                AmCard(
                  onTap: () {},
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
                // Error state
                if (ingest.phase == IngestPhase.error && ingest.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AmColors.redLight.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AmColors.redLight.withValues(alpha: 0.25)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AmColors.redLight, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(ingest.error!,
                            style: const TextStyle(fontSize: 13.5, color: AmColors.redLight))),
                        TextButton(
                          onPressed: _handleClose,
                          child: const Text('Cerrar',
                              style: TextStyle(color: AmColors.redLight, fontSize: 13)),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
            // Processing overlay (uploading / processing)
            if (ingest.phase == IngestPhase.uploading || ingest.phase == IngestPhase.processing)
              _ProcessingOverlay(phase: ingest.phase),
            // Chat sheet (chatting)
            if (ingest.phase == IngestPhase.chatting)
              IngestChatSheet(onClose: _handleClose, onSuccess: _handleSuccess),
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

// ── Processing Overlay ─────────────────────────────────────────────────────────

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.phase});
  final IngestPhase phase;

  @override
  Widget build(BuildContext context) {
    final isUploading = phase == IngestPhase.uploading;
    return Container(
      color: Colors.black.withValues(alpha: 0.34),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 48),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44, height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AmColors.lineLight, borderRadius: BorderRadius.circular(99)),
              ),
              Container(
                width: 80, height: 80,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AmColors.accentWash,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: AmColors.accent.withValues(alpha: 0.18), blurRadius: 20)],
                ),
                child: Image.asset('assets/logo/logo_t.png', width: 46, height: 46),
              ),
              Text(
                isUploading ? 'Subiendo archivo…' : 'Procesando con IA…',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600,
                    color: AmColors.inkLight),
              ),
              const SizedBox(height: 6),
              Text(
                isUploading
                    ? 'Enviando el PDF a Supabase Storage'
                    : 'La IA está extrayendo los datos de la póliza',
                style: const TextStyle(fontSize: 13.5, color: AmColors.mutedLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 36, height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3, color: AmColors.accent),
              ),
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
