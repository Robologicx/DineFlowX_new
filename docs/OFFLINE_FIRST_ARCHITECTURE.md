# Offline-First Architecture Report

## Goal
Convert app from Firestore-dependent data access to local-first architecture where:
- writes are immediate locally
- reads are served from local storage first
- cloud is sync/backup

## Firestore dependency map

### Models
- business, category, menu, product, order, table, room, expense, user, role, permission, sales

### Repositories (write points)
- buisness_repository.dart
- category_repository.dart
- menu_repository.dart
- product_repository.dart
- order_repository.dart
- table_repository.dart
- room_repository.dart
- expense_repository.dart
- user_repository.dart
- role_repository.dart
- permission_repository.dart
- sales_repository.dart
- auth_repository.dart

### Services
- business, category, menu, product, order, table, room, expense, user, role, permission, sales
- media upload queues and printer services

## Implemented in this migration wave

### Local-first infrastructure
- Isar schemas and DB bootstrap added:
  - core/local/isar_collections.dart
  - core/local/isar_database_service.dart
- connectivity listener added:
  - core/sync/connectivity_service.dart
- Firestore->Isar migration service scaffold added:
  - core/sync/firestore_to_isar_migration_service.dart
- local cache read helper added:
  - core/local/offline_local_read_service.dart

### Sync queue
- Existing offline Firestore write queue converted to Isar-backed queue/cache:
  - core/utils/offline_firestore_write_queue_service.dart
- supports set/merge/delete queue operations
- auto-sync on connectivity return + periodic retry

### UI status
- global online/offline/sync banner added:
  - presentation/common_widgets/offline_sync_status_banner.dart
- mounted in both app shells via main.dart and main_client.dart

### Repositories migrated to local-first/queued writes
- business
- category
- menu
- product
- order
- table
- room
- expense

These repositories now:
- write/delete through setOrQueue/deleteOrQueue
- read local cache first for key get/list operations

## Pending for complete project-wide conversion
- full local-first conversion of remaining repositories:
  - user, role, permission, sales, auth-related writes
- local stream-first replacement for all remaining Firestore stream consumers
- one-time migration trigger orchestration per selected business/branch
- conflict resolution policy and dedup safeguards for all entity types
- end-to-end sync audit dashboard (retry, failures, lag)

## Sync safety notes
- unique document path is used as sync identity to prevent duplicate writes
- queue operations are idempotent using merge writes where possible
- delete operations are queued and replayed when online

## Performance notes
- local cache is indexed by business/branch/collection/document keys
- reads avoid network latency when cached data exists
- writes are non-blocking for offline UI continuity
