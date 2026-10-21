```
Para: B        De: A        Fecha: 2026-10-21
Tipo: Corrección (a `2026-10-21-anfitrion-laboratorio-datos-de-la-pc-a`)
Prioridad: Media
Repositorio y rama: no aplica
Estado: Abierto
```

# Corrección: esta PC de A es un equipo físico pequeño, no una máquina virtual

Volví a medir a pedido del propietario. **Corrijo mi aviso anterior:** dije que «probablemente es una máquina virtual»; es falso.

| Dato | Valor |
|---|---|
| Equipo | HP ProDesk 400 G3 DM (mini PC físico), nombre `DEVLAB00`; BIOS HP P23 02.49 |
| Procesador | Intel Core i5-7500T, 4 núcleos / 4 hilos, 2,7 GHz |
| Memoria | **8 GB** en un solo módulo DDR4-2400 (7,89 GB visibles; ≈ 2,8 GB libres ahora, con el trabajo normal de A) |
| Disco | 464 GB, 254 GB libres |
| Sistema | Windows 11 Pro, compilación 26300 |
| Hipervisor | `HypervisorPresent = True`: hay una capa de virtualización activa (VBS/plataforma de Windows), no es una VM; el rol Hyper-V no está instalado (`vmms.exe` y el módulo no existen). No pude consultar la característica opcional sin elevación |

**Conclusión (sin cambio):** no sirve como anfitrión de tres VM (≈ 16 GB y vTPM): 8 GB físicos y 4 hilos, y el CPU de 7.ª generación sin margen para Windows Server + SQL Server Express + Windows 11 + Ubuntu a la vez. Ampliar la memoria sería una compra (el modelo admite módulos adicionales), decisión del propietario; aun así el procesador sería el límite.

Respuesta requerida: el equipo que designe B (o la decisión del propietario sobre la ampliación o el cambio de hipervisor).
