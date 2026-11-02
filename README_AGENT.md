# Panduan Agen: Redesign UI Aplikasi Absensi (Flutter)

Dokumen ini ditujukan untuk AI coding agent (Claude Code, Cursor, Copilot, dll).
Baca SELURUH dokumen ini sebelum mengubah file apa pun.

## 1. Tujuan

Mengganti TAMPILAN (UI) aplikasi Flutter absensi ini dengan desain baru yang
sudah disiapkan sebagai widget siap pakai di `lib/core/`, `lib/ui/`, dan `lib/ui_preview.dart`, TANPA mengubah
fungsionalitas yang sudah ada.

Widget baru hanya lapisan presentasi. Tidak ada logika absen, API, state
management, atau navigasi di dalamnya. Semua data dan aksi HARUS datang dari
kode lama project ini lewat parameter dan callback.

## 2. Aturan wajib (tidak boleh dilanggar)

1. JANGAN mengubah business logic, state management (Provider / Bloc / GetX /
   Riverpod / setState, ikuti yang sudah dipakai), service/repository, API call,
   model, routing (nama route dan argumen), validasi, permission (kamera,
   lokasi), maupun alur face detection / absen.
2. Hanya ubah isi `build()` / widget tree layar yang bersangkutan.
3. Semua `TextEditingController`, `GlobalKey<FormState>`, `validator`,
   `onChanged`, `onPressed`, `onTap`, dan binding ke state lama HARUS tetap
   terhubung ke elemen UI yang setara. Jangan diganti nama, dihapus, atau
   dibuat ulang.
4. Jika elemen di desain baru berbeda bentuk dengan yang lama (contoh:
   dropdown menjadi chip), tetap isi variabel/controller yang SAMA dan nilai
   yang dikirim ke API harus identik.
5. JANGAN menghapus atau menimpa file lama. Cukup ubah isi layar yang
   dikerjakan. Jangan pindahkan atau ganti nama file lama.
6. JANGAN mengubah dependency fungsional di `pubspec.yaml` (camera, face
   detection / ML Kit, geolocator, http/dio, dll). Satu-satunya package baru
   yang dibutuhkan: `google_fonts`. Tambah package lain hanya setelah
   menyebutkan alasannya dan mendapat persetujuan.
7. JANGAN mendaftarkan gambar referensi sebagai asset.
8. Kerjakan SATU LAYAR PER KALI. Setelah selesai, jalankan `flutter analyze`,
   ringkas perubahan, lalu BERHENTI dan tunggu pengguna menjawab "lanjut".
9. Semua teks yang tampil ke pengguna memakai bahasa Indonesia yang ramah.
   Teks/angka/nama di mockup dan `ui_preview.dart` hanyalah DATA CONTOH. Isi
   dari data asli aplikasi.

## 3. Struktur folder

Folder-folder ini berada langsung di `lib/` project utama (tidak ada folder
tambahan seperti ):

```
lib/
  (file-file lama project, TIDAK disentuh)
  core/
    theme/
      app_colors.dart        Warna + extension Color.a(opacity)
      app_theme.dart         ThemeData (font Plus Jakarta Sans via google_fonts)
    widgets/
      glow.dart              Lingkaran blur ("cahaya") untuk background gelap
      glass_container.dart   Efek kaca (BackdropFilter)
      gradient_button.dart   Tombol gradient + state loading/disabled
      status_badge.dart      Badge status (BadgeKind)
      step_indicator.dart    Indikator langkah (Wajah, Lokasi, Kirim)
      live_clock.dart        Jam real-time (tampilan saja) + pad2()
      dashed_border.dart     Painter border putus-putus
      glass_bottom_nav.dart  Bottom nav kaca ala iPhone
  ui/
    splash_body.dart         Tampilan splash
    home_body.dart           Tampilan beranda
    face_attendance_view.dart  Overlay absen wajah
    leave_form_view.dart     Kerangka + komponen form pengajuan
  ui_preview.dart            Demo dengan data contoh (referensi cara pakai)
```

Jika project sudah punya folder `lib/core` atau `lib/ui`, isinya digabung dengan
folder baru ini. JANGAN menimpa file lama yang namanya sama. Jika ada nama file
yang bentrok, hentikan dan tanyakan pengguna (atau beri nama lain pada file baru
dan perbarui import-nya).

Import: semua file baru memakai import relatif di antara mereka sendiri. Dari file
lama, impor dengan `import 'package:<nama_package_app>/ui/home_body.dart';`
(sesuaikan nama package di `pubspec.yaml`) atau path relatif.

Cara melihat demo tanpa menyentuh app: `flutter run -t lib/ui_preview.dart`.
`ui_preview.dart` adalah contoh pemakaian terbaik. Baca file itu.

## 4. Langkah awal (sekali saja)

1. Pastikan `google_fonts` ada di `pubspec.yaml` (`flutter pub add google_fonts`).
2. Di `MaterialApp`, set `theme: AppTheme.light`. Pertahankan properti lain
   (routes, home, navigatorKey, locale, dll).
3. Jika app sudah punya `theme` sendiri, gabungkan dengan `AppTheme.light.copyWith(...)`
   atau tanyakan pengguna, jangan dihapus begitu saja.
4. Analisis project dulu: daftar semua screen, state management yang dipakai,
   dan package di `pubspec.yaml`. Tampilkan ringkasannya ke pengguna.

## 5. Panduan per layar

### 5.1 Splash

Widget: `SplashBody({pill, headline, headlineAccent, subtitle, loadingLabel})`

- Biarkan SEMUA logika splash lama (initState, cek login/token, Timer, auto
  navigate) apa adanya.
- Ganti isi `build()` menjadi `const SplashBody()`.
- Opsional: samakan warna native splash (`flutter_native_splash`) dengan
  `#0A1030` jika package itu sudah dipakai. Jangan menambahkannya jika belum ada.

### 5.2 Beranda + bottom nav

Widget: `HomeBody(...)`, `GlassBottomNav(...)`, `WeekBar`, `LeaveItem`.

```dart
Scaffold(
  extendBody: true, // WAJIB agar efek kaca bottom nav terlihat
  body: HomeBody(
    userName: ..., initials: ..., dateLabel: ...,
    checkIn: ..., checkOut: ..., duration: ...,
    working: sudahCheckInBelumPulang,
    statusLabel: 'Sedang bekerja', // atau 'Belum absen' / 'Sudah pulang'
    progress: 0.44,                // 0.0 sampai 1.0, durasi kerja / target
    weekBars: [...], weekSummary: '...',
    requests: [...],
    onAbsen: () => /* navigasi lama */,
    onRiwayat: ..., onPengajuan: ..., onProfil: ...,
    onRefresh: () async => /* fungsi refresh lama */,
  ),
  bottomNavigationBar: GlassBottomNav(
    currentIndex: indexLama,
    onTap: (i) => /* logika ganti tab lama */,
    items: const [
      GlassNavItem(Icons.home_rounded, 'Beranda'),
      GlassNavItem(Icons.history_rounded, 'Riwayat'),
      GlassNavItem(Icons.description_rounded, 'Pengajuan'),
      GlassNavItem(Icons.person_rounded, 'Profil'),
    ],
  ),
)
```

Catatan:
- `onTap` pada `GlassBottomNav` HARUS memakai mekanisme pindah tab/rute yang
  sudah ada (setState index, PageController, Get.toNamed, context.go, dll).
- Jika app sudah punya bottom nav, ganti widget-nya saja. Jumlah dan urutan
  tab mengikuti yang lama (ubah `items` bila tab-nya bukan 4).
- Jika jam kerja/progress tidak tersedia di data lama, hitung dari data yang ada
  atau beri nilai default `0`. Jangan membuat API baru.
- Bagian yang datanya tidak ada (mis. grafik mingguan, pengajuan terbaru) boleh
  dikosongkan: `weekBars` / `requests` kosong menyembunyikan kartunya.
- Jam besar di header memakai `LiveClock` bawaan. Itu hanya tampilan.
- Tampilkan shimmer/loading dengan cara yang sudah dipakai app saat data belum ada.

### 5.3 Absen wajah

Widget: `FaceAttendanceView(...)`, enum `FaceState { searching, detected, failed }`.

```dart
FaceAttendanceView(
  camera: /* CameraPreview milik controller lama */,
  faceState: /* petakan dari state deteksi wajah lama */,
  doneSteps: /* 0..3 sesuai tahap: wajah, lokasi, kirim */,
  locationName: ..., distanceLabel: ..., insideRadius: ..., dateLabel: ...,
  busy: sedangMengirim,
  onCheckIn: bolehCheckIn ? fungsiCheckInLama : null,
  onCheckOut: bolehCheckOut ? fungsiCheckOutLama : null,
  onBack: ..., onFlipCamera: ... (null jika fitur balik kamera tidak ada),
)
```

Penting:
- JANGAN mengubah `CameraController`, stream/analisis frame, face detection,
  validasi radius, maupun fungsi pengiriman. Widget ini hanya overlay visual
  (dibungkus `IgnorePointer`, tidak menangkap sentuhan dan tidak mengganggu kamera).
- Kirim `null` ke `onCheckIn` / `onCheckOut` jika aturan lama menonaktifkan
  tombolnya (mis. check out belum boleh sebelum check in). Tombol otomatis
  tampil redup.
- Agar preview kamera memenuhi layar tanpa gepeng, bungkus seperti ini:
  ```dart
  SizedBox.expand(
    child: FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize!.height,
        height: controller.value.previewSize!.width,
        child: CameraPreview(controller),
      ),
    ),
  )
  ```
  Sesuaikan dengan cara app ini sudah menampilkan preview (jangan mengubah
  controller-nya). Jika preview lama sudah benar, pakai apa adanya.
- Titik-titik landmark di bingkai hanyalah animasi hiasan. Jangan dipetakan ke
  hasil deteksi kecuali pengguna meminta.
- Pesan sukses/gagal setelah absen: pakai dialog/bottom sheet yang sudah ada,
  boleh dibungkus gaya baru (`GlassContainer`, `GradientButton`), tapi alurnya sama.

### 5.4 Form pengajuan (semua jenis: izin, sakit, cuti, lembur, dll)

Widget: `LeaveFormScaffold`, `FormSection`, `AppChoiceChips<T>`, `AppDateField`,
`AppTextField`, `AttachmentPicker`.

```dart
Form(
  key: _formKey, // formKey lama
  child: LeaveFormScaffold(
    title: 'Pengajuan Izin',
    subtitle: 'Isi data dengan lengkap',
    submitting: sedangMengirim,
    onSubmit: () {
      // pertahankan alur lama (validate lalu submit)
      if (_formKey.currentState!.validate()) { fungsiSubmitLama(); }
    },
    children: [
      FormSection(
        title: 'Jenis pengajuan',
        child: AppChoiceChips<JenisLama>(
          values: daftarJenisLama,
          selected: jenisTerpilihLama,
          labelOf: (v) => namaTampilanLama(v),
          onSelected: (v) => setState(() => jenisTerpilihLama = v), // variabel yang SAMA
        ),
      ),
      FormSection(
        title: 'Tanggal',
        child: Row(children: [
          Expanded(child: AppDateField(label: 'Mulai', valueText: ..., onTap: showDatePickerLama)),
          const SizedBox(width: 10),
          Expanded(child: AppDateField(label: 'Selesai', valueText: ..., onTap: showDatePickerLama)),
        ]),
      ),
      FormSection(
        title: 'Alasan',
        child: AppTextField(controller: alasanController, validator: validatorLama, maxLines: 3, maxLength: 200),
      ),
      FormSection(
        title: 'Lampiran',
        child: AttachmentPicker(onPick: pilihFileLama, onRemove: hapusFileLama, fileName: ..., fileSizeLabel: ...),
      ),
    ],
  ),
)
```

Catatan:
- Terapkan gaya yang sama ke SEMUA form pengajuan di app. Field disesuaikan
  dengan form masing-masing (tambah/kurangi `FormSection`). Field yang tidak ada
  di form lama jangan dibuat baru.
- Validator lama tetap dipakai lewat `AppTextField(validator: ...)`. Untuk field
  non-teks (tanggal, dropdown), gunakan `errorText` pada `AppDateField` dari
  hasil validasi lama.
- `LeaveFormScaffold` sudah berisi `Scaffold`, header, dan tombol kirim yang
  menempel di bawah. Jika layar lama punya `Scaffold`/AppBar, gantikan
  seluruhnya dengan widget ini. Keyboard tidak menutup input karena Scaffold
  menangani `resizeToAvoidBottomInset`.
- Dropdown lama boleh tetap dipakai jika pilihannya terlalu banyak untuk chip
  (lebih dari sekitar 5). Gaya dropdown cukup mengikuti `AppTheme.inputDecorationTheme`.
- Badge durasi ("2 hari") hanya dihitung dari tanggal yang dipilih, tampilan saja.

### 5.5 Layar lain yang tidak punya widget siap pakai

Login, Riwayat, Status Pengajuan, Profil/Pengaturan, dialog, dll. Ikuti gaya yang
sama memakai komponen di `lib/core/`:

- Header gelap melengkung: lihat `_HeaderBg` di `home_body.dart` dan `leave_form_view.dart`.
- Kartu putih: radius 20, shadow lembut, background layar `AppColors.bg`.
- Badge status: `StatusBadge` (Tepat Waktu = success, Terlambat = warning/orange,
  Izin = info, Alpa = danger, Menunggu = warning, Disetujui = success, Ditolak = danger).
- Tombol utama: `GradientButton`. Input: `AppTextField`.
- Efek kaca di atas background gelap: `GlassContainer`.
- Daftar riwayat: kartu putih + `StatusBadge`, empty state ramah, loading
  mengikuti yang sudah ada.
- Layar yang punya bottom nav memakai `GlassBottomNav` yang sama.

Kerjakan layar tambahan ini hanya setelah splash, beranda, absen wajah, dan form
selesai dan disetujui pengguna.

## 6. Design tokens (rujukan cepat)

| Nama | Nilai |
|------|-------|
| Primer | `#2F5BEA` (gelap `#1E3A8A`) |
| Background gelap | `#0A1030` (+ cahaya ungu `#7C3AED`, cyan `#22D3EE`) |
| Hijau (Check In) | `#15803D` / `#166534`, aksen `#4ADE80` |
| Oranye (Check Out / terlambat) | `#C2410C` / `#9A3412` |
| Background terang | `#F5F7FB`, kartu putih |
| Teks | `#0F172A`, sekunder `#475569`, border `#CBD5E1` |
| Font | Plus Jakarta Sans (400, 600, 800) |
| Radius | input/chip 14, kartu 20 sampai 22, panel 28 sampai 32, tombol 16 sampai 20 |

Gunakan `AppColors` dan `Theme.of(context)`. Jangan hardcode warna baru di layar.
Helper `color.a(0.5)` adalah pengganti `withOpacity` (aman untuk semua versi Flutter).

## 7. Kualitas kode dan performa

- Flutter 3.10+ (Dart 3). Jika versi lebih lama, laporkan ke pengguna.
- Pakai `const` sebisa mungkin. Dispose semua controller dan `AnimationController`
  milik widget yang kamu buat.
- Efek blur (`BackdropFilter`, `ImageFiltered`) mahal. Jangan menambah blur baru
  tanpa perlu, dan jangan menumpuk banyak blur di layar yang sama. Uji performa
  di perangkat asli (mode release), bukan hanya emulator.
- Touch target minimal 48x48, kontras teks memadai, pakai `SafeArea`/`MediaQuery`
  padding. Hindari overflow di layar kecil.
- Jika perlu mengubah file di `lib/core` atau `lib/ui` (mis. bug tampilan), ubah seminimal
  mungkin dan sebutkan di ringkasan. Jangan mengubah parameter publik widget
  tanpa memberi tahu pengguna.

## 8. Alur kerja yang diharapkan

1. Baca dokumen ini, `lib/ui_preview.dart`, dan semua file di
   `lib/core` dan `lib/ui`.
2. Analisis project (daftar screen, state management, package). Laporkan.
3. Lakukan langkah awal (bagian 4).
4. Kerjakan layar berurutan: Splash, Beranda (termasuk bottom nav), Absen wajah,
   Form pengajuan (semua jenis), lalu layar lain.
5. Setelah TIAP layar:
   - jalankan `flutter analyze`, pastikan tidak ada error/warning baru;
   - ringkas apa yang diubah dan file mana saja;
   - konfirmasi bahwa semua tombol, input, dan navigasi lama tetap tersambung;
   - berhenti dan tunggu pengguna menjawab "lanjut".
6. Di akhir, buat checklist uji manual untuk pengguna.

## 9. Checklist regresi (diisi di akhir)

- [ ] Splash: auto-login / cek token tetap jalan, navigasi ke layar yang benar
- [ ] Login dan logout
- [ ] Beranda: data hari ini benar, pull-to-refresh jalan
- [ ] Bottom nav: tiap tab membuka layar yang sama seperti sebelumnya
- [ ] Permission kamera dan lokasi tetap diminta seperti sebelumnya
- [ ] Check In berhasil, data terkirim sama seperti sebelumnya
- [ ] Check Out berhasil, aturan enable/disable tombol sama seperti sebelumnya
- [ ] Wajah tidak dikenali / di luar radius: pesan dan perilaku sama
- [ ] Setiap form pengajuan: validasi, upload lampiran, dan submit sama
- [ ] Riwayat, status pengajuan, profil, dan logout
- [ ] Tidak ada overflow di layar kecil, keyboard tidak menutupi input

## 10. Yang JANGAN dilakukan

- Jangan menulis ulang logika "biar rapi".
- Jangan mengganti state management atau struktur folder lama.
- Jangan menambah fitur yang tidak ada di app lama.
- Jangan menghapus field, tombol, atau validasi lama karena tidak ada di desain.
  Jika ada elemen lama yang tidak punya padanan di desain baru, pertahankan dan
  beri gaya yang serasi, atau tanyakan pengguna.
- Jangan lanjut ke layar berikutnya sebelum pengguna menyetujui layar sebelumnya.
- Jangan melaporkan "selesai" tanpa menjalankan `flutter analyze`.
