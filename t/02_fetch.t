use Test::More;
use WebService::Google::Analytics;

unless ($ENV{GA_EMAIL} && $ENV{GA_PASSWORD} && $ENV{GA_TABLE_ID}) {
    plan skip_all => 'GA_EMAIL, GA_PASSWORD, GA_TABLE_ID not set';
} else {
    plan tests => 6;
}

my $ga = WebService::Google::Analytics->new(
    table_id => $ENV{GA_TABLE_ID},
    email    => $ENV{GA_EMAIL},
    password => $ENV{GA_PASSWORD},
);

ok $ga->login;
ok $ga->authorization;

my $result = $ga->fetch_pageviews_by_region(
    start => '2009-04-01',
    end   => '2009-04-01',
    filters => { pagePath => '/' },
);

isa_ok $result, 'ARRAY';
note explain $result;

ok not defined $ga->message;

ok   !$ga->fetch_invalid_metrics_by_country(start => '2009-04-01', end => '2009-04-01');
like $ga->message, qr/Invalid value for metrics parameter/;
