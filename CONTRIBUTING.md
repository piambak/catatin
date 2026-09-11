# Panduan Kontribusi

Panduan lengkapnya ada di wiki proyek:

**→ [wiki/panduan/kontribusi.md](wiki/panduan/kontribusi.md)**

Berkas ini sengaja ditinggal di root: GitHub hanya mencari `CONTRIBUTING.md` di
root, `.github/`, atau `docs/` — **tidak** di `wiki/`. Tanpa berkas ini, tautan
"Contributing guidelines" yang muncul otomatis saat orang membuka isu atau pull
request akan hilang.

Ringkasnya, kalau kamu buru-buru:

- Sunting hanya di `app/`, `wiki/`, `tool/`, dan `.github/`.
- Berkas hasil build di root (`index.html`, `main.dart.js`, `assets/`,
  `canvaskit/`, `icons/`) digenerate otomatis — jangan disunting manual.
- Awalan nama branch: `fitur/`, `perbaikan/`, `docs/`, `tooling/`.
- Sebelum membuka PR, jalankan `flutter analyze` dan `flutter test` di `app/`.
