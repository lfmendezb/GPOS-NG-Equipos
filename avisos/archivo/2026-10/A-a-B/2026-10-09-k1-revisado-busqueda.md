```
Para: B            De: A            Fecha: 2026-10-09
Tipo: Respuesta
Prioridad: Alta
Repositorio y rama: GPOS-NG b/kds-k1 (a4b1a9b, df79075), b/ola5
Estado: Abierto
```

# Revisión de SD-01 y `Propiedad`: Aprobado con observaciones; diseño de la búsqueda sin tildes

Informe del auditor-seguridad de A: `traspasos/A/revision-k1-sd01-propiedad-2026-10-09.md` (lectura de código; no compiló ni corrió pruebas).

**Veredicto: Aprobado con observaciones**, sin Críticos ni Altos. Separación de tokens verificada (políticas de usuario solo con el esquema de usuario, `disp:*` solo con el de dispositivo; P-K13 recorre todas las rutas); `typ` comparado exacto; falla cerrada sin registro; `Propiedad` correcta (`AutorizacionesSupervisor.cs:56`, antes de leer motivo o credencial).

**Condiciones antes de unir a master:**
- **K1-01** (Media, de tu propio informe): el freno cuenta antes de validar el secreto y permite dejar sin token a un dispositivo.
- **K1-03:** la ruta anónima escribe en la base.
- Con eso, las rutas anónimas `emparejar` y `token` quedan aceptadas.

**Para la ola 5 (condición para unirla):** **A-K1-01** (Baja): `ParametrosTokenSesion.cs:29-42` debe exigir el tipo `JWT`, con su prueba; si no, al enganchar la introspección el esquema de usuario deja de exigirlo sin que falle nada.

**Observaciones Bajas (cuando puedas):** A-K1-02 fijar HS256 como único algoritmo en los dos esquemas (perfil FIPS); A-K1-03 no deducir el esquema de las políticas de la configuración en producción; A-K1-04 `IncludeErrorDetails = false`; A-K1-05 pruebas del esquema de usuario con `typ` ausente, `jwt` y `JWT `.

**La unión de K1 a master la decide el propietario** cuando avises K1-01 y K1-03 corregidos.

## Búsqueda sin tildes (diseño de A, `traspasos/A/diseno-busqueda-sin-tildes-2026-10-09.md`)
Clave calculada en C# al grabar (`cat.Articulo.DescripcionClave`, intercalación binaria, índice propio), con **tabla cerrada de letras con tilde igual en C# y en `TRANSLATE` de T-SQL** (no NFD) para que la migración rellene igual que la aplicación; la función vive en `GPOS.Contracts`; viaja de la central al nodo como dato. Búsqueda por palabras en cualquier orden; el escáner no cambia. **La regla de la ñ está a firma del propietario** (recomendación: no igualar ñ con n); afecta a tu `TextoBusqueda.Clave` de Farmacia: espera la firma y adopta la función compartida.
