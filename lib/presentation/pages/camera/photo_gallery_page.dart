import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/batch_delete_result.dart';
import '../../../domain/entities/device.dart';
import '../../../domain/entities/photo.dart';
import '../../providers/camera/camera_providers.dart';
import '../../providers/camera/photo_gallery_controller.dart';
import '../../providers/camera/photo_gallery_filter.dart';
import '../../providers/camera/photo_gallery_state.dart';

/// Máximo de fotos que se pueden seleccionar para un borrado en lote.
const int _maxBatchSelection = 50;

/// Página de la galería de cámaras (`/camaras`).
///
/// Muestra una cuadrícula responsiva de miniaturas de fotos con filtros por
/// dispositivo y rango de fechas, paginación mediante "Cargar más", captura
/// bajo demanda, modo de selección múltiple para borrado en lote y enlaces al
/// stream en vivo de cada cámara.
class PhotoGalleryPage extends ConsumerStatefulWidget {
  const PhotoGalleryPage({super.key});

  @override
  ConsumerState<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends ConsumerState<PhotoGalleryPage> {
  // Selección de filtros locales (se aplican al controlador al cambiar).
  String? _selectedDeviceId;
  DateTime? _fromDate;
  DateTime? _toDate;

  // Estado de operaciones que deshabilitan controles.
  bool _isCapturing = false;
  bool _isBatchDeleting = false;

  @override
  Widget build(BuildContext context) {
    final galleryAsync = ref.watch(photoGalleryControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, galleryAsync.value),
              const SizedBox(height: 16),
              _buildFilters(context),
              const SizedBox(height: 16),
              _buildStreamLinks(context),
              const SizedBox(height: 16),
              galleryAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _ErrorState(error: error),
                data: (state) => _buildGallery(context, state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Encabezado: título + acciones (capturar / seleccionar)
  // ───────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, PhotoGalleryState? state) {
    final isSelectionMode = state?.isSelectionMode ?? false;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Cámaras',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (isSelectionMode)
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Cancelar'),
            onPressed: () {
              ref
                  .read(photoGalleryControllerProvider.notifier)
                  .exitSelectionMode();
            },
          )
        else ...[
          _CaptureButton(
            isCapturing: _isCapturing,
            onCapture: _onCapturePressed,
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.checklist),
            label: const Text('Seleccionar'),
            onPressed: () {
              ref
                  .read(photoGalleryControllerProvider.notifier)
                  .enterSelectionMode();
            },
          ),
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Controles de filtro: dropdown de cámara + rango de fechas
  // ───────────────────────────────────────────────────────────────────────

  Widget _buildFilters(BuildContext context) {
    final cameras = ref.watch(cameraDevicesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedDeviceId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Cámara',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todas las cámaras'),
                      ),
                      ...cameras.map((device) => DropdownMenuItem(
                            value: device.id,
                            child: Text(
                              device.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedDeviceId = value);
                      _applyFilters();
                    },
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      _fromDate != null && _toDate != null
                          ? '${_formatDate(_fromDate!)} – ${_formatDate(_toDate!)}'
                          : 'Rango de fechas',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _pickDateRange(context),
                  ),
                ),
                if (_fromDate != null || _toDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Limpiar fechas',
                    onPressed: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                      });
                      _applyFilters();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Enlaces al stream en vivo por cada cámara disponible (Requirement 10.6)
  // ───────────────────────────────────────────────────────────────────────

  Widget _buildStreamLinks(BuildContext context) {
    final cameras = ref.watch(cameraDevicesProvider);
    if (cameras.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: cameras
            .map((device) => ActionChip(
                  avatar: const Icon(Icons.videocam, size: 18),
                  label: Text('En vivo: ${device.name}'),
                  onPressed: () => _goToStream(device),
                ))
            .toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Cuerpo de la galería: barra de selección, grid y "Cargar más"
  // ───────────────────────────────────────────────────────────────────────

  Widget _buildGallery(BuildContext context, PhotoGalleryState state) {
    if (state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Text(
            'No se encontraron fotos para los filtros seleccionados.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isSelectionMode) _buildSelectionBar(context, state),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = _columnsForWidth(constraints.maxWidth);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final photo = state.items[index];
                return _PhotoTile(
                  photo: photo,
                  thumbnailUrl: ref
                      .read(cameraRepositoryProvider)
                      .getPhotoDownloadUrl(photo.id),
                  isSelectionMode: state.isSelectionMode,
                  isSelected: state.selectedIds.contains(photo.id),
                  onTap: () => _onPhotoTapped(state, photo),
                  onLongPress: () => _onPhotoLongPressed(state, photo),
                );
              },
            );
          },
        ),
        if (state.hasMore) ...[
          const SizedBox(height: 16),
          Center(
            child: state.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  )
                : OutlinedButton(
                    onPressed: () => ref
                        .read(photoGalleryControllerProvider.notifier)
                        .loadMore(),
                    child: const Text('Cargar más'),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectionBar(BuildContext context, PhotoGalleryState state) {
    final count = state.selectedIds.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count seleccionada${count == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          FilledButton.icon(
            icon: _isBatchDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            label: const Text('Eliminar selección'),
            onPressed: count == 0 || _isBatchDeleting
                ? null
                : () => _onDeleteSelectedPressed(state),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Cálculo de columnas responsivas (Requirement 5.1)
  // ───────────────────────────────────────────────────────────────────────

  int _columnsForWidth(double width) {
    if (width < 600) return 2;
    if (width <= 1024) return 3;
    return 4;
  }

  // ───────────────────────────────────────────────────────────────────────
  // Interacción con fotos (tap / long-press)
  // ───────────────────────────────────────────────────────────────────────

  void _onPhotoTapped(PhotoGalleryState state, Photo photo) {
    if (state.isSelectionMode) {
      _toggleSelection(state, photo);
    } else {
      context.push('/camaras/foto/${photo.id}');
    }
  }

  void _onPhotoLongPressed(PhotoGalleryState state, Photo photo) {
    final notifier = ref.read(photoGalleryControllerProvider.notifier);
    if (!state.isSelectionMode) {
      notifier.enterSelectionMode();
    }
    _toggleSelection(state, photo);
  }

  /// Alterna la selección respetando el límite de 50 fotos (Requirement 9.4,
  /// 9.5). Solo bloquea al AÑADIR una nueva foto por encima del límite; quitar
  /// siempre está permitido.
  void _toggleSelection(PhotoGalleryState state, Photo photo) {
    final alreadySelected = state.selectedIds.contains(photo.id);
    if (!alreadySelected && state.selectedIds.length >= _maxBatchSelection) {
      _showSnack(
        'Solo puedes seleccionar hasta $_maxBatchSelection fotos.',
      );
      return;
    }
    ref
        .read(photoGalleryControllerProvider.notifier)
        .toggleSelection(photo.id);
  }

  // ───────────────────────────────────────────────────────────────────────
  // Captura bajo demanda (Requirements 7.x)
  // ───────────────────────────────────────────────────────────────────────

  Future<void> _onCapturePressed() async {
    final cameras = ref.read(cameraDevicesProvider);

    if (cameras.isEmpty) {
      _showSnack('No hay cámaras conectadas.');
      return;
    }

    final Device? device = cameras.length == 1
        ? cameras.first
        : await _pickCameraDevice(cameras);
    if (device == null || !mounted) return;

    setState(() => _isCapturing = true);
    try {
      await ref
          .read(photoGalleryControllerProvider.notifier)
          .capturePhoto(device.id);
      if (!mounted) return;
      _showSnack('Foto capturada correctamente.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('No se pudo capturar la foto: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<Device?> _pickCameraDevice(List<Device> cameras) {
    return showDialog<Device>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Selecciona una cámara'),
        children: cameras
            .map((device) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(device),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.videocam, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(device.name)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // Borrado en lote (Requirements 9.6, 9.7, 9.8, 9.9)
  // ───────────────────────────────────────────────────────────────────────

  Future<void> _onDeleteSelectedPressed(PhotoGalleryState state) async {
    final count = state.selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar fotos'),
        content: Text(
          '¿Eliminar $count foto${count == 1 ? '' : 's'} seleccionada'
          '${count == 1 ? '' : 's'}? Esta acción no se puede deshacer.',
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

    final ids = state.selectedIds.toList();
    setState(() => _isBatchDeleting = true);
    try {
      final BatchDeleteResult result = await ref
          .read(photoGalleryControllerProvider.notifier)
          .deletePhotos(ids);
      if (!mounted) return;
      ref
          .read(photoGalleryControllerProvider.notifier)
          .exitSelectionMode();
      final notFound = result.notFoundIds.isNotEmpty
          ? ' No encontradas: ${result.notFoundIds.join(', ')}.'
          : '';
      _showSnack(
        'Se eliminaron ${result.deletedCount} foto'
        '${result.deletedCount == 1 ? '' : 's'}.$notFound',
      );
    } catch (e) {
      if (!mounted) return;
      // Preserva la selección para reintentar (Requirement 9.9).
      _showSnack('No se pudieron eliminar las fotos: $e');
    } finally {
      if (mounted) setState(() => _isBatchDeleting = false);
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Navegación al stream en vivo
  // ───────────────────────────────────────────────────────────────────────

  void _goToStream(Device device) {
    context.push('/camaras/stream/${device.id}');
  }

  // ───────────────────────────────────────────────────────────────────────
  // Filtros: aplicar y selector de rango
  // ───────────────────────────────────────────────────────────────────────

  void _applyFilters() {
    final filter = PhotoGalleryFilter(
      deviceId: _selectedDeviceId,
      from: _fromDate,
      to: _toDate,
    );
    ref.read(photoGalleryControllerProvider.notifier).applyFilters(filter);
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      helpText: 'Seleccionar rango de fechas',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Guardar',
    );

    if (result != null) {
      setState(() {
        _fromDate = result.start;
        _toDate = result.end;
      });
      _applyFilters();
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón de captura con indicador de carga
// ─────────────────────────────────────────────────────────────────────────────

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.isCapturing,
    required this.onCapture,
  });

  final bool isCapturing;
  final Future<void> Function() onCapture;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: isCapturing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.camera_alt),
      label: const Text('Capturar'),
      onPressed: isCapturing ? null : () => onCapture(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Miniatura individual de foto
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.thumbnailUrl,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final Photo photo;
  final String thumbnailUrl;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, _) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isSelectionMode)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                _formatDateTime(photo.capturedAt),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formatea el timestamp como "dd/MM/yyyy HH:mm" en hora local
  /// (Requirement 5.8).
  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado de error con botón de reintento (Requirement 5.5)
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      'No se pudieron cargar las fotos.\n\nDetalle: $error',
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
              onPressed: () =>
                  ref.invalidate(photoGalleryControllerProvider),
            ),
          ],
        ),
      ),
    );
  }
}
