package Plack::Middleware::Status;

# ABSTRACT: Plack Middleware for mapping urls to status code-driven responses
use strict;
use parent qw/Plack::Middleware/;
use HTTP::Status;
use Plack::Util::Accessor qw( path status );
use Carp;

=head1 SYNOPSIS

    # app.psgi
    use Plack::Builder;
    my $app = sub { 
        # ... 
    };
    builder {
        enable 'Status', path => qr{/not-implemented}, status => 501;
        $app;
    };
    
=cut

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->_handle($env);
    return $res if $res;

    return $self->app->($env);
}

sub _handle {
    my ( $self, $env ) = @_;

    my $path_match = $self->path;
    my $status     = $self->status;
    my $path       = $env->{PATH_INFO};
    for ($path) {
        my $matched = 'CODE' eq ref $path_match ? $path_match->($_) : $_ =~ $path_match;
        return unless $matched;
    }

    my $message = HTTP::Status::status_message($status) or do {
        carp "Invalid HTTP status: $status";
        return;
    };

    return [ $status, [ 'Content-Type' => 'text/plain', 'Content-Length' => length($message) ], [$message] ];
}

1;
