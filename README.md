# RGDev.App.BibleStudy 📖
### Aplicación Nativa de Lectura y Estudio Bíblico para macOS (v1.1.0)

Aplicación nativa para macOS desarrollada en **Swift 6** y **SwiftUI**, diseñada con estricto apego a las **Human Interface Guidelines (HIG) de Apple**. Permite estudiar y contrastar de forma paralela las **4 versiones más utilizadas en español**, con navegación física canónica, selección múltiple de versículos, sincronización directa con **Notas de Apple**, resaltado exacto de las **Palabras de Jesús en rojo** (*Red Letter Edition*), concordancias FTS5 y un panel cronológico de notas de estudio.

---

## 🌟 Características Principales

### 1. Las 4 Versiones Bíblicas Esenciales
- **RVR1960** — *Reina-Valera 1960*: Equivalencia formal tradicional.
- **NTV** — *Nueva Traducción Viviente*: Equivalencia dinámica clara y contemporánea.
- **TLA** — *Traducción en Lenguaje Actual*: Lenguaje directo y comprensión inmediata.
- **NVI** — *Nueva Versión Internacional*: Equilibrio formal y exegético moderno.
- *Visualización simultánea:* Lee 1, 2, 3 o las 4 versiones a la vez en columnas paralelas sincronizadas.

### 2. Selección Múltiple de Versículos y Barra de Acción Flotante
- **Modos de selección nativos de macOS:**
  - `⇧ Mayús + Clic`: Selección de rangos continuos (ej. `1 Pedro 4:7-10`).
  - `⌘ Cmd + Clic`: Selección discontinua de versículos específicos (ej. `Juan 3:16, 18, 20`).
  - Indicador circular en cada versículo para selección sin necesidad de teclado.
- **Barra Flotante Inferior (Floating Action Bar):** Aparece automáticamente con animación fluida al seleccionar versículos, permitiendo:
  - Visualizar la cita formateada y el conteo de versículos.
  - **Crear Nota** con el pasaje pre-citado y estructurado automáticamente.
  - **Copiar** el texto de todos los versículos seleccionados con su cita al portapapeles.
  - **Deseleccionar** con un solo clic.

### 3. Sincronización Automática con Notas de Apple (`Notes.app`)
- Puente nativo en segundo plano (`AppleNotesBridge`) mediante AppleScript asíncrono.
- Crea automáticamente la carpeta **`Estudio Bíblico`** en la cuenta principal de iCloud / Mac del usuario.
- Guarda y actualiza silenciosamente cada nota de estudio sin duplicados, rastreando su identificador interno (`appleNoteId`) y referencia visible `[ref:UUID]`.
- Conmutador en el pie del inspector para activar o pausar la sincronización en cualquier momento.

### 4. Selector de Temas y Resaltado de Palabras de Jesús
- **Conmutador de Temas (Claro / Oscuro / Sistema):** Atajo `⌥⌘T` o menú superior con persistencia automática en `UserDefaults`.
- **Palabras de Jesús en Rojo (*Red Letter Edition*):** Marcado exacto por fragmento y cláusula mediante etiquetas `<wj>...</wj>`, distinguiendo estrictamente el diálogo pronunciado de la narración introductoria.

### 5. Navegación Estilo "Biblia Física"
- **Sidebar Canónico:**
  - **Antiguo Testamento (39 libros):** *Pentateuco*, *Históricos*, *Poéticos y Sabiduría*, *Profetas Mayores*, *Profetas Menores*.
  - **Nuevo Testamento (27 libros):** *Evangelios*, *Historia*, *Epístolas Paulinas*, *Epístolas Generales*, *Profecía*.
- **Selector de Uñero (Thumb Index):** Al tocar cualquier libro o número de capítulo, se despliega una cuadrícula interactiva (`1, 2, 3...`) para saltar a cualquier capítulo en 1 clic.
- **Paso de Páginas Continuo:** Botones inferiores para avanzar o retroceder de capítulo fluidamente.

### 6. Panel de Notas de Estudio (Cronológico e Inspector Nativo)
- Panel derecho nativo (`.inspector(isPresented:)`) accesible con el atajo `⌥⌘N`.
- **Agrupación cronológica automática:** Organizado por día (*"Hoy"*, *"Ayer"*, *"Lunes, 26 de Octubre"*...) con la hora exacta registrada (*"18:05"*).
- **Campos de estudio completos:**
  - Versículo o pasaje anclado (ej. `1 Pedro 4:7-10`) con salto directo al hacer clic en la nota.
  - Traducciones activas utilizadas durante el estudio.
  - Tema / Doctrina (ej. *Salvación, Gracia, Justificación, Promesa*).
  - Resumen ejecutivo destacado (1-2 líneas clave).
  - Cuerpo detallado con editor enriquecido y citas automáticas.

### 7. Motor de Búsqueda FTS5 y Omnibox (`⌘K`)
- **Detector inteligente de citas:** Escribe `Jn 3:16`, `Sal 23`, `1Co 13:4`, `Gen 1` para viajar inmediatamente al pasaje.
- **Búsqueda libre Full-Text:** Búsqueda instantánea en milisegundos ignorando acentos y mayúsculas (`unicode61`) con previsualización en negrita del contexto.

---

## 🛠️ Estructura del Proyecto

```text
RGDev.App.BibleStudy/
├── Package.swift                             # Manifiesto Swift Package nativo
├── scripts/
│   ├── build_bibles_db.py                    # Generador y etiquetador del corpus bíblico
│   └── generate_xcodeproj.py                 # Generador del proyecto Xcode nativo
├── BibleStudy/
│   ├── Info.plist                            # Metadatos del bundle (com.rgdev.BibleStudy)
│   └── Sources/
│       ├── App/
│       │   └── BibleStudyApp.swift           # Punto de entrada @main con inyección de dock icon
│       ├── Models/
│       │   ├── BibleBook.swift               # Modelo canónico y categorías físicas
│       │   ├── BibleVerse.swift              # Modelo de versículo y resultados FTS
│       │   ├── StudyNote.swift               # Modelo de notas con timestamp, tema y Apple Notes ID
│       │   └── AppState.swift                # Estado reactivo central (@ObservableObject) y selección múltiple
│       ├── Database/
│       │   ├── BibleDatabase.swift           # Driver SQLite nativo con FTS5
│       │   ├── StudyNotesStore.swift         # Persistencia local de notas con fallback resiliente
│       │   └── AppleNotesBridge.swift        # Puente AppleScript para sincronización con Notes.app
│       ├── Views/
│       │   ├── MainView.swift                # NavigationSplitView + Toolbar HIG
│       │   ├── SidebarView.swift             # Sidebar categorizado estilo Biblia física
│       │   ├── ChapterPickerPopover.swift    # Selector rápido estilo uñero
│       │   ├── ParallelReaderView.swift      # Lector multicolumna con selección múltiple y barra flotante
│       │   ├── RedLetterText.swift           # Renderizador de Palabras de Jesús
│       │   ├── OmniboxSearchView.swift       # Buscador omnibox (⌘K)
│       │   └── StudyNotesInspectorView.swift # Inspector lateral de notas
│       └── Resources/
│           ├── Bibles.sqlite                 # Base de datos optimizada (RVR1960, NTV, TLA, NVI)
│           ├── AppIcon.png                   # Ícono maestro 3D flotante (1024x1024 con transparencia)
│           ├── AppIcon.icns                  # Paquete multi-resolución de macOS
│           └── Assets.xcassets/              # Catálogo de activos compilados (Assets.car)
```

---

## 🚀 Cómo Abrir y Ejecutar en Xcode

1. **Abrir en Xcode:**
   Puedes abrir la carpeta directamente en Xcode desde la terminal:
   ```bash
   open Package.swift
   ```
   o bien:
   ```bash
   xed .
   ```
2. **Seleccionar el Esquema:**
   En la barra superior de Xcode, selecciona el esquema **`BibleStudy`** y el destino **`My Mac`**.
3. **Ejecutar:**
   Presiona `⌘R` para compilar y lanzar la aplicación nativa.

4. **Compilación desde Terminal:**
   ```bash
   swift build
   ```
