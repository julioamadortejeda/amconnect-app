abstract final class AmDimens {
  /// Padding horizontal de todas las pantallas
  static const screenH = 18.0;

  /// Padding inferior en listas con scroll (espacio para la barra + mic)
  static const scrollBottomPad = 100.0;

  /// Padding inferior en pantallas de detalle con botón flotante al final (80px)
  static const detailScrollBottomPad = 80.0;

  /// Padding interno de AmCard
  static const cardPad = 18.0;

  /// Radio de borde de AmCard
  static const cardRadius = 18.0;

  /// Escala de radios menores para contenedores internos, chips e iconos.
  static const radiusL = 16.0;
  static const radiusM = 12.0;
  static const radiusS = 10.0;
  static const radiusXS = 6.0;

  /// Gap entre secciones principales
  static const gapL = 20.0;

  /// Gap entre ítems dentro de una sección
  static const gapM = 16.0;

  /// Gap entre filas de lista
  static const gapS = 14.0;

  /// Gap entre label de sección y su contenido
  static const gapXS = 11.0;

  // ─── Filas de lista con icono ────────────────────────────────────────────
  // Recordatorios y compromisos comparten la misma anatomía de fila. Estaban
  // duplicados como números sueltos en los dos widgets; si se separan, las
  // listas dejan de alinearse entre sí en el dashboard.

  /// Lado del cuadro de icono al inicio de la fila.
  static const listIconDim = 38.0;

  /// Radio de ese cuadro.
  static const listIconRadius = 11.0;

  /// Separación entre el icono y el texto.
  static const listIconGap = 12.0;

  /// Pastilla de fecha al final de la fila. Recordatorios y compromisos la
  /// comparten: son las dos listas del dashboard y si sus pastillas no miden
  /// igual, las tarjetas se ven de dos apps distintas al hacer scroll.
  static const listBadgeRadius = 8.0;
  static const listBadgePadH = 9.0;
  static const listBadgePadV = 4.0;

  /// Área táctil mínima de un control dentro de una fila, y el diámetro visible
  /// del círculo dentro de esa área. La diferencia es margen invisible: el
  /// botón se ve discreto pero se deja atinar con el pulgar.
  static const listActionHit = 48.0;
  static const listActionDim = 34.0;

  // ─── Pantallas de autenticación ──────────────────────────────────────────
  // Login, registro, login por correo y recuperar contraseña. Tienen su propio
  // padding porque se diseñaron con más aire que el resto de la app: NO usan
  // screenH, y forzarlas a ese token cambiaría el diseño.

  /// Padding horizontal del contenido de auth.
  static const authPadH = 28.0;

  /// Padding superior e inferior del contenido de auth.
  static const authPadTop = 12.0;
  static const authPadBottom = 14.0;

  /// Medidas del teléfono con el que se diseñaron estas pantallas (iPhone 14/15).
  /// El layout de auth escala contra ellas — ver `scale` / `vScale` en cada
  /// pantalla. El login no las aplicaba y por eso sus textos se veían de otro
  /// tamaño al navegar desde las demás.
  static const authBaseWidth = 390.0;
  static const authBaseHeight = 844.0;
}
