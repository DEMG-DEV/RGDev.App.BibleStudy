# RGDev.App.BibleStudy 📖
### Aplicación Nativa de Lectura y Estudio Bíblico para macOS

Aplicación nativa para macOS desarrollada en **Swift 6** y **SwiftUI**, diseñada con estricto apego a las **Human Interface Guidelines (HIG) de Apple**. Permite estudiar y contrastar de forma paralela las **4 versiones más utilizadas en español**, con navegación física canónica, resaltado exacto de las **Palabras de Jesús en rojo** (*Red Letter Edition*), concordancias FTS5 y un panel cronológico de notas de estudio.

---

## 🌟 Características Principales

### 1. Las 4 Versiones Bíblicas Esenciales
- **RVR1960** — *Reina-Valera 1960*: Equivalencia formal tradicional.
- **NTV** — *Nueva Traducción Viviente*: Equivalencia dinámica clara y contemporánea.
- **TLA** — *Traducción en Lenguaje Actual*: Lenguaje directo y comprensión inmediata.
- **NVI** — *Nueva Versión Internacional*: Equilibrio formal y exegético moderno.
- *Visualización simultánea:* Lee 1, 2, 3 o las 4 versiones a la vez en columnas paralelas sincronizadas.

### 2. Resaltado Exacto de las Palabras de Jesús (*Red Letter Edition*)
- Marcado exacto por fragmento y cláusula mediante etiquetas `<wj>...</wj>`.
- Separa estrictamente las fórmulas introductorias del narrador (ej. *«Él respondió y dijo:»*, *«Jesús le contestó:»*) de las palabras pronunciadas por Jesucristo.
- Color semántico dinámico: Carmesí profundo en Modo Claro y Coral suave en Modo Oscuro para no fatigar la vista.
- Interruptor rápido en la barra de herramientas para activar o desactivar el resaltado con un solo clic.

### 3. Navegación Estilo "Biblia Física"
- **Sidebar Canónico:**
  - **Antiguo Testamento (39 libros):** *Pentateuco*, *Históricos*, *Poéticos y Sabiduría*, *Profetas Mayores*, *Profetas Menores*.
  - **Nuevo Testamento (27 libros):** *Evangelios*, *Historia*, *Epístolas Paulinas*, *Epístolas Generales*, *Profecía*.
- **Selector de Uñero (Thumb Index):** Al tocar cualquier libro o número de capítulo, se despliega una cuadrícula interactiva (`1, 2, 3...`) para saltar a cualquier capítulo en 1 clic.
- **Paso de Páginas Continuo:** Botones inferiores para avanzar o retroceder de capítulo fluidamente.

### 4. Panel de Notas de Estudio (Cronológico e Inspector Nativo)
- Panel derecho nativo (`.inspector(isPresented:)`) accesible con el atajo `⌥⌘N`.
- **Agrupación cronológica automática:** Organizado por día (*"Hoy"*, *"Ayer"*, *"Lunes, 26 de Octubre"*...) con la hora exacta registrada (*"18:05"*).
- **Campos de estudio completos:**
  - Versículo anclado (ej. `Juan 3:16`) con salto directo al hacer clic en la nota.
  - Traducciones activas utilizadas durante el estudio.
  - Tema / Doctrina (ej. *Salvación, Gracia, Justificación, Promesa*).
  - Resumen ejecutivo destacado (1-2 líneas clave).
  - Cuerpo detallado con editor enriquecido / Markdown.
- **Filtros rápidos:** Filtro por tema o visualización exclusiva de las *"Notas de este capítulo"*.

### 5. Motor de Búsqueda FTS5 y Omnibox (`⌘K`)
- **Detector inteligente de citas:** Escribe `Jn 3:16`, `Sal 23`, `1Co 13:4`, `Gen 1` para viajar inmediatamente al pasaje.
- **Búsqueda libre Full-Text:** Búsqueda instantánea en milisegundos ignorando acentos y mayúsculas (`unicode61`) con previsualización en negrita del contexto.

---

## 🛠️ Estructura del Proyecto

```text
RGDev.App.BibleStudy/
├── Package.swift                             # Manifiesto Swift Package nativo
├── scripts/
│   └── build_bibles_db.py                    # Generador y etiquetador del corpus bíblico
├── BibleStudy/
│   └── Sources/
│       ├── App/
│       │   └── BibleStudyApp.swift           # Punto de entrada @main de macOS
│       ├── Models/
│       │   ├── BibleBook.swift               # Modelo canónico y categorías físicas
│       │   ├── BibleVerse.swift              # Modelo de versículo y resultados FTS
│       │   ├── StudyNote.swift               # Modelo de notas con timestamp y tema
│       │   └── AppState.swift                # Estado reactivo central (@ObservableObject)
│       ├── Database/
│       │   ├── BibleDatabase.swift           # Driver SQLite nativo con FTS5
│       │   └── StudyNotesStore.swift         # Persistencia de notas de usuario
│       ├── Views/
│       │   ├── MainView.swift                # NavigationSplitView + Toolbar HIG
│       │   ├── SidebarView.swift             # Sidebar categorizado estilo Biblia física
│       │   ├── ChapterPickerPopover.swift    # Selector rápido estilo uñero
│       │   ├── ParallelReaderView.swift      # Lector multicolumna (1 a 4 versiones)
│       │   ├── RedLetterText.swift           # Renderizador de Palabras de Jesús
│       │   ├── OmniboxSearchView.swift       # Buscador omnibox (⌘K)
│       │   └── StudyNotesInspectorView.swift # Inspector lateral de notas
│       └── Resources/
│           └── Bibles.sqlite                 # Base de datos optimizada (RVR1960, NTV, TLA, NVI)
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
