// ESQUELETO PROPUESTO (RB-P4, arquitecto de datos de B, 2026-10-10). No compilado. Los casos están en
// rb-p5-disparadores-completos.md, sección 3; este archivo fija la forma (la de DisparadoresEmisionTests y CompraVariableTablaTests).
// Destino sugerido: tests/GPOS.Tests/ModeloNg/ReglasSoloBaseTests.cs
using GPOS.Tests.Escenarios;
using Microsoft.Data.SqlClient;

namespace GPOS.Tests.ModeloNg;

/// <summary>
/// RB-P4 (ADR-52, precisión del 2026-10-10): pruebas de base de las reglas que solo valida el motor (51379, 51359, 51374, 51375, 51362, 51376) y
/// la comprobación de RB-P3 (51312 solo en <c>TR_Documento_Motivo608</c>). Cada caso copia en borrador un documento real emitido por el servicio,
/// rompe UNA condición y lo emite con un <c>UPDATE</c> directo, dentro de una transacción que se deshace (la base queda como estaba).
/// Base propia: los casos cambian <c>conf.Parametros</c> (tope de días) dentro de la transacción.
/// </summary>
[Trait("Esquema", "NG")]
[Trait("Categoria", "ReglasSoloBase")]
public class ReglasSoloBaseTests(BaseDatosFixture bd) : IClassFixture<BaseDatosFixture>
{
    /// <summary>Documentos de origen, emitidos una vez por base con los servicios (ver la tabla de preparación de la sección 3).</summary>
    private sealed record Origenes(
        long FacHace31, long NcSobreFacHace31, long FacHace30, long NcSobreFacHace30,   // 51379
        long FcpItbisAlCosto, long FcpUsdItbisAlCosto,                                   // 51359
        long Fcp5Unidades, long Dvs2Unidades,                                            // 51362
        long FacCredito, long RecConRetencion,                                           // 51374, 51375 (CXC)
        long FacUsd, long RecUsdOtraTasa, long FcpUsd, long PagoCxpUsd,                  // 51375 (tasas)
        long VentaConNcf);                                                               // RB-P3

    private static readonly Dictionary<string, Task<Origenes>> origenes = [];

    private Task<Origenes> OrigenesAsync()
    {
        lock (origenes)
            return origenes.TryGetValue(bd.ConnectionString, out var t) ? t : origenes[bd.ConnectionString] = CrearOrigenesAsync();
    }

    private Task<Origenes> CrearOrigenesAsync() => throw new NotImplementedException("QA: emitir los orígenes con los servicios (sección 3).");

    // Apoyo reutilizado (internal en FactorUnidadKardexTests): CopiarFilas, Copia(variable, origen, tablas...), Kardex(...), Emitir(variable).
    private static string Copia(string v, long o, params (string, string)[] tablas) => FactorUnidadKardexTests.Copia(v, o, tablas);
    private static string Emitir(string v) => FactorUnidadKardexTests.Emitir(v);

    /// <summary>Casos: (número esperado; 0 = el motor acepta, fragmento del mensaje o null, preparación + acto).</summary>
    private static readonly Dictionary<string, (int Esperado, string? Mensaje, Func<Origenes, string> Lote)> casos = new()
    {
        // ---- 51379 PLAZO_FISCAL (doc.TR_Documento_Ola4b)
        // ["P1 NC a 31 días sin la marca"] = (51379, "PLAZO_FISCAL", o => Copia("@a", o.NcSobreFacHace31, TablasNc) +
        //     "UPDATE ventas.Venta SET FueraPlazoFiscal = 0 WHERE DocumentoId = @a;\n" + Emitir("@a")),
        // ["P2 NC a 31 días con la marca"] = (0, null, o => Copia("@a", o.NcSobreFacHace31, TablasNc) + "SET @fase = 'acto';
" + Emitir("@a")),
        // ...
        // ---- 51359, 51362, 51374, 51375, 51376 y RB-P3: ver la sección 3 del documento
    };

    public static TheoryData<string> Casos() => [.. casos.Keys];

    [Theory]
    [MemberData(nameof(Casos))]
    public async Task Cada_regla_solo_de_base_da_su_numero(string caso)
    {
        var (esperado, mensaje, lote) = casos[caso];
        var (fase, numero, texto) = await CorrerAsync(lote(await OrigenesAsync()));
        Assert.True(fase == "acto", $"La preparación falló: {numero} {texto}");
        Assert.True(esperado == numero, $"Se esperaba {esperado} y el motor dio {numero}: {texto}");
        if (mensaje is not null) Assert.Contains(mensaje, texto, StringComparison.Ordinal);
    }

    /// <summary>Corre el lote en una transacción que siempre se deshace; la última sentencia del lote es el acto (marcado con SET @fase = 'acto').</summary>
    private async Task<(string Fase, int Numero, string? Mensaje)> CorrerAsync(string lote)
    {
        await using var cn = new SqlConnection(bd.ConnectionString);
        await cn.OpenAsync();
        await using var cmd = new SqlCommand($"""
            SET NOCOUNT ON;
            DECLARE @fase varchar(4) = 'prep', @num int = 0, @msg nvarchar(4000) = NULL;
            BEGIN TRAN;
            BEGIN TRY
                {lote}
            END TRY
            BEGIN CATCH
                SELECT @num = ERROR_NUMBER(), @msg = ERROR_MESSAGE();
            END CATCH
            IF @@TRANCOUNT > 0 ROLLBACK;
            SELECT @fase, @num, @msg;
            """, cn) { CommandTimeout = 120 };
        cmd.Parameters.Add(new SqlParameter("@copiar", System.Data.SqlDbType.NVarChar, -1) { Value = FactorUnidadKardexTests.CopiarFilas });
        await using var r = await cmd.ExecuteReaderAsync();
        Assert.True(await r.ReadAsync());
        return (r.GetString(0), r.GetInt32(1), r.IsDBNull(2) ? null : r.GetString(2));
    }

    /// <summary>Guarda de cobertura: cada regla de RB-P4 tiene al menos un caso que falla con su número y uno que pasa.</summary>
    [Fact]
    public void Cada_regla_tiene_un_caso_que_falla_y_uno_que_pasa()
    {
        foreach (var n in new[] { 51379, 51359, 51362, 51374, 51375 })
            Assert.Contains(casos.Values, c => c.Esperado == n);
        Assert.Contains(casos.Values, c => c.Esperado == 0);
    }
}
