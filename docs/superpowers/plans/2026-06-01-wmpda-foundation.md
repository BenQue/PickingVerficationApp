# WMPDA Plan 1 — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a runnable native Kotlin/Compose Android app `WMPDA` (new repo at `/Users/benque/Projects/WMPDA`) with the full online-only infrastructure spine — DI container, WMS network layer, response interpreter, hardware scanner, session, theme, shared components, login, and workbench — so feature plans (合箱校验 / 线边管理 / 中央立库) can plug in.

**Architecture:** Manual DI via a single `AppContainer` object (no Hilt/Koin). Online-only: repositories call Retrofit/OkHttp directly and translate responses through `ResponseInterpreter`; no Room, no WorkManager, no sync. Auth is ASP.NET cookie (OkHttp cookie jar) + identity fields carried per-request; `SessionManager` (DataStore) is the single source of `employeeId / factoryId / workCenter`. Compose UI uses one `StateFlow<UiState>` per screen, `viewModel()` default factory, dependencies pulled from `AppContainer`. Theme is QuickFill's "Industrial Modern Blue v2.1" copied verbatim.

**Tech Stack:** Kotlin 2.0.21 · Jetpack Compose (BOM 2024.10.01, Material 3) · Navigation-Compose · Retrofit 2.11 + OkHttp 4.12 + Gson · DataStore Preferences · JUnit4 + coroutines-test.

**Spec:** `docs/superpowers/specs/2026-06-01-wmpda-warehouse-pda-rewrite-design.md` (§2 architecture, §3 structure, §4 network/auth, §5.1 login, §5.2 workbench, §5.6 scanner, §6 design system).

**Reference source (read-only, DO NOT copy package names):** QuickFill at `/Users/benque/Projects/QuickFill/app/src/main/java/com/quickfill/`. This plan already contains the adapted code; reference only if a step is ambiguous.

---

## File Structure

All paths are under the new repo root `/Users/benque/Projects/WMPDA/`. Kotlin sources under `app/src/main/java/com/bizlink/wmpda/`.

```
WMPDA/
├── settings.gradle.kts                 # root: rootProject.name + include(:app)
├── build.gradle.kts                    # root: plugin aliases (apply false)
├── gradle.properties                   # jvmargs, androidX, kotlin.code.style
├── gradle/libs.versions.toml           # version catalog (NO room/ksp/workmanager)
├── gradle/wrapper/...                  # copied from QuickFill (gradle 8.x)
├── gradlew, gradlew.bat                # copied from QuickFill
├── .gitignore
└── app/
    ├── build.gradle.kts                # namespace com.bizlink.wmpda, BuildConfig base URL
    └── src/
        ├── main/
        │   ├── AndroidManifest.xml
        │   ├── res/values/strings.xml
        │   ├── res/font/...            # IBM Plex Sans + JetBrains Mono ttf (copied)
        │   └── java/com/bizlink/wmpda/
        │       ├── WmpdaApp.kt
        │       ├── MainActivity.kt
        │       ├── AppContainer.kt
        │       ├── core/
        │       │   ├── network/
        │       │   │   ├── WmsResult.kt
        │       │   │   ├── ResponseInterpreter.kt
        │       │   │   ├── TokenExtractor.kt
        │       │   │   ├── WmsEnvelope.kt
        │       │   │   ├── AuthInterceptor.kt
        │       │   │   ├── NetworkClient.kt
        │       │   │   ├── WmsApi.kt
        │       │   │   └── dto/LoginDtos.kt
        │       │   ├── session/SessionManager.kt
        │       │   ├── scanner/ScannerReceiver.kt
        │       │   ├── nav/Routes.kt
        │       │   ├── nav/NavGraph.kt
        │       │   ├── theme/{Color,Font,Type,Shape,Theme}.kt
        │       │   └── components/{QFCard,LED,StatusPill,ScanCard,ErrorOverlay,FlashOverlay,FeedbackPlayer}.kt
        │       └── feature/
        │           ├── auth/
        │           │   ├── data/AuthRepository.kt
        │           │   └── ui/{LoginViewModel,LoginScreen}.kt
        │           └── workbench/ui/WorkbenchScreen.kt
        └── test/java/com/bizlink/wmpda/core/network/
            ├── ResponseInterpreterTest.kt
            ├── TokenExtractorTest.kt
            └── WmsEnvelopeParseTest.kt
```

**Responsibility boundaries:**
- `core/network/` — everything about talking to WMS; provider-agnostic, unit-tested. `ResponseInterpreter` + `WmsEnvelope` are the only places response shape is interpreted.
- `core/session/` — the single source of operator identity + base URL config.
- `AppContainer` — wires the graph; the only service locator.
- `feature/*/data` — thin repositories: call `WmsApi` → interpret → return sealed result.
- `feature/*/ui` — one ViewModel (StateFlow) + Composable per screen.

---

## Pre-flight notes (read once)

- **Real WMS base URL:** `http://svcn5mesp01:8001` (= `http://10.163.130.173:8001`). Cleartext HTTP → manifest needs `usesCleartextTraffic="true"`.
- **Login returns NO token** (real WMS): `POST /api/Auth/Login {userName, password}` → `{isSuccess, message, data: UserDto}`. Session = cookie (auto) + identity fields. `TokenExtractor` is kept as **dormant fallback** (wired but yields null today; proven + tested; activates free if a future endpoint returns a token).
- **`factoryId` / `workCenter` gap:** `UserDto` carries `factoryName`, not the numeric `factoryId` (int, default 2) nor `workCenter` (default `WC001`) that line-stock/picking need. `SessionManager` holds these with documented defaults until backend clarifies the mapping (spec §9). Do NOT hardcode `2`/`WC001` at call sites — always read from `SessionManager`.
- **Fonts:** copy the 8 ttf files from QuickFill `app/src/main/res/font/` (`ibm_plex_sans_{regular,medium,semibold,bold}.ttf`, `jetbrains_mono_{regular,medium,semibold,bold}.ttf`) into WMPDA's `res/font/`. These are bundled assets — never `google_fonts` runtime fetch.
- **Commit cadence:** one commit per task (the final step of each task). Conventional Commits, Chinese summary acceptable.

---

## Task 0: Project scaffold (buildable empty Compose app)

**Files:**
- Create: `/Users/benque/Projects/WMPDA/settings.gradle.kts`
- Create: `/Users/benque/Projects/WMPDA/build.gradle.kts`
- Create: `/Users/benque/Projects/WMPDA/gradle.properties`
- Create: `/Users/benque/Projects/WMPDA/gradle/libs.versions.toml`
- Create: `/Users/benque/Projects/WMPDA/.gitignore`
- Create: `/Users/benque/Projects/WMPDA/app/build.gradle.kts`
- Create: `/Users/benque/Projects/WMPDA/app/src/main/AndroidManifest.xml`
- Create: `/Users/benque/Projects/WMPDA/app/src/main/res/values/strings.xml`
- Create: `/Users/benque/Projects/WMPDA/app/src/main/java/com/bizlink/wmpda/WmpdaApp.kt`
- Create: `/Users/benque/Projects/WMPDA/app/src/main/java/com/bizlink/wmpda/MainActivity.kt`
- Copy: gradle wrapper + `gradlew`/`gradlew.bat` from QuickFill

- [ ] **Step 1: Create the repo and copy the Gradle wrapper**

```bash
mkdir -p /Users/benque/Projects/WMPDA/app/src/main/java/com/bizlink/wmpda
mkdir -p /Users/benque/Projects/WMPDA/app/src/main/res/values
mkdir -p /Users/benque/Projects/WMPDA/app/src/main/res/font
mkdir -p /Users/benque/Projects/WMPDA/app/src/test/java/com/bizlink/wmpda
cd /Users/benque/Projects/WMPDA
git init
cp -R /Users/benque/Projects/QuickFill/gradle/wrapper gradle/wrapper
cp /Users/benque/Projects/QuickFill/gradlew /Users/benque/Projects/QuickFill/gradlew.bat .
chmod +x gradlew
```

- [ ] **Step 2: Write `gradle/libs.versions.toml`** (Room/KSP/WorkManager removed; DataStore added)

```toml
[versions]
agp = "8.7.0"
kotlin = "2.0.21"
coroutines = "1.9.0"
lifecycle = "2.8.7"
activity-compose = "1.9.3"
compose-bom = "2024.10.01"
navigation-compose = "2.8.3"
retrofit = "2.11.0"
okhttp = "4.12.0"
gson = "2.11.0"
datastore = "1.1.1"
junit = "4.13.2"

[libraries]
androidx-core-ktx = { module = "androidx.core:core-ktx", version = "1.13.1" }
androidx-lifecycle-runtime-ktx = { module = "androidx.lifecycle:lifecycle-runtime-ktx", version.ref = "lifecycle" }
androidx-lifecycle-viewmodel-compose = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version.ref = "lifecycle" }
androidx-activity-compose = { module = "androidx.activity:activity-compose", version.ref = "activity-compose" }
androidx-compose-bom = { module = "androidx.compose:compose-bom", version.ref = "compose-bom" }
androidx-compose-ui = { module = "androidx.compose.ui:ui" }
androidx-compose-ui-graphics = { module = "androidx.compose.ui:ui-graphics" }
androidx-compose-ui-tooling-preview = { module = "androidx.compose.ui:ui-tooling-preview" }
androidx-compose-ui-tooling = { module = "androidx.compose.ui:ui-tooling" }
androidx-compose-material3 = { module = "androidx.compose.material3:material3" }
androidx-compose-material-icons = { module = "androidx.compose.material:material-icons-extended" }
androidx-navigation-compose = { module = "androidx.navigation:navigation-compose", version.ref = "navigation-compose" }
androidx-datastore-preferences = { module = "androidx.datastore:datastore-preferences", version.ref = "datastore" }
kotlinx-coroutines-android = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-android", version.ref = "coroutines" }
retrofit = { module = "com.squareup.retrofit2:retrofit", version.ref = "retrofit" }
retrofit-converter-gson = { module = "com.squareup.retrofit2:converter-gson", version.ref = "retrofit" }
okhttp = { module = "com.squareup.okhttp3:okhttp", version.ref = "okhttp" }
okhttp-logging = { module = "com.squareup.okhttp3:logging-interceptor", version.ref = "okhttp" }
okhttp-urlconnection = { module = "com.squareup.okhttp3:okhttp-urlconnection", version.ref = "okhttp" }
gson = { module = "com.google.code.gson:gson", version.ref = "gson" }
junit = { module = "junit:junit", version.ref = "junit" }
kotlinx-coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "coroutines" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
```

- [ ] **Step 3: Write `settings.gradle.kts`**

```kotlin
pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "WMPDA"
include(":app")
```

- [ ] **Step 4: Write root `build.gradle.kts`**

```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.compose) apply false
}
```

- [ ] **Step 5: Write `gradle.properties`**

```properties
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
```

- [ ] **Step 6: Write `.gitignore`**

```gitignore
*.iml
.gradle
/local.properties
/.idea
.DS_Store
/build
/app/build
/captures
.externalNativeBuild
.cxx
local.properties
```

- [ ] **Step 7: Write `app/build.gradle.kts`** (no KSP/Room/WorkManager; DataStore added; BuildConfig base URL)

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.bizlink.wmpda"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.bizlink.wmpda"
        minSdk = 28
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0"

        buildConfigField("String", "DEFAULT_API_BASE_URL", "\"http://svcn5mesp01:8001\"")
        buildConfigField("int", "DEFAULT_FACTORY_ID", "2")
        buildConfigField("String", "DEFAULT_WORK_CENTER", "\"WC001\"")
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures {
        compose = true
        buildConfig = true
    }
    packaging { resources.excludes += "/META-INF/{AL2.0,LGPL2.1}" }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.androidx.datastore.preferences)

    implementation(libs.retrofit)
    implementation(libs.retrofit.converter.gson)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)
    implementation(libs.okhttp.urlconnection)
    implementation(libs.gson)

    debugImplementation(libs.androidx.compose.ui.tooling)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
}
```

- [ ] **Step 8: Write `app/src/main/res/values/strings.xml`**

```xml
<resources>
    <string name="app_name">WMPDA</string>
</resources>
```

- [ ] **Step 9: Write `AndroidManifest.xml`** (no FOREGROUND_SERVICE/sync perms; cleartext on; portrait)

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <application
        android:name=".WmpdaApp"
        android:allowBackup="false"
        android:label="@string/app_name"
        android:supportsRtl="false"
        android:theme="@style/Theme.Material3.DayNight.NoActionBar"
        android:usesCleartextTraffic="true"
        tools:targetApi="31">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait"
            android:configChanges="orientation|screenSize|keyboardHidden"
            android:theme="@style/Theme.Material3.DayNight.NoActionBar">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

- [ ] **Step 10: Write `WmpdaApp.kt`** (one line bootstrap)

```kotlin
package com.bizlink.wmpda

import android.app.Application

class WmpdaApp : Application() {
    override fun onCreate() {
        super.onCreate()
        AppContainer.init(this)
    }
}
```

- [ ] **Step 11: Write a minimal `MainActivity.kt`** (temporary placeholder body — replaced in Task 9)

```kotlin
package com.bizlink.wmpda

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme { Text("WMPDA") }
        }
    }
}
```

- [ ] **Step 12: Write a temporary minimal `AppContainer.kt`** (replaced in Task 6 — needed now so `WmpdaApp` compiles)

```kotlin
package com.bizlink.wmpda

import android.content.Context

object AppContainer {
    private lateinit var appContext: Context

    fun init(context: Context) {
        appContext = context.applicationContext
    }

    val context: Context get() = appContext
}
```

- [ ] **Step 13: Build to verify the scaffold compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`. (First run downloads Gradle + dependencies.)

- [ ] **Step 14: Commit**

```bash
cd /Users/benque/Projects/WMPDA
git add -A
git commit -m "chore: scaffold WMPDA native Kotlin/Compose project"
```

---

## Task 1: Theme (copied verbatim from QuickFill)

**Files:**
- Copy: 8 ttf files into `app/src/main/res/font/`
- Create: `app/src/main/java/com/bizlink/wmpda/core/theme/Color.kt`
- Create: `.../core/theme/Font.kt`
- Create: `.../core/theme/Type.kt`
- Create: `.../core/theme/Shape.kt`
- Create: `.../core/theme/Theme.kt`

- [ ] **Step 1: Copy the font assets**

```bash
cp /Users/benque/Projects/QuickFill/app/src/main/res/font/ibm_plex_sans_regular.ttf \
   /Users/benque/Projects/QuickFill/app/src/main/res/font/ibm_plex_sans_medium.ttf \
   /Users/benque/Projects/QuickFill/app/src/main/res/font/ibm_plex_sans_semibold.ttf \
   /Users/benque/Projects/QuickFill/app/src/main/res/font/ibm_plex_sans_bold.ttf \
   /Users/benque/Projects/QuickFill/app/src/main/res/font/jetbrains_mono_regular.ttf \
   /Users/benque/Projects/QuickFill/app/src/main/res/font/jetbrains_mono_medium.ttf \
   /Users/benque/Projects/QuickFill/app/src/main/res/font/jetbrains_mono_semibold.ttf \
   /Users/benque/Projects/QuickFill/app/src/main/res/font/jetbrains_mono_bold.ttf \
   /Users/benque/Projects/WMPDA/app/src/main/res/font/
```
If a filename differs, list the real names: `ls /Users/benque/Projects/QuickFill/app/src/main/res/font/` and adjust both the copy and `Font.kt`.

- [ ] **Step 2: Write `core/theme/Color.kt`** (22 semantic tokens + 4 container shades — the ONLY file allowed hex literals)

```kotlin
package com.bizlink.wmpda.core.theme

import androidx.compose.ui.graphics.Color

// WMPDA — Industrial Modern Blue (Variant B · Card-Driven), adopted from QuickFill DESIGN.md §3.
// 22 semantic tokens + 4 *Container shades. THIS IS THE ONLY FILE ALLOWED HEX LITERALS.

// Brand
val Primary = Color(0xFF1F5AE3)
val PrimaryDeep = Color(0xFF1648B8)
val PrimaryLight = Color(0xFFDCE6FF)
val OnPrimary = Color(0xFFFFFFFF)

// Neutral
val Background = Color(0xFFF4F6FA)
val Surface = Color(0xFFFFFFFF)
val SurfaceMuted = Color(0xFFEDF0F5)
val Outline = Color(0xFFD5DAE3)
val OutlineSoft = Color(0xFFE5E8EE)
val OnSurface = Color(0xFF0E1116)
val OnSurfaceDim = Color(0xFF4A5260)
val OnSurfaceMuted = Color(0xFF8993A3)

// Status (LED system)
val StatusOnline = Color(0xFF00875A)
val StatusOffline = Color(0xFF8993A3)
val StatusSyncing = Color(0xFF1F5AE3)
val StatusSynced = Color(0xFF00B86B)
val StatusPending = Color(0xFF8993A3)
val StatusWarning = Color(0xFFB26D00)
val StatusError = Color(0xFFD9281F)
val StatusOffPlan = Color(0xFFB5179E)   // RESERVED — only for business-rejected / OFF-PLAN

// Overlay
val FlashSuccess = Color(0x4D00875A)
val OverlayError = Color(0xCCD9281F)
val OverlayOffPlan = Color(0xD9B5179E)

// StatusPill container shades (non-contract utilities)
val StatusOnlineContainer = Color(0xFFE5F4ED)
val StatusErrorContainer = Color(0xFFFBE5E3)
val StatusWarningContainer = Color(0xFFFBEDD9)
val StatusOffPlanContainer = Color(0xFFFBE5F5)
```

- [ ] **Step 3: Write `core/theme/Font.kt`**

```kotlin
package com.bizlink.wmpda.core.theme

import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import com.bizlink.wmpda.R

val WmpdaSans = FontFamily(
    Font(R.font.ibm_plex_sans_regular, FontWeight.Normal),
    Font(R.font.ibm_plex_sans_medium, FontWeight.Medium),
    Font(R.font.ibm_plex_sans_semibold, FontWeight.SemiBold),
    Font(R.font.ibm_plex_sans_bold, FontWeight.Bold),
)

val WmpdaMono = FontFamily(
    Font(R.font.jetbrains_mono_regular, FontWeight.Normal),
    Font(R.font.jetbrains_mono_medium, FontWeight.Medium),
    Font(R.font.jetbrains_mono_semibold, FontWeight.SemiBold),
    Font(R.font.jetbrains_mono_bold, FontWeight.Bold),
)
```

- [ ] **Step 4: Write `core/theme/Type.kt`** (code values are authoritative over DESIGN.md prose)

```kotlin
package com.bizlink.wmpda.core.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp

val PlexSans = WmpdaSans
val JetMono = WmpdaMono

val WmpdaTypography = Typography(
    displayLarge = TextStyle(fontFamily = PlexSans, fontWeight = FontWeight.Bold, fontSize = 48.sp, letterSpacing = (-0.02f).em),
    displayMedium = TextStyle(fontFamily = JetMono, fontWeight = FontWeight.SemiBold, fontSize = 56.sp, letterSpacing = (-0.04f).em),
    displaySmall = TextStyle(fontFamily = JetMono, fontWeight = FontWeight.SemiBold, fontSize = 36.sp),
    headlineLarge = TextStyle(fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 28.sp),
    headlineMedium = TextStyle(fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 22.sp),
    headlineSmall = TextStyle(fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 18.sp),
    titleLarge = TextStyle(fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 18.sp),
    titleMedium = TextStyle(fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 16.sp),
    titleSmall = TextStyle(fontFamily = JetMono, fontWeight = FontWeight.SemiBold, fontSize = 13.sp),
    bodyLarge = TextStyle(fontFamily = PlexSans, fontWeight = FontWeight.Normal, fontSize = 22.sp),
    bodyMedium = TextStyle(fontFamily = PlexSans, fontWeight = FontWeight.Normal, fontSize = 16.sp),
    bodySmall = TextStyle(fontFamily = PlexSans, fontWeight = FontWeight.Normal, fontSize = 13.sp),
    labelLarge = TextStyle(fontFamily = PlexSans, fontWeight = FontWeight.SemiBold, fontSize = 16.sp),
    labelMedium = TextStyle(fontFamily = JetMono, fontWeight = FontWeight.SemiBold, fontSize = 11.sp, letterSpacing = 0.14f.em),
    labelSmall = TextStyle(fontFamily = JetMono, fontWeight = FontWeight.SemiBold, fontSize = 10.sp, letterSpacing = 0.18f.em),
)
```

- [ ] **Step 5: Write `core/theme/Shape.kt`**

```kotlin
package com.bizlink.wmpda.core.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Shapes
import androidx.compose.ui.unit.dp

val WmpdaShapes = Shapes(
    extraSmall = RoundedCornerShape(4.dp),
    small = RoundedCornerShape(8.dp),
    medium = RoundedCornerShape(12.dp),
    large = RoundedCornerShape(16.dp),
    extraLarge = RoundedCornerShape(16.dp),
)
```

- [ ] **Step 6: Write `core/theme/Theme.kt`** (light-only)

```kotlin
package com.bizlink.wmpda.core.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val WmpdaColorScheme = lightColorScheme(
    primary = Primary,
    onPrimary = OnPrimary,
    primaryContainer = PrimaryLight,
    onPrimaryContainer = PrimaryDeep,
    secondary = OnSurfaceDim,
    onSecondary = OnPrimary,
    secondaryContainer = SurfaceMuted,
    onSecondaryContainer = OnSurface,
    tertiary = StatusSyncing,
    onTertiary = OnPrimary,
    error = StatusError,
    onError = OnPrimary,
    background = Background,
    onBackground = OnSurface,
    surface = Surface,
    onSurface = OnSurface,
    surfaceVariant = SurfaceMuted,
    onSurfaceVariant = OnSurfaceDim,
    outline = Outline,
    outlineVariant = OutlineSoft,
)

@Composable
fun WmpdaTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = WmpdaColorScheme,
        typography = WmpdaTypography,
        shapes = WmpdaShapes,
        content = content,
    )
}
```

- [ ] **Step 7: Build to verify theme compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL` (R.font references resolve).

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat(theme): adopt QuickFill Industrial Modern Blue v2.1 theme"
```

---

## Task 2: WmsResult + ResponseInterpreter (TDD)

**Files:**
- Create: `.../core/network/WmsResult.kt`
- Create: `.../core/network/ResponseInterpreter.kt`
- Test: `app/src/test/java/com/bizlink/wmpda/core/network/ResponseInterpreterTest.kt`

- [ ] **Step 1: Write `WmsResult.kt`** (renamed from QuickFill's UploadResult — operation-neutral)

```kotlin
package com.bizlink.wmpda.core.network

sealed class WmsResult {
    object Success : WmsResult()
    object IdempotentSuccess : WmsResult()
    object AuthFailure : WmsResult()
    data class BusinessFailure(val code: String?, val msg: String) : WmsResult()
    data class RetryableFailure(val cause: String) : WmsResult()
}
```

- [ ] **Step 2: Write the failing test `ResponseInterpreterTest.kt`**

```kotlin
package com.bizlink.wmpda.core.network

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ResponseInterpreterTest {

    @Test fun `http 200 with code 0 is success`() {
        assertEquals(WmsResult.Success, ResponseInterpreter.interpret(200, """{"code":0,"message":"ok"}"""))
    }

    @Test fun `http 200 with isSuccess true is success`() {
        assertEquals(WmsResult.Success, ResponseInterpreter.interpret(200, """{"isSuccess":true,"message":"ok"}"""))
    }

    @Test fun `http 200 empty body is success`() {
        assertEquals(WmsResult.Success, ResponseInterpreter.interpret(200, null))
    }

    @Test fun `http 200 with already exists message is idempotent`() {
        assertEquals(WmsResult.IdempotentSuccess, ResponseInterpreter.interpret(200, """{"code":1,"message":"该物料已存在"}"""))
    }

    @Test fun `http 200 with business error is business failure`() {
        val r = ResponseInterpreter.interpret(200, """{"code":99,"message":"未知错误"}""")
        assertTrue(r is WmsResult.BusinessFailure)
        assertEquals("99", (r as WmsResult.BusinessFailure).code)
        assertEquals("未知错误", r.msg)
    }

    @Test fun `http 401 is auth failure`() {
        assertEquals(WmsResult.AuthFailure, ResponseInterpreter.interpret(401, """{"message":"unauthorized"}"""))
    }

    @Test fun `http 400 is business failure`() {
        assertTrue(ResponseInterpreter.interpret(400, """{"message":"bad request"}""") is WmsResult.BusinessFailure)
    }

    @Test fun `http 500 is retryable`() {
        assertTrue(ResponseInterpreter.interpret(500, """{"message":"server error"}""") is WmsResult.RetryableFailure)
    }

    @Test fun `isSuccess false is business failure`() {
        assertTrue(ResponseInterpreter.interpret(200, """{"isSuccess":false,"message":"操作失败"}""") is WmsResult.BusinessFailure)
    }

    @Test fun `wms state true is success`() {
        assertEquals(WmsResult.Success, ResponseInterpreter.interpret(200, """{"msg":"ok","dto":"x","state":true}"""))
    }

    @Test fun `state false not-found msg is business failure not idempotent`() {
        val body = """{"msg":"入库清单中未查询到TEST001","dto":null,"state":false}"""
        val r = ResponseInterpreter.interpret(200, body)
        assertTrue(r is WmsResult.BusinessFailure)
        assertEquals("入库清单中未查询到TEST001", (r as WmsResult.BusinessFailure).msg)
    }

    @Test fun `state false already-bound msg is idempotent`() {
        assertEquals(WmsResult.IdempotentSuccess, ResponseInterpreter.interpret(200, """{"msg":"物料已绑定到其它箱位","state":false}"""))
    }

    @Test fun `isSuccess false with 未登录 is auth failure`() {
        assertEquals(WmsResult.AuthFailure, ResponseInterpreter.interpret(200, """{"message":"请登录后再试","isSuccess":false}"""))
    }

    @Test fun `isSuccess false token expired is auth failure`() {
        assertEquals(WmsResult.AuthFailure, ResponseInterpreter.interpret(200, """{"message":"token expired","isSuccess":false}"""))
    }

    @Test fun `truly business reject stays business failure`() {
        assertTrue(ResponseInterpreter.interpret(200, """{"message":"未找到该物料的库存信息","isSuccess":false}""") is WmsResult.BusinessFailure)
    }
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.core.network.ResponseInterpreterTest"`
Expected: FAIL — `ResponseInterpreter` unresolved reference.

- [ ] **Step 4: Write `ResponseInterpreter.kt`** (note `isSuccess` added to successKeys for the real WMS envelope)

```kotlin
package com.bizlink.wmpda.core.network

import com.google.gson.JsonObject
import com.google.gson.JsonParser

object ResponseInterpreter {
    // 幂等关键词:服务器返回成功但表示"已经处理过",视为成功。
    // 不要加 "未查询到"/"不存在" — 那是真业务失败。
    private val idempotentHints = listOf(
        "已存在", "已绑定", "已经绑定", "已入库", "已添加",
        "重复", "duplicate", "already exist", "already bound",
    )

    // 业务态鉴权失败关键词:WMS 用 HTTP 200 + state/isSuccess=false + 这类 msg 表达 token 失效/未登录。
    private val authFailureHints = listOf(
        "身份验证", "身份未验证",
        "未登录", "请登录", "请先登录",
        "登录已过期", "登录失效", "登录超时", "会话过期", "会话失效",
        "token失效", "token已过期", "token expired", "invalid token",
        "unauthorized", "not authorized",
    )

    private val codeKeys = listOf("code", "Code", "errcode", "errCode", "errorCode", "resultCode")
    private val messageKeys = listOf("msg", "Msg", "message", "Message", "error", "errorMessage")
    // isSuccess 是 BizLink.MES WMS 实际字段;state 是 FOSIWMS 字段;两者都兼容。
    private val successKeys = listOf("isSuccess", "IsSuccess", "state", "State", "success", "Success", "ok")

    fun interpret(httpCode: Int, body: String?): WmsResult {
        if (httpCode == 401) return WmsResult.AuthFailure
        if (httpCode in 500..599) return WmsResult.RetryableFailure("HTTP $httpCode")
        if (httpCode !in 200..299) return WmsResult.BusinessFailure(httpCode.toString(), "HTTP $httpCode")
        if (body.isNullOrBlank()) return WmsResult.Success

        val json = runCatching { JsonParser.parseString(body).asJsonObject }.getOrNull()
            ?: return WmsResult.Success

        val code = findFirstString(json, codeKeys) ?: findFirstNumberAsString(json, codeKeys)
        val success = findFirstBoolean(json, successKeys)
        val message = findFirstString(json, messageKeys) ?: ""

        val codeIsSuccess = code == null || code == "0" || code == "200"
        val successIsTrue = success == null || success == true
        if (codeIsSuccess && successIsTrue) return WmsResult.Success

        if (idempotentHints.any { message.contains(it, ignoreCase = true) }) return WmsResult.IdempotentSuccess
        if (authFailureHints.any { message.contains(it, ignoreCase = true) }) return WmsResult.AuthFailure
        return WmsResult.BusinessFailure(code, message.ifBlank { "业务失败" })
    }

    private fun findFirstString(obj: JsonObject, keys: List<String>): String? {
        for (k in keys) {
            val e = obj.get(k) ?: continue
            if (e.isJsonPrimitive && e.asJsonPrimitive.isString) return e.asString
        }
        return null
    }

    private fun findFirstNumberAsString(obj: JsonObject, keys: List<String>): String? {
        for (k in keys) {
            val e = obj.get(k) ?: continue
            if (e.isJsonPrimitive && e.asJsonPrimitive.isNumber) return e.asNumber.toString()
        }
        return null
    }

    private fun findFirstBoolean(obj: JsonObject, keys: List<String>): Boolean? {
        for (k in keys) {
            val e = obj.get(k) ?: continue
            if (e.isJsonPrimitive && e.asJsonPrimitive.isBoolean) return e.asBoolean
        }
        return null
    }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.core.network.ResponseInterpreterTest"`
Expected: PASS (15 tests).

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat(network): add WmsResult + ResponseInterpreter with envelope tests"
```

---

## Task 3: TokenExtractor (TDD, dormant fallback)

**Files:**
- Create: `.../core/network/TokenExtractor.kt`
- Test: `app/src/test/java/com/bizlink/wmpda/core/network/TokenExtractorTest.kt`

- [ ] **Step 1: Write the failing test `TokenExtractorTest.kt`**

```kotlin
package com.bizlink.wmpda.core.network

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class TokenExtractorTest {

    @Test fun `flat token field`() {
        assertEquals("abc123", TokenExtractor.extract("""{"token":"abc123","other":"x"}"""))
    }

    @Test fun `nested data token`() {
        assertEquals("nested-xyz", TokenExtractor.extract("""{"code":0,"data":{"token":"nested-xyz","userId":1}}"""))
    }

    @Test fun `access_token variant`() {
        assertEquals("BEARER-789", TokenExtractor.extract("""{"access_token":"BEARER-789"}"""))
    }

    @Test fun `authToken camelCase`() {
        assertEquals("camel-Token-42", TokenExtractor.extract("""{"result":{"authToken":"camel-Token-42"}}"""))
    }

    @Test fun `no token field returns null`() {
        assertNull(TokenExtractor.extract("""{"isSuccess":true,"message":"已登录但无 token"}"""))
    }

    @Test fun `malformed json returns null`() {
        assertNull(TokenExtractor.extract("not a json"))
    }

    @Test fun `empty string returns null`() {
        assertNull(TokenExtractor.extract(""))
    }

    @Test fun `prefers first match depth-first`() {
        assertEquals("first", TokenExtractor.extract("""{"token":"first","data":{"token":"second"}}"""))
    }

    @Test fun `JWT in dto field accepted`() {
        val jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" +
            ".eyJuYW1lIjoiYWRtaW4iLCJleHAiOjE3NzkzNjA5ODd9" +
            ".dG2Rk7srEqRZqNLYyu9Kiz8_oCSLULhGT5h0syJIj-8"
        assertEquals(jwt, TokenExtractor.extract("""{"msg":"admin","dto":"$jwt","state":true}"""))
    }

    @Test fun `dto field with non-JWT string is rejected`() {
        assertNull(TokenExtractor.extract("""{"msg":"ok","dto":"not-a-jwt-just-plain","state":true}"""))
    }

    @Test fun `dto field with array payload skipped without crash`() {
        assertNull(TokenExtractor.extract("""{"msg":"ok","dto":[{"id":1},{"id":2}],"state":true}"""))
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.core.network.TokenExtractorTest"`
Expected: FAIL — `TokenExtractor` unresolved reference.

- [ ] **Step 3: Write `TokenExtractor.kt`**

```kotlin
package com.bizlink.wmpda.core.network

import com.google.gson.JsonElement
import com.google.gson.JsonParser

// Dormant fallback: real WMS login returns no token, so this yields null today.
// Kept (and tested) so a future tokened endpoint activates Bearer auth for free.
object TokenExtractor {
    private val tokenKeyPatterns = listOf(
        "token", "access_token", "accesstoken",
        "authtoken", "auth_token",
        "dto",
    )

    private val jwtShape = Regex("^[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+$")

    fun extract(jsonBody: String?): String? {
        if (jsonBody.isNullOrBlank()) return null
        val root = runCatching { JsonParser.parseString(jsonBody) }.getOrNull() ?: return null
        return searchRecursive(root)
    }

    private fun searchRecursive(element: JsonElement): String? {
        when {
            element.isJsonObject -> {
                for ((k, v) in element.asJsonObject.entrySet()) {
                    val keyLower = k.lowercase()
                    if (tokenKeyPatterns.any { keyLower == it || keyLower.contains(it) }) {
                        if (v.isJsonPrimitive && v.asJsonPrimitive.isString) {
                            val s = v.asString
                            if (s.isNotBlank() && acceptsValue(keyLower, s)) return s
                        }
                    }
                }
                for ((_, v) in element.asJsonObject.entrySet()) {
                    searchRecursive(v)?.let { return it }
                }
            }
            element.isJsonArray -> {
                for (item in element.asJsonArray) {
                    searchRecursive(item)?.let { return it }
                }
            }
        }
        return null
    }

    private fun acceptsValue(keyLower: String, value: String): Boolean =
        if (keyLower == "dto") jwtShape.matches(value) else true
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.core.network.TokenExtractorTest"`
Expected: PASS (11 tests).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(network): add TokenExtractor dormant-fallback with tests"
```

---

## Task 4: Network envelope, DTO, WmsApi, AuthInterceptor, NetworkClient

**Files:**
- Create: `.../core/network/WmsEnvelope.kt`
- Create: `.../core/network/dto/LoginDtos.kt`
- Create: `.../core/network/AuthInterceptor.kt`
- Create: `.../core/network/WmsApi.kt`
- Create: `.../core/network/NetworkClient.kt`
- Test: `app/src/test/java/com/bizlink/wmpda/core/network/WmsEnvelopeParseTest.kt`

- [ ] **Step 1: Write the failing test `WmsEnvelopeParseTest.kt`** (verifies Gson maps the real WMS login envelope)

```kotlin
package com.bizlink.wmpda.core.network

import com.bizlink.wmpda.core.network.dto.UserDto
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WmsEnvelopeParseTest {

    @Test fun `parses login envelope with UserDto data`() {
        val body = """{"isSuccess":true,"message":"登录成功","data":{"id":7,"employeeId":"E001","userName":"zhang","factoryName":"工厂A","isActive":true}}"""
        val type = object : TypeToken<WmsEnvelope<UserDto>>() {}.type
        val env: WmsEnvelope<UserDto> = Gson().fromJson(body, type)
        assertEquals(true, env.isSuccess)
        assertEquals("E001", env.data?.employeeId)
        assertEquals("工厂A", env.data?.factoryName)
    }

    @Test fun `parses failure envelope with null data`() {
        val body = """{"isSuccess":false,"message":"用户名或密码错误","data":null}"""
        val type = object : TypeToken<WmsEnvelope<UserDto>>() {}.type
        val env: WmsEnvelope<UserDto> = Gson().fromJson(body, type)
        assertEquals(false, env.isSuccess)
        assertEquals("用户名或密码错误", env.message)
        assertTrue(env.data == null)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.core.network.WmsEnvelopeParseTest"`
Expected: FAIL — `WmsEnvelope` / `UserDto` unresolved.

- [ ] **Step 3: Write `WmsEnvelope.kt`** (generic typed envelope for stable reads)

```kotlin
package com.bizlink.wmpda.core.network

// Generic WMS response envelope {isSuccess, message, data} for typed reads.
// Command/write endpoints use ResponseInterpreter on the raw body instead.
data class WmsEnvelope<T>(
    val isSuccess: Boolean? = null,
    val message: String? = null,
    val data: T? = null,
)
```

- [ ] **Step 4: Write `dto/LoginDtos.kt`**

```kotlin
package com.bizlink.wmpda.core.network.dto

// Real WMS: POST /api/Auth/Login {userName, password}
data class LoginRequest(
    val userName: String,
    val password: String,
)

// data payload of the login envelope. Only the fields WMPDA uses are modelled;
// Gson ignores the rest (domainAccount, isDelete, createdAt, ...).
data class UserDto(
    val id: Int? = null,
    val employeeId: String? = null,
    val userName: String? = null,
    val factoryName: String? = null,
    val isActive: Boolean? = null,
)
```

- [ ] **Step 5: Write `AuthInterceptor.kt`** (Bearer when token present; null today)

```kotlin
package com.bizlink.wmpda.core.network

import okhttp3.Interceptor
import okhttp3.Response

class AuthInterceptor(
    private val tokenProvider: () -> String?,
) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val original = chain.request()
        val token = tokenProvider()
        val req = if (!token.isNullOrBlank()) {
            original.newBuilder().header("Authorization", "Bearer $token").build()
        } else original
        return chain.proceed(req)
    }
}
```

- [ ] **Step 6: Write `WmsApi.kt`** (login only for Plan 1; feature endpoints added in later plans)

```kotlin
package com.bizlink.wmpda.core.network

import com.bizlink.wmpda.core.network.dto.LoginRequest
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

interface WmsApi {
    // Untyped body: parsed by ResponseInterpreter (success/failure) + Gson (UserDto) + TokenExtractor (optional token).
    @POST("api/Auth/Login")
    suspend fun login(@Body body: LoginRequest): Response<ResponseBody>
}
```

- [ ] **Step 7: Write `NetworkClient.kt`** (BODY logging gated behind BuildConfig.DEBUG)

```kotlin
package com.bizlink.wmpda.core.network

import com.bizlink.wmpda.BuildConfig
import com.google.gson.Gson
import okhttp3.JavaNetCookieJar
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.net.CookieManager
import java.net.CookiePolicy
import java.util.concurrent.TimeUnit

class NetworkClient(
    private val baseUrlProvider: () -> String,
    private val tokenProvider: () -> String?,
) {
    private val cookieManager: CookieManager = CookieManager().apply {
        setCookiePolicy(CookiePolicy.ACCEPT_ALL)
    }

    val httpClient: OkHttpClient = OkHttpClient.Builder()
        .cookieJar(JavaNetCookieJar(cookieManager))
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .addInterceptor(AuthInterceptor(tokenProvider))
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) HttpLoggingInterceptor.Level.BODY else HttpLoggingInterceptor.Level.NONE
        })
        .build()

    @Volatile private var cachedApi: WmsApi? = null
    @Volatile private var cachedBaseUrl: String? = null

    fun api(): WmsApi {
        val current = baseUrlProvider()
        if (cachedApi != null && cachedBaseUrl == current) return cachedApi!!
        val built = Retrofit.Builder()
            .baseUrl(ensureTrailingSlash(current))
            .client(httpClient)
            .addConverterFactory(GsonConverterFactory.create(Gson()))
            .build()
            .create(WmsApi::class.java)
        cachedApi = built
        cachedBaseUrl = current
        return built
    }

    fun serializeCookies(): String? {
        val store = cookieManager.cookieStore
        if (store.cookies.isEmpty()) return null
        return store.cookies.joinToString(";") { "${it.name}=${it.value}" }
    }

    private fun ensureTrailingSlash(url: String): String =
        if (url.endsWith("/")) url else "$url/"
}
```

- [ ] **Step 8: Run the envelope test to verify it passes, then build**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest --tests "com.bizlink.wmpda.core.network.WmsEnvelopeParseTest" && ./gradlew :app:assembleDebug`
Expected: tests PASS (2), `BUILD SUCCESSFUL`. (Note: `BuildConfig` resolves only after a build generates it — assembleDebug confirms.)

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "feat(network): add WmsEnvelope, login DTOs, AuthInterceptor, WmsApi, NetworkClient"
```

---

## Task 5: SessionManager (DataStore)

**Files:**
- Create: `.../core/session/SessionManager.kt`

- [ ] **Step 1: Write `SessionManager.kt`** (single source of identity + base URL; replaces Room ConfigRepository + AuthSession)

```kotlin
package com.bizlink.wmpda.core.session

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.bizlink.wmpda.BuildConfig
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore(name = "wmpda_session")

/**
 * Single source of operator identity + runtime config.
 * - employeeId / userName / factoryName come from the login UserDto.
 * - factoryId (Int) and workCenter are NOT in UserDto; default from BuildConfig
 *   (2 / "WC001") until backend provides per-user mapping (spec §9). Read these
 *   here — never hardcode at call sites.
 * - apiBaseUrl lets ops repoint the WMS host without a rebuild.
 */
data class Session(
    val loggedIn: Boolean,
    val employeeId: String,
    val userName: String,
    val factoryName: String,
    val factoryId: Int,
    val workCenter: String,
    val apiBaseUrl: String,
)

class SessionManager(private val context: Context) {

    private object Keys {
        val loggedIn = booleanPreferencesKey("logged_in")
        val employeeId = stringPreferencesKey("employee_id")
        val userName = stringPreferencesKey("user_name")
        val factoryName = stringPreferencesKey("factory_name")
        val factoryId = intPreferencesKey("factory_id")
        val workCenter = stringPreferencesKey("work_center")
        val apiBaseUrl = stringPreferencesKey("api_base_url")
    }

    val session: Flow<Session> = context.dataStore.data.map { p ->
        Session(
            loggedIn = p[Keys.loggedIn] ?: false,
            employeeId = p[Keys.employeeId] ?: "",
            userName = p[Keys.userName] ?: "",
            factoryName = p[Keys.factoryName] ?: "",
            factoryId = p[Keys.factoryId] ?: BuildConfig.DEFAULT_FACTORY_ID,
            workCenter = p[Keys.workCenter] ?: BuildConfig.DEFAULT_WORK_CENTER,
            apiBaseUrl = p[Keys.apiBaseUrl] ?: BuildConfig.DEFAULT_API_BASE_URL,
        )
    }

    suspend fun current(): Session = session.first()

    suspend fun saveLogin(employeeId: String, userName: String, factoryName: String) {
        context.dataStore.edit { p ->
            p[Keys.loggedIn] = true
            p[Keys.employeeId] = employeeId
            p[Keys.userName] = userName
            p[Keys.factoryName] = factoryName
        }
    }

    suspend fun clear() {
        context.dataStore.edit { p -> p[Keys.loggedIn] = false }
    }

    suspend fun setApiBaseUrl(url: String) {
        context.dataStore.edit { p -> p[Keys.apiBaseUrl] = url }
    }

    /** Blocking base-URL read for NetworkClient.baseUrlProvider closure. */
    fun apiBaseUrlBlocking(): String =
        kotlinx.coroutines.runBlocking { current().apiBaseUrl }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(session): add DataStore-backed SessionManager"
```

---

## Task 6: ScannerReceiver + AuthRepository + AppContainer (slim)

> Bundled so the module compiles green at task end: `AppContainer`'s lazy graph references `AuthRepository`, so both land here. Task 7 is then pure login UI.

**Files:**
- Create: `.../core/scanner/ScannerReceiver.kt`
- Create: `.../feature/auth/data/AuthRepository.kt`
- Modify (replace): `.../AppContainer.kt`

- [ ] **Step 1: Write `ScannerReceiver.kt`** (copied verbatim, repackaged)

```kotlin
package com.bizlink.wmpda.core.scanner

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import androidx.core.content.ContextCompat
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow

class ScannerReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "WMPDA"

        // Seuic Cruise2 factory broadcast. If a target device differs, change ACTION/KEY
        // (confirm via logcat on real hardware) — do NOT add branches.
        private const val ACTION = "com.android.server.scannerservice.broadcast"
        private const val KEY = "scannerdata"

        private val _scanFlow = MutableSharedFlow<String>(
            replay = 0,
            extraBufferCapacity = 1,
            onBufferOverflow = BufferOverflow.DROP_OLDEST,
        )
        val scanFlow: SharedFlow<String> = _scanFlow

        @Volatile private var registered: ScannerReceiver? = null

        fun register(context: Context) {
            if (registered != null) return
            val receiver = ScannerReceiver()
            val filter = IntentFilter(ACTION)
            ContextCompat.registerReceiver(context, receiver, filter, ContextCompat.RECEIVER_EXPORTED)
            registered = receiver
            Log.i(TAG, "ScannerReceiver registered for action=$ACTION")
        }

        fun unregister(context: Context) {
            val r = registered ?: return
            runCatching { context.unregisterReceiver(r) }
            registered = null
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras?.keySet()?.joinToString { "$it=${intent.extras?.get(it)}" }
        Log.d(TAG, "Scan broadcast, action=${intent.action}, extras=$extras")
        val data = intent.getStringExtra(KEY)?.trim().orEmpty()
        if (data.isNotEmpty()) {
            Log.i(TAG, "Scan data: $data")
            _scanFlow.tryEmit(data)
        } else {
            Log.w(TAG, "Scan broadcast received but $KEY is empty")
        }
    }
}
```

- [ ] **Step 2: Replace `AppContainer.kt`** (slim: session + network + scanner; no DB/sync)

```kotlin
package com.bizlink.wmpda

import android.content.Context
import com.bizlink.wmpda.core.network.NetworkClient
import com.bizlink.wmpda.core.scanner.ScannerReceiver
import com.bizlink.wmpda.core.session.SessionManager
import com.bizlink.wmpda.feature.auth.data.AuthRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.SharedFlow

object AppContainer {
    private lateinit var appContext: Context

    val applicationScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    val sessionManager: SessionManager by lazy { SessionManager(appContext) }

    // Closure injection breaks Config/Auth circular dep (QuickFill pattern).
    // tokenProvider returns null today (cookie auth); activates if a tokened endpoint appears.
    val networkClient: NetworkClient by lazy {
        NetworkClient(
            baseUrlProvider = { sessionManager.apiBaseUrlBlocking() },
            tokenProvider = { authRepository.currentTokenBlocking() },
        )
    }

    val authRepository: AuthRepository by lazy {
        AuthRepository(network = networkClient, session = sessionManager)
    }

    val scanFlow: SharedFlow<String>
        get() = ScannerReceiver.scanFlow

    fun init(context: Context) {
        appContext = context.applicationContext
        ScannerReceiver.register(appContext)
    }

    val context: Context get() = appContext
}
```

- [ ] **Step 3: Write `feature/auth/data/AuthRepository.kt`** (interactive login; cookie + identity; ResponseInterpreter + Gson + TokenExtractor)

```kotlin
package com.bizlink.wmpda.feature.auth.data

import android.util.Log
import com.bizlink.wmpda.core.network.NetworkClient
import com.bizlink.wmpda.core.network.ResponseInterpreter
import com.bizlink.wmpda.core.network.TokenExtractor
import com.bizlink.wmpda.core.network.WmsEnvelope
import com.bizlink.wmpda.core.network.WmsResult
import com.bizlink.wmpda.core.network.dto.LoginRequest
import com.bizlink.wmpda.core.network.dto.UserDto
import com.bizlink.wmpda.core.session.SessionManager
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

class AuthRepository(
    private val network: NetworkClient,
    private val session: SessionManager,
) {
    private val mutex = Mutex()
    private val gson = Gson()

    @Volatile private var cachedToken: String? = null

    /** Non-blocking read for AuthInterceptor. Null today (cookie auth). */
    fun currentTokenBlocking(): String? = cachedToken

    sealed class LoginResult {
        object Ok : LoginResult()
        data class Failed(val message: String) : LoginResult()
    }

    suspend fun login(userName: String, password: String): LoginResult = mutex.withLock {
        runCatching {
            val response = network.api().login(LoginRequest(userName.trim(), password))
            val body = response.body()?.string() ?: response.errorBody()?.string()
            Log.i("WMPDA", "Login response: $body")

            when (val r = ResponseInterpreter.interpret(response.code(), body)) {
                is WmsResult.BusinessFailure -> return@runCatching LoginResult.Failed(r.msg)
                WmsResult.AuthFailure -> return@runCatching LoginResult.Failed("身份验证失败")
                is WmsResult.RetryableFailure -> return@runCatching LoginResult.Failed("服务器繁忙，请重试 (${r.cause})")
                WmsResult.Success, WmsResult.IdempotentSuccess -> Unit
            }

            val user = parseUser(body)
                ?: return@runCatching LoginResult.Failed("登录响应解析失败")

            // Optional token (dormant): real WMS returns none → null.
            cachedToken = TokenExtractor.extract(body)

            session.saveLogin(
                employeeId = user.employeeId ?: userName.trim(),
                userName = user.userName ?: userName.trim(),
                factoryName = user.factoryName ?: "",
            )
            LoginResult.Ok
        }.getOrElse { e ->
            Log.w("WMPDA", "Login error", e)
            LoginResult.Failed("网络异常：${e.message ?: "无法连接服务器"}")
        }
    }

    suspend fun logout() {
        cachedToken = null
        session.clear()
    }

    private fun parseUser(body: String?): UserDto? {
        if (body.isNullOrBlank()) return null
        return runCatching {
            val type = object : TypeToken<WmsEnvelope<UserDto>>() {}.type
            gson.fromJson<WmsEnvelope<UserDto>>(body, type).data
        }.getOrNull()
    }
}
```

- [ ] **Step 4: Build to verify scanner + AuthRepository + AppContainer compile**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(core): add ScannerReceiver, AuthRepository, slim AppContainer wiring"
```

---

## Task 7: feature/auth — Login screen (UI)

> `AuthRepository` was created in Task 6. This task is the login UI only.

**Files:**
- Create: `.../feature/auth/ui/LoginViewModel.kt`
- Create: `.../feature/auth/ui/LoginScreen.kt`

- [ ] **Step 1: Write `LoginViewModel.kt`**

```kotlin
package com.bizlink.wmpda.feature.auth.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bizlink.wmpda.AppContainer
import com.bizlink.wmpda.feature.auth.data.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class LoginUiState(
    val userName: String = "",
    val password: String = "",
    val submitting: Boolean = false,
    val error: String? = null,
    val success: Boolean = false,
)

class LoginViewModel : ViewModel() {
    private val _state = MutableStateFlow(LoginUiState())
    val state: StateFlow<LoginUiState> = _state.asStateFlow()

    fun onUserName(v: String) { _state.value = _state.value.copy(userName = v, error = null) }
    fun onPassword(v: String) { _state.value = _state.value.copy(password = v, error = null) }

    fun submit() {
        val s = _state.value
        if (s.submitting) return
        if (s.userName.isBlank() || s.password.isBlank()) {
            _state.value = s.copy(error = "请输入账号和密码")
            return
        }
        _state.value = s.copy(submitting = true, error = null)
        viewModelScope.launch {
            when (val r = AppContainer.authRepository.login(s.userName, s.password)) {
                AuthRepository.LoginResult.Ok ->
                    _state.value = _state.value.copy(submitting = false, success = true)
                is AuthRepository.LoginResult.Failed ->
                    _state.value = _state.value.copy(submitting = false, error = r.message)
            }
        }
    }
}
```

- [ ] **Step 2: Write `LoginScreen.kt`**

```kotlin
package com.bizlink.wmpda.feature.auth.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.bizlink.wmpda.core.theme.OnSurfaceDim
import com.bizlink.wmpda.core.theme.Primary
import com.bizlink.wmpda.core.theme.StatusError

@Composable
fun LoginScreen(
    onLoggedIn: () -> Unit,
    viewModel: LoginViewModel = viewModel(),
) {
    val state by viewModel.state.collectAsState()

    LaunchedEffect(state.success) { if (state.success) onLoggedIn() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 32.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text("WMPDA", style = MaterialTheme.typography.displayLarge, color = Primary)
        Spacer(Modifier.height(8.dp))
        Text("仓储作业终端", style = MaterialTheme.typography.bodyMedium, color = OnSurfaceDim)
        Spacer(Modifier.height(40.dp))
        OutlinedTextField(
            value = state.userName,
            onValueChange = viewModel::onUserName,
            label = { Text("账号") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(Modifier.height(16.dp))
        OutlinedTextField(
            value = state.password,
            onValueChange = viewModel::onPassword,
            label = { Text("密码") },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            modifier = Modifier.fillMaxWidth(),
        )
        if (state.error != null) {
            Spacer(Modifier.height(12.dp))
            Text(state.error!!, color = StatusError, style = MaterialTheme.typography.bodyMedium)
        }
        Spacer(Modifier.height(24.dp))
        Button(
            onClick = viewModel::submit,
            enabled = !state.submitting,
            modifier = Modifier.fillMaxWidth().height(56.dp),
        ) {
            if (state.submitting) {
                CircularProgressIndicator(modifier = Modifier.height(24.dp))
            } else {
                Text("登录", style = MaterialTheme.typography.labelLarge)
            }
        }
    }
}
```

- [ ] **Step 3: Build to verify the login UI compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(auth): add Login screen + view model"
```

---

## Task 8: feature/workbench — Workbench screen

**Files:**
- Create: `.../core/components/QFCard.kt`
- Create: `.../feature/workbench/ui/WorkbenchScreen.kt`

(Other shared components — LED/StatusPill/ScanCard/ErrorOverlay/FlashOverlay/FeedbackPlayer — land in Task 10. Workbench only needs QFCard.)

- [ ] **Step 1: Write `core/components/QFCard.kt`**

```kotlin
package com.bizlink.wmpda.core.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.bizlink.wmpda.core.theme.OutlineSoft

/** Workhorse card: Surface white + 1dp OutlineSoft border + 12dp corner + 1dp elevation. */
@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun QFCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    if (onClick != null) {
        Card(
            onClick = onClick,
            modifier = modifier,
            shape = MaterialTheme.shapes.medium,
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
            border = BorderStroke(1.dp, OutlineSoft),
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        ) { content() }
    } else {
        Card(
            modifier = modifier,
            shape = MaterialTheme.shapes.medium,
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
            border = BorderStroke(1.dp, OutlineSoft),
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        ) { content() }
    }
}
```

- [ ] **Step 2: Write `WorkbenchScreen.kt`** (two function groups; only enabled entries wired — feature destinations resolve in their own plans)

```kotlin
package com.bizlink.wmpda.feature.workbench.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.item
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.MoveToInbox
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Upload
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.bizlink.wmpda.core.components.QFCard
import com.bizlink.wmpda.core.theme.OnSurfaceDim
import com.bizlink.wmpda.core.theme.Primary

/**
 * Entry actions. Destinations for picking / linestock / warehouse resolve in later plans;
 * here their callbacks are passed in and wired by NavGraph (Task 9). Unwired ones are
 * temporarily routed to onTodo so the screen is fully interactive in Plan 1.
 */
@Composable
fun WorkbenchScreen(
    operatorName: String,
    onOpenPicking: () -> Unit,
    onOpenStockQuery: () -> Unit,
    onOpenShelving: () -> Unit,
    onOpenRemoval: () -> Unit,
    onOpenReceiving: () -> Unit,
    onOpenReturn: () -> Unit,
    onOpenWarehouseInbound: () -> Unit,
    onOpenWarehouseReturn: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        Row(modifier = Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Text("WMS 工作台", style = MaterialTheme.typography.headlineMedium, modifier = Modifier.weight(1f))
            Text(operatorName, style = MaterialTheme.typography.bodyMedium, color = OnSurfaceDim)
        }
        Spacer(Modifier.height(16.dp))
        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            item { GroupHeader("物料拣配合箱") }
            item {
                ActionCard(Icons.Filled.Inventory2, "合箱校验", "工单物料拣配校验", onOpenPicking)
            }
            item { GroupHeader("线边 / 立库") }
            item { ActionCard(Icons.Filled.Search, "库存查询", "扫码 / 物料号查询", onOpenStockQuery) }
            item { ActionCard(Icons.Filled.Upload, "电缆上架", "上架或转移", onOpenShelving) }
            item { ActionCard(Icons.Filled.Download, "电缆下架", "下架到线边库", onOpenRemoval) }
            item { ActionCard(Icons.Filled.MoveToInbox, "电缆入库", "断线电缆收货", onOpenReceiving) }
            item { ActionCard(Icons.Filled.Download, "电缆退库", "退回 WMS", onOpenReturn) }
            item { ActionCard(Icons.Filled.MoveToInbox, "中央立库入库", "扫码建上架任务", onOpenWarehouseInbound) }
            item { ActionCard(Icons.Filled.Download, "中央立库退货", "扫码建下架任务", onOpenWarehouseReturn) }
        }
    }
}

@Composable
private fun GroupHeader(title: String) {
    Text(title, style = MaterialTheme.typography.titleMedium, color = Primary, modifier = Modifier.padding(top = 8.dp))
}

@Composable
private fun ActionCard(icon: ImageVector, title: String, subtitle: String, onClick: () -> Unit) {
    QFCard(modifier = Modifier.fillMaxWidth(), onClick = onClick) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Icon(icon, contentDescription = null, tint = Primary)
            Column(modifier = Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleLarge)
                Text(subtitle, style = MaterialTheme.typography.bodySmall, color = OnSurfaceDim)
            }
        }
    }
}
```

- [ ] **Step 3: Build to verify**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(workbench): add QFCard + Workbench entry screen"
```

---

## Task 9: Navigation wiring (Routes + NavGraph + MainActivity)

**Files:**
- Create: `.../core/nav/Routes.kt`
- Create: `.../core/nav/NavGraph.kt`
- Modify (replace): `.../MainActivity.kt`

- [ ] **Step 1: Write `core/nav/Routes.kt`** (all destinations declared now; feature screens added in later plans)

```kotlin
package com.bizlink.wmpda.core.nav

object Routes {
    const val LOGIN = "login"
    const val WORKBENCH = "workbench"
    // Declared for later plans (screens added then):
    const val PICKING = "picking"
    const val STOCK_QUERY = "linestock"
    const val SHELVING = "linestock/shelving"
    const val REMOVAL = "linestock/removal"
    const val RECEIVING = "linestock/receiving"
    const val RETURN = "linestock/return"
    const val WAREHOUSE_INBOUND = "warehouse/inbound"
    const val WAREHOUSE_RETURN = "warehouse/return"
}
```

- [ ] **Step 2: Write `core/nav/NavGraph.kt`** (start at LOGIN; feature destinations show a placeholder until their plans land)

```kotlin
package com.bizlink.wmpda.core.nav

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.bizlink.wmpda.AppContainer
import com.bizlink.wmpda.core.session.Session
import com.bizlink.wmpda.feature.auth.ui.LoginScreen
import com.bizlink.wmpda.feature.workbench.ui.WorkbenchScreen

@Composable
fun WmpdaNavGraph(navController: NavHostController = rememberNavController()) {
    val session by AppContainer.sessionManager.session.collectAsState(
        initial = Session(false, "", "", "", 2, "WC001", ""),
    )

    NavHost(navController = navController, startDestination = Routes.LOGIN) {
        composable(Routes.LOGIN) {
            LoginScreen(onLoggedIn = {
                navController.navigate(Routes.WORKBENCH) {
                    popUpTo(Routes.LOGIN) { inclusive = true }
                }
            })
        }
        composable(Routes.WORKBENCH) {
            WorkbenchScreen(
                operatorName = session.userName.ifBlank { "操作员" },
                onOpenPicking = { navController.navigate(Routes.PICKING) },
                onOpenStockQuery = { navController.navigate(Routes.STOCK_QUERY) },
                onOpenShelving = { navController.navigate(Routes.SHELVING) },
                onOpenRemoval = { navController.navigate(Routes.REMOVAL) },
                onOpenReceiving = { navController.navigate(Routes.RECEIVING) },
                onOpenReturn = { navController.navigate(Routes.RETURN) },
                onOpenWarehouseInbound = { navController.navigate(Routes.WAREHOUSE_INBOUND) },
                onOpenWarehouseReturn = { navController.navigate(Routes.WAREHOUSE_RETURN) },
            )
        }
        // Placeholder destinations — replaced by feature plans 2–4.
        listOf(
            Routes.PICKING, Routes.STOCK_QUERY, Routes.SHELVING, Routes.REMOVAL,
            Routes.RECEIVING, Routes.RETURN, Routes.WAREHOUSE_INBOUND, Routes.WAREHOUSE_RETURN,
        ).forEach { route ->
            composable(route) {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("「$route」待实现", style = MaterialTheme.typography.headlineSmall)
                }
            }
        }
    }
}
```

- [ ] **Step 3: Replace `MainActivity.kt`** (theme + nav)

```kotlin
package com.bizlink.wmpda

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.bizlink.wmpda.core.nav.WmpdaNavGraph
import com.bizlink.wmpda.core.theme.WmpdaTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            WmpdaTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background,
                ) {
                    WmpdaNavGraph()
                }
            }
        }
    }
}
```

- [ ] **Step 4: Build + install on a device/emulator and manually verify the end-to-end shell**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.
Manual (device connected): `./gradlew :app:installDebug` then launch. Expected: Login screen → enter any credentials → on a reachable WMS, success navigates to Workbench showing the two function groups; tapping an entry shows the "待实现" placeholder. (Without a reachable WMS, login shows the network-error message — confirms error path renders.)

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(nav): wire Login → Workbench navigation graph + MainActivity"
```

---

## Task 10: Shared scan/feedback component library

**Files:**
- Create: `.../core/components/LED.kt`
- Create: `.../core/components/StatusPill.kt`
- Create: `.../core/components/ScanCard.kt`
- Create: `.../core/components/ErrorOverlay.kt`
- Create: `.../core/components/FeedbackPlayer.kt`
- Create: `.../core/components/FlashOverlay.kt`

These are pure UI/util ports used by the feature plans. No logic to unit-test; verified by build.

- [ ] **Step 1: Write `LED.kt`**

```kotlin
package com.bizlink.wmpda.core.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

@Composable
fun LED(color: Color, modifier: Modifier = Modifier, size: Dp = 9.dp, pulse: Boolean = false) {
    Box(modifier = modifier.size(size * 2), contentAlignment = Alignment.Center) {
        if (pulse) {
            val transition = rememberInfiniteTransition(label = "ledPulse")
            val scale by transition.animateFloat(
                initialValue = 1.0f, targetValue = 1.8f,
                animationSpec = infiniteRepeatable(tween(1000, easing = LinearEasing), RepeatMode.Restart),
                label = "ledPulseScale",
            )
            val alpha by transition.animateFloat(
                initialValue = 0.6f, targetValue = 0.0f,
                animationSpec = infiniteRepeatable(tween(1000, easing = LinearEasing), RepeatMode.Restart),
                label = "ledPulseAlpha",
            )
            Box(Modifier.size(size).scale(scale).alpha(alpha).clip(CircleShape).background(color))
        }
        Box(Modifier.size(size).clip(CircleShape).background(color))
    }
}
```

- [ ] **Step 2: Write `StatusPill.kt`**

```kotlin
package com.bizlink.wmpda.core.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.bizlink.wmpda.core.theme.OnSurfaceDim
import com.bizlink.wmpda.core.theme.OnSurfaceMuted
import com.bizlink.wmpda.core.theme.Primary
import com.bizlink.wmpda.core.theme.PrimaryDeep
import com.bizlink.wmpda.core.theme.PrimaryLight
import com.bizlink.wmpda.core.theme.StatusError
import com.bizlink.wmpda.core.theme.StatusErrorContainer
import com.bizlink.wmpda.core.theme.StatusOffPlan
import com.bizlink.wmpda.core.theme.StatusOffPlanContainer
import com.bizlink.wmpda.core.theme.StatusOnline
import com.bizlink.wmpda.core.theme.StatusOnlineContainer
import com.bizlink.wmpda.core.theme.StatusSynced
import com.bizlink.wmpda.core.theme.StatusSyncing
import com.bizlink.wmpda.core.theme.StatusWarning
import com.bizlink.wmpda.core.theme.StatusWarningContainer
import com.bizlink.wmpda.core.theme.SurfaceMuted

enum class PillTone { ONLINE, OFFLINE, SYNCED, PENDING, WAITING, SYNCING, OFFPLAN, ERROR, WARNING }

private data class PillStyle(val dot: Color, val bg: Color, val text: Color, val pulse: Boolean)

private fun PillTone.style(): PillStyle = when (this) {
    PillTone.ONLINE  -> PillStyle(StatusOnline, StatusOnlineContainer, StatusOnline, true)
    PillTone.OFFLINE -> PillStyle(OnSurfaceMuted, SurfaceMuted, OnSurfaceDim, false)
    PillTone.SYNCED  -> PillStyle(StatusSynced, StatusOnlineContainer, Color(0xFF006847), false)
    PillTone.PENDING -> PillStyle(OnSurfaceMuted, SurfaceMuted, OnSurfaceDim, false)
    PillTone.WAITING -> PillStyle(Primary, PrimaryLight, PrimaryDeep, true)
    PillTone.SYNCING -> PillStyle(StatusSyncing, PrimaryLight, PrimaryDeep, true)
    PillTone.OFFPLAN -> PillStyle(StatusOffPlan, StatusOffPlanContainer, StatusOffPlan, false)
    PillTone.ERROR   -> PillStyle(StatusError, StatusErrorContainer, StatusError, false)
    PillTone.WARNING -> PillStyle(StatusWarning, StatusWarningContainer, StatusWarning, false)
}

@Composable
fun StatusPill(text: String, tone: PillTone, modifier: Modifier = Modifier) {
    val style = tone.style()
    Row(
        modifier = modifier
            .clip(MaterialTheme.shapes.extraSmall)
            .background(style.bg)
            .padding(horizontal = 8.dp, vertical = 3.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        LED(color = style.dot, size = 6.dp, pulse = style.pulse)
        Text(text, style = MaterialTheme.typography.labelSmall, color = style.text, modifier = Modifier.padding(start = 6.dp))
    }
}
```

Note: the single hex `Color(0xFF006847)` here is the one carried-over SYNCED-text exception from QuickFill. If your lint forbids hex outside `Color.kt`, promote it to a token named `StatusSyncedText` in `Color.kt` and reference that instead.

- [ ] **Step 3: Write `ScanCard.kt`**

```kotlin
package com.bizlink.wmpda.core.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.bizlink.wmpda.core.theme.OnSurfaceMuted
import com.bizlink.wmpda.core.theme.Outline
import com.bizlink.wmpda.core.theme.OutlineSoft
import com.bizlink.wmpda.core.theme.Primary
import com.bizlink.wmpda.core.theme.PrimaryLight

@Composable
fun ScanCard(
    stepLabel: String,
    valueLabel: String?,
    placeholder: String,
    active: Boolean,
    modifier: Modifier = Modifier,
) {
    val containerColor = if (active) PrimaryLight else MaterialTheme.colorScheme.surface
    val border = if (active) BorderStroke(1.dp, Primary) else BorderStroke(1.dp, OutlineSoft)
    val railColor = if (active) Primary else Outline

    Card(
        modifier = modifier.fillMaxWidth().height(118.dp),
        shape = MaterialTheme.shapes.medium,
        colors = CardDefaults.cardColors(containerColor = containerColor),
        border = border,
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
    ) {
        Row(modifier = Modifier.fillMaxWidth().fillMaxHeight()) {
            Box(Modifier.width(6.dp).fillMaxHeight().background(railColor))
            Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = stepLabel,
                        style = MaterialTheme.typography.labelMedium,
                        color = if (active) Primary else OnSurfaceMuted,
                        modifier = Modifier.weight(1f),
                    )
                    if (active) StatusPill(text = "WAITING", tone = PillTone.WAITING)
                }
                Spacer(Modifier.height(8.dp))
                Text(
                    text = valueLabel ?: placeholder,
                    style = MaterialTheme.typography.bodyLarge,
                    color = if (valueLabel != null || active) MaterialTheme.colorScheme.onSurface else OnSurfaceMuted,
                )
            }
        }
    }
}
```

- [ ] **Step 4: Write `FeedbackPlayer.kt`**

```kotlin
package com.bizlink.wmpda.core.components

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

object FeedbackPlayer {
    enum class Kind { SUCCESS, ERROR }

    private val toneGenerator: ToneGenerator by lazy {
        ToneGenerator(AudioManager.STREAM_NOTIFICATION, 100)
    }

    fun play(context: Context, kind: Kind) {
        when (kind) {
            Kind.SUCCESS -> runCatching { toneGenerator.startTone(ToneGenerator.TONE_PROP_BEEP, 120) }
            Kind.ERROR -> {
                runCatching { toneGenerator.startTone(ToneGenerator.TONE_CDMA_LOW_L, 600) }
                vibrate(context, 300)
            }
        }
    }

    private fun vibrate(context: Context, millis: Long) {
        val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
        vibrator?.vibrate(VibrationEffect.createOneShot(millis, VibrationEffect.DEFAULT_AMPLITUDE))
    }
}
```

- [ ] **Step 5: Write `ErrorOverlay.kt`** (severity = NORMAL / OFF_PLAN; OFF_PLAN now means "business-rejected", per spec §6)

```kotlin
package com.bizlink.wmpda.core.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.bizlink.wmpda.core.theme.OverlayError
import com.bizlink.wmpda.core.theme.OverlayOffPlan
import com.bizlink.wmpda.core.theme.StatusError
import com.bizlink.wmpda.core.theme.StatusOffPlan

enum class OverlaySeverity { NORMAL, OFF_PLAN }

@Composable
fun ErrorOverlay(
    title: String,
    detail: String,
    severity: OverlaySeverity = OverlaySeverity.NORMAL,
    onDismiss: () -> Unit,
) {
    val bg = if (severity == OverlaySeverity.OFF_PLAN) OverlayOffPlan else OverlayError
    val accent = if (severity == OverlaySeverity.OFF_PLAN) StatusOffPlan else StatusError
    val tag = if (severity == OverlaySeverity.OFF_PLAN) "OFF-PLAN" else "ERROR"

    Box(
        modifier = Modifier.fillMaxSize().background(bg).clickable(onClick = onDismiss),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
            modifier = Modifier.padding(horizontal = 32.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                LED(color = Color.White, size = 10.dp, pulse = true)
                Text(tag, color = Color.White, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.Bold)
            }
            Text(title, color = Color.White, style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold)
            Text(detail, color = Color.White, style = MaterialTheme.typography.bodyMedium)
            Spacer(Modifier.size(8.dp))
            Button(
                onClick = onDismiss,
                colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = accent),
                shape = MaterialTheme.shapes.small,
                modifier = Modifier.height(56.dp).fillMaxWidth(0.72f),
            ) {
                Text("关闭", style = MaterialTheme.typography.labelLarge)
            }
        }
    }
}
```

- [ ] **Step 6: Write `FlashOverlay.kt`** (200ms green success flash; caller toggles a Boolean and consumes it)

```kotlin
package com.bizlink.wmpda.core.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import com.bizlink.wmpda.core.theme.FlashSuccess
import kotlinx.coroutines.delay

/**
 * Full-screen 200ms green flash after a successful scan. Place at the top of a Box.
 * Caller sets `visible=true` on success and resets it via `onConsumed` after the flash.
 */
@Composable
fun FlashOverlay(visible: Boolean, onConsumed: () -> Unit) {
    if (!visible) return
    LaunchedEffect(Unit) {
        delay(200)
        onConsumed()
    }
    Box(Modifier.fillMaxSize().background(FlashSuccess))
}
```

- [ ] **Step 7: Build to verify the component library compiles**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:assembleDebug`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 8: Run the full unit-test suite**

Run: `cd /Users/benque/Projects/WMPDA && ./gradlew :app:testDebugUnitTest`
Expected: PASS — ResponseInterpreterTest (15) + TokenExtractorTest (11) + WmsEnvelopeParseTest (2) = 28 tests green.

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "feat(components): add LED, StatusPill, ScanCard, ErrorOverlay, FlashOverlay, FeedbackPlayer"
```

---

## Task 11: Project docs (CLAUDE.md + DESIGN.md adoption)

**Files:**
- Create: `/Users/benque/Projects/WMPDA/CLAUDE.md`
- Create: `/Users/benque/Projects/WMPDA/DESIGN.md` (copied + retitled from QuickFill)

- [ ] **Step 1: Copy and retitle DESIGN.md**

```bash
cp /Users/benque/Projects/QuickFill/DESIGN.md /Users/benque/Projects/WMPDA/DESIGN.md
```
Then edit the top title line of `/Users/benque/Projects/WMPDA/DESIGN.md` from QuickFill's heading to: `# WMPDA — Design System (Industrial Modern Blue v2.1, adopted from QuickFill)`. Leave the token/type/shape/rule content unchanged (it is the source of truth).

- [ ] **Step 2: Write `CLAUDE.md`** with the hard rules

```markdown
# CLAUDE.md — WMPDA

WMPDA = BizLink 仓储作业 PDA (原生 Kotlin + Jetpack Compose),运行于东集 Seuic Cruise2,锁竖屏。
重写自 Flutter 版 PickingVerficationApp 的简化页面方案,架构参考 QuickFill(在线模型,无离线同步)。

## 代码硬规则
- 架构:`WmpdaApp` → `AppContainer`(顶层手写 DI 单例)装配 SessionManager + NetworkClient + 各 feature Repository。**不引入 Hilt/Koin**。
- 在线模型:Repository = `suspend fun 调 WmsApi → ResponseInterpreter → 返回 WmsResult/sealed 结果`。**不要 Room / WorkManager / 离线队列**。
- WMS 响应壳 `{isSuccess, message, data}` 一律经 `ResponseInterpreter`(命令类)或 `WmsEnvelope<T>`(类型化读)解析,**不要绕过**;`message` 中文原样透传给作业员。
- 鉴权:cookie(OkHttp cookie jar)+ 身份字段随请求带;`employeeId/factoryId/workCenter` 一律从 `SessionManager` 读,**禁止硬编码 2 / WC001**。
- 扫码:`ScannerReceiver` 监听 `com.android.server.scannerservice.broadcast`;真机 action 不一致时只改 `ACTION/KEY` 常量,不加分支。

## 设计硬规则(见 DESIGN.md)
- 永远不在 `core/theme/Color.kt` 外写 hex 字面量(`Color(0x...)` 仅限 Color.kt;StatusPill 的 SYNCED 文字色若保留为内联 hex 需提升为 token)。
- 洋红 `#B5179E`(StatusOffPlan)仅用于业务被拒/OFF-PLAN 全屏覆盖,绝不复用为强调色。
- 橙色已退役;无紫色/渐变/emoji;仅浅色(不做暗色);触控目标 48dp;动效仅功能性。
- 字体打包进 APK(res/font),不走 google_fonts 在线拉取。

## 常用命令
- `./gradlew :app:assembleDebug` — debug APK
- `./gradlew :app:testDebugUnitTest` — 单元测试
- `adb logcat -s WMPDA OkHttp` — 看日志
```

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "docs: add WMPDA CLAUDE.md + adopt DESIGN.md from QuickFill"
```

---

## Done criteria for Plan 1

- `./gradlew :app:assembleDebug` succeeds; `./gradlew :app:testDebugUnitTest` green (28 tests).
- App launches to Login; successful login (against a reachable WMS) navigates to the Workbench with both function groups; entries route to "待实现" placeholders.
- Infra in place for feature plans: `AppContainer`, `NetworkClient`, `WmsApi` (extend per feature), `ResponseInterpreter`/`WmsEnvelope`, `SessionManager`, `ScannerReceiver`, theme, and the shared component library (`ScanCard`/`ErrorOverlay`/`FlashOverlay`/`StatusPill`/`QFCard`/`FeedbackPlayer`).
- No Room / WorkManager / offline-sync anywhere.

## Hand-off to Plan 2 (合箱校验)

Plan 2 adds to `WmsApi`: `GET api/WorkOrderPickVerf` + `PUT api/WorkOrderPickVerf`; a `feature/picking/` module (Repository + ViewModel + screens); replaces the `Routes.PICKING` placeholder. It MUST honor the spec §7 cache-pollution rules (fetch fresh, single ViewModel instance, never fall back to stale data).

---

## Plan Set & Cross-Plan Coordination

This is **Plan 1 of 4**. Execute in order; each produces runnable, testable software:

| # | Plan file | Module | Status |
|---|---|---|---|
| 1 | `2026-06-01-wmpda-foundation.md` | scaffold + core + login + workbench | this file |
| 2 | `2026-06-01-wmpda-picking.md` | 合箱校验 | unblocked |
| 3 | `2026-06-01-wmpda-linestock.md` | 断线线边管理 (5 flows) | unblocked |
| 4 | `2026-06-01-wmpda-warehouse.md` | 中央立库 入库/退货 | **backend-blocked** (placeholder endpoint; live integration deferred) |

**Three shared files are edited by Plans 2–4. All edits are ADDITIVE — never rewrite these files wholesale:**
- `core/network/WmsApi.kt` — each plan APPENDS its endpoints + imports after `login`. Methods never collide (distinct names). Keep all previously-added methods.
- `AppContainer.kt` — each plan APPENDS its `by lazy` repository + import. Keep prior properties.
- `core/nav/NavGraph.kt` — Plan 1 routes all 8 feature destinations through one `listOf(...).forEach { composable(route){ "待实现" } }` placeholder block. Each feature plan REMOVES only its own route(s) from that list and adds real `composable(route){ Screen(...) }` entries. The list shrinks across plans; after Plan 4, delete the now-empty block.

**Accepted architecture trade-off (documented decision):** each feature's Retrofit wire DTOs live in `feature/<name>/data/` and `core/network/WmsApi.kt` imports them — a circular `core ↔ feature` *package* dependency. This compiles cleanly in WMPDA's single Gradle module and keeps one shared `WmsApi`. If WMPDA is ever split into Gradle modules (`:core`, `:feature:*`), relocate the wire DTOs into `core/network/dto/` (where `LoginDtos` already lives) to break the cycle. Until then, the coupling is intentional and harmless. (Login DTOs stay in `core/network/dto/` per Plan 1.)
