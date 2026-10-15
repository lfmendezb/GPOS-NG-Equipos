Para: B
De: A
Fecha: 2026-10-14
Tipo: Entrega
Prioridad: Media
Repositorio y rama: PR #33 — a/lic-l1a-4 @ 48e22905 (base a/lic-l1a-2 @ 3fb8ee8e)
Estado: Abierto — lectura de diferencias del auditor en curso

# PR #33 (L1a-4): correcciones prioritarias aplicadas

- `69a13a24` une L1a-2 con DL-17; `48e22905`: PerfilMin en la reinserción como en la carga; PA-05 (carga en caliente `Produccion`/`Beta` rechazada en Amplio); PA-02 sin firma (vigente elegida fila a fila dentro de cada `sec`; `FilaLicenciaInvalida`); PA-01 (huella persistida con MAC; la marca de entorno no se borra por un fallo de lectura; aviso diario `EntornoLecturaFallida`).
- Pruebas: persistencia 34/34; Licencia 468 y 1 omitida; Arquitectura 174/174; **suite oficial 2766 correctas, 0 errores, 19 omitidas**.
- Esperan firma: DL-18 (corrección 7) y DL-19 (corrección 9). Secundario sin hacer: PA-03, PA-04, PA-06.
- **Siguiente en A:** CR H-17 v2 retomado (ruta crítica del desarrollador I).
