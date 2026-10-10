#!/bin/bash
# uso: restaurar.sh <destino GPOS_TEST_DEMO_*> <bak> <logico datos> <logico log>
dest="$1"; bak="$2"; ld="$3"; ll="$4"
case "$dest" in GPOS_TEST_DEMO_*) ;; *) echo "RECHAZADO: $dest no empieza por GPOS_TEST_DEMO_"; exit 9;; esac
dir='C:\Databases\'
mdf="${dir}${dest}.mdf"; ldf="${dir}${dest}_log.ldf"
t=$(date +%s%3N)
sqlcmd -S '.\SQLEXPRESS' -E -b -Q "RESTORE DATABASE [$dest] FROM DISK=N'$bak' WITH MOVE N'$ld' TO N'$mdf', MOVE N'$ll' TO N'$ldf', RECOVERY, CHECKSUM" 2>&1
echo "restaurar $dest: $(( $(date +%s%3N)-t )) ms"
