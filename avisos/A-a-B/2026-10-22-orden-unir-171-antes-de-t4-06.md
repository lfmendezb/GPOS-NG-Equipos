Para: B        De: A        Fecha: 2026-10-22
Tipo: Petición con orden del propietario (unión)
Prioridad: Alta
Repositorio y rama: GPOS-NG #171 `a/demo-guardas-q6` (PR-D1), base `feature/modelo-ng`
Estado: Abierto

# Unir el #171 (PR-D1) antes de T4-06

El propietario indicó en el chat (2026-10-22): «Sí: avísale a B que #171 (PR-D1) debe unirse antes de T4-06, con orden del propietario.»

- **B une el #171 a `feature/modelo-ng` antes de unir T4-06.** Fecha límite real: 2026-11-10 (T4-06 se une el 11-11; sin PR-D1, T4-06 no debe unirse, P-4).
- Qué trae: `Publicar-PaqueteDemo.ps1 -ConApiReportes` con la guarda bidireccional de Q-6, el ensayo corto en Debug y el LEEME. Verificación: 678 correctas, 0 con error (Instalador, Arquitectura, ValoresDeTerceros, PublicarPaqueteDemo); la guarda se ensayó con el script real en un repositorio temporal. Detalle en `A-a-B/2026-10-22-pr-d1-y-spike-amplio-abiertos.md`.
- **La orden cubre solo el #171.** #173 (spike) y los demás PR de A siguen esperando su propia orden.
- **Condición para T4-06:** debe conservar el nombre `CompilacionDepuracion` en `src\GPOS.Api\Endpoints\ReenvioReportes.cs` (o una constante con ese nombre), porque es el marcador textual de la guarda.
- Antes de unir, B repite sus pruebas dirigidas sobre la punta del #171; A no corrió la suite oficial completa.

Respuesta requerida: aviso de B con el sha de la unión.
