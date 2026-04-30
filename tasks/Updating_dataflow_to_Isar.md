You are refactoring a Flutter app that uses Riverpod, Firestore, and a SyncService. The current architecture is “Firestore-first”, which causes UI delays because data is fetched from the network before rendering.

Your goal is to migrate the app to a local-first architecture using Isar as the source of truth, while keeping Firestore as a background sync layer.

Context
Riverpod is used for state management
Repositories currently read/write directly to Firestore
SyncService already exists and supports enqueueUpsert / offline queue
Reminder system and execution system depend on task data
There is a FutureProvider (todayAllTasksRowsProvider) that loads tasks from Firestore
Objectives

Refactor the architecture so that:

All reads come from Isar (local DB)
All writes go to Isar first, then enqueue sync to Firestore
UI updates instantly from local data (no network dependency)
Firestore is only used for background sync (push + pull)
Required Changes
1. Introduce Isar as Primary Storage
Define Isar collections for:
Task
Routine
Block
PlannedTaskRow (or equivalent flattened structure if needed)
Add an OfflineStore or LocalDatabase service to manage Isar instance
2. Refactor PlanningRepository

Update repository methods:

Before:
getTasks() → Firestore
upsertTask() → Firestore
After:
getTasks() → Isar (reactive query if possible)
upsertTask():
Write to Isar immediately
Call SyncService.enqueueUpsert(...)

Ensure no direct Firestore reads are used in UI-facing methods.

3. Replace FutureProvider with StreamProvider

Refactor:

todayAllTasksRowsProvider (FutureProvider)

Into:

StreamProvider<List<PlannedTaskRow>>

This provider should:

Watch Isar for changes
Emit updates reactively when local data changes
4. Implement Background Sync (Pull)

Extend SyncService:

Add method: syncFromRemote()
Fetch latest data from Firestore
Merge into Isar (upsert locally)
Avoid duplicates or overwriting newer local data
Call this during:
App startup (non-blocking)
Connectivity restored
5. Ensure Write Consistency

For every write (task, reminder, session, score):

Always:
Write to Isar
Enqueue sync
Never:
Write directly to Firestore from UI or providers
6. Keep Existing Features Working

Make sure these flows still work:

Notification tap → task lookup → executionController
Reminder scheduling (ReminderSyncService)
Timer session persistence
Scoring flow

If any of these depend on Firestore reads, refactor them to use Isar instead.

7. Avoid Common Pitfalls
Do NOT re-fetch from Firestore after writing to Isar
Do NOT block UI on sync completion
Ensure conflict resolution strategy (last-write-wins is acceptable for now)
Ensure IDs remain consistent across Isar and Firestore
Deliverables
Updated PlanningRepository using Isar
New or updated Isar schema models
Refactored providers (StreamProvider instead of FutureProvider)
SyncService updated with pull capability
Example of one fully migrated flow (task creation → UI update → background sync)
Notes
Keep code clean and modular
Follow Riverpod best practices
Prefer reactive streams over manual refresh/invalidate
Do not break existing architecture unless necessary — adapt it

Start by refactoring the PlanningRepository and todayAllTasksRowsProvider first, then proceed to sync logic.