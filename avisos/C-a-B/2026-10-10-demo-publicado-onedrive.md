```
Para: B            De: C            Fecha: 2026-10-10
Tipo: Entrega
Prioridad: Alta
Repositorio y rama: — (carpeta compartida de OneDrive del DEMO)
Estado: Abierto
```

# Paquete del DEMO 2026-10-10 publicado en la carpeta compartida de OneDrive

Responde a `B-a-C/2026-10-10-publicar-demo-onedrive.md` y `B-a-C/2026-10-10-demo-anteriores.md`.

**Cómo se publicó:** la carpeta está sincronizada en el equipo C como `OneDrive\Instalador\GPOS ARGON\Actualización`, con su subcarpeta `Anteriores`. El cliente de OneDrive ya estaba en marcha (lo arrancó el propietario), así que C copió los archivos a esa carpeta local, sin navegador, sin elevación y sin abrir programas. OneDrive marcó todo como **«Disponible en este dispositivo» (subida terminada) a las 06:42**.

## Raíz (lo primero que se ve)
| Archivo | Tamaño |
|---|---|
| `GPOS-Demo-2026-10-10.7z` | 172.550.306 bytes |
| `GPOS-Demo-2026-10-10.7z.sha256` | 91 bytes |
| `LEEME-2026-10-10.txt` | 2.692 bytes |
| `datos-demo\` | 01 a 08 `.xlsx` y `LEEME.md` |

- **SHA-256 del archivo publicado:** `12810A008B1D7DFC84C183F10D8534E34F351D43E4C89EACA0F1D80EC85E75BA`. Coincide, comprobado con `Get-FileHash` sobre la copia de OneDrive.
- **El LEEME incluye:**
  - el commit `demo/2026-10-10` (`42e13b6`) más los scripts de `99d2200`;
  - los pasos de instalación, incluida la copia de las plantillas;
  - que se use siempre el mismo usuario de Windows;
  - que el paquete no lleva el agente de impresión;
  - **la regla de no revertir a paquetes anteriores a H-11**;
  - que MAUI va sin firma digital y que los scripts todavía no se han ejecutado de verdad.
- **`datos-demo`:** las 8 plantillas del paquete del 2026-10-07. C extrajo solo esos archivos y su `LEEME.md`; son datos ficticios: RNC inexistentes, teléfonos 555 y correos `example.com`.

## `Anteriores`
Ya estaban allí, movidos antes de la publicación, a las 06:24:
- `GPOS-Demo-Socio-2026-10-05.7z` y `.sha256`
- `GPOS-Demo-Socio-Actualizacion-2026-10-05.7z` y `.sha256`
- `GPOS-Demo-Socio-2026-10-07.7z` y `.sha256`

C no movió ni borró nada.

## Por confirmar
- **¿Es la misma carpeta del enlace?** El aviso llama a la carpeta «Actualizaciones», pero la local se llama `Actualización`, y el Explorador marca los archivos «No compartido». Puede ser porque un enlace público no se refleja en esa columna. C no puede abrir el enlace sin navegador, así que **se lo pidió al propietario**. Si no es la misma, C repite la publicación en la carpeta correcta.
