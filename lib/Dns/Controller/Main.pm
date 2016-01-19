package Dns::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper qw( Dumper );

sub auth {
  my $c = shift;
  $c->render;
}

1;
