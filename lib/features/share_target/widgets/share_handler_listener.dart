import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:go_router/go_router.dart';
import '../providers/share_target_provider.dart';

/// Escucha los archivos compartidos desde otras apps y abre `/share-target`.
///
/// El plugin entrega el contenido por dos vías:
/// - `getMediaStream()` — app viva (iOS: URL `SharingMedia-<bundleId>` que
///   procesa el plugin; Android: `onNewIntent`).
/// - `getInitialSharing()` — arranque en frío. Se consume una sola vez: el
///   plugin limpia su caché al leerla.
class ShareHandlerListener extends ConsumerStatefulWidget {
  const ShareHandlerListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<ShareHandlerListener> createState() => _ShareHandlerListenerState();
}

class _ShareHandlerListenerState extends ConsumerState<ShareHandlerListener> with WidgetsBindingObserver {
  StreamSubscription<List<SharedFile>>? _intentSubscription;
  bool _onShareTarget = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSharingIntent();
  }

  void _initSharingIntent() {
    _intentSubscription = FlutterSharingIntent.instance.getMediaStream().listen(
      (List<SharedFile> value) {
        if (value.isNotEmpty && mounted) {
          _handleSharedFiles(value);
        }
      },
      onError: (err) {
        debugPrint('[SHARE_TARGET] Stream error: $err');
      },
    );

    _checkAndFetchSharedContent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndFetchSharedContent();
    }
  }

  void _checkAndFetchSharedContent() {
    FlutterSharingIntent.instance.getInitialSharing().then((List<SharedFile> value) {
      if (value.isNotEmpty && mounted) {
        _handleSharedFiles(value);
      }
    });
  }

  void _handleSharedFiles(List<SharedFile> files) {
    ref.read(shareTargetProvider.notifier).setSharedFiles(files);

    // El stream y getInitialSharing pueden dispararse casi a la vez; evitar
    // apilar dos veces la misma pantalla.
    if (_onShareTarget) return;
    _onShareTarget = true;
    GoRouter.of(context).push('/share-target').whenComplete(() {
      _onShareTarget = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _intentSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
