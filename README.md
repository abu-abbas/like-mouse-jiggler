# Mouse Jiggler

Aplikasi menu bar untuk macOS yang menggerakkan pointer mouse secara berkala, supaya Mac tidak dianggap idle — layar tidak terkunci, screensaver tidak muncul, dan status "away" di aplikasi kerja tetap online.

Ditulis dengan SwiftUI, tanpa dependensi pihak ketiga.

## Fitur

- Berjalan di menu bar (tanpa ikon Dock, `LSUIElement`)
- Gerakan pointer bolak-balik ke kanan/kiri
- Interval dapat dipilih: 10, 30, atau 60 detik
- Jarak gerak dapat diatur 1–50 px, lewat tombol panah atau scroll wheel
- Status aktif/nonaktif terlihat dari ikon menu bar
- Tampilan dan teks UI dalam bahasa Indonesia

## Kebutuhan

- macOS 14.0 atau lebih baru
- Xcode (untuk build dari source)

## Build & Jalankan

1. Buka `Mouse Jiggler.xcodeproj` di Xcode.
2. Pilih scheme **MouseJiggler**, tekan **⌘R**.

Atau dari terminal:

```sh
xcodebuild -project "Mouse Jiggler.xcodeproj" \
  -scheme MouseJiggler \
  -configuration Release build
```

## Penggunaan

1. Jalankan aplikasi, ikon cursor akan muncul di menu bar.
2. Klik ikonnya untuk membuka panel.
3. Atur **Interval** dan **Jarak gerak** (pengaturan dikunci saat jiggler aktif).
4. Tekan **Start** untuk mulai, **Stop** untuk berhenti, atau **Keluar** untuk keluar dari aplikasi.

## Membuat Rilis

Rilis dibuat otomatis oleh GitHub Actions (`.github/workflows/release.yml`) setiap kali tag `v*` di-push.

1. Tentukan versi rilis dengan SemVer (`MAJOR.MINOR.PATCH`) di Xcode → target **MouseJiggler** → Build Settings → **Versioning → Marketing Version** (`MARKETING_VERSION`). Sekarang `1.0.0`.
2. Commit semua perubahan, lalu buat dan push tag dengan format `v` + versi itu persis:

```sh
git tag v1.0.0
git push origin v1.0.0
```

> Workflow **gagal** kalau tag tidak sama dengan `MARKETING_VERSION` (misal tag `v2.0.0` tapi versi app masih `1.0.0`) — jadi nama file dan isi app tidak pernah bisa beda.
> `CURRENT_PROJECT_VERSION` (build number) bebas, tidak dicek.

3. Tunggu workflow **Release** selesai di tab Actions. Hasilnya jadi 2 asset di halaman **Releases**:
   - `MouseJiggler-v1.0.0.dmg`
   - `MouseJiggler-v1.0.0.app.zip`

Kalau tag yang sama di-push ulang, asset lama ditimpa (`gh release upload --clobber`).

Workflow-nya ada di `.github/workflows/release.yml` dan memakai `GITHUB_TOKEN` bawaan — tidak perlu setup secret apa pun.

## Instalasi dari GitHub Releases

1. Buka halaman **Releases**, unduh `MouseJiggler-vX.Y.Z.dmg` (atau `.app.zip`).
2. Buka `.dmg`, seret **Mouse Jiggler** ke folder **Applications**.
3. Karena app di-sign ad-hoc (tanpa Apple Developer ID), Gatekeeper akan menolak app yang diunduh dari internet. Pilih salah satu:
   - Klik kanan app → **Open** → **Open** lagi, atau
   - jalankan sekali: `xattr -dr com.apple.quarantine "/Applications/Mouse Jiggler.app"`
4. Buka app, lalu berikan izin seperti di bagian **Izin Akses**.

## Izin Akses

Saat pertama menekan **Start**, macOS meminta izin untuk mengontrol event input. Berikan izinnya lewat:

**System Settings → Privacy & Security → Accessibility** (atau **Input Monitoring**) → aktifkan **Mouse Jiggler**.

Tanpa izin ini, pointer tidak akan bergerak. Aplikasi tidak di-sandbox (`ENABLE_APP_SANDBOX = NO`) karena sandbox menghalangi posting event ke HID event tap.

## Cara Kerja

Loop async di `JigglerModel` (`MouseJiggler/ContentView.swift`) berjalan selama aplik aktif:

1. Membaca posisi pointer saat ini via `CGEvent`.
2. Menambahkan offset `distance` px ke sumbu X (nilainya dibalik tiap iterasi supaya gerakannya bolak-balik).
3. Memindahkan kursor dengan `CGWarpMouseCursorPosition` dan memposting event `mouseMoved` ke `cghidEventTap` supaya sistem menganggapnya gerakan nyata.
4. Menunggu `interval` detik, lalu mengulang.

Izin akses dicek dengan `CGPreflightPostEventAccess()` dan diminta dengan `CGRequestPostEventAccess()`.

## Struktur Proyek

```
.github/workflows/
└── release.yml            CI: build → pack → upload ke Releases
Mouse Jiggler.xcodeproj/
├── xcshareddata/xcschemes/  Scheme MouseJiggler (dipakai CI)
└── project.pbxproj
MouseJiggler/
├── MyApp.swift            Entry point, MenuBarExtra
├── ContentView.swift      UI panel + JigglerModel (logika jiggler)
├── Info.plist             Icon app
├── AppIcon.icns
└── Assets.xcassets/       Icon & warna aksen
```

## Info Teknis

| | |
|---|---|
| Bundle ID | `com.wibowo.mousejiggler` |
| Versi | 1.0.0 (SemVer, `MARKETING_VERSION`) |
| Kategori | Utilities |
| Deployment target | macOS 14.0 |
| Sandbox | Nonaktif |
| Dependensi | Tidak ada (SwiftUI, AppKit, CoreGraphics) |
