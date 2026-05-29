# Firestore Security Rules — Audited (Phase 2-E)

_Last audited: May 2026 against `lib/core/firebase/firestore_paths.dart`_

---

## Production rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ── User-scoped app data ─────────────────────────────────────────────────
    // Covers all paths under users/{uid}/**: routines, blocks, tasks,
    // timerSessions, taskScores, reminders, routineModes, flowTransitionEvents,
    // accountabilityLogs, goals (+ actions/milestones/checkIns subcollections),
    // analyticsEvents, analyticsStats, circleIds, circleNotifPrefs.
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    // ── Community circles ────────────────────────────────────────────────────

    // Circle document — any authenticated user can read; only members can write.
    // (Membership is enforced at the application layer via CircleRepository.)
    match /circles/{circleId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && exists(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid));
    }

    // Members sub-collection — anyone can read; each user can only write their own doc.
    match /circles/{circleId}/members/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Messages — authenticated circle members only.
    match /circles/{circleId}/messages/{msgId} {
      allow read: if request.auth != null
                  && exists(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid));
      allow create: if request.auth != null
                    && exists(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid))
                    && request.resource.data.authorId == request.auth.uid;
      allow update, delete: if false; // messages are immutable once sent
    }

    // Activity feed — authenticated circle members only; append-only.
    match /circles/{circleId}/activityFeed/{entryId} {
      allow read: if request.auth != null
                  && exists(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid));
      allow create: if request.auth != null
                    && exists(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid));
      allow update, delete: if false; // feed entries are immutable
    }

    // Weekly commitments, challenges, votes, removal votes, AI pulse — members only.
    match /circles/{circleId}/weeklyCommitments/{docId} {
      allow read, write: if request.auth != null
                         && exists(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid));
    }
    match /circles/{circleId}/challenges/{docId} {
      allow read, write: if request.auth != null
                         && exists(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid));
    }
    match /circles/{circleId}/challenges/{challengeId}/votes/{voteId} {
      allow read: if request.auth != null
                  && exists(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid));
      allow write: if request.auth != null
                   && request.auth.uid == voteId; // one vote per user (doc id == uid)
    }
    match /circles/{circleId}/removalVotes/{docId} {
      allow read, write: if request.auth != null
                         && exists(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid));
    }
    match /circles/{circleId}/aiPulse/{docId} {
      allow read: if request.auth != null
                  && exists(/databases/$(database)/documents/circles/$(circleId)/members/$(request.auth.uid));
      allow write: if false; // written by Cloud Functions only
    }
  }
}
```

---

## Path audit table

| Firestore path | Who can read | Who can write | Rule reference |
|---|---|---|---|
| `users/{uid}/**` | `auth.uid == uid` | `auth.uid == uid` | User-scoped catch-all |
| `circles/{circleId}` | Any signed-in user | Verified member | circles rule |
| `circles/{circleId}/members/{userId}` | Any signed-in user | `auth.uid == userId` only | members rule |
| `circles/{circleId}/messages/{msgId}` | Verified member | Verified member (create only; authorId must match) | messages rule |
| `circles/{circleId}/activityFeed/{entryId}` | Verified member | Verified member (create only) | activityFeed rule |
| `circles/{circleId}/weeklyCommitments/**` | Verified member | Verified member | weeklyCommitments rule |
| `circles/{circleId}/challenges/**` | Verified member | Verified member | challenges rule |
| `circles/{circleId}/challenges/{id}/votes/{voteId}` | Verified member | `voteId == auth.uid` | votes rule |
| `circles/{circleId}/removalVotes/**` | Verified member | Verified member | removalVotes rule |
| `circles/{circleId}/aiPulse/**` | Verified member | Cloud Functions only | aiPulse rule |
| `users/{uid}/circleIds/**` | `auth.uid == uid` | `auth.uid == uid` | User-scoped catch-all |
| `users/{uid}/circleNotifPrefs/**` | `auth.uid == uid` | `auth.uid == uid` | User-scoped catch-all |

---

## Account deletion — orphan cleanup

When a user deletes their account, the following Firestore data is **not automatically removed** and requires a Cloud Function or manual script:

| Orphaned path | Action |
|---|---|
| `users/{uid}/**` | Delete all user-scoped collections via a recursive delete Cloud Function triggered by `auth.user().onDelete()` |
| `circles/{circleId}/members/{uid}` | Remove the member doc and, if the user was the last member, delete the circle |
| `circles/{circleId}/messages/**` where `authorId == uid` | Optionally anonymise (replace display name with "Deleted user") or leave |
| `circles/{circleId}/activityFeed/**` where authored by uid | Same as above |
| `circles/{circleId}/challenges/**` entries referencing the uid | Handled by circle admin on next access |

**Recommended Cloud Function:** `functions/src/onUserDeleted.ts` — use the Firebase Admin SDK's
`firestore.recursiveDelete()` on `users/{uid}` and membership cleanup on all circles the user belonged to.

---

## Notes

- Anonymous sessions produce a real Firebase uid. The same user-scoped rules apply.
- When an anonymous user links their account (Phase C), the uid is **unchanged** — no data migration required.
- The "Continue as guest" flow (`kRequireRegisteredAuth = false`) still signs in anonymously, so all rules apply equally.
- Rules are **not** a substitute for application-layer membership checks in `CircleRepository`.
