---
name: kits-admcloud-prueba-alta-pendiente
description: "2026-10-09: prueba de alta de kit con Components en AdmCloud aplazada por el propietario (no urgente); lectura del kit ya verificada con PAQ0001"
metadata:
  node_type: memory
  type: project
  originSessionId: 04973234-ae57-4e21-9499-3cc3a1aeef9e
  modified: 2026-10-09T15:48:59.842Z
---

El 2026-10-09 se verificó la **lectura** de kits en AdmCloud (PAQ0001, `GET /api/Kits/{ID}` trae `Components`; muestra en `GPOS-B-admcloud`, commit 1f7d358). La prueba de **alta o actualización** de un kit con componentes se **aplazó**: el propietario dijo «se puede quedar para luego, no es urgente, mejor concentremos el esfuerzo en lo necesario».

**Why:** el esquema público del alta (`POST /api/Kits`) no declara `Components`. El propietario creía que `Locations` llevaba los componentes, pero en ese esquema `Locations` son los niveles de reorden por almacén. Hay que probar enviando `Components`, con la misma forma que devuelve el GET.

**How to apply:** cuando se retome, preparar un script que el propietario ejecuta él mismo, como `Consultar-KitAdmCloud.ps1`; el clasificador impide que el agente use las credenciales de la base. El script trabaja solo sobre la empresa de pruebas 928040a7-…, con un SKU de prueba marcado. Para los componentes:
- usar los artículos de `POS_DEMO_AC.dbo.inv_Articulos`;
- tomar `Ac_GuidArticulo` como ItemID (por ejemplo, las aguas 7360000020020 y 7360000021021);
- revisar si `Ac_GuidArticuloPrincipal` corresponde a otro ID de AdmCloud.

Siguen abiertas la opción (a) o (b) del doble descuento y el dueño del costo de la receta.

Relacionado: [[referencias-api-erp]], [[pruebas-proveedores-con-mock]].

**Actualización 2026-10-09:** KD-01 a KD-08 aprobados (ADR-113, master 817b939): opción (a) `ImpactStock=false` + ajuste diario; plato = servicio por omisión; GPOS NG manda en la receta; **KD-08: GPOS NG no crea kits en AdmCloud en v1**, así que la prueba de alta con `Components` ya no hace falta para v1 (solo lectura y espejo). Pendiente KD-06: preguntar a Fortech si la cuenta del ajuste sale del motivo o del artículo.
