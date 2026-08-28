# Requirements Document

## Introduction

Feature de galería de cámaras para el panel IoT de jitomates cherry. Integra los endpoints REST del backend de cámaras para permitir al usuario ver una galería de fotos capturadas, ver fotos individuales a tamaño completo, disparar capturas bajo demanda, eliminar fotos (individual y en lote), ver streaming MJPEG en vivo, y filtrar fotos por dispositivo y rango de fecha. Sigue la arquitectura existente: Repository + DataSource con Riverpod, go_router y dio.

## Glossary

- **Photo**: Registro de una foto capturada por una cámara, con metadatos (id, device_id, filename, tamaño, timestamp).
- **CameraDevice**: Dispositivo IoT de tipo "camera" que puede capturar fotos y transmitir streaming MJPEG.
- **CameraRepository**: Repositorio abstracto responsable de las operaciones de cámara: listar fotos, obtener metadatos, capturar, eliminar, y obtener URLs de streaming/descarga.
- **CameraDataSource**: Contrato abstracto del datasource que comunica con los endpoints `/cameras` del backend.
- **PhotoGalleryPage**: Página de UI en la ruta `/camaras` que muestra una cuadrícula de fotos con filtros y paginación.
- **PhotoViewerPage**: Página de UI en la ruta `/camaras/foto/:id` que muestra una foto a tamaño completo.
- **LiveStreamPage**: Página de UI en la ruta `/camaras/stream/:device_id` que muestra el streaming MJPEG en vivo de una cámara.
- **PhotoFilter**: Conjunto de parámetros opcionales para filtrar fotos: device_id, from, to.
- **BatchDeleteResult**: Resultado de una operación de eliminación en lote: cantidad eliminada y IDs no encontrados.
- **PaginatedResponse**: Estructura genérica reutilizada de la feature readings-and-alerts que encapsula items con metadatos de paginación (total, limit, offset).

## Requirements

### Requirement 1: Photo Entity and DTO

**User Story:** As a developer, I want a domain entity and DTO that model the photo metadata response from the backend, so that the camera feature has a proper domain representation.

#### Acceptance Criteria

1. THE Photo entity SHALL contain the fields: id (String), deviceId (String), filename (String), filepath (String), sizeBytes (int), contentType (String), capturedAt (DateTime), and createdAt (DateTime).
2. THE PhotoDto SHALL parse a JSON object matching the `PhotoMetadataResponseSchema` into a PhotoDto instance, mapping snake_case keys (id, device_id, filename, filepath, size_bytes, content_type, captured_at, created_at) to camelCase Dart fields, storing datetime values as String in the DTO.
3. THE PhotoDto SHALL convert to a Photo domain entity via a `toEntity()` method, parsing the captured_at and created_at String fields into DateTime instances.
4. THE PhotoDto SHALL serialize back to a JSON map via a `toJson()` method producing the same snake_case keys as the backend schema.
5. FOR ALL valid PhotoDto instances, calling `toJson()` and then `PhotoDto.fromJson()` on the result SHALL produce a PhotoDto with identical field values (round-trip serialization property).
6. IF the JSON object passed to `PhotoDto.fromJson()` is missing a required field or contains a value of incorrect type, THEN the PhotoDto SHALL throw a deserialization error.

### Requirement 2: BatchDeleteResult Model

**User Story:** As a developer, I want a model that represents the result of a batch delete operation, so that the UI can report how many photos were deleted and which IDs were not found.

#### Acceptance Criteria

1. THE BatchDeleteResult entity SHALL contain the fields: deletedCount (int, non-negative, maximum 50) and notFoundIds (List of String, each element a valid UUID, maximum 50 elements).
2. WHEN a valid JSON object with fields `deleted_count` (int) and `not_found_ids` (uuid array) is provided, THE BatchDeleteResultDto SHALL parse it into a BatchDeleteResultDto instance mapping `deleted_count` to deletedCount and `not_found_ids` to notFoundIds.
3. IF the JSON object is missing required fields or contains values of incorrect types, THEN THE BatchDeleteResultDto factory SHALL throw a FormatException indicating the parsing failure reason.
4. THE BatchDeleteResultDto SHALL convert to a BatchDeleteResult domain entity via a `toEntity()` method, preserving all field values.

### Requirement 3: Camera DataSource Contract and Backend Implementation

**User Story:** As a developer, I want an abstract datasource contract and a REST implementation for camera operations, so that the camera data layer is decoupled from the HTTP client.

#### Acceptance Criteria

1. THE CameraDataSource contract SHALL define a method `fetchPhotos` that accepts optional filters (deviceId, from, to) and pagination params (limit, offset) and returns a PaginatedResponse of PhotoDto.
2. THE CameraDataSource contract SHALL define a method `fetchPhotoMetadata` that accepts a photoId (String) and returns a single PhotoDto.
3. THE CameraDataSource contract SHALL define a method `getPhotoDownloadUrl` that accepts a photoId (String) and returns the full URL (String) for downloading the photo binary.
4. THE CameraDataSource contract SHALL define a method `capturePhoto` that accepts a deviceId (String) and returns a PhotoDto of the newly captured photo.
5. THE CameraDataSource contract SHALL define a method `deletePhoto` that accepts a photoId (String) and returns void.
6. THE CameraDataSource contract SHALL define a method `deletePhotos` that accepts a list of photoIds (1 to 50) and returns a BatchDeleteResultDto.
7. THE CameraDataSource contract SHALL define a method `getStreamUrl` that accepts a deviceId (String) and returns the full URL (String) for the MJPEG stream.
8. WHEN `fetchPhotos` is called, THE CameraDataSourceBackend implementation SHALL send a GET request to `/cameras/photos` with the provided query parameters using the authenticated Dio instance, serializing `from` and `to` as ISO 8601 strings.
9. WHEN `fetchPhotoMetadata` is called, THE CameraDataSourceBackend implementation SHALL send a GET request to `/cameras/photos/{photo_id}` using the authenticated Dio instance.
10. WHEN `getPhotoDownloadUrl` is called, THE CameraDataSourceBackend implementation SHALL construct the full URL by combining the base API URL with `/cameras/photos/{photo_id}/file` without making a network request.
11. WHEN `capturePhoto` is called, THE CameraDataSourceBackend implementation SHALL send a POST request to `/cameras/{device_id}/capture` using the authenticated Dio instance.
12. WHEN `deletePhoto` is called, THE CameraDataSourceBackend implementation SHALL send a DELETE request to `/cameras/photos/{photo_id}` using the authenticated Dio instance and expect a 204 response.
13. WHEN `deletePhotos` is called, THE CameraDataSourceBackend implementation SHALL send a DELETE request to `/cameras/photos` with the photo_ids in the request body using the authenticated Dio instance.
14. WHEN `getStreamUrl` is called, THE CameraDataSourceBackend implementation SHALL construct the full URL by combining the base API URL with `/cameras/{device_id}/stream` without making a network request.
15. IF the backend responds with a 404 status, THEN THE CameraDataSourceBackend SHALL throw a NotFoundFailure.
16. IF the backend responds with a network error, THEN THE CameraDataSourceBackend SHALL throw a NetworkFailure.
17. IF `deletePhotos` is called with an empty list or a list exceeding 50 items, THEN THE CameraDataSourceBackend SHALL throw an ArgumentError without making a network request.

### Requirement 4: Camera Repository

**User Story:** As a developer, I want an abstract CameraRepository and its implementation, so that the presentation layer can perform camera operations without knowing about HTTP details.

#### Acceptance Criteria

1. THE CameraRepository contract SHALL define a method `getPhotos` that accepts optional filters (deviceId, from, to) and pagination params (limit, offset) and returns a PaginatedResponse of Photo entities.
2. THE CameraRepository contract SHALL define a method `getPhotoMetadata` that accepts a photoId (String) and returns a Photo entity.
3. THE CameraRepository contract SHALL define a method `getPhotoDownloadUrl` that accepts a photoId (String) and returns the full URL (String) for downloading the photo binary.
4. THE CameraRepository contract SHALL define a method `capturePhoto` that accepts a deviceId (String) and returns the Photo entity of the newly captured photo.
5. THE CameraRepository contract SHALL define a method `deletePhoto` that accepts a photoId (String) and returns void.
6. THE CameraRepository contract SHALL define a method `deletePhotos` that accepts a list of photoIds (1 to 50 items) and returns a BatchDeleteResult entity.
7. THE CameraRepository contract SHALL define a method `getStreamUrl` that accepts a deviceId (String) and returns the full URL (String) for the MJPEG stream.
8. WHEN a method that returns a Photo or BatchDeleteResult is called, THE CameraRepositoryImpl SHALL delegate to the corresponding CameraDataSource method and map the returned DTO to the domain entity via its `toEntity()` method.
9. WHEN a method that returns a URL String (getPhotoDownloadUrl, getStreamUrl) is called, THE CameraRepositoryImpl SHALL delegate to the corresponding CameraDataSource method and return the String value directly.
10. IF the CameraDataSource throws a Failure (NetworkFailure, NotFoundFailure), THEN THE CameraRepositoryImpl SHALL propagate the Failure to the caller without wrapping or transforming it.

### Requirement 5: Photo Gallery Page with Grid and Filters

**User Story:** As a user, I want to see a grid of captured photos with filters, so that I can browse historical captures of my plants filtered by camera and date.

#### Acceptance Criteria

1. WHEN the user navigates to `/camaras`, THE PhotoGalleryPage SHALL display photos in a responsive grid layout showing thumbnail previews, using 2 columns on viewports narrower than 600px, 3 columns between 600px and 1024px, and 4 columns on viewports wider than 1024px.
2. THE PhotoGalleryPage SHALL display filter controls at the top for: camera device selection (dropdown with an "All cameras" default option) and date range (from/to date pickers, both initially empty indicating no date filter applied).
3. WHEN the user applies a filter, THE PhotoGalleryPage SHALL reload the photos from offset 0 using the selected filter values.
4. WHILE photos are loading, THE PhotoGalleryPage SHALL display a loading indicator.
5. IF the photos request fails, THEN THE PhotoGalleryPage SHALL display an error message with a retry button that re-sends the last request with the same filter and pagination parameters.
6. THE PhotoGalleryPage SHALL support pagination via a "Load more" button displayed at the bottom of the grid, fetching the next batch of 20 photos per request.
7. WHEN the total number of photos returned by the API exceeds the current offset plus limit, THE PhotoGalleryPage SHALL display the "Load more" button; otherwise, the button SHALL be hidden.
8. THE PhotoGalleryPage SHALL display each photo thumbnail with the captured_at timestamp formatted as "dd/MM/yyyy HH:mm" in the device's local timezone, displayed below the image.
9. WHEN the user taps a photo thumbnail, THE PhotoGalleryPage SHALL navigate to the PhotoViewerPage at `/camaras/foto/:id` for that photo.
10. IF no photos match the current filters, THEN THE PhotoGalleryPage SHALL display an empty-state message indicating that no photos were found for the selected filters.
11. WHEN the page loads initially with no filters applied, THE PhotoGalleryPage SHALL fetch and display the most recent photos across all camera devices, ordered by captured_at descending, starting from offset 0.

### Requirement 6: Photo Viewer Page

**User Story:** As a user, I want to view a captured photo at full size, so that I can inspect the detail of my plants in a specific capture.

#### Acceptance Criteria

1. WHEN the user navigates to `/camaras/foto/:id`, THE PhotoViewerPage SHALL display the full-resolution photo fetched from the download endpoint using the URL from CameraRepository.getPhotoDownloadUrl.
2. THE PhotoViewerPage SHALL display photo metadata below or beside the image: filename, device_id, captured_at (formatted as "dd/MM/yyyy HH:mm"), and file size (formatted in human-readable units: KB or MB).
3. WHILE the photo is loading, THE PhotoViewerPage SHALL display a loading indicator.
4. IF the photo fails to load or the backend returns 404, THEN THE PhotoViewerPage SHALL display an error message with a retry option.
5. THE PhotoViewerPage SHALL provide a delete button that allows the user to delete the current photo.
6. WHEN the user confirms deletion from the PhotoViewerPage, THE PhotoViewerPage SHALL delete the photo and navigate back to the gallery at `/camaras`.
7. THE PhotoViewerPage SHALL provide a back navigation control that returns the user to the PhotoGalleryPage.

### Requirement 7: On-Demand Photo Capture

**User Story:** As a user, I want to trigger a photo capture from a camera device, so that I can get a fresh snapshot of my plants on demand.

#### Acceptance Criteria

1. THE PhotoGalleryPage SHALL display a "Capture" button that allows the user to trigger a photo capture.
2. WHEN the user presses the Capture button, THE PhotoGalleryPage SHALL display a device selection dialog listing available camera devices (if more than one exist) or automatically use the only available camera without prompting.
3. WHEN a capture is triggered, THE system SHALL send a POST request to the backend capture endpoint for the selected device using the CameraRepository.
4. WHILE the capture request is in progress, THE system SHALL display a loading indicator on the Capture button and disable it to prevent duplicate requests.
5. IF the capture request does not complete within 30 seconds, THEN THE system SHALL abort the request, re-enable the Capture button, and display an error notification indicating a timeout.
6. WHEN the capture succeeds, THE system SHALL prepend the newly captured photo to the gallery grid and display a success notification that auto-dismisses after 4 seconds.
7. IF the capture request fails, THEN THE system SHALL re-enable the Capture button and display an error notification with the failure reason that auto-dismisses after 4 seconds.
8. IF no camera devices are available when the user presses the Capture button, THEN THE system SHALL display an informational message indicating that no cameras are connected and SHALL NOT send a capture request.

### Requirement 8: Single Photo Deletion

**User Story:** As a user, I want to delete a single photo, so that I can remove unwanted captures from the gallery.

#### Acceptance Criteria

1. WHEN the user requests to delete a photo from the gallery grid or the PhotoViewerPage, THE system SHALL display a confirmation dialog that identifies the photo and presents confirm and cancel actions.
2. IF the user cancels the confirmation dialog, THEN THE system SHALL dismiss the dialog and take no further action.
3. WHEN the user confirms deletion, THE system SHALL send a delete request to the backend for the specified photo and disable the delete control to prevent duplicate submissions until the request completes.
4. WHEN the deletion succeeds, THE system SHALL remove the photo from the gallery view and display a success notification.
5. IF the deletion request fails, THEN THE system SHALL re-enable the delete control and display an error notification with the failure reason.

### Requirement 9: Batch Photo Deletion

**User Story:** As a user, I want to select and delete multiple photos at once, so that I can efficiently clean up old or unwanted captures.

#### Acceptance Criteria

1. THE PhotoGalleryPage SHALL provide a selection mode that the user can enter via a long-press on any photo or a dedicated "Select" button, and exit via a "Cancel" button displayed in selection mode.
2. WHILE in selection mode, THE PhotoGalleryPage SHALL display a visual indicator (checkbox or highlight) on each selected photo.
3. WHILE in selection mode, THE PhotoGalleryPage SHALL display the count of selected photos and a "Delete Selected" action button that is disabled when the count is 0.
4. THE system SHALL enforce a maximum of 50 photos per batch delete operation.
5. IF the user attempts to select more than 50 photos, THEN THE system SHALL prevent further selection and display a message indicating the 50-photo limit has been reached.
6. WHEN the user presses "Delete Selected", THE system SHALL display a confirmation dialog indicating the number of photos to be deleted before proceeding.
7. WHEN the user confirms batch deletion, THE system SHALL send a batch delete request with the selected photo IDs.
8. WHEN the batch deletion succeeds, THE system SHALL remove the deleted photos from the gallery, exit selection mode, and display a success notification showing the deleted count and listing any IDs that were not found.
9. IF the batch deletion request fails, THEN THE system SHALL display an error notification with the failure reason and preserve the current selection so the user can retry.

### Requirement 10: MJPEG Live Stream Page

**User Story:** As a user, I want to see a live video stream from my camera, so that I can monitor my plants in real time.

#### Acceptance Criteria

1. WHEN the user navigates to `/camaras/stream/:device_id`, THE LiveStreamPage SHALL display the MJPEG stream from the specified camera device by rendering an HTML `<img>` element (via HtmlElementView) whose `src` is the stream URL obtained from CameraRepository.getStreamUrl.
2. THE LiveStreamPage SHALL include the JWT authorization token in the stream URL by appending it as a `token` query parameter, so that the `<img>` element can authenticate the request without custom headers.
3. WHILE the stream `<img>` element is loading frames successfully (no error event fired), THE LiveStreamPage SHALL display the device identifier and a visible "Live" text indicator adjacent to the stream.
4. WHILE the stream URL is being constructed or the `<img>` element has not yet fired a load or error event, THE LiveStreamPage SHALL display a loading indicator in place of the stream.
5. IF the stream `<img>` element fires an error event or fails to begin loading within 10 seconds of navigation, THEN THE LiveStreamPage SHALL hide the stream image, display an error message indicating the stream is unavailable, and display a retry button that reloads the stream by re-setting the `<img>` element `src` attribute.
6. THE PhotoGalleryPage SHALL provide a navigation control (button or link) to the LiveStreamPage for each available camera device listed in cameraDevicesProvider.
7. THE LiveStreamPage SHALL provide a back navigation control that returns the user to the PhotoGalleryPage.

### Requirement 11: Riverpod Providers for Camera Feature

**User Story:** As a developer, I want Riverpod providers that wire the camera infrastructure and expose state to the UI, so that the camera pages can consume data reactively.

#### Acceptance Criteria

1. THE cameraDataSourceProvider SHALL provide a CameraDataSourceBackend instance using the authenticatedDioProvider.
2. THE cameraRepositoryProvider SHALL provide a CameraRepositoryImpl instance using the cameraDataSourceProvider.
3. THE photoGalleryControllerProvider SHALL be an AsyncNotifierProvider that exposes an AsyncValue containing the paginated photo list state (items, total, offset, limit of 20 items per page, and active filters), and SHALL expose methods to apply filters (resetting offset to 0), load more pages (appending items and advancing offset), capture a photo, and delete a photo.
4. WHEN a photo is successfully captured or deleted via the photoGalleryControllerProvider, THE photoGalleryControllerProvider SHALL invalidate itself and reload the current gallery state from the repository so the UI reflects the change.
5. THE photoViewerControllerProvider SHALL be an AsyncNotifierProvider.family parameterized by photo ID, using autoDispose, that exposes an AsyncValue containing the single photo's data and SHALL expose a method to delete the displayed photo.
6. WHEN a photo is successfully deleted via the photoViewerControllerProvider, THE photoViewerControllerProvider SHALL return a success indicator so the UI can navigate back to the gallery.
7. THE cameraDevicesProvider SHALL be a Provider that filters the list of devices from the deviceRepositoryProvider to expose only devices whose type is camera, for use in device selection controls and stream navigation.

### Requirement 12: Go Router Integration

**User Story:** As a developer, I want routes registered for the camera gallery, photo viewer, and live stream pages, so that users can navigate to them via the side menu and deep links.

#### Acceptance Criteria

1. THE router SHALL register the route `/camaras` as a child of the existing ShellRoute, pointing to PhotoGalleryPage.
2. THE router SHALL register the route `/camaras/foto/:id` as a child of the existing ShellRoute, pointing to PhotoViewerPage, where `:id` is a non-empty path parameter representing the photo identifier.
3. THE router SHALL register the route `/camaras/stream/:deviceId` as a child of the existing ShellRoute, pointing to LiveStreamPage, where `:deviceId` is a non-empty path parameter representing the device identifier.
4. THE side navigation menu SHALL include a "Cámaras" entry in the `kNavItems` list that navigates to `/camaras`.
5. IF an unauthenticated user attempts to access any route starting with `/camaras`, THEN THE router SHALL redirect to the login page.
6. THE `AppRoutes` class SHALL define string constants for `/camaras`, `/camaras/foto/:id`, and `/camaras/stream/:deviceId`.
