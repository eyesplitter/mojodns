package Dns::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';
use Mojolicious::Validator;
use Data::Dumper qw( Dumper );
use Digest::MD5 qw(md5 md5_hex md5_base64);


sub check {
  my $c = shift;
  $c->redirect_to('/') and return 0 unless($c->is_user_authenticated);
  return 1;
}

sub check_admin {
  my $c = shift; 
  if ($c->session->{'user'}->{role_id} == 1){
    return 1;
  }else{
    $c->res->code(404); 
    $c->res->message('Not Found');  
    $c->render(text => '404');
    return;
  }
}

sub check_owner {
  my $c = shift; 
  my $user_id = $c->session->{user}->{id};
  my $db = $c->app->pg->db;
  my $domain_id;
  $domain_id = $c->req->url->path->parts->[1] if ($c->req->url->path->parts->[0] eq 'domain');
  
  if ($c->req->url->path->parts->[0] eq 'record') {
    my $record_id = $c->req->url->path->parts->[1] if ($c->req->url->path->parts->[1]);
    $domain_id = $db->query("select domain_id from records where id = ?", $record_id)->hash->{domain_id} if($record_id);
    say $domain_id;
  }

  unless($domain_id){
    say 'no domain_id'; 
    $c->res->code(404); 
    $c->res->message('Not Found');  
    $c->render(text => '404');
    return;
  }

  return 1 if ($c->session->{'user'}->{role_id} == 1);
  my $access_to = $db->query("select domain_id from user_access where user_id = ?", $user_id)->hashes;
  foreach ( @{$access_to}){
    return 1 if ($_->{domain_id} == $domain_id);
  }
  say 'no one';
  $c->res->code(404); 
  $c->res->message('Not Found');  
  $c->render(text => '404');
  return 0;
}


sub signin {
    my $c = shift;
		my @errors;
    if ($c->authenticate($c->param('user'), $c->param('pass'))) {
        $c->session->{'user'}=$c->current_user();
        $c->redirect_to('/dns');
    }else{
		    push(@errors,'Login incorrect');
        $c->flash(error_msg=>\@errors);
        $c->redirect_to("/");
    }
}

sub logoff {
    my $c = shift;
    $c->logout();
    delete $c->session->{'user'};
    $c->redirect_to("/");
}

1;
