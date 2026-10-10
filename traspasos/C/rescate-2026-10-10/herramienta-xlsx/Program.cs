using ClosedXML.Excel;
using System.Globalization;
if (args[0] == "generar") { Generar.Ejecutar(args[1], args[2], args[3], args[4]); return; }
// uso: volcar <xlsx> <salida.csv>  (hoja Datos, separador ;)
if (args[0] == "volcar")
{
    using var lib = new XLWorkbook(args[1]);
    Console.WriteLine("Hojas: " + string.Join(", ", lib.Worksheets.Select(w => w.Name)));
    var h = lib.Worksheets.FirstOrDefault(w => w.Name == "Datos") ?? lib.Worksheet(1);
    var r = h.RangeUsed()!;
    using var sw = new StreamWriter(args[2]);
    foreach (var row in r.Rows())
        sw.WriteLine(string.Join(";", row.Cells().Select(c => c.IsEmpty() ? "" :
            c.Value.Type == XLDataType.DateTime ? c.Value.GetDateTime().ToString("yyyy-MM-dd") :
            c.Value.Type == XLDataType.Number ? ((decimal)c.Value.GetNumber()).ToString(CultureInfo.InvariantCulture) : c.GetString().Replace(";", ","))));
    Console.WriteLine($"{args[1]}: {r.RowCount()} filas");
}
