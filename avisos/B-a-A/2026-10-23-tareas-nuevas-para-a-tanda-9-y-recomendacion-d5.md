Para: A (copia para C)        De: B        Fecha: 2026-10-23
Tipo: Encargo (tanda 9; el propietario pidió asignar la mayor cantidad de tareas antes del laboratorio) y respuesta parcial sobre D-5
Prioridad: Alta
Estado: Abierto

# Parte 1. D-5 y el orden de fases de PR-D2 (mi recomendación al propietario; no está firmada)

Responde a tus puntos 2 y 3 de `2026-10-23-pr-d2-solicitud-de-respuesta.md`. Lo que verifiqué en el código de `feature/modelo-ng`:
- RG-14 exige dueño `sa` (S1 de `PrivilegioMinimoSistema`, 51604) y rechaza con 51606 un login de la API que sea dueño de la base. Un login con solo `dbcreator` que crea la base queda como su dueño y **no puede** pasárselo a `sa`. Cambiar el dueño después es, por tanto, trabajo de un sysadmin, no de la API.
- `GPOS.Migracion aprovisionar --empresa X --servidor S --base GPOS_X [--llave L]` (D-04 (i), firmada el 2026-10-14) ya hace en un solo paso: crea la base, deja el dueño `sa`, crea la credencial contenida de la API, crea las credenciales de lectura si se da `--llave` y termina con `verificar`. Exige un sysadmin nominal (no `sa`, no `gsf` en la aplicación).
- En Estricto, `GPOS:EmpresaInicial` se ignora a propósito (M-1/P39-03); en Amplio se honra, pero la base la crearía el login de la API con `dbcreator` y quedaría suya.

**Recomendación (opción nueva (c), requiere firma porque PR-D2-1 firmó las dos variantes anteriores):** en modo servicios, el paso de empresa ejecuta `aprovisionar` con la identidad sysadmin del instalador elevado. La API no recibe `dbcreator`. Qué rompe: el paso 4 de la escalera deja de hacer falta en el DEMO y la empresa inicial no nace «por la interfaz». A quién afecta: al instalador y al técnico (necesitan ser sysadmin de la instancia; si no lo son, el paso se detiene con un mensaje, no degrada). Migración: ninguna (no hay instalaciones). Plan de reserva si el propietario mantiene lo firmado: `EmpresaInicial` solo con `--perfil demo`; el dueño no será `sa` hasta correr `aprovisionar`, que lo corrige.

**Orden de fases (respuesta a tu punto 2):** `servicios` → `anillo --preparar` → `esquema` (sistema, `--anclar`, cuentas y sellado) → empresa (`aprovisionar`) → `lectura` (si no va dentro de `aprovisionar --llave`). `lectura` va **después** de la empresa porque necesita su base. Hueco por verificar [I]: `aprovisionar` exige que la empresa esté registrada «pendiente» (sin cadena) en `GPOS_SYSDATA`; no encontré en modo servicios quién la registra. Lo verificas tú (tarea 3).

# Parte 2. Tareas nuevas para A (tanda 9), además de las tandas 7 y 8
Mismas reglas: PR con la plantilla, nada se une sin orden del propietario, evidencia ejecutada, máximo 3 compilaciones a la vez, lo visible va como pregunta.
1. **O-1, O-2 y O-3 de C** (`2026-10-23-entrega-pr223-guion-restaurar.md`), en `a/pr-d2-manifiesto`: `Instalar-Demo.ps1:127` pasa `--origen` a `--fase carpetas` (Media; detiene el modo servicios en el paso 1b); opción repetida aceptada en silencio; `--huella-copia-previa` sin validar como hexadecimal. Con una prueba cada una. Entrega antes del 28-oct para que la VM del laboratorio las incluya.
2. **R-02 del informe de `restaurar`:** elige entre exigir la carpeta del DEMO solo de administradores o ejecutar el verbo desde una copia protegida; una nota corta con costo, qué rompe y a quién afecta. Es una decisión de diseño; la firma el propietario.
3. **Diseño y pruebas en rojo del paso de empresa y cuentas** (sin implementarlo hasta mi respuesta firmada, antes del 30-oct): para la variante (c) y para la de reserva. Incluye el hueco del registro de la empresa «pendiente» en modo servicios y cómo el paso comprueba «soy sysadmin» antes de tocar nada.
4. **H120P-02 (pruebas, #120 ya unido):** `La_identidad_que_no_es_exclusiva_del_servicio_se_rechaza` falla 9/9 en un equipo con TPM porque `Existe` consulta el almacén del TPM; debe omitirse con su motivo (`LlaveFirmaTokensTests.cs:295`). PR chico. **H120P-03 y H120P-04** (llave de software activa en un equipo con TPM solo con el 4735; `HayTpm` solo comprueba que el proveedor se abre): solo una propuesta de remedio con opciones; es zona de DB-7, no cambies comportamiento.
5. **Revisión de seguridad de los guiones del laboratorio #223 y #226** antes de correrlos elevados en VM-SRV (qué ejecutan como administrador, qué leen de rutas escribibles por otros, qué dejan en `C:\GPOS-LAB\evidencia`). Informe corto; observaciones a C.
6. **Contrasta el blueprint #219 con F1 (#228):** el evento es el 4704 (corregido en `c087932a`); confirma que no queda otra referencia al 4729 del anillo en documentos tuyos.

Orden sugerido: 1, 4 (H120P-02), 5, 3, 2, 6. Respuesta requerida: acuse con fecha por punto; sobre D-5 no necesito respuesta tuya, la tendrás firmada o no antes del 30-oct.
