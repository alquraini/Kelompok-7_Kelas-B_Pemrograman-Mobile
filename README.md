# Kelompok 7 — Kelas B — Pemrograman Mobile

Repository utama untuk pengumpulan tugas mingguan dan pengembangan **Project Akhir** mata kuliah Pemrograman Mobile[cite: 4].

## Anggota Kelompok
1. **Annisa Latifa Alquraini** — D121241038 — `@alquraini` (UI & Screens)[cite: 3, 4]
2. **Dita Ayodya Al Mira** — D121241008 — `@Almiradyaa` (Logic, State & Routing)[cite: 3, 4]
3. **Heniel Putri Tangko Ramba Padang** — D121241044 — `@HenielPutri5` (Models & Backend/Services)[cite: 3, 4].

---

## Project Akhir: Split Bill App (`split_bill_app`)

### Deskripsi & Masalah yang Diselesaikan
**Split Bill App** adalah aplikasi mobile berbasis Flutter yang dirancang untuk memudahkan pencatatan patungan dan pembagian tagihan secara adil, cepat, dan transparan (seperti patungan makan bersama, pengeluaran acara, maupun kas kelompok). Pengguna dapat mencatat daftar item pengeluaran, membagi beban biaya secara merata maupun per item, serta memantau status pelunasan setiap anggota[cite: 5].

### Fitur Utama & Spesifikasi Teknis
- **Autentikasi & Otorisasi:** Sistem masuk dan pengelolaan hak akses pengguna (*Authentication & Authorization*)[cite: 6].
- **Integrasi Firebase & API:** Penyimpanan data tagihan dan grup secara *real-time* menggunakan Firebase serta integrasi open-source API[cite: 6].
- **State Management:** Pengelolaan alur data dan status transaksi antar-layar secara reaktif dan terstruktur[cite: 6, 11].
- **Push Notifications:** Notifikasi pengingat tagihan bagi anggota yang belum menyelesaikan pembayaran[cite: 6].
- **Perhitungan Tagihan Otomatis:** Kalkulasi subtotal, pajak/biaya layanan, serta rincian pembagian per individu.

### Arsitektur & Struktur Direktori
```text
Kelompok-7_Kelas-B_Pemrograman-Mobile/
├── Tugas/                  # Folder pengumpulan tugas mingguan (Tugas_NIM)
└── split_bill_app/         # Kode sumber proyek akhir Flutter
    └── lib/
        ├── screens/        # Antarmuka halaman utama (Anggota 1)
        ├── widgets/        # Komponen UI reusable (Anggota 1)
        ├── providers/      # State management, logika bisnis & routing (Anggota 2)
        ├── models/         # Struktur data & factory method JSON (Anggota 3)
        └── services/       # Integrasi Firebase, API & penyimpanan lokal (Anggota 3)