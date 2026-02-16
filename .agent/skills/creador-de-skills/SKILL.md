---
name: creador-de-skills
description: Esta habilidad permite crear nuevas habilidades (skills) dentro del espacio de trabajo, siguiendo las mejores prácticas y documentando todo en español. Úsala cuando el usuario quiera automatizar o estandarizar la creación de nuevas capacidades para el agente.
---

# Creador de Skills

Esta habilidad guía al agente en la creación de nuevas habilidades dentro del directorio `.agent/skills/`. Todas las instrucciones, nombres y descripciones generadas por esta habilidad deben estar en **español**.

## Estructura de una Skill

Cada skill debe seguir esta estructura de carpetas:

```text
.agent/skills/nombre-de-la-skill/
├── SKILL.md       # Obligatorio: Instrucciones principales y metadatos
├── scripts/       # Opcional: Scripts de ayuda (Python, JS, Bash, etc.)
├── examples/      # Opcional: Ejemplos de uso o implementaciones de referencia
└── resources/     # Opcional: Plantillas, archivos estáticos o recursos adicionales
```

## Formato de SKILL.md

El archivo `SKILL.md` debe comenzar siempre con un bloque YAML de metadatos:

```markdown
---
name: nombre-legible-de-la-skill
description: Una descripción clara en tercera persona que explique qué hace la skill y cuándo debe activarse.
---
```

## Instrucciones para el Agente

Al crear una nueva skill:

1.  **Identificar el Propósito**: Define claramente qué tarea específica resolverá la skill.
2.  **Crear el Directorio**: Usa `mkdir` o `write_to_file` para crear la carpeta en `.agent/skills/<nombre-de-la-skill>`.
3.  **Redactar SKILL.md**: Escribe instrucciones detalladas en español. Incluye:
    *   Cuándo usar la skill.
    *   Pasos detallados para realizar la tarea.
    *   Convenciones de código o diseño a seguir.
4.  **Añadir Recursos**: Si la skill requiere scripts o plantillas, colócalos en las subcarpetas correspondientes.
5.  **Verificación**: Asegúrate de que la descripción en el YAML sea lo suficientemente descriptiva para que el sistema pueda "descubrir" la skill cuando sea relevante.

## Ejemplo de Plantilla (SKILL.md)

```markdown
---
name: ejemplo-de-skill
description: Breve explicación de la capacidad que añade esta skill.
---
# Nombre de la Skill

Instrucciones detalladas sobre cómo el agente debe comportarse...

## Flujo de Trabajo
1. Paso uno...
2. Paso dos...
```
