```
Para: B (copia a A)        De: C        Fecha: 2026-10-23
Tipo: Entrega (punto 2 del backlog de `B-a-C/2026-10-23-backlog-autonomo-para-c-tanda-7.md`) y observaciones para A
Prioridad: Normal
Repositorio y rama: GPOS-NG [PR #223](https://github.com/lfmendezb/GPOS-NG/pull/223) (`c/guion-restaurar` @ `850dc799`, base `feature/modelo-ng`)
Estado: Abierto
```

# Entrega: `Probar-Restaurar.ps1` (PR-D2, nivel V)

PR #223: `tests/laboratorio-adr090/invitado/Probar-Restaurar.ps1` (1.393 líneas) y `LEEME-Probar-Restaurar.md`. Cubre LAB-RS-01 a LAB-RS-12 contra `a/pr-d2-manifiesto @ cd44043c` (el guion admite también `812d1790`, que añade `# copia=<id>` al manifiesto de la copia previa; RS-04g prueba el caso sin identificador). Solo `tests/`.

**Verificación:** análisis de sintaxis con PowerShell 5.1 y 7, 0 errores en ambos (2026-10-23). **No se ejecutó en ninguna VM ni en esta PC**; los [I] (procesos sueltos vivos sin SQL, `runas /trustlevel` en Server 2025, herencia de DACL, `New-Item -ItemType Junction`) se confirman en VM-SRV. Guardas de LS-11 como `Probar-Instalador.ps1` más equipo y marcador `VM-SRV` y proceso de 64 bits (RA-04); control negativo por caso (sin control no hay `Cumple`); evidencia en `C:\GPOS-LAB\evidencia\D2\` sin secretos.

**Qué trae de más:** `Preparar-Paquetes` fabrica PQ-A y PQ-B con cambios, altas y bajas en `api` y `reportes`, `relleno.bin` distinto y DACL solo para administradores (resuelve D-1 aunque tengas una sola publicación); `Montar-A` y `Montar-A2B` ejecutan PRE-3 a mano; `Estado` informa sin cambiar nada.

**Qué copiar a VM-SRV (detalle en el LEEME):** el guion de `850dc799` en `C:\GPOS-LAB\guiones\` con su SHA-256 anotado; uno o dos paquetes del DEMO publicados con `Publicar-PaqueteDemo.ps1 -Destino Demo -ConApiReportes` (Release) desde `a/pr-d2-manifiesto`, nunca de `feature/modelo-ng` después de T4-06, extraídos en `C:\GPOS-LAB\publicado\A` (y `\B`) con el SHA-256 del `.7z` y de `manifiesto.sha256`. Nada más: ni SQL, ni anillo, ni `Bloquear-Archivo.ps1`. Requisitos: `Preparar-Vm.ps1` aplicado, cuenta `gpos-lab-usuario`, consola elevada de 64 bits con `GPOS_LAB_TLS_VM` y `GPOS_LAB_TLS_ID`, ~3 GB libres y puntos de control `LAB-D2-LISTO`, `LAB-D2-A` y `LAB-D2-A2B`. Siguiente paso: `-Caso Guardas` y `Preparar-Paquetes`.

**Desviaciones respecto al documento de casos:** RS-11b va en orden inverso al de RS-12b y usa PQ-A (solo hay dos paquetes); RS-05h niega la escritura a Administradores, no a SYSTEM (la fase corre como administrador); en RS-06 el paso 3a va después de soltar el archivo; RS-10a usa `runas /trustlevel:0x20000` [I]; la ruta 8.3 solo se prueba si el volumen tiene nombres cortos. Bloqueados (nivel A): RS-03 paso 3, RS-06 3b con GPOS.Api y RS-09 paso 4. LAB-RV-08 y LAB-RV-09 son de nivel G (necesitan `instalacion.json`) y no van en este guion.

**Observaciones para A, de leer el código (no corregidas):** O-1 (Media, solo por lectura) `Instalar-Demo.ps1:127`, en `cd44043c` y en `812d1790`, pasa `--origen` a `--fase carpetas`, y `Incoherencia` rechaza esa opción fuera de `servicios`: el modo de servicios del instalador se detendría en el paso 1b con código 1 (afecta al nivel G). O-2 (Baja) una opción repetida se acepta en silencio y gana la última. O-3 (Baja) `--huella-copia-previa` no se valida como hexadecimal; un texto cualquiera cae en la guarda R-01 con código 4.

Respuesta requerida: ninguna; nada se une sin orden del propietario.
