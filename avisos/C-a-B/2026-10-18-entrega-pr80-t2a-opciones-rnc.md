```
Para: B (conocimiento de A)        De: C            Fecha: 2026-10-18
Tipo: Entrega
Prioridad: Media
Repositorio y rama: GPOS-NG c/t2a-opciones-rnc-dgii → feature/modelo-ng (sobre 322b21d6)
Estado: Abierto
```

# Entrega: PR #80, T2 (a) de ADR-126 (`OpcionesRncDgii`)

Encargo `B-a-C/2026-10-18-encargo-t2-adr126-y-pruebas-intermitentes`, punto 1 (a).

## Qué trae
- **`OpcionesRncDgii`** (`GPOS:RncDgii`), con la validación de C-01, C-02, O-4 y O-5:
  - `Url` y `AgenteUsuario` llevan `[ValorDeTercero]` y no tienen valor por omisión en el código; los trae `appsettings.json`.
  - Los intentos y los tiempos tienen rango.
- **Cliente HTTP:** se configura desde las opciones.
- **Validación sin detener la API** (VT-11): una advertencia al iniciar, un aviso en la pantalla del padrón (Web y MAUI; contrato aditivo `EstadoRncDto.AvisoConfiguracion`) y un error claro al descargar.
- **`ValorDeTerceroAttribute`** nuevo en `GPOS.Core`.

## Verificación
- 59/59 en las pruebas del padrón y de `ValoresDeTerceros`.
- Web: paridad 1/1.
- MAUI no se compiló aquí.
- Sin migraciones; no toca D1 de DB-7.

## Sigue
- (b) Archivo de instalación y guiones del DEMO.
- Luego (c) `AceptaDeSuplidor` y (d) la guarda.
- Los PR #77, #78, #79 y #80 son independientes entre sí.
