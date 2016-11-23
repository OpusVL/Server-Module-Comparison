use Test::Most;
use Server::Module::Comparison;

ok my $comparer = Server::Module::Comparison->new({ 
        perl_path => '/opt/perl5/bin',
        modules => [qw/OpusVL::CMS OpusVL::FB11X::CMSView OpusVL::FB11X::CMS/] 
    });
ok my $versions = $comparer->check_container('quay.io/opusvl/prem-website:staging');
ok my $versions2 = $comparer->check_container('quay.io/opusvl/prem-website:live');
explain $versions;

eq_or_diff $versions, $versions2;


done_testing;
