import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/supabase_agent_repository.dart';

/// Handler de mensajes en segundo plano. Debe ser una función de nivel superior
/// y tener la anotación @pragma('vm:entry-point') para ejecutarse en su propio isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializa Firebase si es necesario (generalmente ya está inicializado por el OS)
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Recibido mensaje en background: ${message.messageId}');
  }
}

class NotificationService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _firebaseConfigured = false;

  NotificationService(this._ref);

  bool get isConfigured => _firebaseConfigured;

  /// Inicializa la configuración de Firebase y los listeners de notificaciones.
  /// Es tolerante a fallos si Firebase aún no está configurado en el proyecto (sin google-services.json).
  Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Inicializar Firebase
      // Si google-services.json o GoogleService-Info.plist no existen, esto lanzará un error.
      // Lo manejamos con try-catch para no romper la app en desarrollo inicial.
      await Firebase.initializeApp();
      _firebaseConfigured = true;

      // 2. Configurar el handler de background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Inicializar notificaciones locales para mostrar alertas en foreground (primer plano)
      await _initLocalNotifications();

      // Habilitar banners nativos en foreground para iOS
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // 4. Escuchar mensajes en primer plano (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Recibido mensaje en foreground: ${message.notification?.title}');
        }
        // En iOS el sistema operativo ya muestra el banner nativo por setForegroundNotificationPresentationOptions.
        // Solo lanzamos la notificación local manual en Android para evitar duplicados.
        if (!Platform.isIOS) {
          _showLocalNotification(message);
        }
      });

      // 5. Escuchar cuando el usuario hace clic en una notificación y abre la app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('App abierta desde notificación: ${message.data}');
        }
        // Aquí se puede redirigir al detalle del recordatorio si message.data['reminderId'] está presente
      });

      // 6. Escuchar cuando el token se refresque automáticamente
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          print('Token FCM refrescado: $newToken');
        }
        await _sendTokenToBackend(newToken);
      });

      _initialized = true;
      if (kDebugMode) {
        print('NotificationService inicializado correctamente.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Advertencia en NotificationService: Firebase no inicializado. '
            'Esto es normal si aún no has agregado google-services.json o GoogleService-Info.plist.\n'
            'Detalle del error: $e');
      }
      _initialized = false;
      _firebaseConfigured = false;
    }
  }

  /// Solicita permisos de notificaciones al asesor y registra el token en el servidor.
  Future<void> requestPermissionsAndRegister() async {
    if (!_firebaseConfigured) {
      if (kDebugMode) {
        print('No se puede registrar token: Firebase no está configurado.');
      }
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // 1. Solicitar permisos al OS
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kDebugMode) {
        print('Permiso de notificaciones: ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 2. Obtener el token de FCM
        String? token;
        try {
          token = await messaging.getToken();
        } catch (e) {
          if (kDebugMode) {
            print('Error al obtener token FCM directo: $e');
          }
          if (Platform.isIOS) {
            // Reintento usando APNS en iOS si falla el directo por sincronía
            final apnsToken = await messaging.getAPNSToken();
            if (apnsToken != null) {
              token = await messaging.getToken();
            }
          }
        }

        if (token != null) {
          if (kDebugMode) {
            print('Token FCM obtenido de forma exitosa: $token');
          }
          await _sendTokenToBackend(token);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al solicitar permisos o registrar token FCM: $e');
      }
    }
  }

  /// Configuración de notificaciones locales nativas de Android e iOS.
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) {
          print('Clic en notificación local: ${details.payload}');
        }
        // Manejar el clic en la notificación local
      },
    );
  }

  /// Muestra una notificación local emergente en la barra de estado.
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Recordatorios',
      channelDescription: 'Canal para las alertas de recordatorios vencidos',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }

  /// Envía el token de dispositivo registrado al servidor Deno.
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final agentRepo = _ref.read(agentRepositoryProvider);
      final platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      
      await agentRepo.registerDeviceToken(
        token: token,
        platform: platform,
      );
      if (kDebugMode) {
        print('Token FCM enviado al backend correctamente.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al enviar el token FCM al backend: $e');
      }
    }
  }
}

/// Provider de Riverpod para instanciar el servicio.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
