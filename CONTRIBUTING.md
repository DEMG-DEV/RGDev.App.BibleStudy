# Guía de Contribución a BibleStudy 📖

¡Gracias por tu interés en contribuir a **BibleStudy**! Este proyecto es de código abierto y busca ofrecer la experiencia de lectura y estudio bíblico más elegante, fluida y respetuosa de la privacidad en macOS.

A continuación encontrarás los lineamientos y pasos necesarios para colaborar eficazmente.

---

## 🛠️ Requisitos del Entorno de Desarrollo

Para compilar y ejecutar **BibleStudy** localmente necesitas:
- **Sistema Operativo:** macOS 14.0 (Sonoma) o macOS 15.0+ (Sequoia).
- **Herramientas de Desarrollo:**
  - [Xcode](https://developer.apple.com/xcode/) 15.4 o 16.0+.
  - [Swift 6.0+](https://www.swift.org/).
  - Git configurado en tu terminal.
  - Python 3.10+ (utilizado para scripts auxiliares y regeneración de proyectos).

---

## 🚀 Cómo Empezar

1. **Hacer un Fork:**
   Haz un fork del repositorio oficial en GitHub: [https://github.com/DEMG-DEV/RGDev.App.BibleStudy](https://github.com/DEMG-DEV/RGDev.App.BibleStudy).

2. **Clonar tu Fork:**
   ```bash
   git clone https://github.com/TU-USUARIO/RGDev.App.BibleStudy.git
   cd RGDev.App.BibleStudy
   ```

3. **Abrir en Xcode:**
   Puedes abrir el paquete directamente:
   ```bash
   open Package.swift
   ```
   o bien el proyecto generado:
   ```bash
   open BibleStudy.xcodeproj
   ```

4. **Compilar desde la Terminal:**
   ```bash
   swift build
   ```

5. **Ejecutar la Aplicación:**
   ```bash
   swift run
   ```
   o presiona `⌘ + R` en Xcode seleccionando el esquema `BibleStudy` y destino `My Mac`.

---

## 📐 Filosofía y Estilo de Código

Al escribir código para **BibleStudy**, asegúrate de respetar los siguientes principios:

### 1. Human Interface Guidelines (HIG) de Apple
- La interfaz debe verse y sentirse como una aplicación nativa de macOS de primera categoría.
- Usar controles nativos de SwiftUI (`NavigationSplitView`, `.inspector`, `.sheet`, `.toolbar`).
- Soporte estricto para **Modo Claro** y **Modo Oscuro** con contraste óptimo.
- Evitar patrones web o interfaces emuladas que desentonen en el entorno de escritorio de Mac.

### 2. Swift 6 y Concurrencia Estricta
- Todo el código debe compilar con **cero advertencias de concurrencia** (`Strict Concurrency Checking`).
- Las clases de interfaz y estado deben estar anotadas con `@MainActor`.
- Los tipos que atraviesen límites de tareas asíncronas deben conformar `Sendable`.

### 3. Rendimiento y Privacidad
- La aplicación es **100% offline**: no agregues telemetría, analytics ni llamadas de red externas no autorizadas.
- Toda consulta bíblica pesada debe apoyarse en la base de datos SQLite embebida y en el motor FTS5 (`unicode61`).

---

## 🌿 Flujo de Trabajo con Git y Ramas

1. **Crear una Rama Descriptiva:**
   Crea una rama partiendo de `master`:
   ```bash
   git checkout -b feature/nombre-de-tu-mejora
   # o bien:
   git checkout -b fix/descripcion-del-bug
   ```

2. **Convención de Commits (Conventional Commits):**
   Utiliza mensajes estructurados:
   - `feat(modulo): descripción concisa` (Nuevas características).
   - `fix(modulo): corrección de error` (Solución de bugs).
   - `docs(modulo): actualización de documentación` (README, guías).
   - `refactor(modulo): refactorización interna sin cambio funcional`.
   - `chore(modulo): tareas de mantenimiento, dependencias o CI`.

   *Ejemplo:*
   ```bash
   git commit -m "feat(reader): add verse bookmarking shortcut" -m "Allows users to press ⌘D to bookmark current verse."
   ```

3. **Verificar Compilación y Empaquetado:**
   Antes de subir tu PR, verifica que la app compila y el instalador se genera limpiamente:
   ```bash
   swift build
   ./scripts/build_dmg.sh
   ```

4. **Enviar Pull Request:**
   Sube tus cambios a tu fork y abre un Pull Request hacia la rama `master` del repositorio principal completando la plantilla estándar de PR.

---

## 🧪 Reportar Problemas (Issues)

Si encuentras un error o tienes una idea para mejorar la app:
- Revisa primero los [Issues existentes](https://github.com/DEMG-DEV/RGDev.App.BibleStudy/issues) para evitar duplicados.
- Si es un bug nuevo, utiliza la plantilla de **Bug Report** detallando tu versión de macOS, pasos para reproducir y capturas de pantalla si aplica.
- Si es una sugerencia, utiliza la plantilla de **Feature Request** explicando el caso de uso y el beneficio para la comunidad.

---

## 📜 Código de Conducta

Al participar en este proyecto, te comprometes a seguir las normas de respeto y cordialidad descritas en [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
