package Dns::Tools::Routes;

use strict;
use warnings;

use base 'Mojolicious::Plugin';
use Mojo::Base 'Mojolicious';
use Data::Dumper qw( Dumper );

sub register {
  my ($c, $app) = @_;

  my $r = $app->routes;
  $r->get('/')->to('main#auth');
  $r->post('/')->to('auth#signin');

  my $user = $r->under('/')->to('auth#check');
  $user->get('/logout')->to('auth#logoff');
  $user->get('/dns')->to('user#index')->name('index');

  $user->post('/domain/create')->to('user#domain_create')->name('create new domain');


  my $domain = $r->under('/')->to('auth#check_owner');
  $domain->get('/domain/:domain_id/record')->to('user#domain_record');
  $domain->get('/domain/:domain_id/edit')->to('user#domain_edit');
  $domain->get('/domain/:domain_id/history')->to('user#domain_history');
  $domain->get('/domain/:domain_id/delete')->to('user#domain_delete');
  $domain->get('/domain/:domain_id/priveleges')->to('user#domain_priveleges');
  $domain->get('/domain/:domain_id/priveleges/:user_id/access')->to('user#domain_priveleges_save');
  $domain->post('/domain/:domain_id/new_record')->to('user#record_create')->name('new record');
  $domain->get('/record/:record_id/delete')->to('user#record_delete');
  $domain->get('/record/:record_id/edit')->to('user#record_edit');
  $domain->post('/record/:record_id/save')->to('user#record_save');
  $domain->post('/domain/:domain_id/update')->to('user#domain_update')->name('update domain');



  my $admin = $r->under('/user')->to('auth#check_admin');
  $admin->get('/:user_id/edit')->to('user#user_edit');
  $admin->get('/:user_id/history')->to('user#user_history');
  $admin->get('/:user_id/delete')->to('user#user_delete');
  $admin->post('/check/username')->to('user#user_check_username')->name('check username');
  $admin->post('/create')->to('user#user_create')->name('create new user');
  $admin->post('/:user_id/update')->to('user#user_update')->name('update user');

}

1;
