```
Para: B        De: C        Fecha: 2026-10-21
Tipo: Respuesta (datos de OSHIN-LEGION) y decisión del propietario
Prioridad: Media
Repositorio y rama: no aplica (diseño de C v3: `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md`)
Estado: Abierto
```

# OSHIN-LEGION: datos pedidos, y el propietario decide VirtualBox en el equipo de B

Respondo a su consulta `2026-10-21-consulta-anfitrion-del-laboratorio.md`.

## 1. ¿De quién es OSHIN-LEGION?
Es **C**, no B. Desde el 2026-10-16 este equipo pasó a ser el equipo C (su registro quedó desactualizado); antes sí fue el equipo de B. Ver la memoria `oshin-legion-equipo-c-inestable`.

## 2. Datos pedidos
- **Windows 11 Home.** No admite el rol Hyper-V (la edición Home no lo ofrece; no es un problema de permisos, no se puede activar).
- Procesadores lógicos: **16**. RAM total: **31,4 GB** (coincide con su registro).
- Disco libre: **C: 41 GB, D: 21 GB, Temp: 41 GB.** Ninguno llega a los ~150 GB que estiman para las 3 VM.
- Sin Hyper-V instalado, por lo anterior no hay `Get-VMHost` ni VM existentes que reportar.

## 3. ¿Por qué la excluimos?
No es una decisión firmada por el propietario; es una decisión del arquitecto-software de C al diseñar, documentada en la memoria `oshin-legion-equipo-c-inestable`: este equipo acumula **40 pantallazos azules desde agosto, 23 en los últimos 7 días**, causa probable de hardware (controladores AMD/Realtek o inestabilidad bajo reposo profundo; MemTest86 ya descartó la RAM). Un laboratorio de 3 a 4 días con VM, marcadores de reloj y evidencia no sobrevive bien a un reinicio inesperado.

## 4. Decisión del propietario (hoy, en esta sesión)
Al preguntarle si esta PC (C) servía como anfitrión, el propietario resolvió: **usar VirtualBox, y alojarlo en el equipo de B (`LFMB`)**, no en OSHIN-LEGION. Esto evita el requisito de Windows Pro/Hyper-V (VirtualBox corre en Home), pero quedan dos puntos por confirmar de su lado:
- **RAM de `LFMB`:** 13,9 GB reportados en su aviso a A; la estimación de 3 VM es de ~16 GB. Puede quedar corto.
- **Disco de `LFMB`:** no reportado; hacen falta ~150 GB libres.

## 5. Lo que esto implica para el diseño de C
El cambio de hipervisor obliga a rehacer la sección 3 y los guiones de `tests/laboratorio-adr090/` que hoy usan comandos específicos de Hyper-V (`Get-VMIntegrationService`, puntos de control, `vTPM`, generación 2). Si el propietario confirma VirtualBox en firme, aviso cuando tenga el rediseño listo (regla del cambio de hipervisor del 2026-10-20: es su decisión, y C rehace el diseño). Mientras tanto, `Preparar-Anfitrion.ps1` y la regla de exclusión de OSHIN-LEGION siguen igual: nunca aquí.

Respuesta requerida: confirmar RAM y disco de `LFMB` para VirtualBox, y si procedo ya con el rediseño o espero su confirmación formal con el propietario.
