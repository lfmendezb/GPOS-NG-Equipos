```
Para: B        De: C            Fecha: 2026-10-21
Tipo: Entrega (N-1, grupos A y B; P-7)
Prioridad: Media
Repositorio y rama: GPOS-NG c/n1-pruebas-orden @ 7c60a06e, PR #132 sobre b/n1-api-modo-servicio (8b143377)
Estado: Abierto
```

# Entrega: pruebas de N-1, grupos A y B (PR #132), antes del 27-oct

[#132](https://github.com/lfmendezb/GPOS-NG/pull/132) agrega 3 archivos de pruebas, 1 207 líneas, sin código de producción. Es texto y reflexión, sin SQL. Resultado por clase:
- `OrdenProgramaApi`: 94/94
- `ModoServicioArquitectura`: 47/47
- `PruebasNeutrales`: 28/28
- `ApiModoServicioArquitectura`: 6/6
- `EventIdUnicos`: 3/3

**Ninguna regla falla hoy sobre el `Program.cs` de `8b143377`.**

## Para que B decida
1. **S1 con systemd.** La regla acepta systemd solo si aparece en el código, y en ese caso debe ir antes de `Build()`. Hoy no está, y `La_API_no_tiene_otra_logica_de_servicio` lo prohíbe.
2. **B-07 adaptada.** La prueba exige el atributo `[SupportedOSPlatform("windows")]`, porque en esta rama no hay archivos `*.Windows.cs`. CA1416 no figura como error en la configuración (ADR-129 B.5, de A).
3. **Dos pruebas de orden conviven.** La tuya, `El_orden_del_middleware_es_el_fijado`, fija la lista entera; las de C fijan las razones del orden.

## Lo que sigue en otras manos
- **Grupo C:** C-01, C-02, C-04, C-05, C-06, C-09 y C-11, para el desarrollador de B.
- **Grupo E:** al unir PR-4 de A, con R1 `Obligatoria = true` y `ExigirArranqueObligatorio = true`.
- **Grupos D y F y el laboratorio:** para el devops de B.

C queda sin trabajo en curso.
