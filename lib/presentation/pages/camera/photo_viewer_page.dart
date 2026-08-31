import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/file_size_formatter.dart';
import '../../../domain/entities/photo.dart';
import '../../providers/auth/auth_local_datasource_provider.dart';
import '../../providers/camera/camera_providers.dart';
import '../../providers/camera/photo_viewer_controller.dart';

/// Página del visor de una foto individual a tamaño completo.
///
/// Carga los metadatos de la foto vía [photoViewerControllerProvider] y la
/// imagen a resolución completa desde la URL de descarga
/// ([CameraRepository.getPhotoDownloadUrl]). Muestra los metadatos, permite
/// eliminar la foto (con confirmación) y navegar de vuelta a la galería.
class PhotoViewerPage extends ConsumerStatefulWidget {
  const PhotoViewerPage({super.key, required this.photoId});

  /// Identificador de la foto, obtenido del parámetro de ruta `:id`.
  final String photoId;

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  /// Evita envíos duplicados de la eliminación mientras está en curso.
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final photoAsync = ref.watch(photoViewerControllerProvider(widget.photoId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _goBackToGallery),
        title: const Text('Foto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar foto',
            // Solo habilitado cuando hay datos y no hay una eliminación en curso.
            onPressed: photoAsync.hasValue && !_isDeleting
                ? () => _confirmDelete(photoAsync.value!)
                : null,
          ),
        ],
      ),
      body: photoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.invalidate(
            photoViewerControllerProvider(widget.photoId),
          ),
        ),
        data: (photo) => _PhotoContent(photo: photo),
      ),
    );
  }

  /// Navega de vuelta a la galería en `/camaras`.
  ///
  /// Se usa la ruta literal porque la constante `AppRoutes.cameras` y el
  /// registro de rutas se agregan en la tarea de integración del router (11.x).
  void _goBackToGallery() {
    context.go('/camaras');
  }

  Future<void> _confirmDelete(Photo photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: Text(
          '¿Estás seguro de eliminar "${photo.filename}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    final success = await ref
        .read(photoViewerControllerProvider(widget.photoId).notifier)
        .deletePhoto();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto eliminada')),
      );
      _goBackToGallery();
    } else {
      setState(() => _isDeleting = false);
      final error = ref
          .read(photoViewerControllerProvider(widget.photoId))
          .error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar la foto: $error')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contenido: imagen a tamaño completo + metadatos
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoContent extends ConsumerWidget {
  const _PhotoContent({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FullResolutionImage(photo: photo),
              const SizedBox(height: 24),
              _MetadataCard(photo: photo),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Imagen a resolución completa con estados de carga/error propios
// ─────────────────────────────────────────────────────────────────────────────

class _FullResolutionImage extends ConsumerWidget {
  const _FullResolutionImage({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La URL de descarga se resuelve de forma síncrona; el token de acceso se
    // lee de storage local de forma asíncrona y se adjunta como query param
    // `token` para que el elemento <img> pueda autenticarse sin headers
    // personalizados (mismo enfoque que el stream MJPEG).
    final urlAsync = ref.watch(_photoDownloadUrlProvider(photo.id));

    return urlAsync.when(
      loading: () => const _ImagePlaceholder(child: CircularProgressIndicator()),
      error: (error, _) => _ImagePlaceholder(
        child: _ImageError(
          onRetry: () => ref.invalidate(_photoDownloadUrlProvider(photo.id)),
        ),
      ),
      data: (url) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const _ImagePlaceholder(
              child: CircularProgressIndicator(),
            );
          },
          errorBuilder: (context, error, _) => _ImagePlaceholder(
            child: _ImageError(
              onRetry: () =>
                  ref.invalidate(_photoDownloadUrlProvider(photo.id)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenedor con relación de aspecto estable para los estados de la imagen.
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: child),
      ),
    );
  }
}

/// Mensaje de error de carga de la imagen con botón de reintento.
class _ImageError extends StatelessWidget {
  const _ImageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined,
            size: 40, color: colorScheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(
          'No se pudo cargar la imagen.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          onPressed: onRetry,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de metadatos
// ─────────────────────────────────────────────────────────────────────────────

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.photo});

  final Photo photo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _MetadataRow(label: 'Nombre', value: photo.filename),
            _MetadataRow(label: 'Dispositivo', value: photo.deviceId),
            _MetadataRow(
              label: 'Capturada',
              value: _formatDateTime(photo.capturedAt),
            ),
            _MetadataRow(
              label: 'Tamaño',
              value: formatFileSize(photo.sizeBytes),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado de error de los metadatos (incluye 404) con botón de reintento
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      color: colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No se pudo cargar la foto.\n\nDetalle: $error',
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider local: URL de descarga con token de acceso adjunto
// ─────────────────────────────────────────────────────────────────────────────

/// Construye la URL de descarga de la foto y le adjunta el access token como
/// query param `token`, de modo que el elemento `<img>` pueda autenticarse sin
/// headers personalizados. Se limpia automáticamente al salir del visor.
final _photoDownloadUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, photoId) async {
  final baseUrl = ref.watch(cameraRepositoryProvider).getPhotoDownloadUrl(photoId);
  final token = await ref.watch(authLocalDataSourceProvider).readToken();
  if (token == null || token.isEmpty) {
    return baseUrl;
  }
  final separator = baseUrl.contains('?') ? '&' : '?';
  return '$baseUrl${separator}token=$token';
});
