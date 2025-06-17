# MovieRent

Aplikasi Flutter untuk menyewa film yang terintegrasi dengan Firebase dan The Movie Database (TMDB) API. Proyek ini memanfaatkan Firestore sebagai basis data cloud, Crashlytics untuk pelaporan error, serta konfigurasi splash screen dan launcher icon.


## User UI
<div align="center">
   <img src="https://github.com/user-attachments/assets/1f9d174b-4e40-46c3-93d7-639765df4cb2" width="245"/>
   <img src="https://github.com/user-attachments/assets/43c0b2c8-0605-4097-9754-7383a5c49f9b" width="245"/>
   <img src="https://github.com/user-attachments/assets/21b56a91-a21e-44dd-97e9-84c2dc925ac7" width="245"/>
   <img src="https://github.com/user-attachments/assets/034450e4-3e5b-4bcd-9911-c8ac3bafb7a2" width="245"/>
   <img src="https://github.com/user-attachments/assets/56021c63-54e9-4f08-b33b-7f213b4876a0" width="245"/>
   <img src="https://github.com/user-attachments/assets/7fdccf91-f523-40d7-b6b7-317fc21cda65" width="245"/>
   <img src="https://github.com/user-attachments/assets/74fa6179-5e90-4993-a94d-ac52a1528b6a" width="245"/>
   <img src="https://github.com/user-attachments/assets/8822675d-b46c-4d79-9bd8-dc7cbbc2fcf3" width="245"/>
</div>

## Admin UI
<div align="center">
   <img src="https://github.com/user-attachments/assets/f5a266b3-7a21-4d05-9fcb-8999e8a99cbc" width="245"/>
   <img src="https://github.com/user-attachments/assets/f32efc04-4327-4da9-87c7-93458711661b" width="245"/>
   <img src="https://github.com/user-attachments/assets/83be6137-a6b8-4d51-94fd-ab241e6aa771" width="245"/>
   <img src="https://github.com/user-attachments/assets/8c2cdfa9-7952-4b50-b62b-c8a9b6570902" width="245"/>
   <img src="https://github.com/user-attachments/assets/0207ea16-5859-4e3c-91be-3ada671f7d87" width="245"/>
</div>


## Rincian Kontribusi

- **Thariq Ivan**
  - Integrasi awal **Firestore** sebagai basis data cloud
  - Membangun modul **Favourite** dan melakukan berbagai perbaikan tampilan dan update favorite
  - Membuat **Rent Page** lengkap dengan proses transaksi (create/update/delete)
  - Menambah animasi **Lottie** pada proses pembayaran
  - Menambahkan **Payment Page** sekaligus perbaikan API dan navigator
  - Menyediakan fitur **update transaction data** untuk admin
  - Mengelola **inventory movie** serta pembaruan stok film
  - Menyertakan **Crashlytics** untuk monitoring error aplikasi
  - Membuat **Splash Screen** dan **Launcher Icon**
- **Muhammad Farras Arif Fadhila**
  - Membuat fitur **Login Page**
  - Integrasi **API**
  - Membuat **Homescreen** dan drawer user
  - Membuat **Admin Panel/Screen**, drawer admin dan **Edit profile admin** (Update)
  - Membuat fitur **Voucher** dan bisa digunakan saat user melakukan transaksi dan input voucher pada kolomnya (Create/Delete)
  - Membuat fitur **Konfirmasi Status Transaksi** oleh admin
  - Membuat fitur **Search Movie**
  - Membuat fitur **History Transaksi** sisi admin dan user

## Fitur Utama

- **Autentikasi** – login/registrasi menggunakan `firebase_auth` sebagai dasar akses semua data.
- **Integrasi TMDB API** – mengambil daftar film populer, tayang, maupun yang akan datang secara real time.
- **Favourite & Wishlist** – pengguna dapat menambah atau menghapus film ke dalam wishlist per kategori serta melihat daftar film yang telah disimpan.
- **Transaksi Penyewaan** – proses sewa film disertai opsi memasukkan voucher. Riwayat transaksi dicatat pada koleksi `transactions` dan statusnya dapat diperbarui (konfirmasi admin, pengembalian film, dll.).
- **Inventori** – admin dapat mengubah stok film (menambah/mengurangi) serta melihat laporan peminjaman.
- **Voucher** – pembuatan, pengecekan validitas, dan penggunaan voucher yang otomatis menandai statusnya sebagai sudah dipakai.
- **Admin Panel** – admin memiliki fitur:
   - Konfirmasi dan mengubah status penyewaan
   - Mengelola inventori stok film
   - Membuat serta menghapus voucher diskon
   - Melihat keseluruhan histori transaksi
- **Crashlytics** – memonitor error aplikasi di produksi.
- **Splash Screen & Launcher Icon** – dihasilkan melalui `flutter_native_splash` dan `flutter_launcher_icons`.

## Struktur Proyek

- `lib/main.dart` – titik awal aplikasi.
- `lib/Model/` – definisi model data (film, transaksi, voucher).
- `lib/Services/` – layanan API TMDB dan interaksi Firestore.
- `lib/screens/` – kumpulan tampilan seperti login, home, favourite, admin panel, dan lainnya.

## Persiapan

1. Pastikan Flutter telah terpasang.
2. Jalankan `flutter pub get` untuk mengambil dependensi (lihat `pubspec.yaml`).
3. Siapkan Firebase project dan file `google-services.json` untuk Android.
4. Buat berkas `.env` di root proyek berisi:
   ```
   TMDB_API_KEY=<apikey Anda>
   ```
5. (Opsional) jalankan perintah berikut untuk menghasilkan ikon dan splash screen:
   ```bash
   flutter pub run flutter_launcher_icons
   flutter pub run flutter_native_splash:create
   ```

## Implementasi CRUD

| Fitur | Create | Read | Update | Delete |
|-------|--------|------|--------|--------|
| Favourite | Menambahkan film ke daftar favorit | Menampilkan daftar film tersimpan |  Menghapus film dari daftar | - |
| Wishlist | Menambahkan film ke daftar wishlist | Menampilkan daftar film tersimpan | Mengubah kategori atau memindahkan film | Menghapus film dari daftar |
| Transaksi Penyewaan | Membuat transaksi baru saat penyewaan film | Melihat riwayat transaksi | Mengubah status (disetujui, dikembalikan) dan keterangan transaksi | Menghapus data trasaksi |
| Inventori | Menambah stok film yang belum ada di daftar | Melihat stok yang tersedia | Menyesuaikan jumlah stok | - |
| Voucher | Menambahkan voucher baru | Menampilkan daftar voucher aktif | Menandai voucher sebagai terpakai | Menghapus/menonaktifkan voucher |

## Menjalankan Aplikasi

Setelah langkah di atas selesai, jalankan aplikasi dengan:

```bash
flutter run
```

Aplikasi akan menampilkan daftar film dari TMDB dan memungkinkan pengguna melakukan proses sewa lengkap dengan histori transaks
