# Fase 14 — Cierre técnico Admin iOS

## Estado recomendado

La Fase 14 puede cerrarse como MVP duro de Admin iOS cuando estén en verde:

1. Auth, sesión y organización activa.
2. Dashboard administrativo.
3. Usuarios, roles y permisos.
4. Configuración del negocio.
5. Catálogo local y solicitudes.
6. Tributario, firma y SRI.
7. Comprobantes, errores SRI, RIDE/XML y email.
8. Caja, reportes y auditoría general.
9. Checklist interno de hardening y TestFlight.

## No tocar si ya está verde

No reabrir módulos ya aprobados salvo por errores de compilación, seguridad o integración:

- dashboard;
- usuarios/roles/permisos;
- negocio/sucursales/puntos de emisión;
- catálogo;
- fiscal/SRI;
- comprobantes;
- reportes/auditoría.

## Bloqueantes antes de TestFlight

- `NexoAPIBaseURL` no puede apuntar a `localhost`.
- Scheme compartido.
- Versión y build incrementados.
- Login real contra API staging/dev.
- Permisos efectivos cargados desde backend.
- Logout limpia sesión local.
- Acciones críticas piden confirmación o motivo.
- La app no firma XML.
- La app no calcula impuestos definitivos.
- No se guardan secretos de firma electrónica en iOS.
- RIDE/XML se manejan como artefactos temporales o compartidos por mecanismos seguros.
- Pantallas críticas tienen loading, empty, error y retry.
- Tests de ViewModels críticos en verde.

## Decisión de cierre

Este sprint no agrega nuevos módulos de negocio. Cierra la fase, reduce riesgo operativo y deja lista la app para pruebas internas controladas.
