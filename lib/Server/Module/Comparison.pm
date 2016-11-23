use strictures 2;
package Server::Module::Comparison;

use Path::Tiny;
use Moo;
use Types::Standard -types;

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
