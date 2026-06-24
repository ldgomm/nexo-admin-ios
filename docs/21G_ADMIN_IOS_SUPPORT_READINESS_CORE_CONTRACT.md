# NEXO 21G — Admin iOS Support / Readiness Core Contract

## Estado

Contrato operativo para 21G.

Admin iOS no debe convertirse en caja, POS, backoffice contable ni operador de ventas.
Admin iOS debe diagnosticar, soportar y confirmar readiness.

## Objetivo

Responder desde Admin:

```text
¿El backend está vivo?
¿Qué versión corre?
¿La organización piloto responde?
¿Qué módulos core tienen señal de actividad?
¿Hay bloqueos de permisos recientes?
¿Se generaron exportaciones?
¿Hay eventos de inventario/caja/pagos relevantes?
¿Business está listo para operar?
```

## Superficies mínimas

### Sistema

Debe consumir:

```text
GET /health
GET /version
```

Debe mostrar:

```text
backend status
version
environment
commit/build if exposed
Mongo/Redis/MinIO if exposed by /health
```

Copy:

```text
Sistema operativo
Sistema con advertencias
Sistema no disponible
```

### Auditoría Admin

Debe consumir:

```text
GET /api/v1/admin/audit-logs
```

Filtros mínimos:

```text
organizationId
from
to
action
resourceType
resourceId
actorUserId
limit
```

Eventos prioritarios:

```text
inventory.adjustment.created
cash.session.opened
cash.movement.created
cash.session.closed
payment.registered
payment.replayed
receivable.created
receivable.payment_registered
export.daily.generated
export.daily.downloaded
permission.blocked
```

### Permisos bloqueados

Vista/filtro específico:

```text
Permisos bloqueados
```

Campos:

```text
actor
requiredPermission
resourceType
resourceId
reason
occurredAt
requestId/correlationId
```

Prohibido en 21G:

```text
editar permisos
cambiar roles
hacer override
crear bypass
```

### Export diagnostics

Vista/filtro:

```text
export.daily.generated
export.daily.downloaded
```

Debe mostrar:

```text
quién generó
cuándo
organizationId
resourceId
result
requestId/correlationId
```

No descargar ZIP desde Admin en 21G salvo endpoint ya existente.

## Seguridad

No mostrar:

```text
tokens
passwords
XML completo
RIDE completo
CSV completo
payloads sensibles
firma electrónica
private keys
idempotencyKey crudo
```

Business debe recibir:

```text
HTTP 403 en /api/v1/admin/audit-logs
```

Si Business recibe 200, es blocker.

## UX mínima

