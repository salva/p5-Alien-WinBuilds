package Alien::WinBuilds::Builder;

use 5.010;
use strict;
use warnings;
use Cwd ();
use Config ();
use File::Spec;
use HTTP::Tiny;
use Archive::Extract;

use parent 'Module::Build';

__PACKAGE__->add_property('win_builds_mirror', 'http://win-builds.org/1.5.0/packages/windows_32/');
__PACKAGE__->add_property('win_builds_installer_url', 'http://win-builds.org/1.5.0/win-builds-1.5.0.zip');
__PACKAGE__->add_property('win_builds_installer_zip', 'win-builds-1.5.0.zip');
__PACKAGE__->add_property('win_builds_prefix', default => \&_default_win_builds_prefix);

sub _default_win_builds_prefix {
    my @path = File::Spec->splitdir(File::Spec->rel2abs(Cwd::realpath($^X)));
    pop @path; # c:\strawberry\perl\bin -> perl.exe
    pop @path; # c:\strawberry\perl -> bin
    my $uname = $Config::Config{myuname} // '';
    if ($uname =~ /^Win32\s+strawberry-perl\b/i) {
        pop @path; # c:\strawberry -> perl
    }
    File::Spec->catdir(@path, 'win-builds');
}

sub ACTION_build {
    my $self = shift;
    $self->SUPER::ACTION_build(@_);

    my $ua = HTTP::Tiny->new;
    my $url = $self->win_builds_installer_url;
    my $zip = $self->win_builds_installer_zip;

    warn "Downloading $url\n";
    my $res = $ua->mirror($url, $zip);
    $res->{success} or die "Unable to download $url: [$res->{status}] $res->{reason}";

    warn "Extracting installer $zip\n";
    my $ae = Archive::Extract->new(archive => $zip);
    $ae->extract or die "Unable to extract $zip: " . $ae->error . "\n";

    my $installer_dir = $ae->extract_path;
    #"$installer_dir.zip" eq $zip or die "Installer unpacked at an unexpected location: $installer_dir";

    $self->notes(yypkg_path => File::Spec->join($installer_dir, 'bin', 'yypkg.exe'));
}

sub ACTION_install {
    my $self = shift;
    $self->SUPER::ACTION_install(@_);

    my $prefix = $self->win_builds_prefix // die "Win-Builds prefix is undefined\n";
    if (-e $prefix) {
        die "The directory $prefix already exists. Aborting!\n";
    }

    my $yypkg = $self->notes('yypkg_path') // die "yypkg_path not found in notes\n";
    warn "yypkg is at $yypkg\n";
    warn "Installing Win-Builds into $prefix\n";

    for my $cmd (['--init'],
                 ['--config', '--set-mirror', $self->win_builds_mirror],
                 ['--config', '--predicates', '--set', "host_system=msys"],
                 ['--config', '--predicates', '--set', "host=i686-w64-mingw32"],
                 ['--config', '--predicates', '--set', "target=i686-w64-mingw32"]) {
        my @cmd = ($yypkg, '--prefix', $prefix, @$cmd);
        warn "Executing '@cmd'...\n";
        system @cmd and die "Failed! \$?: $?";
        warn "ok!\n";
    }
}

1;
