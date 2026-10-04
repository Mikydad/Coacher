# Alarm Mode — a reminder that rings until you stop it

**Status:** V1 built 2026-09-13 on `feat/alarm-mode`; main (v1.0.0-rc1) merged in and two lifecycle bugs fixed 2026-10-04. Not yet verified on a device.
**Owner decisions settled (Miko, 2026-09-13):**

| Decision | Value |
|---|---|
| Sleep | alarm rings at sleep **end** only (wake-up); bedtime stays a notification |
| iOS engine | notification floor now (Time Sensitive + bundled sound); AlarmKit (iOS 26+) is the follow-on phase |
| Ring pattern | every 2 min for 10 min (five rings); pierces boundary, Focus Shield, sleep window |
| Stop rules | Stop / Done / tap stops; Snooze quiets 5 min then restarts the five |
| Scope | task reminders only; goals and intentions unchanged |

---

## 1. Problem

A notification is not enough for the moments that must not be missed —
waking up above all. The reminder system is polite by construction (the
interruption boundary, the Focus Shield, the sleep window, the attention
orchestrator's batching and silencing), and for an alarm every one of those
politenesses is a failure.

## 2. Shape

* **Data.** `ReminderConfig.alertMode` (`notification` | `alarm`) and
  `ReminderConfig.alarmOffsetMinutes` (0 = rings at the reminder time; > 0 =
  rings that many minutes later, i.e. at the task's end). Synced like every
  other reminder field. `ReminderOccurrence.alarmStoppedAtMs` records the
  user's Stop so no recompute re-arms a stopped day. No new entity.
* **Editor.** Sleep: a "Wake-up alarm" toggle row in the Sleep extras card,
  subtitle names the sleep-end time, ON by default for new sleep tasks.
  Everything else: a small "Alarm" chip beside the plan-day footnote inside
  the expanded Reminder card; a one-line footnote explains the ring when on.
* **Task rows.** The Tasks hub meta line says "Alarm on" with an alarm bell
  instead of "Reminder on".
* **Delivery.** `AlarmScheduler` (`lib/features/reminders/application/`)
  schedules the five rings straight onto the OS under
  `alarm:<taskId>:<ring>` ids — never through `LadderCompiler` or the
  orchestrator. iOS: `sidepal_alarm.caf` (28 s chime, Time Sensitive,
  category `sidepalAlarm.v1` with Stop / Snooze / Done). Android: channel
  `sidepal_alarms` on the alarm audio stream with `res/raw/sidepal_alarm`.
* **Lifecycle.** Start-anchored (offset 0): any resolution of the day's
  occurrence retires the alarm. End-anchored (Sleep): `completed` keeps it
  (done at bedtime ≠ don't wake me) and so does `expired` (the 30–60 min
  window closes long before the wake-up — 2026-10-04); `rescheduled` and
  `skipped` retire it. Deleting the task cancels rings explicitly
  (`ReminderSyncService.cancelAlarms`). Every path that rebuilds a
  `ReminderConfig` (Coach AI retime, time-block conflict move) carries
  `alertMode` + `alarmOffsetMinutes` through.
* **Runs** first in the recompute graph's notifications step and after
  every reminder save (`rearmLadders` in the sync service).

## 3. Failure story

* Notification permission denied → the same snackbar the reminder toggle
  shows; nothing rings (honest, not silent — the reminder health row still
  reports permission state).
* iOS mute switch → the ring is visual only. Named in the editor footnote's
  spirit and in the decision log; AlarmKit is the fix.
* Time Sensitive entitlement missing from the provisioning profile → iOS
  degrades the level to `active`; Focus modes can hold the ring. Xcode
  refreshes the profile on the next automatic-signing build.
* Lost from the OS queue → not ledgered on purpose; re-armed by the next
  recompute (every app open / resume).

## 4. Out of scope (V1)

Goals and intentions; per-reminder sound choice; Android exact alarms and
full-screen intent (D8 keeps Android parked); AlarmKit.

## 5. Follow-on: AlarmKit (iOS 26+)

A Swift `AlarmKitBridge` behind a MethodChannel: `schedule(id, date, title)`,
`cancel(id)`, authorization request on first alarm save. `AlarmScheduler`
routes to it when `Platform.isIOS && version >= 26`, keeping the
notification rings as the floor below. Needs `NSAlarmKitUsageDescription`.
