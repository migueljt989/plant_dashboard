import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import '../../providers/auth/auth_local_datasource_provider.dart';
import '../../providers/camera/camera_providers.dart';

/// Página de streaming MJPEG en vivo de una cámara.
///
/// Renderiza un elemento HTML `<img>` (vía [HtmlElementView]) cuyo `src` es la
/// URL del stream obtenida de `CameraRepository.getStreamUrl`, con el JWT
/// adjuntado como query param `token` para que el `<img>` pueda autenticarse
/// sin cabeceras personalizadas.
///
/// Maneja tres estados de UI:
/// - Cargando: mientras se construye la URL o el `<img>` aún no emite `load`
///   ni `error` (con un timeout de 10s).
/// - En vivo: el `<img>` emitió `load` correctamente; se muestra el indicador
///   "Live" y el identificador del dispositivo.
/// - Error: el `<img>` emitió `error` o no cargó en 10s; se muestra "Stream no
///   disponible" con un botón de reintento que vuelve a asignar el `src`.
class LiveStreamPage extends ConsumerStatefulWidget {
  const LiveStreamPage({super.key, required this.deviceId});

  /// Identificador del dispositivo de cámara (viene del path param de la ruta).
  final String deviceId;

  @override
  ConsumerState<LiveStreamPage> createState() => _LiveStreamPageState();
}

enum _StreamStatus { loading, live, error }

class _LiveStreamPageState extends ConsumerState<LiveStreamPage> {
  /// Duración máxima de espera antes de considerar el stream no disponible.
  static const _loadTimeout = Duration(seconds: 10);

  /// Identificador único del view factory / view type para este stream.
  late final String _viewType;

  web.HTMLImageElement? _imgElement;
  StreamSubscription<web.Event>? _loadSub;
  StreamSubscription<web.Event>? _errorSub;
  Timer? _timeoutTimer;

  _StreamStatus _status = _StreamStatus.loading;

  @override
  void initState() {
    super.initState();
    _viewType = 'mjpeg-stream-${widget.deviceId}-${identityHashCode(this)}';
    _registerViewFactory();
    // La URL requiere leer el token de forma asíncrona; se dispara tras el
    // primer frame para poder actualizar el estado con seguridad.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startStream());
  }

  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final img = web.HTMLImageElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain';
        _imgElement = img;
        _attachListeners(img);
        return img;
      },
    );
  }

  void _attachListeners(web.HTMLImageElement img) {
    _loadSub?.cancel();
    _errorSub?.cancel();
    _loadSub = img.onLoad.listen((_) => _onStreamLoaded());
    _errorSub = img.onError.listen((_) => _onStreamError());
  }

  /// Construye la URL del stream (con el token) y la asigna al `<img>`,
  /// arrancando el timeout de carga.
  Future<void> _startStream() async {
    if (!mounted) return;
    setState(() => _status = _StreamStatus.loading);

    final repository = ref.read(cameraRepositoryProvider);
    final localAuth = ref.read(authLocalDataSourceProvider);

    final baseUrl = repository.getStreamUrl(widget.deviceId);
    final token = await localAuth.readToken();
    final url = _appendToken(baseUrl, token);

    // El view factory puede no haberse ejecutado todavía si el HtmlElementView
    // aún no se montó; se reintenta en el siguiente frame hasta tener el <img>.
    if (_imgElement == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _assignSrc(url));
    } else {
      _assignSrc(url);
    }
  }

  void _assignSrc(String url) {
    final img = _imgElement;
    if (img == null || !mounted) return;
    // Re-adjunta listeners por si el elemento fue reutilizado en un reintento.
    _attachListeners(img);
    img.src = url;
    _startTimeout();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_loadTimeout, () {
      if (!mounted) return;
      if (_status == _StreamStatus.loading) {
        setState(() => _status = _StreamStatus.error);
      }
    });
  }

  void _onStreamLoaded() {
    if (!mounted) return;
    _timeoutTimer?.cancel();
    setState(() => _status = _StreamStatus.live);
  }

  void _onStreamError() {
    if (!mounted) return;
    _timeoutTimer?.cancel();
    setState(() => _status = _StreamStatus.error);
  }

  /// Reintenta la carga del stream volviendo a asignar el `src` del `<img>`.
  void _retry() {
    _startStream();
  }

  /// Adjunta el [token] como query param `token`, respetando si la URL ya
  /// contiene otros parámetros.
  String _appendToken(String url, String? token) {
    if (token == null || token.isEmpty) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}token=${Uri.encodeQueryComponent(token)}';
  }

  @override
  void dispose() {
    _loadSub?.cancel();
    _errorSub?.cancel();
    _timeoutTimer?.cancel();
    // Detener la descarga del stream limpiando el src del elemento.
    _imgElement?.src = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Cámara en vivo · ${widget.deviceId}'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildStreamArea(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreamArea(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // El <img> se mantiene montado siempre para que reciba los eventos
            // load/error; se oculta visualmente cuando hay error o carga.
            Offstage(
              offstage: _status != _StreamStatus.live,
              child: HtmlElementView(viewType: _viewType),
            ),
            if (_status == _StreamStatus.loading)
              const Center(child: CircularProgressIndicator()),
            if (_status == _StreamStatus.error) _buildError(context),
            if (_status == _StreamStatus.live) _buildLiveIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveIndicator(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Live',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.deviceId,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Stream no disponible',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            onPressed: _retry,
          ),
        ],
      ),
    );
  }
}
