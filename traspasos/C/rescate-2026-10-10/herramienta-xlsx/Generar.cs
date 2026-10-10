using ClosedXML.Excel;
using System.Globalization;
using System.Text;

/// <summary>C-6 (PQ-4): genera las plantillas del DEMO con existencias para 15 días y artículos con lote.</summary>
static class Generar
{
    static readonly CultureInfo Inv = CultureInfo.InvariantCulture;
    static readonly DateTime Corte = new(2026, 10, 1);
    const int DiasCobertura = 15, Minimo = 12, Multiplo = 6;
    const string ArticuloFaltante = "LAC-020";
    const int CantidadFaltante = 2;

    record Nuevo(string Codigo, string Descripcion, string Impuesto, string Categoria, string Subcategoria, string Marca, decimal Costo, decimal PrecioFinal);
    static readonly Nuevo[] Nuevos =
    [
        new("LAC-023", "Yogur de vainilla Los Pinitos 150 g", "ITBIS18", "LACTEOS", "YOGURES", "LOSPIN", 38, 60),
        new("LAC-024", "Yogur de piña Los Pinitos 150 g", "ITBIS18", "LACTEOS", "YOGURES", "LOSPIN", 38, 60),
        new("LAC-025", "Queso blanco fresco Los Pinitos 1 lb", "ITBIS18", "LACTEOS", "QUESOS", "LOSPIN", 170, 250),
        new("LAC-026", "Leche deslactosada Los Pinitos 1 L", "EXENTO", "LACTEOS", "LECHES", "LOSPIN", 70, 90),
        new("LAC-027", "Crema agria Los Pinitos 8 oz", "ITBIS18", "LACTEOS", "MANTEQUILLAS", "LOSPIN", 80, 120),
        new("BEB-024", "Jugo de chinola refrigerado Monte Azulado 1 L", "ITBIS18", "BEBIDAS", "JUGOS", "MONAZU", 95, 140),
        new("VIV-047", "Pan de molde blanco Trigal Dorado 680 g", "ITBIS18", "VIVERES", "HARINAS", "TRIGAL", 105, 150),
        new("VIV-048", "Pan de molde integral Trigal Dorado 680 g", "ITBIS18", "VIVERES", "HARINAS", "TRIGAL", 120, 170),
    ];

    record LoteDemo(string Articulo, string Lote, decimal Cantidad, DateTime? Vence, int? Dias, string Caso);
    static readonly LoteDemo[] Lotes =
    [
        new("LAC-023", "YV-260901", 6, null, -5, "Vencido: el POS lo rechaza (LOTE_VENCIDO); se da de baja con merma o ajuste"),
        new("LAC-023", "YV-260925", 24, new(2027, 9, 30), null, "Normal"),
        new("LAC-024", "YP-260903", 6, null, 0, "Vence hoy: se vende (PQ-2)"),
        new("LAC-024", "YP-260926", 24, new(2027, 10, 15), null, "Normal"),
        new("LAC-025", "QB-260920", 8, null, 3, "Vence pronto: es el sugerido (vence primero)"),
        new("LAC-025", "QB-260928", 12, new(2027, 8, 31), null, "Normal"),
        new("LAC-026", "LD-260910", 36, new(2027, 7, 31), null, "Normal (el sugerido)"),
        new("LAC-026", "LD-260929", 36, new(2027, 11, 30), null, "Normal"),
        new("LAC-027", "CA-260915", 18, new(2027, 12, 31), null, "Normal (un solo lote)"),
        new("BEB-024", "JC-260918", 12, new(2027, 8, 15), null, "Normal (el sugerido)"),
        new("BEB-024", "JC-260927", 24, new(2027, 12, 15), null, "Normal"),
        new("VIV-047", "PB-260929", 15, null, 5, "Vence pronto: es el sugerido (vence primero)"),
        new("VIV-047", "PB-260930", 15, new(2027, 7, 10), null, "Normal"),
        new("VIV-048", "PI-260930", 10, new(2027, 7, 10), null, "Normal (un solo lote)"),
    ];

    public static void Ejecutar(string origen, string csvVentas, string destino, string trabajo)
    {
        Directory.CreateDirectory(destino);
        foreach (var f in new[] { "01-categorias", "02-subcategorias", "03-marcas", "04-suplidores", "05-clientes", "08-facturas-historicas" })
            File.Copy(Path.Combine(origen, f + ".xlsx"), Path.Combine(destino, f + ".xlsx"), true);

        // Ventas de los últimos 90 días de la plantilla 08 (02/07/2026 a 30/09/2026), por artículo
        var ventas90 = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);
        foreach (var l in File.ReadLines(csvVentas).Skip(1))
        {
            var c = l.Split(';');
            if (string.CompareOrdinal(c[2], "2026-07-02") < 0) continue;
            ventas90[c[9]] = ventas90.GetValueOrDefault(c[9]) + decimal.Parse(c[10], Inv);
        }
        var costos = Nuevos.ToDictionary(n => n.Codigo, n => n.Costo);

        // 06: artículos nuevos con «Requiere lote», que no están en las facturas históricas
        using (var lib = new XLWorkbook(Path.Combine(origen, "06-articulos.xlsx")))
        {
            var h = lib.Worksheet("Datos");
            var col = Columnas(h);
            var fila = h.LastRowUsed()!.RowNumber() + 1;
            var siguiente = h.Column(col["Código de barras"]).CellsUsed().Skip(1).Max(c => long.Parse(c.GetString().Substring(3, 9))) + 1;
            foreach (var n in Nuevos)
            {
                var precio1 = n.Impuesto == "EXENTO" ? n.PrecioFinal : Math.Round(n.PrecioFinal / 1.18m, 4, MidpointRounding.AwayFromZero);
                var margen = Math.Round((precio1 / n.Costo - 1) * 100, 2, MidpointRounding.AwayFromZero);
                Texto(h.Cell(fila, col["Código"]), n.Codigo);
                Texto(h.Cell(fila, col["Descripción *"]), n.Descripcion);
                Texto(h.Cell(fila, col["Código de barras"]), Ean13("209" + (siguiente++).ToString("000000000")));
                Texto(h.Cell(fila, col["Impuesto"]), n.Impuesto);
                Texto(h.Cell(fila, col["Unidad de venta"]), "UND");
                Texto(h.Cell(fila, col["Unidad de compra"]), "UND");
                Texto(h.Cell(fila, col["Se puede facturar"]), "Sí");
                Texto(h.Cell(fila, col["Requiere lote"]), "Sí");
                Texto(h.Cell(fila, col["Categoría"]), n.Categoria);
                Texto(h.Cell(fila, col["Subcategoría"]), n.Subcategoria);
                Texto(h.Cell(fila, col["Marca"]), n.Marca);
                h.Cell(fila, col["Costo"]).Value = n.Costo;
                Texto(h.Cell(fila, col["Moneda del costo"]), "RD$");
                h.Cell(fila, col["% Margen"]).Value = margen;
                h.Cell(fila, col["Precio 1"]).Value = precio1;
                fila++;
            }
            lib.SaveAs(Path.Combine(destino, "06-articulos.xlsx"));
        }

        // 07: cobertura de 15 días de venta (mínimo 12, múltiplos de 6, nunca menos que antes), un faltante adrede y los lotes
        var cambios = new StringBuilder("Articulo;CantidadAnterior;Ventas90Dias;CantidadNueva\n");
        using (var lib = new XLWorkbook(Path.Combine(origen, "07-existencias-iniciales.xlsx")))
        {
            var h = lib.Worksheet("Datos");
            var col = Columnas(h);
            var ultima = h.LastRowUsed()!.RowNumber();
            for (var r = 2; r <= ultima; r++)
            {
                var art = h.Cell(r, col["Artículo *"]).GetString().Trim();
                var antes = (decimal)h.Cell(r, col["Cantidad *"]).GetDouble();
                var v = ventas90.GetValueOrDefault(art);
                var objetivo = Math.Ceiling(v / 90m * DiasCobertura / Multiplo) * Multiplo;
                var nueva = art == ArticuloFaltante ? CantidadFaltante : Math.Max(Math.Max(antes, objetivo), Minimo);
                h.Cell(r, col["Cantidad *"]).Value = nueva;
                cambios.Append(FormattableString.Invariant($"{art};{antes};{v};{nueva}\n"));
            }
            var fila = ultima + 1;
            foreach (var l in Lotes)
            {
                Texto(h.Cell(fila, col["Artículo *"]), l.Articulo);
                Texto(h.Cell(fila, col["Almacén"]), "PRINCIPAL");
                h.Cell(fila, col["Cantidad *"]).Value = l.Cantidad;
                h.Cell(fila, col["Costo"]).Value = costos[l.Articulo];
                h.Cell(fila, col["Fecha"]).Value = Corte;
                Texto(h.Cell(fila, col["Lote"]), l.Lote);
                fila++;
            }
            lib.SaveAs(Path.Combine(destino, "07-existencias-iniciales.xlsx"));
        }
        Directory.CreateDirectory(trabajo);
        File.WriteAllText(Path.Combine(trabajo, "cambios-cantidades-07.csv"), cambios.ToString(), new UTF8Encoding(true));

        // Hoja de trabajo para T4: los mismos lotes con su vencimiento (la plantilla de hoy no tiene esa columna)
        var t4 = new StringBuilder("Articulo;Almacen;Lote;Cantidad;Costo;Fecha;Vence;VenceDiasDesdeInstalacion;Caso\n");
        foreach (var l in Lotes)
            t4.Append(FormattableString.Invariant(
                $"{l.Articulo};PRINCIPAL;{l.Lote};{l.Cantidad};{costos[l.Articulo]};{Corte:yyyy-MM-dd};{l.Vence?.ToString("yyyy-MM-dd", Inv)};{l.Dias};{l.Caso}\n"));
        File.WriteAllText(Path.Combine(destino, "T4-vencimientos-lotes.csv"), t4.ToString(), new UTF8Encoding(true));
    }

    static Dictionary<string, int> Columnas(IXLWorksheet h) =>
        h.Row(1).CellsUsed().ToDictionary(c => c.GetString().Trim(), c => c.Address.ColumnNumber);

    static void Texto(IXLCell c, string v) { c.Style.NumberFormat.Format = "@"; c.Value = v; }

    static string Ean13(string doce)
    {
        var s = 0;
        for (var i = 0; i < 12; i++) s += (doce[i] - '0') * (i % 2 == 0 ? 1 : 3);
        return doce + ((10 - s % 10) % 10);
    }
}
