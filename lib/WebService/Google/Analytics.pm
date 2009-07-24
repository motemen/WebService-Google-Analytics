package WebService::Google::Analytics;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

our $VERSION = '0.01';

use Carp;
use LWP::UserAgent;
use HTTP::Request::Common;
use URI;
use XML::LibXML;
use UNIVERSAL::isa;

__PACKAGE__->mk_accessors(qw(table_id email password ua message authorization));

sub new {
    my $class = shift;
    $class->SUPER::new({
        ua => LWP::UserAgent->new,
        @_,
    });
}

sub _request {
    my $self = shift;
    my $req  = shift;

    $self->message(undef);

    my $res = $self->ua->request($req);
    if ($res->is_error) {
        $self->message($res->content);
        return;
    }
    $res;
}

sub login {
    my $self = shift;

    my $res = $self->_request(
        POST 'https://www.google.com/accounts/ClientLogin', {
            Email       => $self->email,
            Passwd      => $self->password,
            accountType => 'GOOGLE',
            source      => "perl-webservice-google-analytics-$VERSION",
            service     => 'analytics',
        }
    ) or return;

    my ($auth) = $res->content =~ /Auth=(.+)/ or return;
    $self->authorization("GoogleLogin auth=$auth");

    1;
}

sub fetch_data {
    my $self = shift;
    my $uri = $self->_data_feed_uri(@_);

    $self->login unless $self->authorization;

    my $res = $self->_request(
        GET $uri,
        Authorization => $self->authorization,
    ) or return;

    _parse_xml($res->content);
}

sub AUTOLOAD {
    my $self = shift;
    my $method = our $AUTOLOAD;
       $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    if (my ($metric, $dimension) = $method =~ /^fetch_(\w+?)_by_(\w+)$/) {
        my $code = sub {
            my $self = shift;
            $self->fetch_data(@_, metrics => $metric, dimensions => $dimension);
        };

        no strict 'refs';
        *$method = $code;

        return $self->$code(@_);
    }

    croak "Undefined subroutine $method called";
}

sub _data_feed_uri {
    my $self = shift;
    my %args = @_;

    defined $args{$_} or croak "mandatory parameter $_ was not passed"
        foreach qw(start end metrics dimensions);

    $args{start} = $args{start}->ymd if UNIVERSAL::isa($args{start}, 'DateTime');
    $args{end}   = $args{end}->ymd   if UNIVERSAL::isa($args{end},   'DateTime');

    my $metrics    = join ',', map "ga:$_", (ref $args{metrics}    eq 'ARRAY' ? @{$args{metrics}}    : $args{metrics});
    my $dimensions = join ',', map "ga:$_", (ref $args{dimensions} eq 'ARRAY' ? @{$args{dimensions}} : $args{dimensions});

    my %query = (
        ids          => $self->table_id,
        'start-date' => $args{start},
        'end-date'   => $args{end},
        metrics      => $metrics,
        dimensions   => $dimensions,
    );

    if (my $filters = $args{filters}) {
        $query{filters} = _parse_filters($filters);
    }

    my $uri = URI->new('https://www.google.com/analytics/feeds/data');
    $uri->query_form(%query);

    $uri;
}

sub _parse_xml {
    my $string = shift;

    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_string($string);

    my @data = map { [
        map ($_->getAttribute('value'), $_->getElementsByTagName('dxp:dimension')),
        map ($_->getAttribute('value'), $_->getElementsByTagName('dxp:metric')),
    ] } $doc->getElementsByTagName('entry');

    \@data;
}

sub _parse_filters {
    my $cond = shift;
    my @filters;

    while (my ($k, $v) = each %$cond) {
        my ($op, $value) = ref $v eq 'HASH' ? %$v : ('==', $v);
        push @filters, "ga:$k" . $op . $value;
    }

    join ';', @filters; # TODO OR
}

1;

__END__

=head1 NAME

WebService::Google::Analytics - A Perl interface to Google Analytics Data Export API

=head1 SYNOPSIS

  use WebService::Google::Analytics;

  my $ga = WebService::Google::Analytics->new(table_id => $table_id, email => $email, password => $password);
  # or
  my $ga = WebService::Google::Analytics->new(table_id => $table_id, authorization => $authorization);

  $ga->fetch_data(start => '2009-04-01', end => '2009-04-30', metrics => 'pageviews', dimensions => 'country');

=head1 DESCRIPTION

WebService::Google::Analytics provides access to Google Analytics data.

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
