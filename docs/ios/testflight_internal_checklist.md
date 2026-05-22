# Checklist TestFlight interno — Nexo Admin iOS

## Build

- [ ] `CFBundleShortVersionString` actualizado.
- [ ] `CFBundleVersion` incrementado.
- [ ] `NexoBuildConfiguration` configurado como `staging` o `production`.
- [ ] `NexoAPIBaseURL` apunta a una URL accesible por internet, no a localhost.
- [ ] Scheme compartido.
- [ ] Firma/capabilities revisadas en Xcode.
- [ ] App icon y nombre visibles correctos.

## Smoke test funcional

- [ ] Login admin.
- [ ] Restore session.
- [ ] Selector de organización.
- [ ] Dashboard carga.
- [ ] Usuarios carga.
- [ ] Roles/permisos carga.
- [ ] Negocio carga.
- [ ] Catálogo carga.
- [ ] Tributario/SRI carga.
- [ ] Comprobantes carga.
- [ ] Reportes/auditoría carga.
- [ ] Logout borra sesión local.

## Seguridad

- [ ] Tokens en Keychain.
- [ ] No se persiste password de firma.
- [ ] No se expone XML/firma en logs.
- [ ] Acciones críticas piden motivo o confirmación.
- [ ] Permisos efectivos ocultan acciones no autorizadas.
- [ ] Backend valida siempre permisos.

## SRI y tributario

- [ ] iOS no firma XML.
- [ ] iOS no envía directo al SRI.
- [ ] iOS no calcula impuestos definitivos.
- [ ] Producción SRI exige gate backend.
- [ ] Errores SRI se muestran de forma entendible.

## Cierre

- [ ] `xcodebuild test` en verde.
- [ ] Archive generado.
- [ ] Subida a TestFlight completada.
- [ ] Grupo interno asignado.
- [ ] Notas de prueba enviadas.
