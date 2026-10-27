# Changelog 📜

Todas las modificaciones notables introducidas en **BibleStudy** se documentan cronológicamente en este archivo.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y este proyecto se adhiere a [Semantic Versioning (SemVer)](https://semver.org/lang/es/).

---

## [1.1.1] - 2026-10-27

### Añadido
- **Automatización CI/CD:** Flujo de GitHub Actions en `.github/workflows/build-dmg.yml` que compila en macOS y publica el archivo `.dmg` en los Releases de GitHub en cada tag, push o evento de release.
- **Doble nomenclatura de distribución:** Generación de `BibleStudy-1.1.1-macOS.dmg` y alias universal `BibleStudy.dmg`.
- **Landing Page en GitHub Pages:** Sitio web promocional oficial en `docs/index.html` con diseño Apple HIG, mockup interactivo de macOS Sequoia y descarga directa del instalador.
- **Documentación de Proyecto Integral:** Incorporación de `LICENSE` (MIT), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, plantillas de Issues y Pull Requests.

### Corregido
- Solucionado el issue por el cual los releases manuales o sin tag no adjuntaban el archivo `.dmg`.
- Actualizados enlaces canónicos al repositorio oficial `DEMG-DEV/RGDev.App.BibleStudy`.

---

## [1.1.0] - 2026-10-26

### Añadido
- **Selección Múltiple de Versículos:**
  - Soporte para rangos continuos mediante `⇧ Mayús + Clic` (ej. `1 Pedro 4:7-10`).
  - Soporte para selección discontinua mediante `⌘ Cmd + Clic` (ej. `Juan 3:16, 18, 20`).
  - Indicador circular interactivo `○`/`✓` en cada celda de versículo para selección táctil o con ratón.
- **Barra de Acción Flotante (Floating Action Bar):** HUD inferior animado con accesos rápidos para crear nota con pasaje precitado, copiar versículos al portapapeles y deseleccionar.
- **Sincronización Silenciosa con Notas de Apple (`Notes.app`):**
  - Creación automática de la carpeta `Estudio Bíblico` en iCloud/Mac.
  - Deduplicación mediante identificadores internos persistentes (`appleNoteId`) y etiquetas `[ref:UUID]`.
  - Conmutador en el inspector de notas para activar o pausar la sincronización en tiempo real.
- **Selector de Temas:** Conmutador interactivo entre Modo Claro, Modo Oscuro y Automático (`⌥⌘T`) con persistencia en `UserDefaults`.
- **Nuevo Ícono Oficial 3D Flotante:**
  - Diseño en relieve de Biblia en cuero azul medianoche con cruz dorada y cinta carmesí.
  - Canal alfa 100% transparente sin marcos blancos para integración perfecta en el Dock de macOS.
  - Inyección dinámica en memoria al arrancar la app (`NSApplication.shared.applicationIconImage`).

---

## [1.0.0] - 2026-10-26

### Añadido
- **4 Versiones Bíblicas Esenciales:** RVR1960, NTV, TLA y NVI integradas en SQLite offline.
- **Lector Paralelo Sincronizado:** Visualización simultánea de 1 a 4 traducciones en columnas perfectamente alineadas fila por fila.
- **Palabras de Jesús en Rojo (*Red Letter Edition*):** Etiquetado exegético mediante `<wj>...</wj>` distinguiendo la narración del diálogo directo del Señor.
- **Navegación Canónica Estilo Biblia Física:**
  - División física en 39 libros del Antiguo Testamento y 27 libros del Nuevo Testamento con categorías doctrinales.
  - Uñero interactivo (*Thumb Index*) para salto inmediato a capítulos.
- **Panel de Notas de Estudio:** Inspector cronológico agrupado por día con hora exacta, cita anclada, tema y cuerpo enriquecido.
- **Búsqueda Instantánea FTS5 y Omnibox (`⌘K`):** Reconocimiento inteligente de citas (`Jn 3:16`, `Sal 23`) y búsqueda textual a nivel de milisegundos con realce en negrita.
