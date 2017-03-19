#! perl

use 5.010;
use strict;
use warnings;

use lib 'inc';
use Alien::WinBuilds::Builder;

$^O =~ /^MSWin32/i or die "Alien::WinBuilds can only be installed on MS Windows operating systems";

my $builder = Alien::WinBuilds::Builder->new(module_name => 'Alien::WinBuilds',
                                             license     => 'perl',
                                             requires    => { 'perl' => '5.10.0' });

my $prefix = $builder->win_builds_prefix;

warn "Win-Builds installation directory: '$prefix'\n";
if (-e $prefix) {
    #unless ($builder->_reinstall) {
    #    die "Directory $prefix already exists, aborting installation.\n".
    #        "You can use 'reinstall=yes' to force reinstallation. Note that any previously installed package will be removed.\n";
    #}
    #warn "Directory '$prefix' already exists but you have forced reinstallation\n";
}

$builder->create_build_script;
