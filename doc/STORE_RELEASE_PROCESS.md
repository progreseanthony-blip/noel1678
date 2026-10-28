# Actualizaciones de Global Golf para tiendas

Esta es la guía específica de este repositorio para las siguientes entregas.
La guía STORE_DEPLOYMENT_GUIDE.md contiene ejemplos de otro proyecto; para iOS
se utiliza el editor visual **Default Workflow**, según CODEMAGIC_DEFAULT_WORKFLOW.md.

## Cada actualización

1. Revisar el estado de Git y la versión en `apps/main_app/pubspec.yaml`.
2. Incrementar el número después de `+`. Compararlo con el último número enviado
   a ambas tiendas si se hicieron entregas fuera de este repositorio. Aumentar la
   versión visible cuando corresponda al alcance del cambio.
3. Ejecutar desde la raíz:

   ```powershell
   .\scripts\build_store_release.ps1
   ```

   El script exige la clave de firma Android existente, resuelve las dependencias,
   genera Riverpod y compila el bundle usando exclusivamente la configuración
   pública de `.env.production`. No usa firma de depuración ni imprime contraseñas.
   `-SkipPreparation` solo es apropiado si ya se completaron los pasos de
   dependencias y generación para el mismo código.
4. El script verifica la firma del AAB con `jarsigner -verify` y guarda el SHA-256.
   Los archivos quedan en `releases/android/`, fuera de Git. Los registros de
   compilación están en `scratch/store_release_*.log`.
5. Hacer commit y push de la versión y los cambios a `main`.
6. Entregar el AAB al responsable para cargarlo a Google Play Console.
7. El responsable ejecuta Codemagic desde `main` con **Default Workflow**,
   project path `apps/main_app` y Flutter **3.44.6 o posterior compatible**.
   Conservar firma y publicación existentes, ejecutar el pre-build documentado
   y verificar que cualquier `--build-number` o `--build-name` personalizado
   coincida con la entrega; un argumento explícito sustituye al pubspec.
8. Confirmar el resultado de iOS en Codemagic/TestFlight y el de Android en Google
   Play. Generar un artefacto local o hacer push no confirma su aceptación en tiendas.

## Entrega preparada el 28 de octubre de 2026

- Versión prevista para ambas plataformas: **1.0.0+4**.
- Android: `releases/android/global-golf-1.0.0-build4.aab`.
- Bundle generado y firma verificada (`jar verified`), 74.473.240 bytes.
- Manifest del AAB verificado: paquete `com.globalgolf.projectapp`, versión
  `1.0.0`, código de compilación `4`.
- SHA-256: `A4C6033B8DF3AED3DD3AA925817131F259E819706762E031846AA7BB0FC311D5`.
- iOS: mínimo 14.0; compilación y carga a cargo del responsable de Codemagic.
- La entrega anterior del repositorio era 1.0.0+3. La actualización de plugins
  está en el commit `c15e2e2`.

Esta misma conversación puede usarse para las siguientes entregas, junto con
esta guía y la versión registrada en el repositorio.
