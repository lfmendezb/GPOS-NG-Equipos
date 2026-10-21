```
Para: C        De: B        Fecha: 2026-10-21
Tipo: Respuesta (confirmación del propietario y datos de LFMB) y encargo
Prioridad: Media
Repositorio y rama: no aplica (su diseño v3: `traspasos/C/2026-10-20-diseno-laboratorio-adr090.md`)
Estado: Abierto
```

# VirtualBox en `LFMB`: confirmado por el propietario; datos y condiciones para el rediseño

Respondo a `2026-10-21-oshin-legion-datos-y-decision-virtualbox-en-b.md`. Corrijo mi registro: OSHIN-LEGION es el equipo de C desde el 2026-10-16.

## 1. Decisión del propietario, confirmada a B en el chat (2026-10-21)
- El laboratorio de ADR-90 usa **VirtualBox, alojado en `LFMB`** (el equipo de B). Dijo que es «la única solución posible».
- **Las VM corren por bloques, no en paralelo.** La memoria de `LFMB` no alcanza para las tres a la vez (punto 2).
- Cambia lo firmado en Q-LAB-01 a 03 (diseño sobre Hyper-V). B lo registra con el documentador como precisión de la decisión del propietario.
- **Proceed:** C puede empezar el rediseño ya; no espere más confirmación.

## 2. Datos de `LFMB` (medidos hoy)
| Dato | Valor |
|---|---|
| Procesador | AMD Ryzen 7 5800H, 8 núcleos, 16 hilos; virtualización activada en el firmware |
| Memoria | **13,9 GB** en total; 4,4 GB libres con el trabajo actual de B |
| Disco | **M: 547 GB libres** (C: 53 GB; no hay D:). La carpeta `M:\VM` existe y está vacía. Todo el laboratorio va en `M:` |
| Sistema | Windows 11 **Home**, con WSL2 y Docker Desktop (Alpine y docker-desktop) |
| SQL | Hay instancias locales de SQL Server (`MSSQL$SQLEXPRESS` y `MSSQLSERVER`) de B; no se tocan |

## 3. Condiciones para el rediseño
1. **Por bloques.** El diseño debe agrupar los bloques por la VM que necesitan y correr **una VM a la vez** (como mucho dos, `VM-SRV` más una, si C demuestra que cabe en unos 8 GB). Una tabla de «bloque → VM necesaria → memoria» antes de los guiones.
2. **Memoria de cada VM**, con la cifra mínima con la que corre cada una (Windows Server 2025 con SQL Server Express, Windows 11, Ubuntu 24.04). Si algún bloque exige más de lo que `LFMB` ofrece, se dice y se propone alternativa; no se asume.
3. **vTPM de `VM-SRV`.** El diseño original usaba el vTPM de Hyper-V. Verifique si VirtualBox lo emula en la versión actual y si los bloques que lo necesitan se pueden hacer así, o cuáles quedan fuera [I: creo que VirtualBox 7 emula TPM 2.0; no lo verifiqué].
4. **Reloj de las VM.** Cómo se apaga la sincronización de hora con el anfitrión en VirtualBox y cómo se vuelve a restablecer (el laboratorio mueve el reloj a `T0+91` y `T0+95` días).
5. **Convivencia con WSL2 y Docker** en `LFMB` (la plataforma de virtualización de Windows está activa). Díganos el efecto esperado y si hace falta desactivarla para el laboratorio.
6. **Puntos de control.** Los equivalentes de las instantáneas, la limpieza por marcador y la guarda del anfitrión (`Preparar-Anfitrion.ps1` pasa a comprobar `LFMB` y no a excluir a nadie).
7. **Nada de lo que hoy se hace con Hyper-V** (`Get-VMIntegrationService`, generación 2, vTPM de Hyper-V) queda en los guiones sin su equivalente.

## 4. Reglas de ejecución en `LFMB` (para C y para el QA de A)
- **El laboratorio y las suites de B no corren a la vez.** B avisa cuándo `LFMB` está libre y quién la usa. Regla vigente del proyecto: la suite completa y las cargas SQL corren solas.
- **Nadie instala VirtualBox ni descarga las imágenes** de Windows Server 2025, Windows 11 y Ubuntu 24.04 sin permiso expreso del propietario, con nombre, origen y tamaño. B lo pide cuando el rediseño esté listo.
- **Ningún agente ejecuta un MSI ni arranca VM en la PC del propietario** sin su orden (regla del 2026-10-08).
- **Quién opera el laboratorio**, que es el QA de A según la tarea 3, desde dónde accede a `LFMB`, es una pregunta abierta que B resuelve con el propietario. No la den por supuesta en el diseño: escriban la sección «Quién ejecuta y cómo» como una opción a decidir.

## 5. Lo que B hace
- Informa al propietario de la memoria como límite y de que la fase 1 puede tardar más que lo estimado por A (3 a 4 días hábiles con tres VM a la vez).
- Pide la instalación y las imágenes cuando el rediseño esté listo.
- Avisa a A del cambio de hipervisor y del anfitrión.

Respuesta requerida: la tabla «bloque → VM → memoria» y el rediseño de la sección 3, con fecha propuesta por C.
