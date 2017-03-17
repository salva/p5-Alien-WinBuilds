package Alien::WinBuilds::Builder;

use 5.010;
use strict;
use warnings;
use Cwd ();
use Config ();
use Data::Dumper ();
use File::Spec;
use HTTP::Tiny;
use Archive::Extract;


use parent 'Module::Build';

__PACKAGE__->add_property('win_builds_mirror', 'http://win-builds.org/1.5.0/packages/windows_32/');
__PACKAGE__->add_property('win_builds_installer_url', 'http://win-builds.org/1.5.0/win-builds-1.5.0.zip');
__PACKAGE__->add_property('win_builds_installer_zip', 'win-builds-1.5.0.zip');
__PACKAGE__->add_property('win_builds_prefix', default => \&_default_win_builds_prefix);
__PACKAGE__->add_property('reinstall', 'no');

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

sub _reinstall {
    my $ov = shift->reinstall;
    return 0 if $ov =~ /^(0|n|no)$/i;
    return 1 if $ov =~ /^(1|y|yes)$/i;
    die "Invalid value for property reinstall, use 'yes' or 'no'";
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

    $self->notes(installer_dir => $installer_dir);
    $self->notes(yypkg => File::Spec->join($installer_dir, 'bin', 'yypkg.exe'));

    1;
}

sub _remove_old {
    my $self = shift;
    my $prefix = $self->win_builds_prefix;
    warn "Deleting old '$prefix' directory\n";
    system "rmdir", "/s", "/q", $prefix
        and die "rmdir failed!\n";
}

sub ACTION_install {
    my $self = shift;
    $self->SUPER::ACTION_install(@_);

    my $prefix = $self->win_builds_prefix // die "Win-Builds prefix is undefined\n";
    $self->_remove_old if -e $prefix;

    my $installer_dir = $self->notes('installer_dir') // die "installer_dir not found in notes\n";
    my $yypkg = $self->notes('yypkg') // die "yypkg not found in notes\n";
    warn "yypkg is at $yypkg\n";
    warn "Installing Win-Builds into $prefix\n";

    my $yypkg_bin_dir = File::Spec->join($prefix, 'yypkg_bin');
    my $installer_bin_dir = File::Spec->join($installer_dir, 'bin');

    my @cmds = (map([$yypkg, '--prefix', $prefix, @$_],
                    ['--init'],
                    ['--config', '--set-mirror', $self->win_builds_mirror],
                    ['--config', '--predicates', '--set', "host_system=msys"],
                    ['--config', '--predicates', '--set', "host=i686-w64-mingw32"],
                    ['--config', '--predicates', '--set', "target=i686-w64-mingw32"]),
                [xcopy => '/e', '/q', '/i', '/y', $installer_bin_dir, $yypkg_bin_dir]);
    for my $cmd (@cmds) {
        warn "Executing '@$cmd'...\n";
        system @$cmd and die "Failed! \$?: $?";
        warn "ok!\n";
    }
}

sub ACTION_code {
    my $self = shift;
    $self->SUPER::ACTION_code(@_);

    my $dir = "blib/lib/Alien/WinBuilds";
    my $file = "$dir/Config.pm";
    warn "Generating '$file'\n";

    my $prefix = $self->win_builds_prefix;
    my $yypkg = File::Spec->join($prefix, 'yypkg_bin', 'yypkg.exe');

    my %cfg = (prefix => $prefix);

    mkdir $dir;
    unless (do {local $!; -d $dir}) {
        die "Unable to create directory $dir: $!";
    }
    open my $fh, '>', "$dir/Config.pm";

    print {$fh}
        Data::Dumper->Dump([\%cfg], ['*Alien::WinBuilds::Config']), "\n",
        "1;\n";

    close $fh;

    1;
}

1;
