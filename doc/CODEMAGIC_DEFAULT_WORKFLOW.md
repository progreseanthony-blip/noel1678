# iOS con Default Workflow de Codemagic

Se mantiene el editor visual y la firma/publicacion configuradas en Codemagic.
No es necesario usar un workflow YAML.

## Configuracion inicial (una vez)

1. Seleccionar la rama `main` y **Default Workflow**.
2. En **Build**, seleccionar **Project path**: `apps/main_app` y Flutter `3.44.6` (la version usada por el despliegue de produccion).
3. En **Pre-build**, agregar esta linea, conservando cualquier script existente:

   ```bash
   bash "$CM_BUILD_DIR/scripts/codemagic_pre_build.sh"
   ```

4. En **Build arguments**, agregar este argumento, conservando los argumentos de firma/version existentes:

   ```text
   --dart-define-from-file=.dart_tool/codemagic/production.json
   ```

   Si ya existen otros argumentos `--dart-define` para `ENVIRONMENT`, `SUPABASE_URL` o `SUPABASE_ANON_KEY`, sustituirlos por el argumento anterior para evitar valores contradictorios.

5. Guardar y lanzar un build nuevo desde `main` usando **Default Workflow**.

## Que hace Pre-build

Resuelve dependencias desde la raiz y los paquetes locales, ejecuta `build_runner` en core, data y main_app, verifica que existan los archivos declarados con `part` y prepara los tres valores publicos de `.env.production` para compilacion. No imprime las claves ni modifica datos de Supabase. Los archivos generados quedan solo en el runner.

Los siguientes builds usan el proceso habitual. No se incluyen cambios de ramas de desarrollo.

## Diagnostico

- `*.g.dart: No such file or directory`: revisar el log **Pre-build**; debe terminar correctamente antes de **Building for iOS**.
- `No matching profiles`: revisar el perfil App Store y su certificado en la configuracion de firma existente.
- Si Pre-build termina bien pero el compilador busca archivos generados inexistentes, revisar si algun otro script ejecuta una limpieza o elimina archivos despues de Pre-build.
- La compilacion debe mostrar `--dart-define-from-file=.dart_tool/codemagic/production.json` en el comando Flutter.

Referencias: https://docs.codemagic.io/flutter-configuration/custom-scripts/ y https://docs.codemagic.io/knowledge-others/dart-define-from-file-secrets/
