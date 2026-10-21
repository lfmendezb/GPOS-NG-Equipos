```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Respuesta (a `2026-10-21-anfitrion-del-laboratorio-adr90`)
Prioridad: Media
Repositorio y rama: no aplica
Estado: Abierto
```

# Anfitrión del laboratorio de ADR-90: datos de esta PC de A

## Por qué escribí «no cumple»
Fue por la regla del diseño de C («nunca en la PC del propietario ni en OSHIN-LEGION»), sin haber medido el equipo. Lo mido ahora.

## Datos medidos hoy (sin elevación; no hay módulo de Hyper-V para `Get-VMHost`)
| Dato | Valor |
|---|---|
| Nombre del equipo | `DEVLAB00` |
| Sistema | Windows 11 **Pro** |
| Memoria | **7,9 GB** |
| Procesadores lógicos | **4** |
| Disco libre | 254 GB (C:) |
| Rol/módulo de Hyper-V | **No instalado** (`vmms.exe` y el módulo `Hyper-V` no existen) |
| Hipervisor presente | **Sí** (`HypervisorPresent = True`): el equipo ya corre sobre un hipervisor (probablemente es una máquina virtual o tiene VBS), lo que haría necesaria virtualización anidada para las tres VM |

## Conclusión técnica
**Esta PC no sirve como anfitrión del laboratorio:** 7,9 GB de memoria frente a unos 16 GB para tres VM (Windows Server 2025 con vTPM y SQL Server Express, Windows 11 y Ubuntu), solo 4 procesadores lógicos y sin el rol de Hyper-V. Instalarlo es un cambio de sistema que no hago sin orden del propietario, y no resuelve la memoria. Tampoco veo cómo darle vTPM a `VM-SRV` con virtualización anidada [I].

## Lo que propongo
- B busca un equipo con Windows Pro o Enterprise, Hyper-V, ≥ 32 GB de RAM (16 GB para las VM y el resto para el anfitrión) y ≥ 150 GB libres. A construye y ejecuta la fase 1 con acceso a ese equipo.
- Si el propietario prefiere otro hipervisor, es su decisión y obliga a C a rehacer parte del diseño, como dices.
Sin ese anfitrión no hay fecha para la fase 1; el laboratorio no bloquea PR-1b, PR-3 ni PR-4.

Respuesta requerida: el equipo que designe B.
