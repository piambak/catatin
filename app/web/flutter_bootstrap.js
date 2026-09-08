// app/web/flutter_bootstrap.js
//
// Bootstrap kustom — menggantikan berkas yang biasanya dibuat otomatis
// `flutter build web`.
//
// Bedanya cuma satu: `_flutter.loader.load()` dipanggil TANPA
// `serviceWorkerSettings`, jadi tidak ada service worker yang didaftarkan.
//
// Kenapa: situs ini dipakai untuk memperlihatkan perubahan UI ke kontributor.
// Dengan service worker, pengunjung yang pernah membuka halaman ini akan terus
// mendapat versi lama dari cache — dan "hard reload" TIDAK menghapusnya, karena
// Ctrl+Shift+R hanya melewati cache HTTP, bukan membatalkan service worker yang
// sudah terdaftar. Service worker Flutter memasang versi baru di latar lalu
// mengaktifkannya pada navigasi berikutnya, sehingga gejalanya khas: "masih
// lama setelah reload sekali, baru benar setelah dua kali".
//
// Untuk situs pratinjau, caching offline tidak memberi manfaat apa pun dan
// justru membuat setiap rilis tampak gagal. Flutter sendiri sudah menandai
// service worker-nya deprecated.
//
// Kalau nanti aplikasi ini perlu jalan offline sungguhan, kembalikan
// `serviceWorkerSettings` di sini dan siapkan cara memberi tahu pengguna saat
// ada versi baru — jangan mengandalkan mereka menebak harus reload dua kali.

{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load();
