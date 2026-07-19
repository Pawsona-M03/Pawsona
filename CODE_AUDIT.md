# Pawsona Code Audit

Audited at commit `0f49520` (branch `feature/detail-view`), 2026-07-19. ~2,500 LOC of app code
across 42 Swift files plus 7 test files. Findings marked **[fixed in this PR]** were resolved on
`refactor/mvvm-vaccine-many-to-many`; everything else is left for follow-up.

## 1. Executive summary

1. **[High] `force_try` in DogListView preview fails the SwiftLint CI job** — §5.1 — `Pawsona/View/Dog/DogListView.swift:109` **[fixed in this PR]**
2. **[High] VaccineRecord↔Dog modeled one-to-many with cascade delete, contradicting the product requirement (one record = many vaccines, many dogs)** — §5.2 — `Pawsona/Model/VaccineRecord.swift:14-17` **[fixed in this PR]**
3. **[High] Vaccine records with no dog could never be edited from the Vaccines tab** — §5.3 — `Pawsona/View/Vaccine/VaccineListView.swift:42` **[fixed in this PR]**
4. **[High] `DogCardView` uses `.frame(width: .infinity)` — an invalid frame that triggers runtime layout errors** — §8.1 — `Pawsona/View/Component/DogCardView.swift:20`
5. **[Medium] Every save error lands in a view model `errorMessage` that no view ever renders — persistence failures are invisible to the user** — §5.4 — `Pawsona/ViewModel/DogViewModel.swift:16`, `Pawsona/ViewModel/VaccineViewModel.swift:15`
6. **[Medium] A PDF of *all* dogs is regenerated on every dogs-array change and the resulting URL is never used** — §7.1 — `Pawsona/View/Dog/DogListView.swift:63-65`
7. **[Medium] `weight` and `sex` exist on the model and are displayed, but no form can set them** — §5.5 — `Pawsona/View/Dog/DogFormView.swift`
8. **[Medium] ~30 SwiftLint style violations (whitespace, braces, comma spacing, 6-parameter functions)** — §9.1, §9.2 — `Pawsona/ViewModel/VaccineViewModel.swift` and others **[fixed in this PR]**
9. **[Medium] Model and ViewModel layers were flat while Views were feature-foldered — inconsistent MVVM layout** — §9.3 **[fixed in this PR]**

## 2. Quick wins

- Delete the unused `deleteDogs(at:)` in `DogListView` (dead since the grid moved to `DogListContentView`). **[fixed in this PR]**
- Run `swiftlint --fix` for trailing whitespace / brace spacing / comma spacing. **[fixed in this PR]**
- Add a `.swiftlint.yml` excluding `build/`, `.derivedData/`, `.claude/` so local lint output matches CI. **[fixed in this PR]**
- Replace `Color(.black)` / `Color(.brown)` tints in `DogListView.swift:48,54` with semantic or asset colors (UIKit-bridged colors, and pure black breaks in dark mode).
- Fix `.frame(width: .infinity)` → `.frame(maxWidth: .infinity)` in `DogCardView.swift:20`.

## 3. Concurrency

### 3.1 Pointless `Task {}` around synchronous deletes
- **Location:** `Pawsona/View/Vaccine/DogVaccinationRecordView.swift:103-107`, `Pawsona/View/Vaccine/VaccineListView.swift:77-81`
- **What:** Synchronous `deleteRecord(id:in:)` calls are wrapped in `Task {}` for no reason.
- **Why:** Adds a main-actor hop per delete, defers work past the `onDelete` animation, and implies asynchrony that doesn't exist.
- **Action:** Call the delete loop directly; reserve `Task` for actual `await`s (as `ReminderFormView.save()` correctly does).
- **Severity:** Low

### 3.2 Main-actor-isolated call from Codable init
- **Location:** `Pawsona/Model/Dog/DogTransferPackage.swift:30`
- **What:** The only concurrency warning in the build log: `DogTransferPackage.init(dog:)` maps records through the main-actor-isolated `VaccineRecordTransferPackage.init(vaccineRecord:)` from a nonisolated context (Codable machinery).
- **Why:** Harmless under Swift 5 mode, but becomes an error under Swift 6 strict concurrency.
- **Action:** Mark the transfer package types `nonisolated` (they are plain value types) or construct them explicitly on the main actor.
- **Severity:** Medium

Otherwise clean: no other concurrency warnings (Swift 5 mode, main-actor-by-default isolation), and `NotificationService` correctly uses async/await behind the `NotificationScheduling` protocol.

## 4. API modernity

_No findings._ The codebase is in good shape here: `FormatStyle` everywhere, no `DateFormatter`, no GCD, `NavigationStack` + `navigationDestination(for:)`, `Tab` API, `ImageRenderer` for PDF, `URL.temporaryDirectory`/`appending(path:)`, `localizedStandardContains` for search.

## 5. Bugs / logic errors

### 5.1 `force_try` in DogListView preview breaks CI
- **Location:** `Pawsona/View/Dog/DogListView.swift:109`
- **What:** `try! ModelContainer(...)` in the `#Preview` block is an error-severity SwiftLint violation — the only error in the repo, and the reason the Code Check workflow fails.
- **Why:** `swiftlint` exits non-zero on errors, so every push fails the check.
- **Action:** Preview-only container creation is genuinely unrecoverable; suppress with a targeted `swiftlint:disable:next force_try`. **[fixed in this PR]**
- **Severity:** High

### 5.2 VaccineRecord↔Dog relationship shape is wrong for the product
- **Location:** `Pawsona/Model/VaccineRecord.swift:14-17`, `Pawsona/Model/Dog.swift:23`
- **What:** `VaccineRecord` held a single `vaccine: VaccineType` and a single `dog: Dog?`, with `Dog.vaccineRecords` cascade-deleting records. Requirement: one record stores multiple vaccines and can be assigned to multiple dogs.
- **Why:** The planned multi-vaccine checkbox UI and multi-dog assignment can't be represented; once shared, cascade delete from one dog would destroy another dog's history.
- **Action:** `vaccines: [VaccineType]` + many-to-many `dogs: [Dog]?` with the inverse on the record side and default (nullify) delete rule, mirroring the existing `Reminder.dogList` pattern. Both stay CloudKit-legal (defaults/optionals, no unique constraints). **[fixed in this PR]**
- **Severity:** High

### 5.3 Dog-less vaccine records were uneditable
- **Location:** `Pawsona/View/Vaccine/VaccineListView.swift:42`
- **What:** The edit sheet guarded on `let dog = vaccineRecord.dog`, so a record with `dog == nil` (a state the model and tests explicitly allow) rendered an empty sheet.
- **Why:** Users could see but never edit or re-assign such records.
- **Action:** Drop the guard; editing no longer requires a dog. **[fixed in this PR]**
- **Severity:** High

### 5.4 Save errors are captured but never shown
- **Location:** `Pawsona/ViewModel/DogViewModel.swift:16`, `Pawsona/ViewModel/VaccineViewModel.swift:15`, `Pawsona/ViewModel/ReminderFormViewModel.swift:21`
- **What:** Every view model stores failures in `errorMessage`, but no view reads it — there is no alert or banner anywhere.
- **Why:** A failed `modelContext.save()` (e.g., CloudKit/store issues) silently drops user data.
- **Action:** Surface `errorMessage` once, centrally (e.g., an `.alert(item:)` on the tab root), rather than per-screen.
- **Severity:** Medium

### 5.5 `weight` and `sex` can never be entered
- **Location:** `Pawsona/View/Dog/DogFormView.swift` (fields absent), `Pawsona/View/Dog/DogDetailView.swift:101-103` (displayed)
- **What:** `Dog.weight`/`Dog.sex` are displayed as stat boxes but the add/edit form has no inputs for them; they're only settable via AirDrop import.
- **Why:** The detail page shows "-" forever for locally created dogs.
- **Action:** Add the two fields to `DogFormView`/`DogDraft` when the product wants them, or drop the stat boxes.
- **Severity:** Medium

### 5.6 `.pawsonadog` files have no format version
- **Location:** `Pawsona/Model/Dog/DogTransferPackage.swift:12`
- **What:** The AirDrop payload is a bare Codable struct; any field rename (like this PR's `vaccine` → `vaccines`) makes old files undecodable with only a generic error.
- **Why:** Cross-device sharing between app versions breaks silently.
- **Action:** Add a `version` field and lenient decoding (`decodeIfPresent` + legacy key fallback) before the format is in the wild.
- **Severity:** Medium

## 6. Security

### 6.1 Unvalidated import via `onOpenURL`
- **Location:** `Pawsona/ViewModel/DogViewModel.swift:137-157`, `Pawsona/View/Dog/DogListView.swift:69-71`
- **What:** Any file handed to the app is read fully into memory, JSON-decoded, and inserted into the store with no size or content sanity checks (`photoData` is unbounded).
- **Why:** A crafted or huge file can bloat the CloudKit-synced store or OOM the app; low real-world risk for this app class, but it is the only untrusted input boundary.
- **Action:** Cap file and `photoData` size, and validate decoded values before insert.
- **Severity:** Low

No secrets in the repo; entitlements are minimal (CloudKit container only).

## 7. Performance

### 7.1 Eager all-dogs PDF on every change, result unused
- **Location:** `Pawsona/View/Dog/DogListView.swift:63-65`
- **What:** `.task(id: viewModel.dogs.map(\.id))` regenerates a PDF of every dog (rendering all photos through `ImageRenderer`) whenever the id list changes — and `exportedPDFURL` is never read anywhere in the view.
- **Why:** Wasted main-thread rendering proportional to photo count on every list mutation.
- **Action:** Delete the task and state, or generate lazily when a share affordance actually needs it (as `DogDetailView` does).
- **Severity:** Medium

### 7.2 Detail view regenerates PDF + transfer file on every appearance
- **Location:** `Pawsona/View/Dog/DogDetailView.swift:81-84`
- **What:** `.task(id: isShowingEditDogForm)` re-renders the PDF and re-encodes the transfer package each time the view appears or the edit sheet toggles.
- **Why:** Acceptable for one dog, but it runs even when the user never opens the share menu.
- **Action:** Generate on first open of the share menu instead.
- **Severity:** Low

## 8. SwiftUI / UI

### 8.1 Invalid `.frame(width: .infinity)`
- **Location:** `Pawsona/View/Component/DogCardView.swift:20`
- **What:** `width: .infinity` is not a valid fixed-frame value; SwiftUI logs "Invalid frame dimension" at runtime and the modifier is ignored.
- **Why:** Layout works only by accident of the sibling `.frame(width: 162)`; the log spam hides real issues.
- **Action:** Use `.frame(maxWidth: .infinity)`.
- **Severity:** High

### 8.2 Hardcoded / UIKit-bridged tint colors
- **Location:** `Pawsona/View/Dog/DogListView.swift:48,54`
- **What:** `Color(.black)` and `Color(.brown)` bridge UIKit colors; pure black toolbar tint is invisible against dark mode chrome.
- **Why:** Violates the project's semantic-color rule and dark-mode contrast.
- **Action:** Use `.primary` / the asset-catalog accent color.
- **Severity:** Medium

### 8.3 `NotificationService` instance per reminder form
- **Location:** `Pawsona/View/Reminder/ReminderFormView.swift:23`
- **What:** Each form default-constructs its own `NotificationService`, separate from the one owned by `UpcomingRemindersView`.
- **Why:** Works today because the underlying notification center is a global singleton, but permission state is tracked per-instance and can diverge.
- **Action:** Pass the existing service down (environment or init) instead of defaulting.
- **Severity:** Low

Accessibility is otherwise in good shape: rows group with `.accessibilityElement(children: .ignore)` + combined labels, buttons are real `Button`s, fonts are text styles, `@ScaledMetric` is used for hero/card heights.

## 9. Dead code / duplication / refactor

### 9.1 SwiftLint style debt in VaccineViewModel and friends
- **Location:** `Pawsona/ViewModel/VaccineViewModel.swift` (brace spacing, comma spacing, trailing whitespace ×6), `Pawsona/App/ContentView.swift:17,21`, `Pawsona/View/Dog/DogListView.swift:17,74`, `Pawsona/Model/Dog.swift:22-23`, `Pawsona/Model/Reminder.swift:16` (implicit `= nil`)
- **What:** ~30 warning-level violations, concentrated in the newest files.
- **Action:** `swiftlint --fix` plus manual cleanup. **[fixed in this PR]**
- **Severity:** Medium

### 9.2 Six-parameter functions
- **Location:** `Pawsona/ViewModel/DogViewModel.swift:69` (`editDog`), `Pawsona/ViewModel/VaccineViewModel.swift:64` (`editRecord`)
- **What:** Both exceeded SwiftLint's 5-parameter threshold by threading every form field individually.
- **Action:** Introduced `DogDraft` for the dog form round-trip; vaccine edit dropped its redundant `dog` parameter (both call sites re-assigned the record's existing dog — a no-op). **[fixed in this PR]**
- **Severity:** Medium

### 9.3 Flat Model/ and ViewModel/ folders
- **Location:** `Pawsona/Model/`, `Pawsona/ViewModel/`
- **What:** 13 model files and 4 view models sat in flat folders while `View/` was already feature-foldered.
- **Action:** Feature subfolders (`Dog/`, `Vaccine/`, `Reminder/`) under each MVVM layer; `View/` layout kept. **[fixed in this PR]**
- **Severity:** Medium

### 9.4 Unused `deleteDogs(at:)` in DogListView
- **Location:** `Pawsona/View/Dog/DogListView.swift:97-105`
- **What:** Private method never referenced since the grid moved into `DogListContentView`.
- **Action:** Deleted. **[fixed in this PR]**
- **Severity:** Low

### 9.5 `VaccineViewModel.vaccines` state largely bypassed
- **Location:** `Pawsona/ViewModel/VaccineViewModel.swift:14`, consumers in `Pawsona/View/Vaccine/`
- **What:** The VM maintains a fetched `vaccines` array, but both list views actually render from `@Query` / `dog.vaccineRecords`; `getAllRecord` runs after every mutation to refresh state nobody reads.
- **Why:** Duplicate source of truth and redundant fetches.
- **Action:** Either drive the views from the VM array or drop it and keep the VM as pure mutation logic.
- **Severity:** Medium

### 9.6 `get`-prefixed method names
- **Location:** `Pawsona/ViewModel/VaccineViewModel.swift:36,49`, `Pawsona/ViewModel/DogViewModel.swift:33,46`
- **What:** `getAllRecord`, `getRecordById`, `getDogLists`, `getDog` violate Swift API Design Guidelines.
- **Action:** Rename (`fetchRecords`, `record(withID:)`, …) in a mechanical follow-up.
- **Severity:** Low

## 10. Cross-cutting recommendations

- **One error-surfacing mechanism.** All five view models replicate `errorMessage` + `saveChanges(in:)`; none is displayed (§5.4). Extract one persistence-error pathway and render it once.
- **Keep CloudKit rules mandatory** (no `@Attribute(.unique)`, defaults/optionals everywhere) — the current models all comply; new models must too.
- **Follow the `Reminder.dogList` pattern** for any future many-to-many with `Dog` (as the vaccine fix now does).
- **Generate share artifacts lazily** rather than eagerly in `.task` blocks (§7.1, §7.2).

## 11. What was NOT audited

- Xcode build settings, scheme configuration, and `project.pbxproj` internals beyond the file-sync group check.
- CloudKit runtime behavior (sync conflicts, migration of existing device stores to the new schema) — the schema change was verified against SwiftData locally via unit tests only.
- Localization (all strings are hardcoded English; the project has not adopted `Localizable.xcstrings` yet).
- Instruments-level performance profiling; §7 findings are code-reading, not traces.
- `security.yml` workflow and asset catalogs.

## 12. Verification

- **§5.1** — `Pawsona/View/Dog/DogListView.swift:109`: `let container = try! ModelContainer(` inside `#Preview`; SwiftLint reports it at error severity, and `codecheck.yml` runs bare `swiftlint`, which exits non-zero on errors.
- **§5.2** — `Pawsona/Model/VaccineRecord.swift:14-17`: `var vaccine: VaccineType` (singular) and `@Relationship(inverse: \Dog.vaccineRecords) var dog: Dog?`; `Pawsona/Model/Dog.swift:23`: `@Relationship(deleteRule: .cascade)`.
- **§5.3** — `Pawsona/View/Vaccine/VaccineListView.swift:42`: `if let vaccineRecord = editingVaccineRecord, let dog = vaccineRecord.dog {` gates the entire edit sheet.
- **§8.1** — `Pawsona/View/Component/DogCardView.swift:20`: `.frame(width: .infinity)`.
- **§5.4** — grep for `errorMessage` across `Pawsona/View/`: zero reads; all writes are in view models.
