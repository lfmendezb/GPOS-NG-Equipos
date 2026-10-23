---
name: laboratorio-adr90-virtualbox-en-lfmb
description: "2026-10-21: laboratorio de ADR-90 con VirtualBox en LFMB (equipo de B, Win11 Home, 13,9 GB, M: 547 GB), VM por bloques; OSHIN-LEGION es de C desde el 16-oct"
metadata:
  node_type: memory
  type: project
  originSessionId: fa41992d-86b9-4341-98ef-a923780a09be
  modified: 2026-10-21T07:07:54.288Z
---

El propietario decidió el 2026-10-21 que el laboratorio de ADR-90 (diseño de C v3, Q-LAB-01..03) usa **VirtualBox alojado en `LFMB`** (el equipo de B, el de esta sesión: Ryzen 7 5800H, 16 hilos, 13,9 GB de RAM, Windows 11 Home sin Hyper-V, disco M: con 547 GB libres, `M:\VM`), con las VM **por bloques y no en paralelo**. Descartados: `DEVLAB00` (PC de A, 8 GB, 4 hilos), OSHIN-LEGION (equipo de C desde el 2026-10-16, Home, 40 pantallazos azules) y los demás.

**Why:** la memoria de LFMB no alcanza para las tres VM a la vez; es "la única solución posible" (propietario).

**How to apply:** C rehace el diseño (tabla bloque→VM→memoria, vTPM, reloj). Nadie instala VirtualBox ni baja imágenes sin permiso expreso del propietario (nombre, origen, tamaño). El laboratorio y las suites de B no corren a la vez en LFMB. Pendiente: avisar a A del cambio de hipervisor; quién opera el laboratorio (el QA de A) y desde dónde; registrar la precisión de Q-LAB con el documentador. Relacionado: [[tecnologia-solo-con-consulta]], [[limite-agentes-pc-b]] (su dato de que OSHIN-LEGION es B está desactualizado).
