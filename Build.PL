#! perl

use 5.010;
use strict;
use warnings;

use lib 'inc';
use Alien::WinBuilds::Builder;

$^O =~ /^MSWin32/i or die "Alien::WinBuilds can only be installed on MS Windows operating systems";

my $builder = Alien::WinBuilds::Builder->new(module_name => 'Alien::WinBuilds',
                                             license     => 'perl',
                                             requires    => { 'perl'          => '5.10.0' } );

warn "Win-Builds installation directory: " . $builder->win_builds_prefix . "\n";

$builder->create_build_script;





