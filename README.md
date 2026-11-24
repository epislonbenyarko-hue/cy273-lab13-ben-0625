# CY 273 — Lab 13: Release Build of the Capstone Project

| | |
|---|---|
| **Name** | Richard G. Benyarkoh |
| **Index No.** | FCM.41.018.062.025 |
| **Course** | CY 273 — Mobile Application Development (UMaT) |
| **App name** | **UMaT Market** |
| **Version** | `1.0.0+1` (versionName 1.0.0 / versionCode 1) |
| **Application ID** | `gh.edu.umat.lab13_release` |
| **GitHub repo** | https://github.com/epislonbenyarko-hue/cy273-lab13-ben-0625 |

This is the release-practice app for Lab 13: a 2,000-product lazily built
list, search, and favourites stored in a `ChangeNotifier`.

## Release build steps completed

1. **Project** — `flutter create --org gh.edu.umat lab13_release`.
2. **Dependencies** — `provider` for exercise 3; `flutter_launcher_icons`
   added as a dev dependency; unused `cupertino_icons` removed (exercise 4).
3. **Icon** — a 1024×1024 PNG at `assets/icon/icon.png`; config in
   `pubspec.yaml`; generated with `dart run flutter_launcher_icons`.
4. **Name & version** — `android:label="UMaT Market"` in
   `AndroidManifest.xml` and `version: 1.0.0+1` in `pubspec.yaml`.
5. **Signing** — keystore generated with Android Studio's `keytool`:

   ```powershell
   & "C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe" -genkeypair -v `
     -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 `
     -validity 10000 -alias upload `
     -dname "CN=Richard G. Benyarkoh, OU=CY 273, O=UMaT, L=Tarkwa, ST=Western, C=GH"
   ```

   `android/key.properties` holds `storeFile`, `storePassword`, `keyAlias` and
   `keyPassword`. **Both the keystore and key.properties are gitignored and are
   NOT in the submitted zip.**
6. **Gradle** — `android/app/build.gradle.kts` reads `key.properties` and uses
   `signingConfigs.release` for `buildTypes.release`.
7. **Builds**:

   ```powershell
   flutter build apk --release --split-per-abi
   flutter build appbundle --release
   flutter build apk --analyze-size
   ```

## Build output and APK size

```text
flutter build apk --release --target-platform android-arm64
√ Built build\app\outputs\flutter-apk\app-release.apk (15.9 MB, 16,708,108 bytes)

flutter build apk --release --split-per-abi
√ app-armeabi-v7a-release.apk (13.3 MB, 13,980,008 bytes)
√ app-arm64-v8a-release.apk  (15.9 MB, 16,708,112 bytes)
√ app-x86_64-release.apk     (17.3 MB, 18,150,426 bytes)

flutter build appbundle --release
√ Built build\app\outputs\bundle\release\app-release.aab (45.3 MB, 47,466,680 bytes)

flutter build apk --analyze-size --target-platform android-arm64
√ app-release.apk (total compressed): 16 MB
Font asset "MaterialIcons-Regular.otf" tree-shaken 1,645,184 -> 1,920 bytes (99.9%).
Full analysis: C:\Users\RICHARD\.flutter-devtools\apk-code-size-analysis_01.json
```

The release APKs are submitted separately, as the lab manual instructs. The
zip contains source only — no `build/` folder, no keystore, no `key.properties`.

## Performance practices applied

- `ListView.builder` builds only the rows currently on screen instead of all
  2,000 `ListTile`s.
- `RepaintBoundary` around each product tile confines repaints.
- `const` constructors for `ReleaseApp`, `ProductListPage`, `FavouriteCount`
  and the icon widgets.
- `context.select` in `ProductTile` rebuilds only the row whose favourite flag
  changed, not the whole list.
- The search query lives in `ProductBrowser`, a sibling of the `AppBar`, so
  typing never rebuilds the AppBar.
- `cupertino_icons` was removed because no `Cupertino` widget is used.

On a real phone you would run `flutter run --profile`, open **DevTools →
Performance**, scroll the 2,000-item list and confirm the frame bars stay
under the 16 ms (60 fps) budget. This host has no connected physical device,
so the profile-mode check is documented here rather than screenshotted from a
phone; the equivalent widget-level evidence is in `test/release_test.dart`
(fewer than 50 tiles built at rest, and the AppBar `Element` survives typing).

## Exercises completed

### 1. `ListView.builder` vs plain `ListView`

A plain `ListView` instantiates all 2,000 `ProductTile` widgets on the first
frame. That creates thousands of elements immediately, so the first frame and
scroll jank are much worse, and every `setState` has far more children to
diff. `ListView.builder` calls `itemBuilder` only for visible rows (plus a
small cache area), so the widget tree stays a few dozen tiles no matter how
long the list is. I tried the plain version, observed the much larger initial
widget tree, then restored `ListView.builder`; the final code keeps the lazy
version.

### 2. Search without rebuilding the AppBar

`ProductBrowser` owns the `TextEditingController` and filtered index list. The
`AppBar` is built by the sibling `ProductListPage`, so its `Element` is not
rebuilt when the query changes. `test/release_test.dart` asserts this by
capturing the AppBar `Element` before typing and comparing object identity
afterwards.

### 3. Provider + `ChangeNotifier` + `context.select`

`Favourites` is a `ChangeNotifier` provided above `MaterialApp`.
`FavouriteCount` uses `context.select<Favourites, int>((f) => f.count)`, so it
rebuilds only when the number changes. Each `ProductTile` selects its own
`bool`, so toggling one heart rebuilds only that row and the counter.

### 4. Size analysis

`flutter build apk --analyze-size` output is saved in
`analyze_size_output.txt` (excluded from the zip only if large; the README
records the numbers). The three largest parts were:

1. **`lib/arm64-v8a`** — about **16 MB** compressed. This is the ARM64 native
   library containing the Dart AOT snapshot. Inside it, the Dart AOT symbols
   account for ~4 MB decompressed, of which `package:flutter` alone is ~2 MB
   (then `dart:mixin_deduplication` 247 KB, `dart:core` 247 KB, `dart:ui` 212 KB).
2. **`classes.dex`** — **232 KB** compressed: the compiled Android/Kotlin code
   and generated bindings.
3. **`assets/flutter_assets`** — **104 KB** compressed: the Flutter asset bundle
   (the launcher icons also add ~14 KB across `res/`). `resources.arsc` is 7 KB.

The single biggest win was Flutter's icon tree-shaking (Material Icons shrank
from 1.6 MB to 1,920 bytes). Removing unused `cupertino_icons` also removed
its font from the app, and the launcher icon is generated from one 1024×1024
PNG rather than shipping several large hand-drawn images.

I reduced size by removing the unused `cupertino_icons` dependency and keeping
the launcher icon as a single 1024×1024 PNG that Flutter resamples, instead of
shipping several large hand-drawn images.

### 5. Publishing plan (Google Play internal testing)

1. Sign in to <https://play.google.com/console> with a Google account that has
   developer access.
2. **Create app** → name `UMaT Market`, language English, app type **App**,
   free, accept the declarations.
3. **Dashboard → Internal testing → Create new release** → upload the signed
   `.aab` from `build/app/outputs/bundle/release/app-release.aab`.
4. Enter release name `1.0.0 (1)` and release notes ("CY 273 Lab 13 release").
5. Add tester email addresses (or a Google Group) and copy the opt-in link.
6. **Review release** → **Start rollout to Internal testing**.
7. Install via the opt-in link on a phone, confirm the icon, no DEBUG banner,
   search and favourites work.
8. After testing, **Promote release** to Closed testing → Production.

Screenshots of each Play Console page require your own developer account;
the zip instead includes the app screenshots captured locally. Add them to
`screenshots/play_console_*.png` before submitting if you have access.

## Screenshots

- `screenshots/01_product_list.png` — the 2,000-item list (golden capture)
- `screenshots/02_search.png` — filtered to items 199, 1990–1999
- `screenshots/03_favourites.png` — two hearts toggled, `♥ 2` in the AppBar
- `screenshots/04_launcher_icon_preview.png` — the generated icon in a mock
  home screen (no physical phone was available for a real install shot)
- `screenshots/05_github_repo.png` — the pushed GitHub repository page

The first four are deterministic Flutter golden images from the real widgets,
with `debugShowCheckedModeBanner: false`, so no DEBUG ribbon appears.

## Demo video

_Pending — record a short demo and paste the Google Drive/YouTube link here
before submitting (the lab manual asks for a link, not a video file in the
zip)._

Record a short screen capture (search, toggle a favourite, scroll) and paste
the Google Drive/YouTube link above before submitting.

## Tests

```powershell
flutter analyze     # No issues found
flutter test        # all tests passing
```

`test/release_test.dart` covers the notifier, the 2,000-item model, lazy
building, search, clear-search, the unchanged AppBar element, and Provider
favourite toggling.

## Reflection questions

1. **What was the most difficult part of this lab, and how did you solve it?**
   The signing setup was the hardest part: Gradle's KTS file needed to load
   `key.properties`, find the `.jks`, and use `signingConfigs.release` instead
   of the debug key. I generated a keystore with Android Studio's bundled
   `keytool`, kept both secret files out of Git and out of the zip, then built
   split APKs and an App Bundle to prove the configuration worked.

2. **Name one widget, function or concept you used today and explain what it
   does in your own words.**
   **`context.select`**: it watches one small piece of a Provider model. When
   `Favourites` notifies listeners, Flutter compares only the selected value;
   the AppBar counter rebuilds when `count` changes, while the rest of the app
   stays untouched. Combined with `ListView.builder`, that keeps scrolling
   smooth even with 2,000 products.
