# Multi-Puppy Vaccine — Progress & Context

Catatan ini buat lanjutin coding manual (vibecode) di Claude biasa, biar ada konteks
tanpa harus re-explain dari nol. Branch: `feature/multi-puppy-vaccine-views`.

## Kenapa fitur ini ada

Referensi desain: 4 layar (Empty State, New Vaccination Record, filled form, Saved
Vaccination Record) — intinya satu form vaccine bisa milih **banyak puppy sekaligus**,
tapi di database `VaccineRecord.dog` itu **1-ke-1** (satu record cuma nempel 1 dog).
Jadi kalau pilih 3 puppy, sistem bikin **3 `VaccineRecord` terpisah** (vaccine +
tanggal sama, dog beda) — dan pas ditampilin di list, 3 record itu perlu digabung
lagi jadi 1 card visual (avatar numpuk).

## Yang udah selesai

1. **`Pawsona/View/VaccineSelectionRow.swift`** — radio-style row buat pilih 1 vaccine
   (single-select). Dipake di dalam `Form` section "Vaccine".
2. **`Pawsona/View/DogAvatarSelectionRow.swift`** — avatar bulat + nama, multi-select
   (ring muncul kalau kepilih). Dipake horizontal di section "Dog".
3. **`Pawsona/ViewModel/VaccineRecordFormViewModel.swift`** — otak form:
   - `vaccine`, `dateGiven`, `notes`, `selectedDogs: [Dog]`
   - `toggleDog(_:)`, `isSelected(_:)`, `isSaveEnabled`
   - `save(in:)` — mode edit update 1 record, mode baru loop `createRecord` per dog
     di `selectedDogs`
4. **`Pawsona/View/VaccineRecordFormView.swift`** — form utuh, gabungan komponen di
   atas + `VaccineRecordFormViewModel`. Toolbar X/checkmark bentuk bulat.
5. **`Pawsona/View/VaccineListView.swift`** — sheet add/edit udah nyambung ke form
   baru (`VaccineRecordFormView()` / `VaccineRecordFormView(editing:)`).

## Yang BELUM — ini yang mau dikerjain manual

### `groupedRecords` di `VaccineListView.swift`

Tujuan: dari `vaccineRecords: [VaccineRecord]` (flat, hasil `@Query`), kelompokkan
jadi grup berdasarkan `vaccine` + `dateGiven` yang sama, biar tiap grup jadi 1 card
di List (nunjukin nama vaccine, tanggal, dan avatar numpuk semua dog di grup itu).

Konsep (bukan kode jadi, biar dikerjain sendiri):

- Pakai `Dictionary(grouping:by:)` dari Swift stdlib — nggak perlu dependency baru.
- Key groupingnya gabungan `vaccine` (enum) + `dateGiven` (Date). Karena Date
  presisinya sampai detik/nanosecond, kalau mau dianggap "record yg sama" biarpun
  disimpen beda milidetik, mending normalize dulu ke `Calendar.current.startOfDay`
  atau bulatkan ke menit sebelum dijadiin key.
- Hasil grouping itu `[Key: [VaccineRecord]]` — perlu diubah ke array biar bisa
  di-`ForEach` di List (Dictionary nggak punya urutan stabil). Sort by tanggal
  terbaru dulu (`dateGiven descending`) biar konsisten sama `@Query` yang lain.
- Tiap grup butuh ditampilin sebagai 1 row/card baru — bikin view kecil misal
  `VaccineRecordGroupRowView` (nama vaccine, tanggal, `HStack` avatar numpuk dari
  `group.compactMap(\.dog)`), gantiin `VaccineRecordRowView` yang sekarang dipake
  flat per-record.
- Edit-tap: karena 1 card mewakili banyak `VaccineRecord`, mikirin dulu UX-nya —
  apa tap-nya buka semua record itu buat diedit bareng, atau cuma buka salah satu?
  (belum diputusin, ini keputusan produk yang perlu dipikirin sebelum ngoding)

### Checklist singkat
- [ ] Bikin key grouping (vaccine + dateGiven yang dinormalize)
- [ ] `groupedRecords: [...]` computed property pakai `Dictionary(grouping:)`
- [ ] View baru buat 1 card/grup (avatar numpuk)
- [ ] Ganti `ForEach(vaccineRecords)` jadi `ForEach(groupedRecords)` di `recordList`
- [ ] Putusin UX tap-to-edit buat card yang isinya banyak record

## Catatan tambahan

- Beberapa error SourceKit ("Cannot find type X in scope") yang muncul selama
  sesi ini kemungkinan besar cuma index lag di editor (environment CLI cuma ada
  Command Line Tools, bukan Xcode penuh) — build asli di Xcode buat validasi nyata.
- Semua komponen baru dibuat tanpa dependency luar, sesuai `CLAUDE.md` (native
  SwiftUI + SF Symbols aja).
