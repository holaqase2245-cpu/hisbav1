# حسبة — Android

هذه النسخة تحتوي كود التطبيق وملف هوية حسبة. إذا كان مجلد `android/` غير موجود، جهّزه مرة واحدة بالأمر التالي:

```bash
./tool/prepare_android.sh
```

السكريبت يقوم بـ:
- إنشاء ملفات Android الخاصة بـ Flutter.
- تغيير اسم التطبيق الظاهر في الجهاز إلى **حسبة**.
- توليد أيقونات Android من `assets/icon/hisba_icon.png` بنفس الثيم الداكن/الذهبي.

بعدها:

```bash
flutter pub get
flutter build apk --release
```

الـ APK يكون عادةً في:
`build/app/outputs/flutter-apk/app-release.apk`

ولـ Play Store:

```bash
flutter build appbundle --release
```
