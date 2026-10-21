```
Para: B        De: C        Fecha: 2026-10-21
Tipo: Entrega (tarea 1: rediseño del laboratorio de ADR-90 con VirtualBox)
Prioridad: Media
Repositorio y rama: no aplica (documento en el área común)
Estado: Abierto — respuesta requerida de B
```

# Entrega: rediseño del laboratorio con VirtualBox en `LFMB`

Documento: `traspasos/C/2026-10-21-rediseno-laboratorio-adr090-virtualbox.md`. Lo hizo devops de C (el arquitecto-software lo rechazó primero: por su contrato, esto es infraestructura de laboratorio, no arquitectura del producto; se reasignó a devops). No toqué el diseño v3 original, no instalé nada, no descargué imágenes ni ejecuté nada en `LFMB`.

## Resumen
- **¿Cabe el laboratorio completo en `LFMB`?** Parcialmente.
  - **N, F, S, N-L:** caben con una sola VM activa (3 a 3,5 GB `VM-SRV`, o 1 a 1,5 GB `VM-LNX`), compatibles con los 4,4 GB libres de hoy.
  - **B (navegadores):** necesita `VM-SRV` + `VM-PUESTO` a la vez (6,5 a 7,5 GB). Cabe en el techo de ~8 GB, pero solo si detienen su trabajo mientras corre.
  - **V y R (fase 2):** con SQL Server Express arrancado en `VM-SRV`, la estimación sube a 7-8,5 GB, que **rebasa** el techo de 8 GB. Recomendación: no arrancar SQL salvo en los casos que lo exigen, y confirmar memoria libre real antes de cada ejecución; si algún caso puntual no cabe, se ejecuta aparte.
  - Nunca se necesitan las 3 VM a la vez.
- **vTPM:** ningún caso del laboratorio (LAB-01 a LAB-99) depende del TPM. Se puede omitir sin perder cobertura, exista o no buen soporte en VirtualBox 7 (sin verificar contra documentación oficial — sin acceso a búsqueda web en esta sesión).
- **Reloj y puntos de control:** equivalente directo (`VBoxManage guestproperty`, `VBoxManage snapshot`); sin bloqueo técnico.
- **WSL2/Docker:** no hace falta desactivarlos; conviven con VirtualBox 7 vía el backend NEM, con posible penalización de rendimiento.
- **Guarda del anfitrión:** `Preparar-Anfitrion.ps1` pasa de lista de exclusión a comprobación positiva de que el nombre sea `LFMB`.
- **"Quién ejecuta y cómo":** quedó como decisión abierta con 3 opciones (QA de A por remoto a `LFMB`; B ejecuta y A revisa evidencia; cuenta de Windows separada solo para el laboratorio), sin elegir.

## Pendiente de confirmar por B
1. Las cifras de memoria por VM son estimaciones de piso, no medidas; ajustar con la primera VM real.
2. Confirmar un tope fijo en `.wslconfig` (por ejemplo `memory=4GB`) para que los 4,4 GB libres no fluctúen con la carga de Docker/WSL2.
3. Decidir, con el propietario, la opción de "quién ejecuta" (sección 4 del documento).
4. Pedir al propietario el permiso expreso para instalar VirtualBox 7 y descargar las 3 imágenes, con nombre, origen y tamaño, como ya pidió en su aviso.

Fecha de entrega: hoy, 2026-10-21 (dentro del plazo propuesto del 22 al 24-oct). C queda sin trabajo en curso en esta tarea; sigo con la tarea 2 (#132).
