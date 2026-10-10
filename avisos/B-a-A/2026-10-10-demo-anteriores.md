```
Para: C (copia a A)            De: B (coordinador)            Fecha: 2026-10-10
Tipo: Encargo (decisión del propietario)
Prioridad: Alta
Repositorio y rama: —
Estado: Abierto
```

# Carpeta de paquetes del DEMO: solo el más reciente a la vista; los anteriores en «Anteriores»

Precisa `2026-10-10-publicar-demo-onedrive`. **Decisión del propietario (2026-10-10):** en la carpeta compartida de los paquetes del DEMO (https://1drv.ms/f/c/bff1673e46b5ff20/IgB-F_eHmtQoT7TeFbaXnqF8AZ8kRiPyD5gz5SV3EC7TgoM) **lo primero que se ve es siempre el DEMO más actualizado**. Las versiones anteriores se mueven a la subcarpeta **`Anteriores`** dentro de esa misma carpeta (mismo permiso de edición).

## Regla para toda publicación
1. Antes de subir un paquete nuevo, **mover** a `Anteriores` todo lo de la versión anterior que esté en la raíz (el `.7z`, su `.sha256`, su `LEEME-*.txt`). Si `Anteriores` no existe, créala. Mover, nunca borrar.
2. Subir el paquete nuevo a la raíz y comprobar su SHA-256.
3. La subcarpeta `datos-demo` (plantillas) se queda en la raíz mientras siga sirviendo al paquete vigente; si cambian las plantillas, la versión vieja va a `Anteriores` con el nombre de su fecha.

## Ahora
- Si en la raíz hay paquetes de antes del 2026-10-10 (por ejemplo, los del 2026-10-05 o del 2026-10-07), muévelos a `Anteriores` y deja en la raíz solo `GPOS-Demo-2026-10-10`.
- Las mismas reglas de siempre: sin elevación ni programas con ventanas; si necesitas OneDrive o el navegador, pídeselo al propietario.
- Confirma en `avisos/C-a-B/` qué quedó en la raíz y qué en `Anteriores`.

**Para A (copia):** la misma regla rige cuando A publique un paquete del DEMO.
