package ThisTest;
use strict;
use base qw(Test::Class);
use Test::More;
use URI::QueryParam;
use WebService::Google::Analytics;

sub _data_feed_uri : Test(7) {
    my $ga = WebService::Google::Analytics->new(table_id => 'ga:XXXXXX');

    {
        my $uri = $ga->_data_feed_uri(
            start => '2009-04-01',
            end   => '2009-04-30',
            metrics    => 'pageviews',
            dimensions => 'country',
        );
        isa_ok $uri, 'URI';
        is     $uri->query_param('ids'),        'ga:XXXXXX';
        is     $uri->query_param('start-date'), '2009-04-01';
        is     $uri->query_param('end-date'),   '2009-04-30';
        is     $uri->query_param('metrics'),    'ga:pageviews';
        is     $uri->query_param('dimensions'), 'ga:country';
    }

    {
        my $uri = $ga->_data_feed_uri(
            start => '2009-04-01',
            end   => '2009-04-30',
            metrics    => 'pageviews',
            dimensions => 'country',
            filters    => {
                pagePath => '/',
            }
        );
        is $uri->query_param('filters'), 'ga:pagePath==/';
    }
}

sub _parse_filters : Test(3) {
    my $code = WebService::Google::Analytics->can('_parse_filters');

    is   $code->({ pagePath => '/' }),           'ga:pagePath==/';
    is   $code->({ pagePath => { '=~', '/' } }), 'ga:pagePath=~/';
    like $code->({ pagePath => { '=~', '/' }, country => 'Japan' }),
         qr<^(ga:pagePath=~/;ja:country==Japan|ga:country==Japan;ga:pagePath=~/)$>
}

__PACKAGE__->runtests;

1;
