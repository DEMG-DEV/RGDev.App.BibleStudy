<p align="center">
  <img src="BibleStudy/Sources/Resources/AppIcon.png" alt="BibleStudy Logo" width="160" />
</p>

<h1 align="center">BibleStudy para macOS</h1>

<p align="center">
  <strong>La experiencia definitiva, nativa y sin distracciones de estudio bíblico en tu Mac.</strong>
</p>

<p align="center">
  <a href="https://github.com/DEMG-DEV/RGDev.App.BibleStudy/releases/latest"><img src="https://img.shields.io/badge/Versi%C3%B3n-v1.1.1-blue.svg?style=flat-square" alt="Version"></a>
  <img src="https://img.shields.io/badge/Plataforma-macOS%2014%20%7C%2015%2B%20(Sonoma%20%7C%20Sequoia)-black?style=flat-square&logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138.svg?style=flat-square&logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/UI-SwiftUI%20%2B%20Apple%20HIG-5856D6.svg?style=flat-square" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Motor-SQLite%20FTS5%20Offline-003B57.svg?style=flat-square&logo=sqlite" alt="SQLite">
  <img src="https://img.shields.io/badge/Privacidad-100%25%20Offline%20%26%20Zero--Telemetry-success.svg?style=flat-square" alt="Privacidad">
  <a href="https://demg-dev.github.io/RGDev.App.BibleStudy/"><img src="https://img.shields.io/badge/Web-GitHub%20Pages-informational.svg?style=flat-square" alt="Landing Page"></a>
</p>

<p align="center">
  <a href="#-descarga-e-instalación">Descargar .DMG</a> &bull;
  <a href="#-innovaciones-principales">Características</a> &bull;
  <a href="#-las-4-versiones-bíblicas">Versiones</a> &bull;
  <a href="#-atajos-de-teclado-para-usuarios-pro">Atajos de Teclado</a> &bull;
  <a href="https://demg-dev.github.io/RGDev.App.BibleStudy/">Página Web Oficial</a>
</p>

---

## 💡 ¿Por qué BibleStudy?

Muchas aplicaciones bíblicas en el escritorio son portales web empaquetados en Electron: lentos, sobrecargados de suscripciones, cuentas obligatorias y rastreadores de publicidad.

**BibleStudy** nació bajo una filosofía diametralmente opuesta: **crear una aplicación de primera clase puramente nativa para macOS**, diseñada en **Swift 6** y **SwiftUI**, con respeto absoluto a las *Human Interface Guidelines (HIG)* de Apple. Toda la biblioteca de 4 traducciones fundamentales, las concordancias completas y tus notas personales residen **100% offline** en tu disco duro en un motor SQLite C de alto rendimiento.

---

## 🌟 Innovaciones Principales

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. Lector Paralelo Sincronizado Fila por Fila (RVR1960 / NTV / TLA / NVI)    │
│ 2. Resaltado Gramatical Exacto: Palabras de Jesús (Red Letter Edition)      │
│ 3. Sincronización Silenciosa en Segundo Plano con Notas de Apple (iCloud)   │
│ 4. Selección Múltiple con HUD Flotante (⇧ Mayús + Clic / ⌘ Cmd + Clic)      │
│ 5. Uñero Canónico de Biblia Física (Thumb Index) y Salto Rápido             │
│ 6. Motor FTS5 Omnibox (⌘K) con Reconocimiento Inteligente de Citas          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1. 📖 Lector Paralelo Fila por Fila
Compara hasta 4 versiones en columnas simultáneas sincronizadas horizontalmente versículo por versículo. Si una traducción utiliza equivalencia dinámica y fusiona cláusulas contiguas, el motor mantiene la alineación visual perfecta para que nunca pierdas el hilo del pasaje al desplazarte.

### 2. 🔴 Edición con Palabras de Jesús en Rojo (*Red Letter*)
A diferencia de los visores convencionales que colorean oraciones completas, nuestro etiquetador gramatical separa estrictamente el relato del narrador de las declaraciones pronunciadas por Jesús:
> *«Jesús le respondió y dijo:* <span style="color:#ff6b6b">«De cierto, de cierto te digo, que el que no naciere de nuevo, no puede ver el reino de Dios.»</span> *(Jn 3:3)*

El color adopta tonalidades adaptativas: **carmesí real** en Modo Claro y **coral suave** en Modo Oscuro para garantizar confort visual durante horas de estudio prolongado.

### 3. 🍏 Sincronización Automática con Notas de Apple (`Notes.app`)
Cada vez que escribes una observación exegética o devocional, el puente en segundo plano (`AppleNotesBridge`) la replica automáticamente en la carpeta **«Estudio Bíblico»** de tu cuenta de **Notas de Apple**:
- **Continuidad Total:** Escribe en tu Mac y consulta tus notas en tu iPhone o iPad vía iCloud al instante.
- **Deduplicación Inteligente:** Utiliza identificadores internos persistentes (`x-coredata://...`) para actualizar la misma nota sin generar duplicados al editarla.
- **Sin Bloqueo de UI:** AppleScript asíncrono sobre hilos de utilidad que no ralentiza la interfaz.

### 4. 🎯 Selección Múltiple con Barra de Acción Flotante
- **Rangos continuos:** Haz clic en un versículo inicial y luego `⇧ Mayús + Clic` en el final para seleccionar pasajes enteros (ej. `1 Pedro 4:7-10`).
- **Versículos alternos:** Pulsa `⌘ Cmd + Clic` en versículos específicos (ej. `Juan 3:16, 18, 20`).
- **HUD Flotante:** Al seleccionar versículos, emerge una barra inferior con acciones directas para **Crear Nota** (con el texto pre-citado automáticamente), **Copiar Texto** o **Deseleccionar**.

---

## 📚 Las 4 Versiones Bíblicas

| Traducción | Nombre Completo | Tipo de Traducción | Enfoque Principal |
| :--- | :--- | :--- | :--- |
| **RVR1960** | *Reina-Valera 1960* | Equivalencia Formal | Precisión verbal tradicional, memorización clásica y liturgia. |
| **NTV** | *Nueva Traducción Viviente* | Equivalencia Dinámica | Claridad contemporánea, belleza poética y comprensión inmediata. |
| **NVI** | *Nueva Versión Internacional* | Equivalencia Óptima | Rigor académico, equilibrio exegético moderno y lectura pública. |
| **TLA** | *Traducción en Lenguaje Actual* | Lenguaje Directo | Sencillez pedagógica y lenguaje cotidiano sin arcaísmos. |

---

## ⚡ Atajos de Teclado para Usuarios Pro

| Atajo | Acción | Descripción |
| :---: | :--- | :--- |
| `⌘ K` | **Buscador Omnibox** | Salta a citas (`Jn 3:16`, `Sal 23`) o busca texto con FTS5 en milisegundos. |
| `⌥ ⌘ N` | **Alternar Notas** | Abre o repliega el inspector cronológico lateral de notas de estudio. |
| `⌥ ⌘ T` | **Alternar Tema** | Cambia instantáneamente entre Modo Claro, Modo Oscuro y Automático. |
| `⇧ + Clic` | **Rango de Versículos** | Selecciona un bloque continuo de versículos en el lector paralelo. |
| `⌘ + Clic` | **Selección Discontinua** | Agrega o quita versículos individuales de la selección activa. |
| `⌘ [` / `⌘ ]` | **Navegación de Capítulos** | Pasa al capítulo anterior o siguiente de forma continua. |

---

## 💾 Descarga e Instalación

### Opción 1: Descargar el Instalador Oficial (.DMG)
1. Descarga la versión más reciente desde [Releases](https://github.com/DEMG-DEV/RGDev.App.BibleStudy/releases/latest).
2. Abre **`BibleStudy-1.1.1-macOS.dmg`**.
3. Arrastra el icono de **BibleStudy** hacia la carpeta **Aplicaciones**.
4. ¡Listo! La app está completamente optimizada para Apple Silicon (M1/M2/M3/M4) e Intel.

### Opción 2: Compilar desde el Código Fuente
Requisitos: macOS 14+, Xcode 15+ o Swift 6 toolchain.

```bash
# 1. Clonar el repositorio
git clone https://github.com/DEMG-DEV/RGDev.App.BibleStudy.git
cd RGDev.App.BibleStudy

# 2. Compilar con Swift Package Manager
swift build -c release

# 3. O crear el instalador .DMG completo con un solo comando:
./scripts/build_dmg.sh
```
El archivo resultante se generará en `dist/BibleStudy-1.1.1-macOS.dmg`.

---

## 🤖 Integración Continua (CI/CD con GitHub Actions)

El proyecto incluye dos flujos de trabajo automatizados listos para producción:

- **`.github/workflows/build-dmg.yml`**: Compila la aplicación en runners macOS de GitHub Actions, genera el `.dmg` comprimido de distribución y lo publica automáticamente en los Releases de GitHub al crear una etiqueta (`git tag v1.1.0`).
- **`.github/workflows/deploy-pages.yml`**: Publica automáticamente la página web promocional en **GitHub Pages** desde la carpeta `docs/`.

---

## 🛡️ Privacidad y Seguridad

- **Cero Telemetría:** No recopilamos analíticas, identificadores de publicidad ni datos de navegación.
- **Base de Datos Local Embebida:** `Bibles.sqlite` se almacena localmente en el paquete de la aplicación.
- **Tus Notas son Tuyas:** Las notas se guardan en tu carpeta local de soporte de usuario (`~/Library/Application Support/RGDev.App.BibleStudy`) y en tu cuenta privada de Notas de Apple.

---

## 🤝 Comunidad y Contribución

¡Las contribuciones de la comunidad son bienvenidas y apreciadas!

- 📘 [Guía de Contribución](CONTRIBUTING.md) — Requisitos del entorno, arquitectura y flujo de Git.
- 📜 [Código de Conducta](CODE_OF_CONDUCT.md) — Normas de convivencia comunitaria.
- 🛡️ [Política de Seguridad](SECURITY.md) — Reporte responsable de vulnerabilidades.
- 📝 [Historial de Cambios](CHANGELOG.md) — Registro detallado de cada versión (SemVer).

---

## 📜 Licencia

Distribuido bajo la Licencia **MIT**. Consulta [LICENSE](LICENSE) para más información. Desarrollado con dedicación por [DEMG-DEV](https://github.com/DEMG-DEV).
