# Pawsona Code Audit

Audited at commit `f9ab0b2` on `dev` (~3,700 LOC, 57 Swift files: `Pawsona/` + `PawsonaTests/`).
Inputs: full SwiftLint run (31 violations, 1 error), clean `xcodebuild` warning capture, three
parallel scoped reviews (concurrency/API modernity; dead code/duplication; bugs/security/perf),
and a SwiftUI-specific pass over every view. Key claims were verified by reading the cited lines.

## 1. Executive summary

1. **[High] Edit form silently drops all but the first selected vaccine and dog** — §5.1 — `Pawsona/ViewModel/VaccineRecordFormViewModel.swift:101-109`
2. **[High] CI is red: SwiftLint `force_try` error plus 30 style warnings** — §2.1 — `Pawsona/View/Dog/DogListView.swift:109`
3. **[Medium] Vaccine cards group by wall-clock minute, so unrelated records merge and group-delete removes both** — §5.3 — `Pawsona/View/Vaccine/VaccineListView.swift:91-94`
4. **[Medium] Full multi-dog PDF is regenerated on the main actor on every list change and never used** — §7.1 — `Pawsona/View/Dog/DogListView.swift:15,63-65`
5. **[Medium] Transfer packages inherit MainActor isolation, producing the two standing build warnings** — §3.1 — `Pawsona/Model/DogTransferPackage.swift:30`
6. **[Medium] Dog list uses a one-shot manual fetch instead of `@Query`, so CloudKit sync changes don't appear** — §5.4 — `Pawsona/View/Dog/DogListView.swift:13,60-71`
7. **[Medium] Branch merges left triple-duplicated avatar/selection-row logic and a dead view-model store** — §9.1–§9.6
8. **[Medium] Reminder repeat rules exist in the model but are never set or scheduled — the feature is dead** — §5.2 — `Pawsona/Service/NotificationService.swift:50`
9. **[Medium] Photos are stored and CloudKit-synced at full resolution with no downsizing** — §7.4 — `Pawsona/View/Dog/DogFormView.swift:118-122`
10. **[Medium] Errors across save/import/schedule paths are swallowed into an `errorMessage` no view displays** — §5.7

## 2. Quick wins

### 2.1 SwiftLint: 31 violations, 1 error — the reason the Code Check workflow fails
- **Location:** repo-wide; the one error is `Pawsona/View/Dog/DogListView.swift:109` (`try!` in the preview)
- **What:** `swiftlint` exits with code 2 because of the `force_try` error; the other 30 are warnings (trailing whitespace ×13, `opening_brace` ×6, `implicit_optional_initialization` ×4, `function_parameter_count` ×2 at `DogViewModel.swift:69` and `VaccineViewModel.swift:64`, `line_length` ×2 at `VaccineRecordFormView.swift:112,114`, plus `trailing_comma`, `comma`, `vertical_whitespace` ×2, `empty_parentheses_with_trailing_closure`).
- **Why:** Every push to every branch runs this workflow; it has been red since the vaccine/detail merges.
- **Action:** `swiftlint --fix` clears most; manually restructure the preview to avoid `try!`, wrap the two long lines, and reduce the two 6-parameter functions.
- **Severity:** High

### 2.2 Invalid `.frame(width: .infinity)` on the grid card photo
- **Location:** `Pawsona/View/Component/DogCardView.swift:20`
- **What:** `width:` (a fixed dimension) is passed `.infinity`; the author meant `maxWidth:`.
- **Why:** Non-finite fixed frames log "invalid frame dimension" runtime errors and produce undefined layout.
- **Action:** Change to `.frame(maxWidth: .infinity)`.
- **Severity:** Low

### 2.3 Delete the unused PDF-export state in the dog list
- **Location:** `Pawsona/View/Dog/DogListView.swift:15,63-65`
- **What:** `exportedPDFURL` is written by a `.task(id:)` but read nowhere. Full finding at §7.1.
- **Action:** Delete the property and the task.
- **Severity:** Medium

### 2.4 `Section("")` used as a spacer
- **Location:** `Pawsona/View/Vaccine/VaccineRecordFormView.swift:107`
- **What:** An empty-string section title stands in for an untitled section.
- **Action:** Use `Section { ... }` with no title.
- **Severity:** Low

### 2.5 String-keyed color lookup `Color("VaccineBrown")`
- **Location:** `Pawsona/View/VaccineSelectionRow.swift:30`, `Pawsona/View/Vaccine/VaccineRecordFormView.swift:78`
- **What:** Raw string asset lookup, duplicated in two files.
- **Why:** Not compile-checked; a rename silently returns clear.
- **Action:** Use the generated symbol `Color(.vaccineBrown)`.
- **Severity:** Low

### 2.6 Stale `Item.swift` note in CLAUDE.md/AGENTS.md
- **Location:** `CLAUDE.md` (SwiftData section)
- **What:** The guide still says to delete `Item.swift`; it is already gone and unreferenced.
- **Action:** Drop the sentence from both agent guides.
- **Severity:** Low

## 3. Concurrency

### 3.1 Transfer-package structs inherit MainActor isolation (both build warnings, one root cause)
- **Location:** `Pawsona/Model/VaccineRecordTransferPackage.swift:12-21`, `Pawsona/Model/DogTransferPackage.swift:12-31` (warning at :30)
- **What:** Under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` both `Codable` snapshot structs are MainActor-isolated, so passing `VaccineRecordTransferPackage.init` to `map` crosses an actor boundary and emits the two standing compiler warnings.
- **Why:** These are meant to be plain Sendable snapshots for JSON encode/decode and AirDrop transfer; isolation is semantically wrong and blocks any future off-main encoding.
- **Action:** Mark both structs `nonisolated` (and `Sendable`).
- **Severity:** Medium

### 3.2 Fire-and-forget `Task {}` wrapping synchronous delete loops
- **Location:** `Pawsona/View/Dog/DogListView.swift:100-104`, `Pawsona/View/Vaccine/VaccineListView.swift:99-103`, `Pawsona/View/Vaccine/DogVaccinationRecordView.swift:74-78`
- **What:** Each `onDelete` wraps fully synchronous main-actor delete calls in an unstructured `Task {}`.
- **Why:** The task buys nothing, defers the delete a run-loop hop (racing list re-diffing), and is uncancellable.
- **Action:** Call the delete methods directly.
- **Severity:** Low

### 3.3 Photo load task not tied to view lifecycle
- **Location:** `Pawsona/View/Dog/DogFormView.swift:118-122` (triggered from `.onChange` at :85)
- **What:** `loadPhoto` spawns an unstructured `Task` that awaits `loadTransferable` and discards errors via `try?`.
- **Why:** A stale load can overwrite a newer pick or complete after dismissal; failures are invisible.
- **Action:** Use `.task(id: photoSelection)` so SwiftUI cancels superseded loads, and surface failure.
- **Severity:** Low

### 3.4 Reminder save dismisses regardless of outcome
- **Location:** `Pawsona/View/Reminder/ReminderFormView.swift:87-92`
- **What:** `save()` ignores the view model's return value and calls `dismiss()` unconditionally.
- **Why:** When persistence fails (`errorMessage` set, nil return) the sheet still closes and the user believes the reminder saved.
- **Action:** Branch on the result; only dismiss on success.
- **Severity:** Low

### 3.5 Multiple independent `NotificationService` instances hold divergent permission state
- **Location:** `Pawsona/View/Reminder/UpcomingRemindersView.swift:24`, `Pawsona/ViewModel/UpcomingRemindersViewModel.swift:25`, `Pawsona/View/Reminder/ReminderFormView.swift:23`
- **What:** Default arguments (`= NotificationService()`) mint fresh instances, each with its own `permissionState` over the same process-wide notification center.
- **Why:** The banner in one view can disagree with the authorization another instance observed.
- **Action:** Inject one shared service (e.g. via `@Environment`).
- **Severity:** Low

### 3.6 Notification scheduling swallows failures
- **Location:** `Pawsona/Service/NotificationService.swift:54`
- **What:** `try? await center.add(request)` discards the error.
- **Why:** A rejected request leaves a persisted reminder that never fires, silently.
- **Action:** Propagate or record the failure.
- **Severity:** Low

## 4. API modernity

_No findings._ The codebase already uses `FormatStyle`, `foregroundStyle`, `clipShape(.rect(cornerRadius:))`, the `Tab` API, `NavigationStack` + `navigationDestination(for:)`, `@Observable`, `localizedStandardContains`, and async `UNUserNotificationCenter`. Grep confirmed zero hits for `DateFormatter`, `String(format:)`, `DispatchQueue`, `NavigationView`, `tabItem`, `onTapGesture`, `foregroundColor`, `ObservableObject`, `UIScreen.main.bounds`.

## 5. Bugs / logic errors

### 5.1 Edit mode silently drops all but the first selected vaccine and dog
- **Location:** `Pawsona/ViewModel/VaccineRecordFormViewModel.swift:101-109`, with the multi-select UI at `Pawsona/View/Vaccine/VaccineRecordFormView.swift:94-102,128-141`
- **What:** The editing branch of `save` uses only `selectedDogs.first` and `selectedVaccines.first`, while the edit form still renders full multi-select vaccine rows and dog avatars.
- **Why:** A user who adds a second vaccine or dog while editing gets those selections discarded with no error — data the user believes was saved is not.
- **Action:** Constrain the edit UI to single-select while `isEditing`, or fan the edit out into create/delete of the extra combinations.
- **Severity:** High

### 5.2 Reminder repeat rules are never set or scheduled
- **Location:** `Pawsona/Service/NotificationService.swift:50` (`repeats: false` hardcoded); `Pawsona/Model/Reminder.swift:18`; `Pawsona/View/Reminder/ReminderFormView.swift:38-71` (no repeat UI)
- **What:** `Reminder.repeatRule`, `RepeatRule`, and `RepeatUnit` exist, but no UI writes them and the trigger ignores them.
- **Why:** A whole model surface is dead weight; a "repeating" reminder fires once.
- **Action:** Wire repeat into the form and trigger, or delete the three types until the feature is built.
- **Severity:** Medium

### 5.3 Vaccine grouping by rounded minute merges unrelated submissions
- **Location:** `Pawsona/View/Vaccine/VaccineListView.swift:91-94` (`groupKey`), delete path at :96-104
- **What:** Records group by `vaccine + minute-bucketed dateGiven`, so two independent single-dog submissions of the same vaccine within the same minute collapse into one card — and swipe-deleting that card deletes both records.
- **Why:** Incorrect visual grouping plus a real data-loss path on delete.
- **Action:** Stamp records created by one form submission with a shared batch UUID and group by that.
- **Severity:** Medium

### 5.4 Dog list won't reflect CloudKit sync or external changes
- **Location:** `Pawsona/View/Dog/DogListView.swift:13,60-71`
- **What:** The list renders `viewModel.dogs` from a one-shot fetch in `.task`, unlike the other two tabs which use `@Query`.
- **Why:** With `cloudKitDatabase: .automatic`, dogs synced from another device won't appear until something forces a refetch.
- **Action:** Drive the list from `@Query` and keep the view model for mutations, matching `VaccineListView`/`UpcomingRemindersView`.
- **Severity:** Medium

### 5.5 Dog deletion is unreachable from the UI
- **Location:** `Pawsona/View/Dog/DogListView.swift:97-105`; `Pawsona/ViewModel/DogViewModel.swift:88-96`
- **What:** `deleteDogs(at:)` exists but nothing calls it — the grid has no `.onDelete`, context menu, or delete button.
- **Why:** Users cannot delete a dog; the delete code path (and its cascade behavior) is never exercised.
- **Action:** Add a context-menu or detail-screen delete, or remove the dead methods until designed.
- **Severity:** Low

### 5.6 Deleting a dog would orphan its reminders and their notifications
- **Location:** `Pawsona/ViewModel/DogViewModel.swift:88-96`; `Pawsona/Model/Reminder.swift:16`
- **What:** The many-to-many `Dog.reminders` relationship nullifies on delete; `deleteDog` neither removes now-empty reminders nor cancels their pending notifications.
- **Why:** Once deletion is reachable (§5.5), dog-less reminders survive and still fire.
- **Action:** On delete, detach or remove empty reminders and cancel their notifications.
- **Severity:** Low

### 5.7 Errors are swallowed into an `errorMessage` no view displays
- **Location:** `Pawsona/ViewModel/DogViewModel.swift:48-50,108-114,165,168-171`; `Pawsona/ViewModel/VaccineViewModel.swift:44-46,95-97`; `Pawsona/ViewModel/UpcomingRemindersViewModel.swift:57-61`; `Pawsona/Service/NotificationService.swift:54`; `Pawsona/View/Dog/DogFormView.swift:120`
- **What:** One root cause across many sites: save/fetch/import/schedule failures land in `errorMessage` properties that no view binds, or vanish via `try?` / empty `catch`.
- **Why:** Failed saves and corrupt imports look like success to the user.
- **Action:** Bind `errorMessage` to an alert in each tab's root view; stop discarding thrown errors.
- **Severity:** Medium

## 6. Security

### 6.1 Exported PDF/transfer files carrying PII accumulate in the temp directory
- **Location:** `Pawsona/ViewModel/DogViewModel.swift:99-149`
- **What:** Dog name, breed, birthday, vaccine history, and photo are written to `URL.temporaryDirectory` for sharing and never cleaned up.
- **Why:** Avoidable data-at-rest; the OS reclaims temp eventually, but eagerly generated files (§7.1/§7.2) make it worse.
- **Action:** Generate on demand and remove after the share sheet completes.
- **Severity:** Low

### 6.2 Unused remote-notification background mode and development APS environment
- **Location:** `Pawsona/Info.plist:28-31`; `Pawsona/Pawsona.entitlements:5-6`
- **What:** `remote-notification` background mode and `aps-environment: development` are declared, but the app only schedules local notifications.
- **Why:** Unused capability surface; if push is added later, the development APS value breaks release builds silently.
- **Action:** Remove both until remote push is actually planned.
- **Severity:** Low
- **Correction (post-review):** *Do not apply.* SwiftData's CloudKit sync (`cloudKitDatabase: .automatic`) uses silent remote notifications to learn about changes from other devices, so both declarations are in use; `aps-environment` is also switched to `production` automatically at distribution signing. Finding retained for the record but withdrawn.

_Verified clean:_ no hardcoded secrets/keys/tokens anywhere; all three `@Model` types satisfy the CloudKit rules (defaults/optionals everywhere, optional relationships, no `.unique`).

## 7. Performance

### 7.1 Full multi-dog PDF regenerated on every dog-list change, output never used
- **Location:** `Pawsona/View/Dog/DogListView.swift:15,63-65` → `Pawsona/ViewModel/DogViewModel.swift:98-115` → `Pawsona/Service/PDFGenerator.swift`
- **What:** `.task(id: viewModel.dogs.map(\.id))` renders every dog and photo through `ImageRenderer` and writes a PDF to disk each time the dog set changes; `exportedPDFURL` is read nowhere.
- **Why:** Heavy main-actor rendering and disk I/O for output that is discarded — hitches scale with herd size.
- **Action:** Delete the state and task (§2.3); generate PDFs only from the share action.
- **Severity:** Medium

### 7.2 Detail view re-renders PDF and re-encodes the photo on every edit-sheet toggle
- **Location:** `Pawsona/View/Dog/DogDetailView.swift:81-84`
- **What:** `.task(id: isShowingEditDogForm)` runs `exportDogToPDF` and `shareDogData` on appear and on every sheet open *and* close.
- **Why:** Two heavyweight main-actor operations fire repeatedly even if Share is never tapped.
- **Action:** Generate lazily when the Share menu is invoked (ShareLink can take an async item source), or at minimum only when the sheet closes.
- **Severity:** Medium

### 7.3 Vaccine save loop saves and refetches once per dog×vaccine combination
- **Location:** `Pawsona/ViewModel/VaccineRecordFormViewModel.swift:110-122` → `Pawsona/ViewModel/VaccineViewModel.swift:17-34`
- **What:** `createRecord` calls `modelContext.save()` plus a full `getAllRecord` fetch per invocation, inside a nested loop (5 dogs × 3 vaccines = 15 saves + 15 fetches).
- **Why:** O(n×m) redundant main-context work per form submission.
- **Action:** Insert all records, then save once.
- **Severity:** Medium

### 7.4 Photos stored and synced at full resolution
- **Location:** `Pawsona/View/Dog/DogFormView.swift:118-122`; `Pawsona/Model/Dog.swift:21`
- **What:** Raw `PhotosPicker` data (multi-MB originals) goes straight into `photoData` external storage and through CloudKit, PDF rendering, and JSON transfer.
- **Why:** Inflates sync traffic, storage, and every encode path above.
- **Action:** Downscale to a display-appropriate max dimension and re-encode as JPEG before assigning.
- **Severity:** Medium

### 7.5 `groupedRecords` recomputed per body evaluation
- **Location:** `Pawsona/View/Vaccine/VaccineListView.swift:66,84-89,97`
- **What:** `Dictionary(grouping:)` + sort runs in the `ForEach`, in its `id:`, and again in the delete handler.
- **Why:** Wasteful re-derivation per render; fine today, scales poorly.
- **Action:** Compute once per data change (view model or `onChange` cache).
- **Severity:** Low

### 7.6 Import decodes external files synchronously on the main actor
- **Location:** `Pawsona/View/Dog/DogListView.swift:69-71` → `Pawsona/ViewModel/DogViewModel.swift:152-172`
- **What:** `onOpenURL` triggers `Data(contentsOf:)` + JSON decode of a potentially photo-laden `.pawsonadog` file on the main actor.
- **Why:** Blocks the UI during app-open handoff.
- **Action:** Decode off-main via the (then-nonisolated, §3.1) transfer package, hop back for the insert.
- **Severity:** Low

## 8. SwiftUI / UI

### 8.1 UIKit-bridged and hardcoded colors in the dog-list toolbar
- **Location:** `Pawsona/View/Dog/DogListView.swift:48,54`
- **What:** `.tint(Color(.black))` and `.tint(Color(.brown))` bridge UIKit colors; the fixed black also ignores Dark Mode.
- **Why:** Violates the project's "no UIKit colors, use semantic colors" rules; black-on-dark toolbar glyphs lose contrast.
- **Action:** Use `.tint(.primary)` (or drop the tint) for the sort menu and `.tint(.brown)` for the add button.
- **Severity:** Low

### 8.2 Views split with computed `some View` properties instead of View structs
- **Location:** `Pawsona/View/Vaccine/VaccineRecordFormView.swift:94-151` (five section properties); `Pawsona/View/Vaccine/VaccineListView.swift:44-89`; `Pawsona/View/Dog/DogDetailView.swift:87-145` (`sheetContent`)
- **What:** Sections live in computed properties, against the project rule to extract `View` structs.
- **Why:** Computed properties defeat granular diffing and the codebase's own convention (`DogListContentView` does it right).
- **Action:** Extract each section into a small `View` struct when these files are next touched.
- **Severity:** Low

### 8.3 Coupled magic numbers in avatar rendering
- **Location:** `Pawsona/View/DogAvatarSelectionRow.swift:26,32` (56/60 diameter-vs-ring), `Pawsona/View/DogStackedAvatar.swift:15,17`, `Pawsona/View/VaccineRecordGroupRowView.swift:28` (`spacing: -12` must track the avatar radius)
- **What:** Avatar diameter, selection-ring size, and negative overlap are independent literals with implicit relationships.
- **Why:** Changing one without the others breaks the overlap/ring visuals; none scale with Dynamic Type.
- **Action:** Derive ring and overlap from one named diameter constant (consider `@ScaledMetric`).
- **Severity:** Low

### 8.4 Two `DatePicker`s bound to the same date but only the date picker is range-capped visually
- **Location:** `Pawsona/View/Vaccine/VaccineRecordFormView.swift:106-119`
- **What:** Date and time pickers share `$viewModel.dateGiven` and both cap at `.now`; picking today then a future time snaps back without explanation, and the labels are hidden with no accessibility replacement beyond the hidden built-in labels.
- **Why:** Minor UX confusion; VoiceOver users hear two identically-purposed pickers.
- **Action:** Keep one `DatePicker` with `[.date, .hourAndMinute]` (as `ReminderFormView` does).
- **Severity:** Low

## 9. Dead code / duplication / refactor

### 9.1 Photo-or-placeholder avatar logic implemented three ways
- **Location:** `Pawsona/View/DogStackedAvatar.swift:20-32`, `Pawsona/View/DogAvatarSelectionRow.swift:46-59`, `Pawsona/View/Component/DogPhotoView.swift:16-30`
- **What:** The `UIImage(data:)`-or-`pawprint` fallback is duplicated in both avatar views while `DogPhotoView` and its `Image(data:)` extension already solve it.
- **Why:** Three copies of one concept, two redundant `import UIKit`s.
- **Action:** Extract one avatar view (or reuse `Image(data:)`) for all three call sites.
- **Severity:** Medium

### 9.2 Three near-identical selectable-row components
- **Location:** `Pawsona/View/VaccineSelectionRow.swift`, `Pawsona/View/Component/PuppySelectionRow.swift`, `Pawsona/View/DogAvatarSelectionRow.swift`
- **What:** Same `item + isSelected + toggle` Button pattern with `.accessibilityAddTraits(.isSelected)`; the first two differ only in the trailing glyph.
- **Action:** Collapse `VaccineSelectionRow`/`PuppySelectionRow` into one generic selection row; keep the avatar one if its layout warrants.
- **Severity:** Medium

### 9.3 `toggleDog`/`isSelected` duplicated verbatim across two form view models
- **Location:** `Pawsona/ViewModel/ReminderFormViewModel.swift:53-63`, `Pawsona/ViewModel/VaccineRecordFormViewModel.swift:65-76`
- **What:** Identical multi-select helpers over `selectedDogs` (and the same shape again for vaccines at :79-90).
- **Action:** Extract a small shared multi-select helper.
- **Severity:** Medium

### 9.4 Hand-rolled SwiftData CRUD duplicated between DogViewModel and VaccineViewModel
- **Location:** `Pawsona/ViewModel/VaccineViewModel.swift:36-98` vs `Pawsona/ViewModel/DogViewModel.swift:40-96,219-226`
- **What:** Fetch-all, fetch-by-id, delete-then-refetch, and a byte-identical `saveChanges(in:)` exist in both.
- **Why:** Every persistence fix must land twice; the pattern is poised to be copied a third time.
- **Action:** Share the common helpers (at minimum `saveChanges`).
- **Severity:** Medium

### 9.5 Two vaccine screens duplicate list/sheet/delete scaffolding
- **Location:** `Pawsona/View/Vaccine/VaccineListView.swift`, `Pawsona/View/Vaccine/DogVaccinationRecordView.swift`
- **What:** Both wire empty-state, add/edit sheets onto `VaccineRecordFormView`, and `Task`-wrapped delete loops near-verbatim; they differ only in grouping.
- **Action:** Factor the shared scaffolding into one container taking a record source and row builder.
- **Severity:** Medium

### 9.6 `VaccineViewModel.vaccines` + `getAllRecord` is dead state
- **Location:** `Pawsona/ViewModel/VaccineViewModel.swift:14,36-47` (calls at :33,:78,:88)
- **What:** The array is refetched after every mutation but read by no view or test — both list screens use `@Query`/relationships.
- **Why:** Dead work on every save and a misleading "source of truth".
- **Action:** Delete the property, `getAllRecord`, and its call sites.
- **Severity:** Medium

### 9.7 `VaccineRecordRowView.showsDogName` is never enabled
- **Location:** `Pawsona/View/Component/VaccineRecordRowView.swift:12,20-24,40-49`
- **What:** The only call site leaves the flag at its `false` default, making the dog-name branches unreachable.
- **Action:** Remove the flag and dead branches, or use it in the grouped list.
- **Severity:** Low

### 9.8 Date formatting inline-repeated across seven files
- **Location:** e.g. `VaccineRecordGroupRowView.swift:22,51`, `VaccineRecordRowView.swift:26,45`, `ReminderRowView.swift:30,62`, `DogPDFSectionView.swift:51,59`
- **What:** `.formatted(date: .abbreviated, time: ...)` repeated inline, often twice per file (display + accessibility label).
- **Action:** Hoist to one or two named `FormatStyle` constants.
- **Severity:** Low

### 9.9 `Image(data:)` extension hidden inside DogPhotoView.swift
- **Location:** `Pawsona/View/Component/DogPhotoView.swift:33-38`
- **What:** A general-purpose extension lives in a feature view's file, which is why §9.1's duplicates never found it.
- **Action:** Move to `Image+Data.swift` in a shared location.
- **Severity:** Low

### 9.10 Mixed-language comments across merged features
- **Location:** vaccine files throughout (`VaccineListView.swift`, `VaccineRecordFormView.swift`, `VaccineRecordFormViewModel.swift`, avatar/selection rows)
- **What:** Indonesian comments in the vaccine feature vs English everywhere else.
- **Action:** Standardize on English.
- **Severity:** Low

### 9.11 Flat Model/ViewModel folders and four loose files at View/ root
- **Location:** `Pawsona/View/DogAvatarSelectionRow.swift`, `DogStackedAvatar.swift`, `VaccineRecordGroupRowView.swift`, `VaccineSelectionRow.swift`; `Pawsona/Model/*` and `Pawsona/ViewModel/*` (flat)
- **What:** The View layer is partially feature-foldered while Model and ViewModel are flat and four merged files sit at the View root.
- **Why:** Inconsistent navigation; the agreed structure is Model/View/ViewModel each with feature subfolders (Dog, Vaccine, Reminder, …).
- **Action:** Move every file into its feature subfolder (being applied in the companion restructure PR).
- **Severity:** Medium

## 10. Cross-cutting recommendations

### 10.1 Pick one list-data pattern: `@Query` for reads, view models for mutations
Vaccine and Reminder tabs already do this; Dog does not (§5.4). Converging removes the manual refetch choreography (`getDogLists` after every mutation) and the CloudKit staleness class of bugs.

### 10.2 Surface errors once, at tab roots
One `errorMessage`-driven alert per tab root view resolves §5.7's whole family without threading error UI through every subview.

### 10.3 Generate share artifacts lazily
All PDF/JSON export paths (§7.1, §7.2, §6.1) share one fix: build the file when the user taps Share, then delete it after.

### 10.4 De-duplicate before the next feature branch
The merge-driven duplication (§9.1–§9.5) will compound with every branch; extracting the shared avatar view, selection row, and save helper now keeps the next merge honest.

## 11. What was NOT audited

- Xcode project/build settings beyond deployment target and default actor isolation.
- Runtime CloudKit sync behavior (only static model-rule compliance was checked).
- Test quality/coverage (tests were only cross-referenced for dead-code checks).
- Localization wording; the app currently hardcodes English strings with no string catalog.
- Instruments profiling — performance findings are static-analysis inferences.
- `PawsonaUITests` (no meaningful content) and asset catalogs.

## 12. Verification

- **§5.1** — `Pawsona/ViewModel/VaccineRecordFormViewModel.swift:101` reads `if let editingRecord, let dog = selectedDogs.first, let vaccine = selectedVaccines.first` while `VaccineRecordFormView.swift:96-99,132-136` render unrestricted multi-select in edit mode. Confirmed by direct read.
- **§2.1** — `swiftlint lint Pawsona PawsonaTests` exits 2: `DogListView.swift:109:21: error: Force Try Violation`; totals match the failing `Code Check` run on `dev` (31 violations, 1 serious).
- **§3.1** — clean `xcodebuild` emits exactly one app warning: `DogTransferPackage.swift:30:57: call to main actor-isolated initializer 'init(vaccineRecord:)' in a synchronous nonisolated context`.
- **§7.1** — `DogListView.swift:15` declares `exportedPDFURL`; its only other occurrence is the write at :64; no read exists in the file or elsewhere (grep).
- **§5.3** — `VaccineListView.swift:92-93` buckets `dateGiven` to `Int(timeIntervalSinceReferenceDate / 60)`; the delete handler at :97 flat-maps every id in the bucket.
