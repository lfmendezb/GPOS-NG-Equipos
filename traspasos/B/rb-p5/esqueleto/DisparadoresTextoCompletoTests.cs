// ESQUELETO PROPUESTO (RB-P5, arquitecto de datos de B, 2026-10-10). No compilado: lo completa el desarrollador-backend con QA.
// Destino sugerido: tests/GPOS.Tests/ModeloNg/DisparadoresTextoCompletoTests.cs
using System.Reflection;
using System.Text.RegularExpressions;
using GPOS.Core.Datos.Empresa;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace GPOS.Tests.ModeloNg;

/// <summary>
/// RB-P5 (ADR-52, precisión del 2026-10-10): el texto completo de cada disparador consolidado vive en un solo archivo
/// (<c>database/empresa/disparadores/{objeto}.sql</c>) y cada migración que lo escribe lee su copia congelada
/// (<c>database/empresa/disparadores/congelados/{objeto}.{migración}.sql</c>). Cuatro garantías:
/// <list type="number">
/// <item>N1: cada copia congelada es, carácter por carácter, el último <c>CREATE OR ALTER</c> de ese objeto en el guion que genera EF hasta su
/// migración (sin la sangría de EF y con las comillas desdobladas). La primera copia de cada objeto prueba que el texto consolidado es el que
/// armaban los parches.</item>
/// <item>V: el archivo vigente es la copia congelada más reciente.</item>
/// <item>N2: en una base creada con el guion embebido, <c>OBJECT_DEFINITION</c> normalizada es el archivo vigente, con ANSI_NULLS y
/// QUOTED_IDENTIFIER activos.</item>
/// <item>M: toda migración posterior a la consolidación que redefine el objeto tiene su copia congelada (nadie vuelve al parche ni lee el
/// vigente).</item>
/// </list>
/// </summary>
[Trait("Esquema", "NG")]
[Trait("Categoria", "Disparadores")]
public class DisparadoresTextoCompletoTests(BaseDatosFixture bd) : IClassFixture<BaseDatosFixture>
{
    /// <summary>Objetos consolidados por RB-P5. Se agrega uno cuando su primera copia congelada entra al repositorio.</summary>
    public static TheoryData<string> Consolidados() =>
        ["doc.TR_Documento_Emision", "doc.TR_Documento_Ola4", "doc.TR_Documento_Ola4b", "doc.TR_Documento_Anulacion"];

    private static readonly Assembly Core = typeof(EmpresaNgDbContext).Assembly;
    private const string CarpetaVigente = ".disparadores.", CarpetaCongelados = ".disparadores.congelados.";

    // ------------------------------------------------------------------ Normalización (una sola definición para N1, V y N2)

    private static string Lf(string s) => s.Replace("\r\n", "\n", StringComparison.Ordinal).TrimStart('﻿').TrimEnd('\n');

    /// <summary>EF (IndentedStringBuilder) sangra con 4 espacios las líneas 2..n del literal dentro de <c>BEGIN … END</c>; las vacías no.</summary>
    private static string SinSangriaEf(string texto)
    {
        var l = Lf(texto).Split('\n');
        for (var i = 1; i < l.Length; i++)
        {
            if (l[i].Length == 0) continue;
            Assert.True(l[i].StartsWith("    ", StringComparison.Ordinal), $"Línea {i + 1} sin la sangría de EF: el texto no viene del guion.");
            l[i] = l[i][4..];
        }
        return string.Join('\n', l);
    }

    /// <summary>SQL Server guarda <c>CREATE OR ALTER TRIGGER</c> como <c>CREATE   TRIGGER</c> (verificado en SQL Server 2025 Express, 2026-10-10).</summary>
    private static string DesdeCatalogo(string definicion)
    {
        var t = SinSangriaEf(definicion);
        const string guardado = "CREATE   TRIGGER ";
        Assert.StartsWith(guardado, t, StringComparison.Ordinal);
        return "CREATE OR ALTER TRIGGER " + t[guardado.Length..];
    }

    /// <summary>Último literal <c>EXEC(N'CREATE OR ALTER TRIGGER {objeto} ON …')</c> del guion, con las comillas desdobladas.</summary>
    private static string UltimoLiteral(string guion, string objeto)
    {
        var m = Regex.Matches(guion, @"EXEC\(N'(CREATE OR ALTER TRIGGER " + Regex.Escape(objeto) + @" ON (?:[^']|'')*)'\);");
        Assert.NotEmpty(m);
        return m[^1].Groups[1].Value.Replace("''", "'", StringComparison.Ordinal);
    }

    // ------------------------------------------------------------------ Recursos

    private static string Leer(string recurso)
    {
        using var s = Core.GetManifestResourceStream(recurso)!;
        using var r = new StreamReader(s);
        return Lf(r.ReadToEnd());
    }

    private static string Vigente(string objeto) =>
        Leer(Core.GetManifestResourceNames().Single(n => n.EndsWith(CarpetaVigente + objeto + ".sql", StringComparison.Ordinal)));

    /// <summary>Copias congeladas de <paramref name="objeto"/> ordenadas por migración (el id de EF ordena por fecha).</summary>
    private static IReadOnlyList<(string Migracion, string Texto)> Congelados(string objeto)
    {
        var prefijo = CarpetaCongelados + objeto + ".";
        return Core.GetManifestResourceNames()
            .Select(n => (n, i: n.IndexOf(prefijo, StringComparison.Ordinal)))
            .Where(x => x.i >= 0)
            .Select(x => (Migracion: x.n[(x.i + prefijo.Length)..^".sql".Length], Texto: Leer(x.n)))
            .OrderBy(x => x.Migracion, StringComparer.Ordinal)
            .ToList();
    }

    private static string Guion(string? desde, string hasta)
    {
        using var db = new DisenoEmpresaNg().CreateDbContext([]);
        return db.GetService<IMigrator>().GenerateScript(desde, hasta, MigrationsSqlGenerationOptions.Idempotent);
    }

    // ------------------------------------------------------------------ N1, V, N2, M

    [Theory]
    [MemberData(nameof(Consolidados))]
    public void N1_cada_copia_congelada_es_el_texto_que_genera_EF_hasta_su_migracion(string objeto)
    {
        var copias = Congelados(objeto);
        Assert.NotEmpty(copias);
        foreach (var (migracion, texto) in copias)
            Assert.True(texto == SinSangriaEf(UltimoLiteral(Guion(null, migracion), objeto)),
                $"{objeto}: la copia congelada de {migracion} no es el texto que genera EF hasta esa migración.");
    }

    [Theory]
    [MemberData(nameof(Consolidados))]
    public void V_el_archivo_vigente_es_la_ultima_copia_congelada(string objeto) =>
        Assert.True(Vigente(objeto) == Congelados(objeto)[^1].Texto,
            $"{objeto}: el archivo vigente cambió sin una migración que lo congele (o la última copia no se actualizó).");

    [Theory]
    [MemberData(nameof(Consolidados))]
    public async Task N2_la_definicion_en_la_base_es_el_archivo_vigente(string objeto)
    {
        await using var cn = new SqlConnection(bd.ConnectionString);
        await cn.OpenAsync();
        await using var cmd = new SqlCommand("""
            SELECT m.definition, m.uses_ansi_nulls, m.uses_quoted_identifier
              FROM sys.sql_modules m WHERE m.object_id = OBJECT_ID(@o)
            """, cn);
        cmd.Parameters.Add(new SqlParameter("@o", System.Data.SqlDbType.NVarChar, 256) { Value = objeto });   // GPOS_SYSDATA/catálogo: nvarchar
        await using var r = await cmd.ExecuteReaderAsync();
        Assert.True(await r.ReadAsync(), $"{objeto} no existe en la base.");
        Assert.True(r.GetBoolean(1) && r.GetBoolean(2), $"{objeto} se creó sin ANSI_NULLS o QUOTED_IDENTIFIER (¿guion aplicado con sqlcmd sin -I?).");
        Assert.True(DesdeCatalogo(r.GetString(0)) == Vigente(objeto), $"{objeto}: la definición en la base no es el archivo vigente.");
    }

    [Theory]
    [MemberData(nameof(Consolidados))]
    public void M_toda_migracion_posterior_que_redefine_el_objeto_tiene_su_copia_congelada(string objeto)
    {
        using var db = new DisenoEmpresaNg().CreateDbContext([]);
        var migraciones = db.Database.GetMigrations().ToList();
        var primera = Congelados(objeto)[0].Migracion;
        var congeladas = Congelados(objeto).Select(c => c.Migracion).ToHashSet(StringComparer.Ordinal);
        var marca = "CREATE OR ALTER TRIGGER " + objeto + " ON";
        for (var i = migraciones.IndexOf(primera) + 1; i < migraciones.Count; i++)
        {
            var tramo = Guion(migraciones[i - 1], migraciones[i]);
            if (tramo.Contains(marca, StringComparison.Ordinal))
                Assert.True(congeladas.Contains(migraciones[i]),
                    $"{migraciones[i]} redefine {objeto} sin copia congelada: escriba el texto completo en el archivo vigente y congélelo (RB-P5).");
        }
    }

    // ------------------------------------------------------------------ Huella de reglas (ayuda de revisión; opcional)

    /// <summary>Multiconjunto de (número, mensaje) de los THROW: un cambio de forma no debe tocarlo; un cambio de regla lo declara aquí.</summary>
    private static IReadOnlyList<string> Huella(string texto) =>
        Regex.Matches(texto, @"THROW\s+(\d{5}),\s*N'((?:[^']|'')*)'").Select(m => m.Groups[1].Value + " " + m.Groups[2].Value)
             .Order(StringComparer.Ordinal).ToList();

    /// <summary>Diferencias de huella declaradas por migración (objeto → (quitadas, agregadas)). Ejemplo: RB-P3 quita 51312 de la anulación.</summary>
    private static readonly Dictionary<(string Objeto, string Migracion), (string[] Quitadas, string[] Agregadas)> cambiosDeclarados = new()
    {
        // [("doc.TR_Documento_Anulacion", "<migración que lo toque>")] =
        //     (["51312 Anular un documento con NCF exige el código del 608 (CA-02)."], []),
    };

    [Theory]
    [MemberData(nameof(Consolidados))]
    public void La_huella_de_reglas_solo_cambia_lo_declarado(string objeto)
    {
        var copias = Congelados(objeto);
        for (var i = 1; i < copias.Count; i++)
        {
            var antes = Huella(copias[i - 1].Texto);
            var despues = Huella(copias[i].Texto);
            cambiosDeclarados.TryGetValue((objeto, copias[i].Migracion), out var d);
            var esperado = antes.ToList();   // multiconjunto: se quita una aparición por cada regla declarada (Except quitaría duplicados)
            foreach (var q in d.Quitadas ?? []) Assert.True(esperado.Remove(q), $"{objeto}: se declaró quitar «{q}», que no estaba.");
            esperado = esperado.Concat(d.Agregadas ?? []).Order(StringComparer.Ordinal).ToList();
            Assert.True(esperado.SequenceEqual(despues), $"{objeto} en {copias[i].Migracion}: cambió una regla sin declararla.");
        }
    }
}
