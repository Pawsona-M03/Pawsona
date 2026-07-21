# Pawsona — Code Audit

**Date:** 2026-07-22 · **Branch:** `staging` @ `18d0e21` · **Scope:** `Pawsona/` (58 files, ~4,000 LOC) + `PawsonaTests/` (9 files, ~1,400 LOC)

**Compiler ground truth:** clean `xcodebuild` Debug build for `generic/platform=iOS Simulator`, **zero Swift warnings, zero errors**. The only build output was `appintentsmetadataprocessor` noting no AppIntents dependency, which is expected. Every concurrency and deprecation finding below therefore comes from reading, not from a warning list — there is no warning list.

> **Remediation status (2026-07-22, branch `bugfix/code-audit-remediation`).** The Critical
> finding and all eight High findings are fixed, along with most Medium and Low items, across
> nine commits. Test count went from 48 to 71; the build and SwiftLint are both clean.
> **Still open, deliberately:** §5.9 (nil-name sort order — needs a schema decision), §4.2
> (VisionKit document camera — a feature change, not a defect), and §10.6 (localization — the
> largest remaining item, worth planning on its own). Section numbers below are unchanged so
> existing references still resolve.

**Overall:** this is a well-kept codebase. Secrets are handled correctly, models are CloudKit-legal, accessibility has clearly been built in rather than retrofitted, and the vaccine-scan subsystem is genuinely well-tested. The findings concentrate in three places: a **locale-dependent data-loss bug in the dog form**, **eager PDF/JSON generation on the main actor whose output is partly thrown away**, and **shipping push-notification configuration for a feature the app does not have**.

---

## 1. Executive summary

1. **[Critical] Editing a dog silently erases its weight in comma-decimal locales** — §5.1 — `Pawsona/View/Dog/DogFormView.swift:39,224`. Proven: in `id_ID`/`de_DE`, `12.5` formats to `"12,5"`, and `Double("12,5")` is `nil`. Indonesia is this app's primary market.
2. **[High] `aps-environment` and the `remote-notification` background mode ship with no push code at all** — §6.1 — `Pawsona/Pawsona.entitlements:4-5`, `Pawsona/Info.plist:31-34`. App Review rejection risk, and a hardcoded `development` APNs environment.
3. **[High] The dog list renders a full PDF of every dog on every list change and discards it** — §7.1 — `Pawsona/View/Dog/DogListView.swift:16,78-80`. `exportedPDFURL` is written and never read.
4. **[High] `navigationDestination` runs a SwiftData fetch and mutates observable state during view-body evaluation** — §5.2 — `Pawsona/View/Dog/DogListView.swift:42-46`.
5. **[High] AirDrop import is wired only to the Puppy tab and deletes the source file unconditionally** — §5.3, §5.4 — `Pawsona/View/Dog/DogListView.swift:87-89`, `Pawsona/ViewModel/Dog/DogViewModel.swift:154`.
6. **[High] Hardcoded `.black` text and tint break Dark Mode** — §8.1 — `Pawsona/View/Dog/DogFormView.swift:119`, `Pawsona/View/Dog/DogListView.swift:58`. Directly against the project's own accessibility rules.
7. **[High] Fixed 60pt form rows and 17×17pt colour swatches fail Dynamic Type and the 44×44pt hit-target minimum** — §8.2, §8.3 — `Pawsona/View/Dog/DogFormView.swift:68,93,100,122,133,140`.
8. **[High] The detail screen regenerates a PDF *and* JSON-encodes the full-resolution photo on every appearance** — §7.2 — `Pawsona/View/Dog/DogDetailView.swift:86-89`.
9. **[Medium] Two view models keep arrays that nothing reads, refetching the whole store after every mutation** — §7.5, §9.4 — `Pawsona/ViewModel/Vaccine/VaccineViewModel.swift:14,33`.
10. **[Medium] The vaccine form carries a `notes` value with no UI to edit it** — §5.7 — `Pawsona/View/Vaccine/VaccineRecordFormView.swift:22,37,178`.

---

## 2. Quick wins

### 2.1 Delete the write-only `exportedPDFURL` state in the dog list
- **Location:** `Pawsona/View/Dog/DogListView.swift:16,78-80`
- **What:** The property is assigned in a `.task(id:)` and never read anywhere in the file; there is no `ShareLink` on this screen.
- **Why:** Deleting the property also deletes the expensive work in §7.1 — the single highest value-per-minute change in this report.
- **Action:** Remove the `@State` property and the whole `.task(id: viewModel.dogs.map(\.id))` block. Keep `exportDogsToPDF()` on the view model; it is still reachable and worth keeping for a future "export all" affordance.
- **Severity:** Medium

### 2.2 Remove the unused `title` property from the colour swatch
- **Location:** `Pawsona/View/Component/DogColorPickerRow.swift:27-46`
- **What:** A 20-line `private var title` that nothing calls. The live version is `ColorType.accessibilityName` in `DogFormView.swift:286-305`.
- **Why:** Two spellings of the same table invites them to drift apart.
- **Action:** Delete it; see §9.2 for consolidating the survivor onto `ColorType`.
- **Severity:** Low

### 2.3 Remove the no-op selection ring
- **Location:** `Pawsona/View/Component/DogColorPickerRow.swift:19-22`
- **What:** `Circle().stroke(.primary, lineWidth: 0)` — a zero-width stroke draws nothing.
- **Why:** It reads as an intended selection indicator that silently does nothing; selection is currently conveyed by size alone.
- **Action:** Either delete the overlay or give it a real width. Note that size-only selection is also a colour/shape-independence concern for the accessibility pass.
- **Severity:** Low

### 2.4 Drop the pointless `Task` around a synchronous delete
- **Location:** `Pawsona/View/Vaccine/DogVaccinationRecordView.swift:132-136`
- **What:** `deleteSingleVaccineRecord` wraps a fully synchronous `deleteRecord` call in `Task { }`.
- **Why:** It defers the delete by a hop for no reason and makes the call look async when it is not.
- **Action:** Call the view model directly.
- **Severity:** Low

### 2.5 Translate the one Indonesian comment
- **Location:** `Pawsona/View/Vaccine/DogVaccinationRecordView.swift:42`
- **What:** `// Long-press untuk menghapus` in an otherwise all-English codebase.
- **Why:** Consistency for a mixed team; every other comment in the repo is English.
- **Action:** Reword to English.
- **Severity:** Low

### 2.6 `CLAUDE.md` / `AGENTS.md` reference a file that no longer exists
- **Location:** `CLAUDE.md` SwiftData section, `AGENTS.md` (identical copy)
- **What:** Both say "`Item.swift` is leftover Xcode template code — delete it once you're sure nothing references it." There is no `Item.swift` in the repo.
- **Why:** Stale agent instructions cost every agent session a wasted search.
- **Action:** Remove the sentence from both files — they are maintained as duplicates.
- **Severity:** Low

---

## 3. Concurrency

The project builds clean with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_VERSION = 5.0`. Because main-actor-by-default is on, **every type in this codebase without an explicit isolation annotation is main-actor isolated** — including `struct GeminiScanner` and `enum PDFGenerator`. That is the root cause of the two findings below, and it is invisible in the warning list precisely because it is legal.

### 3.1 Image downscale, JPEG encode, and base64 all run on the main actor
- **Location:** `Pawsona/Service/GeminiScanner.swift:148-182` (entry), `:266-274` (`downscale`), `:153` (`jpegData`), `:160` (`base64EncodedString`)
- **What:** `GeminiScanner` is main-actor isolated by default, so `scan(_:)` performs a full-size `UIGraphicsImageRenderer` redraw, a JPEG compression, and a base64 encode of a multi-megabyte camera image before it ever reaches `await URLSession...`.
- **Why:** A 12MP camera image makes this hundreds of milliseconds of main-thread work — a visible hitch right as the scanning spinner appears. The `await` afterwards correctly leaves the actor, so only the preparation is affected.
- **Action:** Mark the pure image-preparation work `nonisolated` and `await` it from `scan`, so it hops off the main actor. `downscale` and the JPEG/base64 step take only a `UIImage` in and `Data` out, so they have no main-actor dependency to lose.
- **Severity:** Medium

### 3.2 PDF rendering runs on the main actor and is never awaited off it
- **Location:** `Pawsona/Service/PDFGenerator.swift:11-34`, called from `Pawsona/ViewModel/Dog/DogViewModel.swift:88-123`
- **What:** `ImageRenderer.render` plus `CGContext` PDF encoding, synchronously on the main actor, for every dog including full-resolution photos.
- **Why:** `ImageRenderer` genuinely must touch SwiftUI on the main actor, so this cannot simply be moved. The real fix is to stop calling it eagerly — see §7.1 and §7.2.
- **Action:** Keep the rendering main-actor, but make it demand-driven. If it stays slow with many dogs, render at a capped image resolution rather than the stored photo size.
- **Severity:** Medium

### 3.3 A failed save still schedules the notification
- **Location:** `Pawsona/ViewModel/Reminder/ReminderFormViewModel.swift:126-134`
- **What:** The `do/catch` around `modelContext.save()` records `errorMessage` and then falls through to `await notificationService.schedule(reminder)` regardless.
- **Why:** If the save failed, the user gets a notification for a reminder that was never persisted — it fires pointing at nothing.
- **Action:** Only schedule on the success path; on failure, surface the error and skip scheduling. The existing `errorMessage` plumbing is already there but no view currently displays it (see §5.10).
- **Severity:** Medium

### 3.4 `CameraPicker.Coordinator` captures the view struct, including its `dismiss`
- **Location:** `Pawsona/Service/CameraPicker.swift:27-42`
- **What:** The coordinator stores `let parent: CameraPicker`, a snapshot of the struct taken at `makeCoordinator()` time, and calls `parent.dismiss()` from the delegate callbacks.
- **Why:** `updateUIViewController` is empty, so the coordinator's copy is never refreshed. `@Environment(\.dismiss)` captured into a stale struct copy is a known source of "dismiss does nothing" bugs. It currently works because the cover is presented once and torn down, but it is fragile.
- **Action:** Pass the binding and an explicit `onFinish` closure to the coordinator instead of the whole struct, or set `context.coordinator.parent = self` in `updateUIViewController`.
- **Severity:** Low

---

## 4. API modernity

### 4.1 Locale-unaware `Double(String)` for user-entered numbers
- **Location:** `Pawsona/View/Dog/DogFormView.swift:222-225`
- **What:** `Double(trimmedWeight)` parses only the C locale. The same file *formats* the value with the locale-aware `.formatted(.number...)` at line 39.
- **Why:** This asymmetry is the mechanism behind §5.1. It is an API-modernity issue with a data-loss consequence.
- **Action:** Parse with the matching modern strategy — `Double(weightText, format: .number)` or a `FloatingPointParseStrategy` — so formatting and parsing use the same locale. Better still, bind the `TextField` with `value:format:` and drop the string round-trip entirely.
- **Severity:** High

### 4.2 `UIImagePickerController` for camera capture
- **Location:** `Pawsona/Service/CameraPicker.swift:12-25`
- **What:** A `UIViewControllerRepresentable` wrapper, with an honest comment acknowledging SwiftUI has no native camera view.
- **Why:** Still supported for camera source on iOS 26, so this is not a bug. But the app photographs *documents* — vaccine booklets — which is exactly what `VisionKit`'s `VNDocumentCameraViewController` is for: it gives edge detection, perspective correction, and multi-page capture for free, and would measurably improve scan accuracy.
- **Action:** Evaluate `VNDocumentCameraViewController` as a replacement. Perspective-corrected input is likely worth more to §1's scan accuracy than any prompt change. Treat as an enhancement, not a defect.
- **Severity:** Medium

### 4.3 `heroHeight` is clamped so its `@ScaledMetric` can never grow
- **Location:** `Pawsona/View/Dog/DogDetailView.swift:20,164-166`
- **What:** `@ScaledMetric(relativeTo: .largeTitle) private var heroHeight = 380` is immediately passed through `min(heroHeight, 380)`.
- **Why:** `@ScaledMetric` scales *up* at larger type sizes, so the `min` pins it at exactly 380 for every size at or above default. The scaling is dead code in the direction it was written for.
- **Action:** Decide the intent. If the hero should not grow, use a plain constant and delete the `@ScaledMetric`. If it should grow but bounded, raise the cap well above 380.
- **Severity:** Low

---

## 5. Bugs / logic errors

### 5.1 Editing a dog silently erases its weight in comma-decimal locales
- **Location:** `Pawsona/View/Dog/DogFormView.swift:38-40` (format), `:222-225` (parse), reaching `Pawsona/ViewModel/Dog/DogViewModel.swift:70`
- **What:** `DogEditView` pre-fills the weight field via `draft.weightKg?.formatted(.number.precision(.fractionLength(1)))`, which is locale-aware and produces `"12,5"` in `id_ID`. `parsedWeightKg` then calls `Double("12,5")`, which returns `nil`. `editDog` assigns that `nil` straight to `dog.weight`.
- **Why:** Open a dog, change nothing but the name, tap Save — the weight is gone, with no error and no warning. **The user has to do nothing wrong to hit this.** Verified by execution: `id_ID` and `de_DE` both format `12.5` as `"12,5"` and both parse it back as `nil`; `en_US` round-trips fine, which is why it has not been noticed. Indonesia is this app's primary market — the vaccine books in `PawsonaTests/Fixtures` are Indonesian.
- **Action:** Parse with the same locale-aware style used to format (§4.1). Add a regression test that round-trips a weight through `DogDraft` under a comma-decimal locale. Also consider a migration concern: weights already destroyed by this bug are unrecoverable.
- **Severity:** Critical

### 5.2 `navigationDestination` fetches from SwiftData and mutates observable state during body evaluation
- **Location:** `Pawsona/View/Dog/DogListView.swift:42-46`, calling `Pawsona/ViewModel/Dog/DogViewModel.swift:48-62`
- **What:** The destination builder calls `viewModel.getDog(id:in:)`, which runs a `FetchDescriptor` fetch *and* writes `errorMessage` (line 56 on success, line 59 on failure) — both inside the closure SwiftUI evaluates while building the view.
- **Why:** Two problems. Mutating `@Observable` state that the same view reads is the classic "Modifying state during view update" pattern, which SwiftUI treats as undefined behaviour and which can loop invalidation. Separately, a store fetch per navigation push is unnecessary work when the `Dog` is already in hand at the call site.
- **Action:** Navigate with the `Dog` itself rather than its `UUID` — `DogGridItemView` already has the object (`DogGridItemView.swift:14`). That removes the fetch and the mutation together. If value-based routing must stay, move the lookup into a `.task` and store the result in `@State`.
- **Severity:** High

### 5.3 AirDrop import only works while the Puppy tab is on screen
- **Location:** `Pawsona/View/Dog/DogListView.swift:87-89`
- **What:** `.onOpenURL` is attached inside `DogListView`, which is the content of one `Tab` in `ContentView.swift:14-16`.
- **Why:** `TabView` does not keep unselected tabs' view hierarchies alive. Receive a `.pawsonadog` file while the Reminder or Vaccine tab is selected and the URL is delivered to a hierarchy that is not installed — the import is silently dropped, with no error and no imported dog. This is the app's only entry point for the sharing feature.
- **Action:** Move `.onOpenURL` up to the `WindowGroup` in `PawsonaApp.swift:33-36`, or to `ContentView`'s `TabView`, and have it switch to the Puppy tab after a successful import so the user sees the result.
- **Severity:** High

### 5.4 Import deletes the source file even when it is not a disposable copy
- **Location:** `Pawsona/ViewModel/Dog/DogViewModel.swift:154`
- **What:** `try? FileManager.default.removeItem(at: url)` runs unconditionally after a successful decode.
- **Why:** For AirDrop this is right — the file is a throwaway in the app's Inbox. But `CFBundleDocumentTypes` in `Info.plist:16-27` also registers Pawsona as an **Editor** with `LSHandlerRank: Owner` for `.pawsonadog`, so the same code path can receive a file the user opened from the Files app or iCloud Drive. Deleting the user's own file after reading it is destructive and unrecoverable.
- **Action:** Only delete when the URL is inside the app's own `Documents/Inbox` (or `tmp`). Leave anything else alone. This pairs with §5.5.
- **Severity:** High

### 5.5 Imported file is read without security-scoped access
- **Location:** `Pawsona/ViewModel/Dog/DogViewModel.swift:143`
- **What:** `Data(contentsOf: url)` with no `startAccessingSecurityScopedResource()` / `stopAccessing...` pair.
- **Why:** Files delivered from outside the sandbox — the Files app, another app's share sheet — arrive as security-scoped URLs. Reading without claiming the scope fails, and the failure lands in the generic `catch` at line 157, surfacing as a raw `localizedDescription` in `errorMessage` that no view displays (§5.10). The user sees nothing happen at all.
- **Action:** Bracket the read with the security-scoped access pair, `defer`-releasing it. Combine with §5.4's ownership check, since both hinge on where the URL came from.
- **Severity:** Medium

### 5.6 The edit form's save button is always labelled "Add Dog"
- **Location:** `Pawsona/View/Dog/DogFormView.swift:164`
- **What:** `Button("Add Dog", systemImage: "checkmark", ...)` is hardcoded, while the navigation title correctly reflects the mode via the `title` parameter (`DogEditView.swift:19` passes `"Edit Dog"`).
- **Why:** The screen reads "Edit Dog" at the top and "Add Dog" on its confirm button. The VoiceOver label is separately hardcoded to `"Save dog"` at line 168, so the visible and spoken labels disagree with each other *and* with the title.
- **Action:** Derive the button title from the mode alongside `title`, and let the accessibility label follow it rather than being independently hardcoded.
- **Severity:** Medium

### 5.7 The vaccine form stores a `notes` value the user cannot enter
- **Location:** `Pawsona/View/Vaccine/VaccineRecordFormView.swift:22,37,173-179`
- **What:** `notes` is declared as `@State`, seeded from the initialiser, trimmed, and passed to `onSave` — but `body` renders only `vaccineSection`, `dateSection`, and `dogSection`. There is no notes field anywhere in the form.
- **Why:** `VaccineRecord.notes` is a real persisted property and the edit path faithfully round-trips whatever is already there, so this reads as a UI that was dropped rather than a model that was never wired. Users cannot annotate records at all.
- **Action:** Confirm the intent with the team. Either add the notes field to the form, or remove `notes` from this view's parameters and let the callers pass `nil` explicitly. Do not leave it half-wired.
- **Severity:** Medium

### 5.8 The reminder form gets a different `NotificationService` than the screen presenting it
- **Location:** `Pawsona/View/Reminder/ReminderFormView.swift:23-26` (default argument), presented from `Pawsona/View/Reminder/UpcomingRemindersView.swift:94-99`
- **What:** `UpcomingRemindersView.init` carefully creates one service and injects it into its view model, with a comment at lines 22-23 saying it is "One service instance shared by the list ... and injected into the view model". But both `.sheet` bodies call `ReminderFormView()` / `ReminderFormView(editing:)` without passing it, so the default `NotificationService()` argument constructs a second instance.
- **Why:** Not currently a functional break — both instances wrap the same `UNUserNotificationCenter.current()` singleton, so scheduling and cancelling work. But `permissionState` is per-instance, so the form's copy is permanently `.notDetermined` and cannot ever gate on permission. More importantly the comment asserts an invariant the code does not hold, which is how this becomes a real bug later.
- **Action:** Pass the existing service into both sheet presentations. Consider moving the service into the environment so the default argument can be removed entirely.
- **Severity:** Medium

### 5.9 Dogs with no name sort ahead of every named dog
- **Location:** `Pawsona/Model/Dog/DogSortOption.swift:28`
- **What:** `SortDescriptor(\Dog.name, order: .forward)` over an optional `String`, which orders `nil` first.
- **Why:** `DogViewModel.resolvedDogName` (`DogViewModel.swift:169-181`) guarantees every dog created through the app gets a "Puppy N" name, so `nil` should be unreachable in practice — but `Dog.name` is optional at the model level and CloudKit sync from another device carries no such guarantee. When it happens, unnamed dogs cluster at the top with a blank label.
- **Action:** Either make the sort fall back to a non-optional key, or reconsider whether `name` needs to be optional given the app always populates it.
- **Severity:** Low

### 5.10 `errorMessage` is written in eleven places and read in none
- **Location:** `Pawsona/ViewModel/Dog/DogViewModel.swift:16,44,59,90,101,120,136,158,203,213`; `Pawsona/ViewModel/Vaccine/VaccineViewModel.swift:15,45,59,96`; `Pawsona/ViewModel/Reminder/ReminderFormViewModel.swift:22,91,130`
- **What:** Every view model diligently records failures into an `errorMessage` property. No view in the project observes any of them. (`VaccineScanViewModel.errorMessage` is the sole exception — it is correctly surfaced by the alert at `VaccineListView.swift:100-104`.)
- **Why:** Every persistence failure, PDF failure, import failure, and export failure in the app is currently silent. §5.5's failure mode is exactly this. The plumbing already exists; only the presentation is missing.
- **Action:** Surface these — an `.alert` bound to the view model, following the `isShowingError` pattern already proven in `VaccineScanViewModel.swift:20-23`. Note that raw `error.localizedDescription` from SwiftData is not user-facing copy; map to friendly messages the way `GeminiScanner.ScanError` already does so well.
- **Severity:** Medium

### 5.11 `UpcomingRemindersViewModel`'s default argument builds a throwaway service
- **Location:** `Pawsona/ViewModel/Reminder/UpcomingRemindersViewModel.swift:27`
- **What:** `notificationService: NotificationService = NotificationService()` as a default parameter.
- **Why:** Same class of issue as §5.8. The one production call site (`UpcomingRemindersView.swift:26`) does inject correctly, so this default only serves tests — where an explicit spy is passed anyway.
- **Action:** Drop the default and require injection, so the dependency is impossible to forget at a future call site.
- **Severity:** Low

---

## 6. Security

**Positive finding, stated explicitly because it is easy to get wrong:** the Gemini API key is handled correctly. `Config/Secrets.xcconfig` is gitignored (`.gitignore:87`), only `Secrets.xcconfig.example` and `Shared.xcconfig` are tracked (confirmed via `git ls-files Config/`), `Shared.xcconfig` uses `#include?` so a fresh checkout still builds, and the key travels in the `x-goog-api-key` header rather than a query string (`GeminiScanner.swift:177`) so it cannot leak into URL logs. No secret is committed anywhere in the repo.

### 6.1 Push entitlement and background mode ship for a feature that does not exist
- **Location:** `Pawsona/Pawsona.entitlements:4-5`, `Pawsona/Info.plist:31-34`
- **What:** The entitlements declare `aps-environment: development`, and `Info.plist` declares `UIBackgroundModes: [remote-notification]`. A repo-wide grep for `registerForRemoteNotifications`, `didRegisterForRemoteNotifications`, `UIApplicationDelegate`, and `UNUserNotificationCenterDelegate` returns **nothing**. The app uses only local `UNCalendarNotificationTrigger`s, which need neither declaration.
- **Why:** Two distinct risks. **App Review:** declaring a background mode the app does not exercise is a documented rejection reason, and reviewers do check. **Runtime:** `aps-environment` hardcoded to `development` means a distribution build points at the sandbox APNs gateway; if push is ever added without revisiting this, it will fail in production in a way that is notoriously hard to diagnose.
- **Action:** Delete both declarations. Local notifications continue to work untouched — `NotificationServiceTests` covers that path and will confirm it. Re-add them properly, with the entitlement managed by the signing configuration rather than hardcoded, if and when remote push is actually built.
- **Severity:** High

### 6.2 Full Gemini error bodies are logged at `.public` privacy
- **Location:** `Pawsona/Service/GeminiScanner.swift:215-216`, also `:197`, `:244`, `:260`
- **What:** `logger.error("Gemini returned HTTP \(status): \(message, privacy: .public)")` writes the entire response body to the unified log unredacted. Line 244 does the same for the whole response envelope.
- **Why:** The API key is not in the body, so this is not a credential leak. But the body of a failed vision request can echo request metadata, and these logs persist on-device and are collectable via sysdiagnose. The codebase is otherwise thoughtful about not leaking raw API text to users (`VaccineScanDecodingTests.swift:117` even tests for it) — the log is the gap in that policy.
- **Why it is not higher:** no health data or photo content is in these strings, only API diagnostics.
- **Action:** Drop `privacy: .public` so the default redaction applies, keeping the status code public for triage. Alternatively keep the body public only under `#if DEBUG`.
- **Severity:** Medium

### 6.3 `.pawsonadog` files are decoded with no size or sanity limits
- **Location:** `Pawsona/ViewModel/Dog/DogViewModel.swift:143-144`
- **What:** `Data(contentsOf: url)` then `JSONDecoder().decode(DogTransferPackage.self, ...)` on a file that arrived from another device, with no bound on file size or on the embedded base64 `photoData` / `vaccineRecords` count.
- **Why:** The app is `LSHandlerRank: Owner` for this type, so a crafted file is a realistic input. `Data(contentsOf:)` loads the whole thing into memory — a large file is an easy memory-pressure termination. `JSONDecoder` itself is memory-safe, so this is a denial-of-service and robustness concern rather than a code-execution one.
- **Action:** Check the file size before reading and reject anything implausible; cap the decoded photo size and record count. Report rejections through the §5.10 error surface rather than failing silently.
- **Severity:** Medium

### 6.4 Health data and photos are written to the temp directory in the clear
- **Location:** `Pawsona/ViewModel/Dog/DogViewModel.swift:94,97` (all-dogs PDF), `:113,116` (per-dog PDF), `:129,131` (`.pawsonadog` JSON)
- **What:** Exported files land in `URL.temporaryDirectory` with default protection and are never cleaned up. Per §7.1 and §7.2 these are written **eagerly**, not on user request, so they accumulate for users who never tap Share.
- **Why:** The content is a pet's vaccination history and photos — low sensitivity, but it is written without the user asking. Default data protection means the files are readable whenever the device is unlocked.
- **Action:** Make export on-demand (§7.1, §7.2), which removes most of the exposure. Set `.completeFileProtection` on the written files and delete them once the share sheet dismisses.
- **Severity:** Low

---

## 7. Performance

### 7.1 A PDF of every dog is rendered on every list change, then discarded
- **Location:** `Pawsona/View/Dog/DogListView.swift:78-80`, rendering via `Pawsona/ViewModel/Dog/DogViewModel.swift:88-104` and `Pawsona/Service/PDFGenerator.swift:11-34`
- **What:** `.task(id: viewModel.dogs.map(\.id)) { exportedPDFURL = viewModel.exportDogsToPDF() }` fires whenever the set of dog IDs changes — on first appear, after every add, edit, delete, and every sort change. It runs `ImageRenderer` over a view containing every dog's full-resolution photo, encodes a PDF, validates it by constructing a `PDFDocument`, and writes it to disk. **Grep confirms `exportedPDFURL` is never read** — there is no `ShareLink` in this file.
- **Why:** Pure waste, all of it on the main actor (§3.2), scaling linearly with the number of dogs and the size of their photos. On a device with a dozen photographed dogs this is a multi-hundred-millisecond main-thread stall on every list mutation — precisely when the user has just tapped Save and expects the UI to respond.
- **Action:** Delete the property and the `.task` (§2.1). If an "export all" feature is planned, generate on tap, not ahead of time.
- **Severity:** High

### 7.2 The detail screen eagerly generates a PDF and a JSON copy of the photo on every appearance
- **Location:** `Pawsona/View/Dog/DogDetailView.swift:86-89`
- **What:** `.task(id: isShowingEditDogForm)` runs `exportDogToPDF(dog)` *and* `shareDogData(dog)` — the latter JSON-encodes the full-resolution `photoData` to base64 (`DogTransferPackage.swift:30`) and writes it to disk. It re-runs every time the edit sheet opens *or* closes.
- **Why:** Unlike §7.1 the results *are* used — the `ShareLink`s at lines 66 and 72 need a URL up front, which is presumably why this was done eagerly. But the cost is paid by every user who opens a dog, not just those who share. Base64 inflates the photo by ~33% and both files hit the disk.
- **Action:** Keep the `ShareLink`s responsive without the eager cost by giving them a lazily-evaluated item, or swap to a `.sheet`-presented share triggered by a `Button` that generates on tap. If the eager approach stays, at minimum stop regenerating on sheet *dismissal* when nothing was edited.
- **Severity:** High

### 7.3 Photo `Data` is decoded to a `UIImage` on every view-body evaluation
- **Location:** `Pawsona/View/Component/DogPhotoView.swift:16,33-38`; also `Pawsona/View/Component/VaccineRecordRowView.swift:102`, `Pawsona/View/Vaccine/VaccineRecordFormView.swift:239`, `Pawsona/View/Dog/DogFormView.swift:184`
- **What:** `Image(data:)` — a custom extension wrapping `UIImage(data:)` — is called directly inside `body`. There is no cache, and `photoData` is `@Attribute(.externalStorage)`, so each call can also fault the blob back from disk.
- **Why:** `DogPhotoView` renders in grid cells, reminder rows, and selection avatars — the exact places SwiftUI re-evaluates most often, and inside `LazyVGrid`/`LazyVStack` where scrolling drives repeated evaluation. Full-resolution decode for a 50×50pt avatar is the worst case, and it happens per frame of scrolling in the worst path.
- **Action:** Decode once and cache — either store a downscaled thumbnail alongside the original on save, or use a small `@Observable` image cache keyed by dog ID. Given avatars are 50-64pt, storing a thumbnail at save time is the simplest large win and also shrinks CloudKit sync payloads.
- **Severity:** Medium

### 7.4 Every vaccine mutation refetches the entire record table into an array nothing reads
- **Location:** `Pawsona/ViewModel/Vaccine/VaccineViewModel.swift:14,33,36-47,78,88`
- **What:** `createRecord`, `editRecord`, and `deleteRecord` each call `getAllRecord`, which fetches every `VaccineRecord` in the store into `self.vaccines`. Both consumers of this view model — `VaccineListView.swift:14` and `DogVaccinationRecordView.swift:97-99` — get their data from `@Query` and `dog.vaccineRecords` respectively. Nothing reads `vaccines`.
- **Why:** A full table scan after every single-record write, discarded immediately. `@Query` already delivers the update reactively, so the refetch buys nothing.
- **Action:** Delete the `vaccines` property and the `getAllRecord` calls from the mutation paths. This is the same dead-write pattern as §7.1, in the data layer.
- **Severity:** Medium

### 7.5 `DogViewModel.dogs` duplicates what `@Query` would provide
- **Location:** `Pawsona/ViewModel/Dog/DogViewModel.swift:15,35-46`, consumed by `Pawsona/View/Dog/DogListView.swift:14,19-28,75-77,84-86`
- **What:** Unlike §7.4 this array *is* read — `filteredDogs` derives from it. But it is maintained by hand: `getDogLists` is called from a `.task`, from `onChange(of: sortOption)`, and from the tail of every mutation.
- **Why:** Manual cache invalidation against a reactive store. A write made anywhere else — the vaccine screens, CloudKit sync landing in the background — will not refresh this list, so the Puppy tab can show stale data until something re-triggers a fetch. This is a correctness risk as much as a performance one, and it is the reason `DogListView` needs the fetch in §5.2.
- **Why it is Medium, not High:** in the current navigation flow, returning to the list generally re-runs `.task`, so staleness is short-lived and hard to observe. CloudKit sync makes it observable.
- **Action:** Move to `@Query` with a dynamic sort, matching what `VaccineListView` and `ReminderFormView` already do correctly. Keep `DogViewModel` for the mutations and exports. This single change also resolves §5.2 and removes three of the manual refresh call sites.
- **Severity:** Medium

---

## 8. SwiftUI / UI

### 8.1 Hardcoded `.black` breaks Dark Mode in two places
- **Location:** `Pawsona/View/Dog/DogFormView.swift:119`, `Pawsona/View/Dog/DogListView.swift:58`
- **What:** `Text(sex.displayName).foregroundStyle(.black)` on the gender menu label, and `.tint(Color(.black))` on the sort menu.
- **Why:** In Dark Mode both render near-black on a dark surface — the gender row becomes effectively invisible, and it is a required-looking field in the primary create flow. This contradicts the project's own rule ("Never hardcode text colors. Use semantic colors") and is the only place in the codebase that breaks it; every other view correctly uses `.primary` / `.secondary`.
- **Action:** Use `.primary` for the gender label. For the sort menu, drop the explicit tint and let it inherit, or use a semantic colour. Verify both in Dark Mode.
- **Severity:** High

### 8.2 Fixed 60pt form rows clip their text at large Dynamic Type sizes
- **Location:** `Pawsona/View/Dog/DogFormView.swift:93,100,122,133,140`
- **What:** Six form rows each pinned with `.frame(height: 60)` — breed, name, gender menu, date picker, and weight.
- **Why:** The fonts inside scale with Dynamic Type but the container does not, so at accessibility sizes the content overflows or truncates. The rest of the codebase handles this well — `DogDetailView` swaps to a `VStack` at accessibility sizes, `DogListView` collapses to one column, `ReminderRowView` and `WeekStripView` use `@ScaledMetric` — which makes this form the outlier.
- **Action:** Replace the fixed heights with `minHeight` plus padding, or `@ScaledMetric`, following the pattern already used in `WeekStripView.swift:20-21`.
- **Severity:** High

### 8.3 Colour swatches are 17×17pt — well under the 44×44pt minimum
- **Location:** `Pawsona/View/Dog/DogFormView.swift:60-75`, sizing at `:68`
- **What:** Eight colour buttons at `.frame(width: 17, height: 17)` with `spacing: 10`, and no `.contentShape` or padding to enlarge the tap area.
- **Why:** Roughly a sixth of the required hit-target area, with eight of them in a tight row — hard for anyone, and a real barrier for users with motor impairments. The project's rules require 44×44pt on every interactive element, and other controls honour it (`VaccineSelectionButton` uses `minHeight: 44`, `RepeatDayPicker` uses `minWidth: 44, minHeight: 44`).
- **Action:** Keep the 17pt visual swatch but expand the tappable region to 44×44pt with padding plus `.contentShape(.rect)`. Related: selection is currently indicated by size alone (§2.3), which also warrants a non-size cue.
- **Severity:** High

### 8.4 Views are decomposed with computed properties instead of extracted structs
- **Location:** `Pawsona/View/Dog/DogDetailView.swift:92` (`sheetContent`); `Pawsona/View/Vaccine/VaccineRecordFormView.swift:69,87,111` (`vaccineSection`, `dateSection`, `dogSection`); `Pawsona/View/Dog/DogFormView.swift:181` (`photoPickerLabel`)
- **What:** Large sub-hierarchies returned from computed `var`s on the parent view.
- **Why:** Explicitly against the project rule ("Do not break views up using computed properties; extract them into new `View` structs"). Beyond style, it defeats SwiftUI's invalidation granularity: a computed property is inlined into the parent's `body`, so any change to any parent state re-evaluates all of it. Extracted structs with their own inputs can be skipped when their inputs are unchanged. `VaccineRecordFormView` gets this right for its leaf rows (`VaccineSelectionButton`, `VaccineDogSelectionButton` are proper structs) and wrong for its sections.
- **Action:** Extract each into its own `View` struct taking exactly the values it needs. Prioritise `sheetContent` and the `VaccineRecordFormView` sections, which are the largest.
- **Severity:** Medium

### 8.5 Two screens present empty states in three different styles
- **Location:** `Pawsona/View/Vaccine/VaccineListView.swift:26-37` vs `Pawsona/View/Dog/DogListContentView.swift:17-26` vs `Pawsona/View/Vaccine/DogVaccinationRecordView.swift:22-31`
- **What:** `VaccineListView` uses a bare `Text("Tap '+' to add Vaccination Record")`; the other two use `ContentUnavailableView` with an icon and description.
- **Why:** Inconsistent look, and the bare `Text` loses the standard structure, spacing, and accessibility grouping. It also references the "+" glyph in copy, which does not survive translation or VoiceOver well.
- **Action:** Use `ContentUnavailableView` in `VaccineListView` to match the other two.
- **Severity:** Low

### 8.6 The vaccine add button builds its label manually
- **Location:** `Pawsona/View/Vaccine/VaccineListView.swift:65-71`
- **What:** `Button { } label: { Image(systemName: "plus").foregroundStyle(.white).accessibilityLabel(...) }` — with a hardcoded white tint.
- **Why:** The project rule is `Button("Tap me", systemImage: "plus", action:)`, which every other toolbar button in the codebase follows (`DogListView.swift:64`, `UpcomingRemindersView.swift:87`, `DogVaccinationRecordView.swift:63`). The hardcoded `.white` is also a milder instance of §8.1 — it happens to be correct against the brown tint, but it will not follow a theme change.
- **Action:** Use the `Button(_:systemImage:action:)` form and let `.buttonStyle(.glassProminent)` supply the foreground.
- **Severity:** Low

### 8.7 `ContentView`'s preview container omits two of the three models
- **Location:** `Pawsona/App/ContentView.swift:32`
- **What:** `.modelContainer(for: Dog.self, inMemory: true)` while the tabs render `Reminder` and `VaccineRecord` data.
- **Why:** SwiftData infers related models through relationships so this generally resolves, but it diverges from the real schema in `PawsonaApp.swift:14-18` and from the other previews that list models explicitly (`VaccineListView.swift:200`, `ReminderFormView.swift:145`).
- **Action:** List all three models, matching `PawsonaApp`'s `Schema`.
- **Severity:** Low

---

## 9. Dead code / duplication / refactor

### 9.1 `displayName` is reimplemented six times
- **Location:** `Pawsona/View/Dog/DogDetailView.swift:159-162`; `Pawsona/View/Dog/DogListContentView.swift:48-51`; `Pawsona/View/Component/DogCardView.swift:47-50`; `Pawsona/View/Component/DogGridItemView.swift:22-25`; `Pawsona/View/Vaccine/DogVaccinationRecordView.swift:92-95`; `Pawsona/View/Vaccine/VaccineRecordFormView.swift:257-260`
- **What:** The identical "trim the name, fall back to a placeholder" logic, copied six times. **The fallbacks already disagree** — four use `"Dog"`, `VaccineRecordFormView` uses `"Puppy"`, and `PuppySelectionRow.swift:31,39` and `ReminderRowView.swift:53` use a bare `dog.name ?? "Puppy"` with no trimming at all.
- **Why:** This is drift that has already happened, not drift that might. The same dog is labelled "Dog" on one screen and "Puppy" on the next, and the untrimmed variants will show a whitespace-only name as blank.
- **Action:** Add a single `displayName` computed property to `Dog` and delete all six copies. Pick one fallback — "Puppy" matches the generated-name scheme in `DogViewModel.resolvedDogName`. `breedText` and `ageText` are duplicated across the same files and should move with it.
- **Severity:** Medium

### 9.2 The colour-name table exists twice, in different files, one of them unused
- **Location:** `Pawsona/View/Dog/DogFormView.swift:285-306` (`ColorType.accessibilityName`, used) and `Pawsona/View/Component/DogColorPickerRow.swift:27-46` (`title`, unused)
- **What:** Two identical eight-case switches mapping `ColorType` to an English name.
- **Why:** The live one is also declared as a `fileprivate` extension on `ColorType` inside a *view* file, which is where nobody will look for it.
- **Action:** Delete the unused `title` (§2.2) and move `accessibilityName` onto `ColorType` in `Model/Dog/ColorType.swift`, alongside the existing `color` property.
- **Severity:** Low

### 9.3 `pendingNotificationRequests()` exists only for tests
- **Location:** `Pawsona/Service/NotificationScheduling.swift:15`
- **What:** Declared on the protocol; no production code calls it. It is used by the test spy in `PawsonaTests/NotificationServiceTests.swift`.
- **Why:** Legitimate — it is how the tests assert scheduling behaviour, and those tests are good. Noted so a future reader does not delete it as dead.
- **Action:** No change. Optionally add a comment marking it as the test-observation hook.
- **Severity:** Low

### 9.4 Test coverage gaps in the layer with the most findings
- **Location:** `PawsonaTests/` — no test file exists for `DogViewModel`, `VaccineViewModel`, `VaccineScanViewModel`, `PDFGenerator`, or `DogTransferPackage`
- **What:** Coverage is strong where it exists: `NotificationServiceTests` (10 tests), `VaccineScanDecodingTests` (13), `ReminderFormViewModelTests` (9), `UpcomingRemindersViewModelTests` (6), plus model round-trip suites. But `DogViewModel` — which owns the weight bug (§5.1), the import/delete behaviour (§5.4, §5.5), and both export paths — has zero tests.
- **Why:** The untested files are exactly where this audit found its Critical and two of its High findings. That correlation is not a coincidence.
- **Action:** Add a `DogViewModelTests` suite covering the draft round-trip (with a comma-decimal locale, per §5.1), name generation and collision handling, and import of a malformed package. Follow the existing in-memory-container pattern in `TestSupport.swift`.
- **Severity:** Medium

---

## 10. Cross-cutting recommendations

1. **Format and parse with the same locale, always.** §5.1 exists because one direction was locale-aware and the other was not. Audit every `Double(...)`/`Int(...)` over user input — currently only `DogFormView:224`, so this is cheap to fix and cheap to keep fixed.
2. **Pick one source of truth per screen.** `@Query` where the view needs reactive reads; view models for mutations and derived work. Today `VaccineListView` and `ReminderFormView` do this right while `DogListView` maintains a manual mirror (§7.5) and `VaccineViewModel` maintains one nobody reads (§7.4).
3. **Never do expensive work "just in case."** Both High performance findings (§7.1, §7.2) are eager export. Make sharing generate on tap.
4. **Put shared presentation logic on the model.** `displayName`, `breedText`, and `ageText` belong on `Dog`, not copied into six views (§9.1) where they have already diverged.
5. **Surface the errors already being recorded.** Eleven write sites, zero read sites (§5.10). The `VaccineScanViewModel` alert pattern is the model to copy.
6. **Adopt `Localizable.xcstrings`.** Every user-facing string is a hardcoded English literal, including all accessibility labels. The project's own guidance calls for symbol keys with `extractionState: "manual"`, and the app targets an Indonesian audience — the fixture vaccine books are Indonesian. This is the largest deferred item in the report and worth planning deliberately rather than doing incidentally.
7. **Ship only the entitlements the app uses** (§6.1). Re-check `Info.plist` and entitlements before the first TestFlight build.

---

## 11. What was NOT audited

- **Gemini prompt accuracy.** The prompt (`GeminiScanner.swift:32-117`) and its response schema are treated as given. The `ink_marks_seen`-before-`vaccines` ordering is load-bearing for accuracy and was left untouched; `GeminiScannerLiveTests` covers it against real fixtures and requires live API quota to run, which this audit did not consume.
- **Live network behaviour.** `GeminiScannerLiveTests` was not executed. Only `decodeVisits` and the error mapping were reviewed statically.
- **Xcode project and build settings** beyond the specific values quoted (`SWIFT_DEFAULT_ACTOR_ISOLATION`, `SWIFT_VERSION`, `IPHONEOS_DEPLOYMENT_TARGET`). Signing, capabilities, and scheme configuration were not reviewed.
- **CloudKit sync behaviour at runtime.** Models were checked against the CloudKit schema rules (no `@Attribute(.unique)`, defaults on every property, optional relationships) and **all three models are compliant**. Actual sync, conflict resolution, and multi-device merge were not exercised.
- **Instruments profiling.** §7 identifies work on hot paths by reading. No trace was captured, so the millisecond figures are reasoned, not measured.
- **VoiceOver and Dynamic Type testing on device.** The accessibility findings come from code review. §8.1-§8.3 should be confirmed with VoiceOver on and at the largest accessibility size before and after fixing.
- **Localization correctness.** §10.6 notes that localization is absent; no assessment of wording or translation was made.
- **`ci_scripts/ci_post_clone.sh`** and the `.github/` workflow configuration.
- **Assets.** Colour sets were checked only for the naming rule in `CLAUDE.md` (no `Color` suffix) — all comply. Contrast ratios were not measured.

---

## 12. Verification

Each entry below names the exact evidence for a Critical or High finding. All were opened and confirmed during the audit; two were confirmed by execution.

- **§5.1** — **Executed.** Ran a Swift script formatting `12.5` via `.number.precision(.fractionLength(1))` and re-parsing with `Double(_:)` across locales. Output: `en_US: "12.5" -> 12.5`; `id_ID: "12,5" -> nil`; `de_DE: "12,5" -> nil`. Cross-referenced with `DogFormView.swift:38-40` (the format call) and `:222-225` (the parse call), and `DogViewModel.swift:70` (`dog.weight = draft.weightKg`, assigning the `nil`).
- **§6.1** — **Executed.** `grep -rn "didRegisterForRemoteNotifications\|UIApplicationDelegate\|registerForRemoteNotifications\|UNUserNotificationCenterDelegate" Pawsona/` returned no matches. Confirmed against `Pawsona.entitlements:4-5` (`aps-environment: development`) and `Info.plist:31-34` (`UIBackgroundModes: [remote-notification]`).
- **§7.1** — **Executed.** `grep -n "exportedPDFURL" Pawsona/View/Dog/DogListView.swift` returns exactly two lines: the declaration at `:16` and the assignment at `:79`. A second grep for `ShareLink` in the same file returns nothing, confirming the value has no consumer.
- **§5.2** — Read `DogListView.swift:42-46`; the `navigationDestination(for: UUID.self)` closure calls `viewModel.getDog(id:in:)`. Read `DogViewModel.swift:48-62`; that method runs `modelContext.fetch` and assigns `errorMessage` on both the success path (`:56`) and the failure path (`:59`). `errorMessage` is a stored property of the `@Observable` `DogViewModel` (`:16`).
- **§5.3** — Read `DogListView.swift:87-89` (`.onOpenURL` attached inside the view) and `ContentView.swift:13-26` (`DogListView` is the body of one `Tab` among three). Grep confirms `onOpenURL` appears nowhere else in `Pawsona/`.
- **§5.4** — Read `DogViewModel.swift:141-161`; line `:154` is `try? FileManager.default.removeItem(at: url)`, unconditional on the success path. Read `Info.plist:16-27`, confirming `CFBundleTypeRole: Editor` and `LSHandlerRank: Owner` for `com.pawsona.dogdata`.
- **§7.2** — Read `DogDetailView.swift:86-89`; `.task(id: isShowingEditDogForm)` calls both `exportDogToPDF(dog)` and `shareDogData(dog)`. Traced `shareDogData` to `DogViewModel.swift:126-138`, which encodes `DogTransferPackage`; traced that to `DogTransferPackage.swift:30`, confirming `photoData = dog.photoData` is carried into the JSON.
- **§8.1** — Read `DogFormView.swift:119` (`.foregroundStyle(.black)` on the gender `Text`) and `DogListView.swift:58` (`.tint(Color(.black))` on the sort `Menu`). Grep for `foregroundStyle(.black)` across `Pawsona/` confirms these are the only two hardcoded-black text sites.
- **§8.2** — Read `DogFormView.swift`; `.frame(height: 60)` appears at `:93`, `:100`, `:122`, `:133`, and `:140`, on the breed field, name field, gender menu, date picker, and weight field respectively.
- **§8.3** — Read `DogFormView.swift:60-75`; the swatch `Button` label is `DogColorPickerRow(...).frame(width: 17, height: 17)` at `:68`, inside an `HStack(spacing: 10)`. No `.contentShape`, padding, or `minWidth`/`minHeight` is applied to the button.
- **§4.1** — Read `DogFormView.swift:222-225`; `parsedWeightKg` is `Double(trimmedWeight)`. Same evidence as §5.1.
