---
name: litedb-configuracion-embebida
description: "Cuando haga falta una base de datos embebida para configuraciones, el usuario quiere LiteDB."
metadata:
  node_type: memory
  pinned: false
  originSessionId: f996b5de-a7ff-414c-a94d-a243315ed78c
  modified: 2026-09-30T01:12:47.644Z
---

El usuario (Leonardo Méndez) fijó que, **si se requiere una base de datos embebida para configuraciones, se usa LiteDB**. Nunca MS Access, que está prohibido, y tampoco otra base embebida sin consultarle. Lo indicó al prohibir Access y el almacenamiento de secretos en texto plano (ver sin-access-ni-texto-plano).

Cómo aplicarlo: en cualquier proyecto suyo que necesite guardar configuración local o embebida, propón LiteDB. Si esa configuración incluye secretos, deben ir cifrados; LiteDB admite contraseña de archivo, y el usuario tiene un módulo propio, SecureSecrets, que usa LiteDB como repositorio de llaves de Data Protection. LiteDB no reemplaza a la base de datos transaccional del negocio (SQL Server o PostgreSQL según el proyecto).
