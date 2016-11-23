use strictures 2;
package Server::Module::Comparison;

# ABSTRACT: check perl module versions installed on servers.

use Path::Tiny;
use Moo;
use Types::Standard -types;

our $VERSION = '0.001';

has perl_path => (is => 'ro', isa => Str, default => '');
has modules => (is => 'ro', isa => ArrayRef);

sub FromModuleList
{
    my $filename = shift;
    my @modules = map { chomp; $_ } grep { !/^\s*$/ }  path($filename)->lines_utf8;
    return Server::Module::Comparison->new({ modules => \@modules });
}

sub _mversion_command
{
    my $self = shift;
    return [path($self->perl_path)->child('mversion'), '-f', @{$self->modules}, '2>&1'];
}

sub check_container
{
    my $self = shift;
    my $container = shift;
    my $cmd = "docker run --rm -i $container " . join(' ', @{$self->_mversion_command});
    return $self->_run_mversion($cmd);
}

sub check_ssh_server
{
    my $self = shift;
    my $server = shift;
    my $cmd = "ssh $server " . join(' ', @{$self->_mversion_command});
    return $self->_run_mversion($cmd);
}

sub _run_mversion
{
    my $self = shift;
    my $cmd = shift;
    #print "$cmd\n";
    open my $fh, "-|", $cmd || die 'Failed to get module list';
    my @lines = map { chomp; $_ } grep { !/^\s*$/ } <$fh>;
    close $fh;
    my %versions = map { _module_pair($_) } @lines;
    return \%versions;
}

sub _module_pair
{
    my $line = shift;
    my ($module, $version) = $line =~ /(.*) ((:?\d+(:?\.\d+)*|undef))/;
    if($module)
    {
        return ($module, $version);
    }
    else
    {
        my ($missing_module) = $line =~ /'(.*)' does not seem/;
        unless($missing_module)
        {
            print "Error: $line\n";
            return ("error", "error");
        }
        return ($missing_module, 'missing');
    }
}

1;

=head1 DESCRIPTION

A module for checking which versions of a particular list of perl modules
are installed on a server.

This relies on C<mversion> (L<Module::Version>) being installed on the server
to make querying the module version numbers simple.

This module uses system and isn't expected to defend against malicous input
at all.  It is designed as a quick and simple developer tool.

=head1 METHODS

=head2 FromModuleList

Createa a new Server::Module::Comparison object from a line delimited list of 
modules.

=head2 check_container

Run mversion in a docker container.

=head1 ATTRIBUTES

=head2 perl_path

Location of perl (and therefore also where mversion will be installed).
Set this if you have your perl installed in a non default location not
on the path.  We have ours installed to C</opt/perl5/bin> for example.

=head2 modules

The list of modules to check.  This is an array ref.

=cut