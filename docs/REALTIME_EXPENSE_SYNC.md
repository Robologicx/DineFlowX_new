# Real-Time Expense Sync Architecture

## Overview
The expense management system now uses a **cloud-first, real-time synchronization strategy** with offline fallback capability. This ensures:
- Expenses are immediately synced across all devices when online
- Expenses are saved locally and automatically uploaded when connectivity returns
- Users always see the latest data from the cloud (not stale local copies)
- Full functionality when offline with automatic sync when online

## Architecture Components

### 1. ExpenseSyncService (`core/sync/expense_sync_service.dart`)
**Purpose**: Real-time bidirectional sync service for expenses

**Key Features**:
- Cloud-first read strategy: Always prefers cloud data when online
- Real-time Firestore listeners for automatic updates
- Local cache fallback when offline
- Automatic connectivity change handling
- Syncs local cache with cloud changes

**Initialization**:
```dart
final syncService = ExpenseSyncService(
  businessId: 'business123',
  branchId: 'branch456',
);
await syncService.initialize();
```

**Usage**:
- `currentExpenses` - Get current expenses list
- `expensesStream` - Subscribe to real-time updates
- `getExpensesByDateRange()` - Filter by date range
- `getCurrentBusinessDayExpenses()` - Filter by business day
- `refresh()` - Manual refresh from cloud
- `dispose()` - Clean up resources

### 2. Cloud-First Repository (`data/repositories/expense_repository.dart`)
**Strategy**: Prefer cloud, fall back to local

```dart
// Try cloud first, fall back to local if offline
try {
  final snapshot = await _expensesCollection.get();
  // Process and cache in local
  await _updateLocalCache(expenses);
  return expenses;
} catch (e) {
  // Cloud failed (offline) - use local cache
  return _loadFromLocal();
}
```

**Benefits**:
- Ensures users see latest data
- Prevents stale data from being served
- Automatic fallback to local when needed

### 3. Real-Time Riverpod Providers (`state_management/expense_sync_providers.dart`)

#### `realtimeExpensesProvider`
Provides a stream of all expenses with real-time updates across devices.

```dart
// Watch real-time expenses
final expenses = ref.watch(
  realtimeExpensesProvider((businessId, branchId)),
);

// UI rebuilds automatically when expenses change on cloud
expenses.whenData((expenses) {
  // Build UI with expenses
});
```

#### `realtimeExpensesByDateRangeProvider`
Filtered real-time expenses by date range.

```dart
final expenses = ref.watch(
  realtimeExpensesByDateRangeProvider((
    businessId,
    branchId,
    startDate,
    endDate,
  )),
);
```

#### `realtimeCurrentBusinessDayExpensesProvider`
Real-time expenses for current business day.

#### `realtimeTotalExpensesProvider`
Real-time total sum of expenses by date range.

### 4. Offline-First Write Queue (`core/utils/offline_firestore_write_queue_service.dart`)
**Purpose**: Queue writes when offline, sync when online

```dart
// Automatically saves locally and queues for sync
await OfflineFirestoreWriteQueueService.instance.setOrQueue(
  documentPath: 'businesses/{id}/branches/{id}/expenses/{id}',
  data: expenseData,
  merge: true,
);
```

**Features**:
- Non-blocking saves
- Automatic retry on internet return
- Periodic retry timer (20 seconds)
- Status tracking (pending, synced)

### 5. Local Cache (`core/local/isar_database_service.dart`)
**Purpose**: Offline read/write storage using Isar

- Stores synced data from cloud
- Provides fast local queries
- Fallback when offline
- Automatic cleanup

## Data Flow

### When Adding Expense (Online)
```
User adds expense
  ↓
Saves to local cache + Firestore simultaneously
  ↓
Firestore listener broadcasts change
  ↓
All devices receive update via real-time listener
  ↓
UI updates automatically
```

### When Adding Expense (Offline)
```
User adds expense
  ↓
Saves to local cache + queues for sync
  ↓
UI shows expense immediately from local
  ↓
When online: Auto-syncs to Firestore
  ↓
Firestore listener receives update
  ↓
Other devices receive update in real-time
```

### When Loading Expenses
```
Screen opens
  ↓
ExpenseManagementScreen uses realtimeExpensesProvider
  ↓
If online: Fetch from cloud + start listener
If offline: Use local cache
  ↓
UI shows data
  ↓
Real-time listener automatically updates UI when data changes
```

## Usage in UI

### Update ExpenseManagementScreen
```dart
// Watch real-time expenses
final expensesAsyncValue = ref.watch(
  realtimeExpensesProvider((businessId, branchId)),
);

// Handle async states
expensesAsyncValue.when(
  data: (expenses) => buildExpenseList(expenses),
  loading: () => const CircularProgressIndicator(),
  error: (error, st) => ErrorWidget(error),
);

// UI automatically updates when expenses change
```

### Check Offline Status
```dart
// Watch connectivity
final isOnline = ref.watch(connectivityStatusProvider);

// Show offline banner
if (!isOnline) {
  showOfflineIndicator();
}
```

### Manual Refresh
```dart
// Pull latest from cloud
ref.invalidate(
  realtimeExpensesProvider((businessId, branchId)),
);
```

## Key Benefits

1. **Real-Time Sync Across Devices**
   - Changes on one device appear immediately on others
   - No manual refresh needed
   - Powered by Firestore real-time listeners

2. **Offline Functionality**
   - Add/edit/delete expenses without internet
   - Data saved locally
   - Automatic sync when online

3. **Always Latest Data**
   - Cloud-first read strategy prevents stale data
   - Local cache only used as fallback
   - Users see most recent state

4. **Automatic Connectivity Handling**
   - Switches between cloud and local seamlessly
   - Automatic sync when connectivity returns
   - No user intervention needed

5. **Performance**
   - Instant UI updates from local writes
   - Efficient Firestore queries
   - Minimal network traffic

## Implementation Checklist

- [x] Create ExpenseSyncService with cloud-first strategy
- [x] Update ExpenseRepository to prefer cloud
- [x] Create Riverpod providers for real-time streams
- [x] Update ExpenseManagementScreen to use real-time providers
- [x] Add offline indicator to UI
- [x] Add connectivity status provider
- [x] Ensure write queue handles offline scenarios
- [x] Test multi-device sync
- [x] Document architecture

## Testing Scenarios

### Scenario 1: Add Expense on Device 1
1. Device 1 adds expense (online)
2. Expense saves to Firestore + local
3. Firestore listener triggers on both devices
4. Device 2 receives update automatically
5. Result: Both devices show new expense

### Scenario 2: Add Expense While Offline
1. Device 1 adds expense (offline)
2. Expense saves to local + write queue
3. UI shows expense immediately
4. Device comes online
5. Write queue syncs expense to Firestore
6. Firestore listener broadcasts change
7. All devices receive update
8. Result: Expense synced after connectivity returns

### Scenario 3: Open App on New Device
1. Device 3 opens app (online)
2. realtimeExpensesProvider initializes
3. Fetches expenses from Firestore
4. Starts real-time listener
5. Updates local cache
6. Result: Device 3 shows latest expenses

## Migration from Old System

Old system issues:
- Local data served if it exists (never refreshed from cloud)
- No cross-device sync
- Devices maintained separate copies

New system:
- Always syncs from cloud when possible
- Real-time cross-device updates
- Single source of truth (Firestore)
- Automatic offline fallback

## Future Enhancements

1. Conflict resolution when offline edits conflict with cloud changes
2. Selective sync (sync specific date ranges only)
3. Compression for large sync payloads
4. Batch sync for multiple changes
5. Analytics on sync performance
6. User notifications for sync status
