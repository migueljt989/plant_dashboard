# Implementation Plan: Camera Gallery

## Overview

Implements the camera gallery feature following clean architecture (domain → infrastructure → presentation). Tasks are ordered by dependency: domain entities first, then infrastructure (DTOs, datasource, repository), then presentation (providers, controllers, state, pages), and finally router integration. Each task is a discrete coding step that builds on previous ones.

## Tasks

- [x] 1. Domain layer — entities and repository contract
  - [x] 1.1 Create Photo entity
    - Create `lib/domain/entities/photo.dart` with the `Photo` class containing all fields: id, deviceId, filename, filepath, sizeBytes, contentType, capturedAt, createdAt
    - All fields are final, constructor uses required named params
    - _Requirements: 1.1_

  - [x] 1.2 Create BatchDeleteResult entity
    - Create `lib/domain/entities/batch_delete_result.dart` with `BatchDeleteResult` class containing deletedCount (int) and notFoundIds (List<String>)
    - _Requirements: 2.1_

  - [x] 1.3 Create CameraRepository abstract class
    - Create `lib/domain/repositories/camera_repository.dart` defining the abstract `CameraRepository` contract with methods: getPhotos, getPhotoMetadata, getPhotoDownloadUrl, capturePhoto, deletePhoto, deletePhotos, getStreamUrl
    - Import `Photo`, `BatchDeleteResult`, and the existing `PaginatedResponse` generic
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [x] 2. Infrastructure layer — DTOs
  - [x] 2.1 Create PhotoDto with fromJson/toJson and toEntity
    - Create `lib/infrastructure/models/photo_dto.dart` with manual JSON serialization mapping snake_case backend keys to camelCase Dart fields
    - Store capturedAt and createdAt as String in the DTO, parse to DateTime in `toEntity()`
    - _Requirements: 1.2, 1.3, 1.4, 1.5, 1.6_

  - [ ]* 2.2 Write property tests for PhotoDto serialization (Property 1 & 2)
    - **Property 1: PhotoDto serialization round-trip** — For any valid PhotoDto, `toJson()` then `fromJson()` produces identical fields
    - **Property 2: PhotoDto rejects invalid JSON** — Missing/wrong-type fields cause errors
    - **Validates: Requirements 1.5, 1.6**

  - [x] 2.3 Create BatchDeleteResultDto with fromJson and toEntity
    - Create `lib/infrastructure/models/batch_delete_result_dto.dart` with manual fromJson parsing `deleted_count` and `not_found_ids`, and `toEntity()` mapping
    - Throw `FormatException` on missing or incorrectly typed fields
    - _Requirements: 2.2, 2.3, 2.4_

  - [ ]* 2.4 Write property tests for BatchDeleteResultDto (Property 3 & 4)
    - **Property 3: BatchDeleteResultDto parse-to-entity preserves data** — For valid JSON, fromJson + toEntity preserves values
    - **Property 4: BatchDeleteResultDto rejects invalid JSON** — Missing/wrong-type fields throw FormatException
    - **Validates: Requirements 2.2, 2.3, 2.4**

- [x] 3. Infrastructure layer — DataSource contract and backend implementation
  - [x] 3.1 Create CameraDataSource abstract class
    - Create `lib/infrastructure/datasources/camera/camera_datasource.dart` with the abstract contract defining all methods matching the design interface
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

  - [x] 3.2 Implement CameraDataSourceBackend
    - Create `lib/infrastructure/datasources/camera/camera_datasource_backend.dart` implementing `CameraDataSource` using authenticated Dio
    - Implement fetchPhotos (GET `/cameras/photos` with query params), fetchPhotoMetadata (GET `/cameras/photos/{id}`), capturePhoto (POST `/cameras/{device_id}/capture`), deletePhoto (DELETE `/cameras/photos/{id}`), deletePhotos (DELETE `/cameras/photos` with body)
    - Implement getPhotoDownloadUrl and getStreamUrl as URL construction without network calls
    - Validate deletePhotos input (1–50 items) throwing ArgumentError
    - Map 404 to NotFoundFailure, connection errors to NetworkFailure
    - _Requirements: 3.8, 3.9, 3.10, 3.11, 3.12, 3.13, 3.14, 3.15, 3.16, 3.17_

  - [ ]* 3.3 Write property test for URL construction (Property 5)
    - **Property 5: URL construction correctness** — For any non-empty photoId/deviceId, getPhotoDownloadUrl ends with `/cameras/photos/{photoId}/file` and getStreamUrl ends with `/cameras/{deviceId}/stream`
    - **Validates: Requirements 3.10, 3.14, 10.2**

- [ ] 4. Infrastructure layer — Repository implementation
  - [ ] 4.1 Implement CameraRepositoryImpl
    - Create `lib/infrastructure/repositories/camera_repository_impl.dart` implementing `CameraRepository`
    - Receive `CameraDataSource` via constructor, delegate all calls, map DTOs to entities via `toEntity()`
    - Pass through URL strings directly, propagate failures without wrapping
    - _Requirements: 4.8, 4.9, 4.10_

- [ ] 5. Checkpoint — Domain and infrastructure layers complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Presentation layer — Providers and state models
  - [ ] 6.1 Create PhotoGalleryFilter model
    - Create `lib/presentation/providers/camera/photo_gallery_filter.dart` with `PhotoGalleryFilter` class (deviceId, from, to)
    - _Requirements: 5.2, 5.3_

  - [ ] 6.2 Create PhotoGalleryState model
    - Create `lib/presentation/providers/camera/photo_gallery_state.dart` with `PhotoGalleryState` class (items, total, limit, offset, filter, isLoadingMore, selectedIds, isSelectionMode)
    - Implement `hasMore` getter: `offset + items.length < total`
    - Implement `copyWith` method for immutable state updates
    - _Requirements: 5.6, 5.7, 9.1, 9.3_

  - [ ]* 6.3 Write property test for pagination hasMore invariant (Property 6)
    - **Property 6: Pagination hasMore invariant** — `hasMore` returns true iff `offset + items.length < total`
    - **Validates: Requirements 5.7**

  - [ ] 6.4 Create camera_providers.dart
    - Create `lib/presentation/providers/camera/camera_providers.dart` with cameraDataSourceProvider, cameraRepositoryProvider, and cameraDevicesProvider
    - cameraDevicesProvider filters devices from existing devicesControllerProvider to only camera-type devices
    - _Requirements: 11.1, 11.2, 11.7_

  - [ ]* 6.5 Write property test for camera device filtering (Property 10)
    - **Property 10: Camera devices filter returns only camera-type devices** — Filtering logic returns exactly those devices with type == camera, preserving order
    - **Validates: Requirements 11.7**

- [ ] 7. Presentation layer — Controllers
  - [ ] 7.1 Implement PhotoGalleryController (AsyncNotifier)
    - Create `lib/presentation/providers/camera/photo_gallery_controller.dart` with `PhotoGalleryController` extending `AsyncNotifier<PhotoGalleryState>`
    - Implement `build()` to load initial page (offset 0, limit 20, no filters)
    - Implement `applyFilters(PhotoGalleryFilter)` resetting offset to 0
    - Implement `loadMore()` appending items and advancing offset
    - Implement `capturePhoto(deviceId)` with 30s timeout, prepend result, invalidate state
    - Implement `deletePhoto(photoId)` with invalidation
    - Implement `deletePhotos(List<String>)` for batch delete with invalidation
    - Implement selection mode methods: toggleSelection, enterSelectionMode, exitSelectionMode
    - _Requirements: 11.3, 11.4, 7.3, 7.5, 7.6, 8.3, 8.4, 9.7, 9.8_

  - [ ]* 7.2 Write property tests for gallery controller (Properties 8 & 9)
    - **Property 8: Applying filters resets offset to zero** — For any state and new filter, applyFilters produces state with offset == 0
    - **Property 9: Load more appends items and advances offset** — When hasMore is true, loadMore appends new items and advances offset correctly
    - **Validates: Requirements 5.3, 5.6, 11.3**

  - [ ] 7.3 Implement PhotoViewerController (AsyncNotifier.family)
    - Create `lib/presentation/providers/camera/photo_viewer_controller.dart` with `PhotoViewerController` extending `AutoDisposeAsyncNotifier<Photo>` parameterized by photo ID
    - Implement `build()` to fetch photo metadata
    - Implement `deletePhoto()` returning success indicator for navigation
    - _Requirements: 11.5, 11.6_

- [ ] 8. Presentation layer — Utility helpers
  - [ ] 8.1 Create file size formatter utility
    - Create `lib/core/utils/file_size_formatter.dart` with a function that formats sizeBytes to human-readable: KB when < 1,048,576, MB otherwise, rounded to 1 decimal
    - _Requirements: 6.2_

  - [ ]* 8.2 Write property test for file size formatting (Property 7)
    - **Property 7: File size formatting** — For any non-negative sizeBytes, output ends in "KB" when < 1,048,576 or "MB" otherwise, with correct calculation
    - **Validates: Requirements 6.2**

- [ ] 9. Checkpoint — Providers and controllers complete
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Presentation layer — Pages
  - [ ] 10.1 Implement PhotoGalleryPage
    - Create `lib/presentation/pages/camera/photo_gallery_page.dart`
    - Responsive grid: 2 cols < 600px, 3 cols 600–1024px, 4 cols > 1024px
    - Filter controls: camera dropdown (from cameraDevicesProvider) and date range pickers
    - Photo thumbnails with captured_at formatted "dd/MM/yyyy HH:mm"
    - Loading indicator, error state with retry, empty state message
    - "Load more" button when hasMore is true
    - Capture button with device selection dialog (or auto-select single device)
    - Selection mode: long-press or "Select" button, checkboxes, count display, "Delete Selected" button, 50-photo limit enforcement
    - Navigation to PhotoViewerPage on tap, navigation links to LiveStreamPage per camera device
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9, 5.10, 5.11, 7.1, 7.2, 7.4, 7.6, 7.7, 7.8, 8.1, 8.2, 8.4, 8.5, 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.8, 9.9, 10.6_

  - [ ] 10.2 Implement PhotoViewerPage
    - Create `lib/presentation/pages/camera/photo_viewer_page.dart`
    - Full-resolution photo loaded from getPhotoDownloadUrl
    - Metadata display: filename, device_id, captured_at, file size (using formatter)
    - Loading indicator, error state with retry (including 404)
    - Delete button with confirmation dialog, navigate back on success
    - Back navigation control
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

  - [ ] 10.3 Implement LiveStreamPage
    - Create `lib/presentation/pages/camera/live_stream_page.dart`
    - MJPEG stream via HtmlElementView rendering an HTML `<img>` element
    - Stream URL from getStreamUrl with JWT token appended as `?token=` query param
    - Loading indicator before stream loads, "Live" indicator while streaming
    - Error handling: 10s timeout, error event detection, "Stream unavailable" message with retry button
    - Back navigation control
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.7_

- [ ] 11. Router integration and navigation
  - [ ] 11.1 Add route constants to AppRoutes
    - Add `cameras`, `cameraPhoto`, and `cameraStream` constants to `lib/presentation/router/app_routes.dart`
    - _Requirements: 12.6_

  - [ ] 11.2 Register camera routes in app_router.dart
    - Add `/camaras`, `/camaras/foto/:id`, and `/camaras/stream/:deviceId` as children of the existing ShellRoute in `lib/presentation/router/app_router.dart`
    - Ensure auth guard applies (unauthenticated users redirect to login)
    - _Requirements: 12.1, 12.2, 12.3, 12.5_

  - [ ] 11.3 Add "Cámaras" entry to side navigation menu
    - Add navigation item to the `kNavItems` list pointing to `/camaras`
    - _Requirements: 12.4_

- [ ] 12. Final checkpoint — Full feature integration
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- The implementation uses Dart/Flutter with Riverpod (no codegen), go_router, and dio as specified in the tech stack
- All JSON serialization is manual (no freezed/json_serializable)
- Domain layer has zero dependency on Flutter or infrastructure packages

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3", "2.1", "2.3"] },
    { "id": 2, "tasks": ["2.2", "2.4", "3.1"] },
    { "id": 3, "tasks": ["3.2"] },
    { "id": 4, "tasks": ["3.3", "4.1"] },
    { "id": 5, "tasks": ["6.1", "6.2", "6.4", "8.1"] },
    { "id": 6, "tasks": ["6.3", "6.5", "8.2", "7.1", "7.3"] },
    { "id": 7, "tasks": ["7.2", "10.1", "10.2", "10.3"] },
    { "id": 8, "tasks": ["11.1"] },
    { "id": 9, "tasks": ["11.2", "11.3"] }
  ]
}
```
