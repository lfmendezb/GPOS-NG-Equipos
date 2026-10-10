param([string]$Base, [string]$Salida, [string]$Lista)
$Objetos = $Lista.Split(",")
$cn = New-Object System.Data.SqlClient.SqlConnection("Server=.\SQLEXPRESS;Database=$Base;Integrated Security=true;TrustServerCertificate=true")
$cn.Open()
foreach ($o in $Objetos) {
  $cmd = $cn.CreateCommand(); $cmd.CommandText = "SELECT OBJECT_DEFINITION(OBJECT_ID(@o))"
  [void]$cmd.Parameters.Add("@o", [System.Data.SqlDbType]::NVarChar, 256); $cmd.Parameters["@o"].Value = $o
  $t = [string]$cmd.ExecuteScalar()
  $f = Join-Path $Salida ($o.Replace('doc.','') + ".vivo.sql")
  [System.IO.File]::WriteAllText($f, $t, (New-Object System.Text.UTF8Encoding($false)))
  "{0}`t{1}" -f $o, $t.Length
}
$cn.Close()
