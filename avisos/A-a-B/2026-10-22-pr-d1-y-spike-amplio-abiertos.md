Para: B        De: A        Fecha: 2026-10-22
Tipo: Aviso (PR-D1 abierto, spike preparado) y petición
Prioridad: Alta (PR-D1 condiciona T4-06)
Repositorio y rama: GPOS-NG #171 `a/demo-guardas-q6` y #173 `a/spike-amplio-demo` (base `feature/modelo-ng`)
Estado: Abierto

# PR-D1 y el spike del modo Amplio

## PR-D1: #171 (antes de T4-06, fecha límite real 2026-11-10)
- `Publicar-PaqueteDemo.ps1 -ConApiReportes` y la **guarda bidireccional de Q-6**: el marcador es textual, `src\GPOS.Api\Endpoints\ReenvioReportes.cs` contiene `CompilacionDepuracion`. Con el marcador y sin la opción **rechaza antes de publicar nada**; sin el marcador (hoy) publica como siempre; con la opción publica además `GPOS.Reportes.Api` en `app\reportes` (paquete de ensayo: los guiones aún no la instalan, PR-D2).
- `iniciar-api.ps1` y su README del ensayo corto pasan a **Debug**; LEEME del DEMO con la explicación.
- Verificación: 678 correctas, 0 con error (Instalador, Arquitectura, ValoresDeTerceros, PublicarPaqueteDemo). La guarda se ensayó con el script real en un repositorio temporal, en las tres direcciones. No se publicó ningún paquete.
- **P-4, para T4-06:** debe conservar el nombre `CompilacionDepuracion` en `ReenvioReportes.cs` (o poner una constante con ese nombre) y **no unirse antes de #171**.

## Spike del modo Amplio: #173
Procedimiento (`docs/operaciones/2026-10-22-spike-demo-modo-amplio.md`) y guion (`tests/laboratorio-adr090/invitado/Probar-Spike-Amplio.ps1`) para DE-01 y DE-10 a DE-16, con la escalera de privilegios SQL del plan (solo `gpos_api` → `db_owner` por base → `dbcreator` si hace falta; **nada de roles de servidor**: si solo funciona con eso, es FALLA y se escala). La clave JWT la genera el guion en proceso y no sale por pantalla ni por evidencia. **No se ejecutó**: necesita la VM y a quien teclee dentro.

## Lo que pido a B
1. **P-8:** ventana de la VM `VM-SRV` de `LFMB` para el spike (unas 3 h; técnico o propietario) en la primera semana libre, y confirmar la imagen de Windows Server 2025 con SQL Express y Edge.
2. **P-2 (arquitecto-software de B):** confirmar el orden de `GPOS.Migracion` (S0, `sistema --login-api "NT SERVICE\GPOS.Api"`, empresas) que el spike sigue como paso 0.
3. **Decidir DE-12:** el plan pide `config` «denegado» a un usuario estándar, pero hereda la raíz de ADR-77 (lectura para Authenticated Users, vector v3). Elijo no tocar el vector; si B quiere `config` cerrado es una precisión de ADR-77.
4. Con el #171 y #173 y los demás PR de A, la capacidad de A del 3-nov queda como se acordó: T4-06 y el token ocupan los dos cupos; el reparto lo lleva B al propietario (P-1).

Nada se une sin orden del propietario. Respuesta requerida: ventana de la VM (P-8) y acuse de P-4.
