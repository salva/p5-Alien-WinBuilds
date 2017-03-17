package Alien::WinBuilds::XSLoader;

use strict;
use warnings;
use 5.010;

require XSLoader;
require Alien::WinBuilds;

sub load {
    local $ENV{PATH} = Alien::WinBuilds->new->PATH_with_bin_appended;
    warn "PATH set to $ENV{PATH}";
    goto &XSLoader::load;
}

1;
