package Alien::WinBuilds;

our $VERSION = '0.01';

use 5.010;
use strict;
use warnings;

use File::Spec;
use Alien::WinBuilds::Config;
our %Config;

sub new {
    my $class = shift;
    bless {}, $class
}

sub __path_quote {
    my $path = shift;
    $path =~ tr/"// and die q(Can't quote path containing double-quote character ("));
    return (($path =~ tr/;//) ? qq("$path") : $path);
}

sub __args {
    my $self = shift;
    my %opts = (ref $_[0] ? %{shift()} : ());
    return $self, \%opts, @_;
}

sub __PATH_append {
    my $append = join ';', map __path_quote($_), @_;
    my $PATH = $ENV{PATH};
    ((defined $PATH and length $PATH) ? "$PATH;$append" : $append)
}

sub PATH_with_yypkg_bin_appended {
    my $self = shift;
    __PATH_append($self->bin, $self->yypkg_bin);
}

sub PATH_with_bin_appended { __PATH_append(shift->bin) }

sub yypkg {
    my $self = shift;
    local $ENV{PATH} = $self->PATH_with_yypkg_bin_appended;
    system(File::Spec->join($self->yypkg_bin, 'yypkg.exe'), '--prefix', $Config{prefix}, @_) == 0;
}

sub __yes_no {
    my ($opts, $name, $default) = @_;
    my $key = $name;
    $name =~ tr/_/-/;
    return ("--$name", (($opts->{$name} // $default) ? 'yes' : 'no'))
}

sub web {
    my ($self, $opts, @pkgs) = &__args;
    $self->yypkg('--web',
                  __yes_no($opts, auto => 1),
                  __yes_no($opts, follow_dependencies => 1),
                  '--packages', @pkgs);
}

sub prefix    { $Config{prefix} }
sub include   { File::Spec->join($Config{prefix}, 'include'  ) }
sub bin       { File::Spec->join($Config{prefix}, 'bin'      ) }
sub lib       { File::Spec->join($Config{prefix}, 'lib'      ) }
sub yypkg_bin { File::Spec->join($Config{prefix}, 'yypkg_bin') }

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Alien::WinBuilds - Install and use binary packages from Win-Builds

=head1 SYNOPSIS

  use Alien::WinBuilds;
  my $awb = Alien::WinBuilds->new;
  $awb->web('win-iconv', 'gettext');

  my $include = $awb->include;
  my $lib = $awb->lib;
  my $bin = $awb->bin;

  WriteMakefile(...,
                LIBS => "-L$lib -l$foo",
                INC => '-I$include');


  # Then, from the "pm" file...
  package MyPackage;
  $VERSION = '0.01';

  BEGIN {
    require Alien::WinBuilds::XSLoader;
    Alien::WinBuilds::XSLoader::load(__PACKAGE__, $VERSION);
  }

=head1 DESCRIPTION

Win-Builds is a project that builds packages of common open source
libraries and programs for MS Windows.

Alien::WinBuilds allows to download those packages so that they can be
used from Perl modules and programs.

=head2 API

=over 4

=item $amb = Alien::WinBuilds->new

=item $amb->web(@packages)

Install the packages of the given names.

(the method name comes from the C<yypkg> action name)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Salvador FandiE<ntilde>o (sfandino@yahoo.com).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
