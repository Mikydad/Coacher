# Firestore Rules (Option C: Anonymous Auth)

Use these Firestore rules in Firebase Console to allow only authenticated users to access their own user-scoped data.

```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User-scoped app data.
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## Notes
- The app signs in with Firebase Anonymous Auth on startup.
- Data paths are now under `users/{request.auth.uid}/...`.
- **Goals** live at `users/{uid}/goals/{goalId}` with subcollections `actions`, `milestones`, `checkIns`. The rule above already covers them via `{document=**}`.
- If you need to debug quickly, do not use wide-open rules in production.
