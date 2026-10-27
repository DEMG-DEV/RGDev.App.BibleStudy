# Política de Seguridad 🛡️

La seguridad y privacidad de los datos de nuestros usuarios es una prioridad fundamental en **BibleStudy**.

---

## Versiones con Soporte de Seguridad

| Versión | Con Soporte Activo |
| :---: | :---: |
| `1.1.x` | ✅ Sí |
| `1.0.x` | ❌ Retirada (actualizar a 1.1.x) |

---

## Filosofía de Seguridad y Privacidad

- **Arquitectura 100% Local (Air-Gapped):** BibleStudy no transmite solicitudes de red, consultas bíblicas ni notas personales a servidores externos.
- **Base de Datos Embebida de Solo Lectura:** La base de datos SQLite (`Bibles.sqlite`) se abre con banderas `SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX` previniendo cualquier inyección o alteración indebida.
- **Sincronización Segura con Notas de Apple:** Se ejecuta a través de los mecanismos estándar y autorizados de macOS (AppleScript / Sandboxed IPC) directamente contra la base de datos de iCloud del propio usuario.

---

## Reporte de Vulnerabilidades

Si descubres una posible vulnerabilidad de seguridad o un problema de privacidad en este repositorio:

1. **Por favor, NO abras un Issue público.**
2. Envía un reporte privado mediante la pestaña de **Security Advisories** de GitHub:
   [https://github.com/DEMG-DEV/RGDev.App.BibleStudy/security/advisories](https://github.com/DEMG-DEV/RGDev.App.BibleStudy/security/advisories)
   o contacta a los mantenedores de **DEMG-DEV** directamente.
3. Incluye:
   - Descripción detallada de la vulnerabilidad.
   - Pasos para reproducirla o prueba de concepto (PoC).
   - Versión de macOS y versión de la aplicación afectada.

### Nuestro Compromiso
- Acusaremos recibo del reporte dentro de las primeras **48 horas**.
- Proporcionaremos una estimación del tiempo necesario para mitigar el problema.
- Publicaremos un parche de seguridad y agradeceremos públicamente la contribución responsable una vez resuelto.
