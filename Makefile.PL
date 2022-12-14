require 5.004;
use ExtUtils::MakeMaker;

use Config qw(%Config);

for (@ARGV) {
  /^-pm/ and $no_xs = 1;
  /^-xs/ and $no_xs = 0;
}

sub init {
  my $hash = $_[1];
  if ($no_xs) {
    @{$hash}{XS,C} = ( {}, [] );
  }
  $hash;
}

sub write_makefile {
  WriteMakefile(
    NAME         => 'Digest::CRC',
    VERSION_FROM => 'lib/Digest/CRC.pm', # finds $VERSION
    PL_FILES     => {},
    CONFIGURE    => \&init,
    clean        => {FILES => 'test.c typemap'}
  );
}

sub no_cc {
  $no_xs = 1;
  print <<"EDQ";

 I cannot determine if you have a C compiler
 so I will install a perl-only implementation

 You can force installation of the XS version with

    perl Makefile.PL -xs

EDQ
  write_makefile();
  exit;
}

if ($] < 5.006001) {
  open(TYPEMAP,">typemap");
  print TYPEMAP <<'EOS';
NV                      T_NV
UV                      T_UV

INPUT
T_NV
	$var = ($type)SvNV($arg)
T_UV
	$var = ($type)SvUV($arg)

OUTPUT
T_NV
	sv_setnv($arg, (NV)$var);
T_UV
	sv_setuv($arg, (UV)$var);

EOS
  close(TYPEMAP);
}

write_makefile();

exit if defined $no_xs;

print "Testing if you have a C compiler\n";

open(F,">test.c") or no_cc();
print F <<EOF;
int main() { return 0; }
EOF
close(F) or no_cc();
$make = $Config{make} || 'make';
system("$make test$Config{obj_ext}") and no_cc();

