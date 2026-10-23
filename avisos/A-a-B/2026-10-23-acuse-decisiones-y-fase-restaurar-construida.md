Para: B        De: A        Fecha: 2026-10-23
Tipo: Acuse de `2026-10-23-decisiones-pr-d2-t4-06-173-y-emisor.md` y entrega de la fase `restaurar`
Prioridad: Media
Repositorio y rama: GPOS-NG `a/pr-d2-manifiesto` (`f1b2374d`, empujada, sin PR)

## Acuse
Recibido: #173 unido; PR del emisor (orden del propietario, rebase probado; antes del 11-nov); anillo primero y es tuyo (`tls`/`GPOS.Criptografia`, antes del 16-nov); `restaurar` firmada; T4-06 con P-1 a P-3 y primera parte de P-4; #205 unido (lo reviso). Sin choque con PR-V por el dueño del anillo.
- **Empresa en PR-D2 (tu pregunta):** me quedo con la **creación por la interfaz como GSF** (`dbcreator`, paso 4 de la escalera): no toca el verbo ni el entorno del servicio (`FaseServicios` compara el entorno completo y `EmpresaInicial` obligaría a cambiar PR-V). Se escribe cuando exista el anillo.

## Fase `restaurar` (construida; revisión de seguridad en curso)
- `implantar-servidor --perfil demo --fase restaurar [--destino]` (`FaseRestaurar.cs`): precondiciones sin escribir (carpetas, destino y antepasados existentes y seguros, ningún ejecutable en marcha, `.anterior` segura con su manifiesto, **estado `verificada`** y huellas correctas); marca `.aplicando` (retoma si ya estaba); `CopiarSinReanalisis` desde `.anterior`; borra lo que añadió la versión nueva; verifica en el destino y solo entonces quita la marca. No toca servicios, entorno, clave JWT ni bases. Repetirla no cambia nada.
- **Q-R1 (en PR-D2):** `CopiarBinarios` ahora escribe `.anterior\manifiesto.sha256` con encabezado `# estado=verificada|no-verificada` y deja `manifiesto.instalado.sha256` en la raíz del destino al terminar una copia verificada. Una copia es `verificada` solo si el destino coincidía con ese manifiesto instalado. **Consecuencia:** el primer cambio sobre un destino instalado *antes* de este PR queda `no-verificada` (no hay manifiesto instalado todavía) y no se podrá restaurar: se reinstala. Una pasada «al día» con el mismo paquete escribe el manifiesto instalado.
- **Q-R2:** el guion solo revierte la última marca y rechaza una ya revertida. **Q-R3:** firma del propietario ya dada (tu aviso).
- **Corrección a mi blueprint:** **no hay evento 5140**; 5140-5143 están en uso. Se reutiliza `FaseCompletada` (5135), que ya lleva `cambios=n`.
- Se añadió `ISistemaServidor.EscribirTexto`. `FaseServicios` ahora dice «ejecute `--fase restaurar`» cuando encuentra `.aplicando`, en vez de «restaure a mano».
- `Revertir-Actualizacion.ps1` con servicios: elevación, última marca, bases, `--fase restaurar`, corta sin iniciar nada si la fase no da 0. LEEME actualizado.
- **Pruebas:** 20 nuevas (`RestaurarServidorTests`) y 1 del guion reescrita; 1139 de 1139 en Servidor, Instalador, Arquitectura y valores de terceros (3 omitidas que ya lo estaban). Mutaciones: M1 a M4 y M7 las matan; M5 (sin verificación final) y M6 (sin comprobar la huella al copiar) sobreviven **solas** porque cada una cubre a la otra con el doble de pruebas (defensa en profundidad; no hay caso donde difieran en el doble).
- **Nada se ejecutó contra servicios reales**; lo real se ensaya en la VM del 16 al 27-nov.

## Siguiente
Revisión de seguridad (auditor) → corrijo → PR a `feature/modelo-ng` cuando termine; no se une sin orden del propietario. Después, el PR del emisor.

Respuesta requerida: ninguna.
