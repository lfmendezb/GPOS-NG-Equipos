---
name: sin-access-ni-texto-plano
description: El usuario prohíbe usar MS Access y guardar contraseñas o datos sensibles en texto plano; el login sa debe estar deshabilitado.
metadata:
  node_type: memory
  pinned: false
  originSessionId: f996b5de-a7ff-414c-a94d-a243315ed78c
  modified: 2026-09-30T01:11:57.335Z
---

El usuario (Leonardo Méndez) fijó como norma que **no se debe usar MS Access** como almacenamiento y que **no se deben guardar contraseñas ni datos sensibles en texto plano** (ni en código, ni en archivos de configuración, ni en DSN, ni en bases sin cifrar). Lo estableció al descartar los hallazgos del sistema legado BP2 (VB6), que guardaba credenciales en Access y tenía la clave `sa` escrita en el código.

Como buena práctica de SQL Server, pidió deshabilitar el login `sa` y usar en su lugar un login administrativo nominal llamado `gsf`.

Cómo aplicarlo: al diseñar o revisar cualquier proyecto suyo, no propongas Access ni almacenamiento de secretos en claro. Usa cifrado (por ejemplo, Data Protection) o un almacén de secretos. Señala como hallazgo cualquier uso de `sa` o de credenciales escritas en el código.
