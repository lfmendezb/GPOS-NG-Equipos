# Extrae del guion acumulado la última CREATE OR ALTER de cada disparador pedido, con su migración, y desdobla las comillas.
# El literal N'...' se lee como (?:[^']|'')* hasta la comilla de cierre seguida de ");".
use strict; use warnings;
my ($guion, $salida, @objs) = @ARGV;
open my $fh, '<:raw', $guion or die; local $/; my $g = <$fh>; close $fh;
$g =~ s/^\xEF\xBB\xBF//;
for my $o (@objs) {
  my ($ultimo, $mig, $n) = (undef, undef, 0);
  while ($g =~ /EXEC\(N'(CREATE OR ALTER TRIGGER \Q$o\E ON (?:[^']|'')*)'\);/gs) {
    my ($lit, $pos) = ($1, $-[0]); $n++;
    my @m = (substr($g, 0, $pos) =~ /\[MigrationId\] = N'([^']+)'/g);
    ($ultimo, $mig) = ($lit, $m[-1]);
  }
  $ultimo =~ s/''/'/g;
  open my $out, '>:raw', "$salida/$o.guion.sql" or die; print $out $ultimo; close $out;
  printf "%s\tversiones=%d\tultima=%s\tlargo=%d\n", $o, $n, $mig, length($ultimo);
}
