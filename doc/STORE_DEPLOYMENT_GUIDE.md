# Guia de Despliegue a Tiendas — Android, iOS y Web

Referencia basada en la sesion de trabajo del proyecto JFA Quality Drywall. Sirve como checklist y guia para publicar y actualizar apps Flutter en Google Play Store, Apple App Store y Firebase Hosting.

---

## Como Usar Este Documento

### Primera vez (setup inicial)

Copia y pega este prompt en una sesion nueva de tu proyecto Flutter:

```
Lee docs/STORE_DEPLOYMENT_GUIDE.md y ayudame a configurar mi proyecto
Flutter para publicar en Google Play Store y Apple App Store.
Sigue el checklist paso a paso desde cero. Verifica primero si ya
existe un keystore, release.keystore y un codemagic.yaml en el proyecto.
```

### Versiones posteriores (updates)

Copia y pega este prompt cuando hagas cambios y necesites subir una nueva version:

```
Lee docs/STORE_DEPLOYMENT_GUIDE.md. Se realizaron cambios en el codigo.
Necesito actualizar las versiones para Android y iOS. Sigue el checklist
de la seccion 6 "Checklist por release".
```

---

## 1. Versionamiento

En `pubspec.yaml` la version sigue el formato:

```yaml
version: X.Y.Z+N
```

| Parte               | Ejemplo | Android                     | iOS                            |
| ------------------- | ------- | --------------------------- | ------------------------------ |
| `X.Y.Z`             | 1.0.0   | `versionName`               | `CFBundleShortVersionString`   |
| `N` (build number)  | 19      | `versionCode`               | `CFBundleVersion`              |

**Regla importante:** Incrementar `N` en cada release. Apple no permite reusar un build number ya subido a App Store Connect (error 409).

Codemagic lee el build number directamente de `pubspec.yaml`:
```bash
--build-number=$(grep '^version:' pubspec.yaml | sed 's/.*+//')
```

---

## 2. Android — Google Play Store

### 2.1 Keystore de firma

Generar un keystore RSA2048 para la subida (upload key):

```bash
keytool -genkey -v -keystore release.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

**NUNCA commitear** el keystore. Agregar a `.gitignore`:

```
*.keystore
*.jks
key.properties
```

### 2.2 Configurar signing en `build.gradle.kts`

En `android/app/build.gradle.kts`:

```kotlin
android {
    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "TU_PASSWORD"
            storeFile = file("release.keystore")
            storePassword = "TU_PASSWORD"
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 2.3 Obtener SHA-256 (para Google Play Console)

```bash
keytool -list -v -keystore release.keystore -alias upload -storepass TU_PASSWORD
```

Copiar el valor de `SHA256` y pegarlo en Google Play Console donde lo solicite (App Signing section).

### 2.4 Build del AAB

```bash
cd apps/client
flutter build appbundle --release
```

El AAB se genera en:
```
build/app/outputs/bundle/release/app-release.aab
```

### 2.5 Upload a Google Play Console (Internal Testing)

1. Ir a **Testing → Internal testing**
2. **Create new release**
3. Subir `app-release.aab`
4. Agregar descripcion, screenshots, etc.
5. **Save** → **Roll out**

### 2.6 Publicacion a Produccion (desde Internal Testing)

Una vez que la app funcione correctamente en Internal Testing, crear un release nuevo en Production:

> **NO se puede "promover" directamente de Internal a Production.** Se debe crear un release nuevo.

1. Ir a **Test and release → Production**
2. Clic en **Create new release**
3. Subir el mismo `app-release.aab` (o uno con version mas alta)
4. Agregar release notes
5. Clic en **Next** → **Preview and confirm**
6. Clic en **Start rollout to production**

**Requisitos previos para publicar a produccion:**

| Elemento | Donde verificarlo |
|----------|-------------------|
| Store listing completa (titulo, descripcion, icono, screenshots) | Grow → Store listing |
| Privacy Policy URL | Grow → Store listing → Privacy Policy |
| Clasificacion de contenido | Grow → Store listing → App content |
| Declaracion de seguridad de datos (DSA) | Grow → Store listing → App content |
| Precio gratuito configurado | Grow → Pricing & distribution |
| Países/regiones objetivo | Grow → Pricing & distribution |
| App review credentials (usuario + contrasena de prueba) | Grow → Store listing → App review information |

**Tips para la primera publicacion:**

- Google puede tardar horas o dias en la primera revision
- Recibiras notificacion por email cuando sea aprobada
- La app aparecera en Google Play para todos los usuarios
- Para updates futuros, usar staged rollout (20% → 50% → 100%)
- Si detectas problemas despues de publicar, puedes pausar el release desde Production

### 2.7 Metadatos requeridos

- Nombre de la app
- Descripcion corta y larga
- Screenshots (phone y tablet)
- Icono de la app (512x512 PNG)
- Privacy Policy URL (obligatorio)
- Declaracion de seguridad de datos (DSA) si aplica
- Clasificacion de contenido

---

## 3. iOS — Apple App Store (via Codemagic)

### 3.1 Apple App Store Connect API Key

1. Ir a **App Store Connect → Users and Access → Keys**
2. Crear una nueva clave con rol **App Manager** o **Developer**
3. Descargar el archivo `.p8` (solo se puede descargar una vez)
4. Anotar: **Key ID**, **Issuer ID**, y guardar el `.p8` en lugar seguro

### 3.2 Variables de entorno en Codemagic

Crear estas variables en **Codemagic → Team Settings → Environment variables**:

| Variable         | Valor                        |
| ---------------- | ---------------------------- |
| `APPLEKEYID`     | Key ID de App Store Connect  |
| `APPLEISSUERID`  | Issuer ID de App Store Connect |
| `APPLEAPIKEY`    | Contenido del archivo `.p8`  |

**IMPORTANTE:** Los nombres NO deben tener guiones bajos. Usar `APPLEKEYID` no `APPLE_KEY_ID`.

### 3.3 Archivo `codemagic.yaml`

Crear en la raiz del repo (no dentro de `apps/client/`):

```yaml
workflows:
  ios-build:
    name: iOS Build & TestFlight
    instance_type: mac_mini_m2
    working_directory: apps/client
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
      ios_signing:
        automatic:
          app_store_connect:
            auth_type: api_key
            api_key_id: $APPLEKEYID
            api_key_issuer_id: $APPLEISSUERID
            api_key: $APPLEAPIKEY
      vars:
        APP_ID: com.tu.paquete
    triggering:
      events:
        - push
      branch_patterns:
        - pattern: main
          include: true
          source: true
    scripts:
      - name: Install Melos
        script: |
          dart pub global activate melos
          echo "$HOME/.pub-cache/bin" >> $CM_BUILD_DIR/.cm_env
      - name: Bootstrap Melos
        script: |
          cd ../..
          melos bootstrap
      - name: Generate Code
        script: |
          cd ../..
          melos run build_runner --no-select
      - name: Build iOS IPA
        script: |
          flutter clean
          flutter build ipa --release \
            --export-method=app-store \
            --build-number=$(grep '^version:' pubspec.yaml | sed 's/.*+//')
    artifacts:
      - build/ios/ipa/*.ipa
      - build/ios/ipa/*.dSYM.zip
    publishing:
      app_store_connect:
        auth_type: api_key
        api_key_id: $APPLEKEYID
        api_key_issuer_id: $APPLEISSUERID
        api_key: $APPLEAPIKEY
        submit_to_testflight: true
```

### 3.4 Configuracion de code signing en Xcode

En `ios/Runner.xcodeproj/project.pbxproj` (seguir el orden correcto de debug → release):

```swift
/* Debug */ CODE_SIGN_STYLE = Manual;
/* Release */ CODE_SIGN_STYLE = Automatic;
/* Release */ DEVELOPMENT_TEAM = TU_TEAM_ID;
```

**Tip:** El `DEVELOPMENT_TEAM` va en el proyecto (project-level) y en el target Runner, solo en la seccion Release.

### 3.5 Problema comun: Provisioning Profile type

En la UI de Codemagic, ir a **App settings → iOS code signing** y configurar:

- **Provisioning profile type:** `App Store` (NO `Development`)

Si queda en `Development`, el upload a TestFlight fallara.

### 3.6 Problema comun: Error 409 en App Store Connect

Causa: intentar subir un build number que ya existe.

Solucion: Leer el build number de `pubspec.yaml` (ya implementado en el `codemagic.yaml` de arriba).

### 3.7 Verificacion

1. Push a `main` → Codemagic se dispara automaticamente
2. Verificar en **Codemagic Dashboard** que el build termine exitosamente
3. Verificar en **App Store Connect → TestFlight** que aparezca la version correcta

---

## 4. Firebase Hosting (Web)

### 4.1 Build

```bash
cd apps/client
flutter build web --release --dart-define=SUPABASE_ANON_KEY="TU_KEY"
```

### 4.2 Deploy

```bash
firebase deploy --only hosting --project TU_PROJECT_ID
```

**Requisitos:**
- `firebase-tools` instalado globalmente: `npm install -g firebase-tools`
- Sesion activa: `firebase login`

### 4.3 Firebase Hosting URL

El sitio queda disponible en:
```
https://TU_PROJECT_ID.web.app
```

---

## 5. Archivos Sensibles — NUNCA Commitear

Agregar a `.gitignore`:

```
# Signing keys
*.keystore
*.jks
key.properties
*.p8

# Environment
.env.local

# Melos-generated overrides (contiene paths del sistema)
pubspec_overrides.yaml
```

**Por que `pubspec_overrides.yaml`?**
Melos lo genera automaticamente con paths absolutos. En Windows contiene `..\\..\\packages\\...` (backslashes) que rompen el build en macOS/Codemagic.

---

## 6. Checklist por Release

### Setup inicial (primera vez)

- [ ] Generar keystore Android (`keytool -genkey`)
- [ ] Configurar `signingConfigs` en `build.gradle.kts`
- [ ] Crear Apple App Store Connect API Key (`.p8`)
- [ ] Crear `codemagic.yaml` en la raiz del repo
- [ ] Configurar variables en Codemagic (`APPLEKEYID`, `APPLEISSUERID`, `APPLEAPIKEY`)
- [ ] Configurar `DEVELOPMENT_TEAM` en `project.pbxproj` (solo Release)
- [ ] Configurar Provisioning profile type a `App Store` en Codemagic UI
- [ ] Agregar archivos sensibles a `.gitignore`
- [ ] Verificar que `.env` tenga las credenciales de produccion
- [ ] Obtener SHA-256 y agregarlo en Google Play Console

### Cada release (updates)

- [ ] Hacer commit de los cambios en codigo
- [ ] Bump version en `pubspec.yaml` (+1 al build number)
  ```yaml
  # Ejemplo: de 1.0.0+18 a 1.0.0+19
  version: 1.0.0+19
  ```
- [ ] Build Android: `flutter build appbundle --release`
- [ ] Subir `app-release.aab` a Google Play Console → Internal testing → Create new release
- [ ] Push a `main` para disparar Codemagic (iOS automatico)
- [ ] Verificar en TestFlight que aparezca la nueva version
- [ ] (Opcional) Deploy web: `flutter build web ... && firebase deploy --only hosting`

### Publicacion a produccion (primera vez)

- [ ] Verificar store listing completa (titulo, descripcion, icono, screenshots)
- [ ] Verificar Privacy Policy URL configurada
- [ ] Verificar clasificacion de contenido
- [ ] Verificar declaracion de seguridad de datos (DSA)
- [ ] Verificar precio gratuito en Pricing & distribution
- [ ] Verificar paises/regiones objetivo
- [ ] Verificar app review credentials (usuario + contrasena de prueba)
- [ ] Ir a **Test and release → Production**
- [ ] Clic en **Create new release**
- [ ] Subir `app-release.aab` (mismo de Internal Testing o con version mas alta)
- [ ] Agregar release notes
- [ ] Clic en **Next** → **Preview and confirm**
- [ ] Clic en **Start rollout to production**
- [ ] Esperar revision de Google (horas o dias)
- [ ] Recibir notificacion de aprobacion por email

---

## 7. Comandos Rapidos de Referencia

```bash
# Verificar version actual
grep "^version:" apps/client/pubspec.yaml

# Build Android
cd apps/client && flutter build appbundle --release

# Build iOS (requiere macOS)
cd apps/client && flutter build ipa --release --export-method=app-store

# Build Web
cd apps/client && flutter build web --release --dart-define=SUPABASE_ANON_KEY="..."

# Deploy Web
firebase deploy --only hosting --project jfa-quality-drywall-inc

# Obtener SHA-256
keytool -list -v -keystore release.keystore -alias upload -storepass TU_PASSWORD
```
