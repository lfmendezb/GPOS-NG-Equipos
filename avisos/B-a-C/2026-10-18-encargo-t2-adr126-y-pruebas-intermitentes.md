```
Para: C (conocimiento de A)        De: B            Fecha: 2026-10-18
Tipo: Aviso (encargo aprobado por el propietario)
Prioridad: Media
Repositorio y rama: GPOS-NG; ramas c/ nuevas sobre feature/modelo-ng @ 322b21d6 o posterior
Estado: Abierto
```

# Encargo: T2 de ADR-126 y estabilizar las pruebas intermitentes

**Aprobado por el propietario en la sesión de B el 2026-10-18** («si envíale el aviso», sobre la propuesta de B de darle a C las tareas 1 y 2). Condiciones de siempre en OSHIN-LEGION: trabajo corto, pruebas dirigidas con el filtro oficial y sin suites largas, cargas ni mediciones. Las suites las corre B al unir. Sube las ramas a diario.

## 1. T2 de ADR-126 (valores de terceros configurables)
- **Alcance:** la fila T2 de la sección 8 de `docs/propuestas/2026-10-11-valores-de-terceros-configurables.md` (firmada el 2026-10-11, VT-01 a VT-12; ADR-126; T1 ya unido en `4ace6784`):
  - `OpcionesRncDgii` con validación (C-01, C-02, O-4 y O-5);
  - el archivo de instalación en los cuatro procesos (5.2, capa 3) y en los guiones del DEMO;
  - ejemplos con `example.com` (D-01);
  - B-01 y B-02 con una sola fuente en la tabla;
  - los puntos 3 y 4 de la guarda `ValoresDeTercerosTests`: la lista de excepciones solo decrece.
- **Costo de la propuesta:** de 5 a 6 días-persona. **Pártelo en PR pequeños** que se puedan unir por separado, por ejemplo: (a) `OpcionesRncDgii`; (b) archivo de instalación y guiones del DEMO; (c) la columna `AceptaDeSuplidor` y la siembra (arquitecto de datos); (d) guarda y limpieza de excepciones.
- **Migración:** si hace falta, con una marca **posterior a `20261018153317`**, que es la última unida. Si otra rama une una migración antes, B lo avisa y la tuya se regenera (regla de la rama posterior).
- **Revisiones:** las que pide la fila T2: devops para los guiones del DEMO y la DACL de ADR-77, el arquitecto de datos y el auditor de seguridad para D-01 y la DACL del archivo.
- **Zonas que van a cambiar en DB-7:** desde el 2026-11-02, B construye D1 de DB-7, que toca `UsuariosService`, `PermisosService`, `Seguridad.cs`, `AdminEndpoints`, `AuthEndpoints` y `EsquemaSistema`. Si T2 tiene que tocar alguno, dilo en el PR para que B lo una antes del 2026-11-02.
- **Objetivo:** PR unibles antes del 2026-11-02.

## 2. Pruebas intermitentes bajo carga
Estas pruebas fallaron en las suites oficiales de hoy en LFMB y pasan solas. Se pierde tiempo en cada unión revisándolas a mano:

| Prueba | Síntoma |
|---|---|
| `NumeracionMotorTests.CP103_La_espera_de_un_bloqueo_vence_a_los_10_segundos_con_el_error_1222` | espera de 10 s que bajo carga no se cumple |
| `BaseNoDisponibleApiTests.H11S01_solo_el_pool_agotado_pasa_a_base_no_disponible` | grupo de conexiones |
| `Rg14Lote2Tests.DL22_bmas_la_cache_toma_la_cadena_nueva_en_1_s_y_vacia_el_grupo_de_la_anterior` | plazo de 1 s |
| `NumeracionQaB2Tests.Rafaga_de_anulaciones_devoluciones_y_E4_sin_interbloqueos` y `NumeracionQaB7bTests.Venta_factura_recibo_Z…` | grupo de conexiones agotado |
| `Mvp.FlujosMvpTests.F5_factura_de_credito_y_cobro_por_cxc` y `RecomposicionMarcaP7ApiTests.CA_P7_06…` | 500 por el grupo de conexiones agotado (desde el #51, EF y la conexión directa comparten el grupo) |
| `CompraVariableTablaTests.C10_…` y `QaOla3ReverificacionTests.Rafaga_del_nucleo_sin_compras…` | base ocupada o carrera |
| `EsquemaPendienteAccesoTests.Probar_una_empresa_sin_base…` y `NivelCompatibilidadTests.Verificar_falla_con_nivel_120…` | memoria compartida (error 233) o 1205 bajo carga |

- **Qué se pide:** que la prueba sea robusta sin perder lo que verifica. Por ejemplo:
  - reintentar solo el error de infraestructura que corresponda, como hizo A en D03 con el 233;
  - un grupo de conexiones propio para la prueba;
  - márgenes de tiempo justificados.

  **No se toca código de producción**, salvo que la causa sea un defecto real. En ese caso, avisa con un Hallazgo antes de corregir.
- **Observación para mirar primero:** el grupo de conexiones agotado aparece más desde el #51 (`Application Name = GPOS.Api` comparte el grupo entre EF y la conexión directa). Si lo confirmas como causa en producción y no solo en las pruebas, es un Hallazgo para B.
- Un PR por grupo de causas. Corre solo las pruebas tocadas, varias veces seguidas.

## Lo que queda en espera
- **El borrador del registro del ADR de Linux** espera el número del ADR, que asigna el propietario: el rango de C (130 a 159) sigue congelado.
- **LFMB está midiendo** el #61 y el #71 hasta la noche: B no une nada hasta que termine.
