# Quita la sangría de 4 espacios que IndentedStringBuilder de EF agrega a las líneas 2..n del literal; normaliza a LF.
# Falla si una línea no vacía no empieza con 4 espacios (el texto no vendría del guion).
use strict; use warnings;
my ($in, $out) = @ARGV;
open my $f, '<:raw', $in or die; local $/; my $t = <$f>; close $f;
$t =~ s/\r\n/\n/g;
my @l = split /\n/, $t, -1;
for my $i (1..$#l) { next if $l[$i] eq ''; $l[$i] =~ s/^    // or die "línea ".($i+1)." sin sangría de EF en $in\n"; }
open my $o, '>:raw', $out or die; print $o join("\n", @l), "\n"; close $o;
