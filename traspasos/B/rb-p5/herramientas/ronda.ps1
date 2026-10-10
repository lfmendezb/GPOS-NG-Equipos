# Comprobación de ida y vuelta (RB-P5, nivel 2 de la prueba de equivalencia) en una base GPOS_TEST_* creada con el guion acumulado:
# 1. Antes de tocar nada, OBJECT_DEFINITION de cada disparador, normalizado (CRLF -> LF, "CREATE   TRIGGER" -> "CREATE OR ALTER TRIGGER",
#    sin la sangría de 4 espacios que agrega EF en las líneas 2..n), debe ser igual al texto completo del archivo.
# 2. Ejecuta cada texto con la sangría de EF y vuelve a comparar: la definición no cambia.
# 3. Variantes (sin 51312; PR #21): compilan.
# Uso: powershell -File ronda.ps1 -Base GPOS_TEST_x -Dir <carpeta con los .sql>
param([string]$Base, [string]$Dir)
$cn = New-Object System.Data.SqlClient.SqlConnection("Server=.\SQLEXPRESS;Database=$Base;Integrated Security=true;TrustServerCertificate=true")
$cn.Open()
function Sangrar([string]$t) { $l = $t.TrimEnd("`n").Split("`n"); for ($i=1; $i -lt $l.Length; $i++) { if ($l[$i] -ne '') { $l[$i] = '    ' + $l[$i] } }; return ($l -join "`r`n") }
function Normalizar([string]$d) {
  $l = $d.Replace("`r`n", "`n").Split("`n")
  if (-not $l[0].StartsWith('CREATE   TRIGGER ')) { throw "Cabecera inesperada: $($l[0])" }
  $l[0] = 'CREATE OR ALTER TRIGGER ' + $l[0].Substring('CREATE   TRIGGER '.Length)
  for ($i=1; $i -lt $l.Length; $i++) { if ($l[$i] -ne '') { if (-not $l[$i].StartsWith('    ')) { throw "Línea $($i+1) sin sangría de EF" }; $l[$i] = $l[$i].Substring(4) } }
  return ($l -join "`n")
}
function Def([string]$o) { $c=$cn.CreateCommand(); $c.CommandText="SELECT OBJECT_DEFINITION(OBJECT_ID('$o'))"; return [string]$c.ExecuteScalar() }
function Ejecutar([string]$sql) { $c=$cn.CreateCommand(); $c.CommandText=$sql; [void]$c.ExecuteNonQuery() }
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($p in @(@('Emision','doc.TR_Documento_Emision.sql'),@('Ola4','doc.TR_Documento_Ola4.sql'),@('Ola4b','doc.TR_Documento_Ola4b.sql'),@('Anulacion','doc.TR_Documento_Anulacion.sql'))) {
  $o = 'doc.TR_Documento_' + $p[0]
  $txt = [IO.File]::ReadAllText((Join-Path $Dir $p[1]), $utf8).TrimEnd("`n")
  $n1 = (Normalizar (Def $o)) -ceq $txt
  Ejecutar (Sangrar $txt)
  $n2 = (Normalizar (Def $o)) -ceq $txt
  "{0}: catálogo = archivo antes: {1}; después de ejecutarlo: {2}" -f $o, $n1, $n2
}
foreach ($p in @(@('Anulacion','doc.TR_Documento_Anulacion.sin51312.sql'),@('Ola4','doc.TR_Documento_Ola4.pr21.sql'))) {
  $o = 'doc.TR_Documento_' + $p[0]
  $txt = [IO.File]::ReadAllText((Join-Path $Dir $p[1]), $utf8).TrimEnd("`n")
  Ejecutar (Sangrar $txt)
  $d = Def $o
  "{0} <- {1}: compila; catálogo = archivo: {2}; THROW 51312: {3}; DECLARE @e: {4}" -f $o, $p[1], ((Normalizar $d) -ceq $txt), $d.Contains('THROW 51312'), $d.Contains('DECLARE @e TABLE')
}
$cn.Close()
