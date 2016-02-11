package Dns::Controller::User;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper qw( Dumper );
use Net::IDN::Encode ':all';
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);

sub index {
  my $c = shift;
  my $db = $c->app->pg->db;

  my $domains;
  my $domain_group;
  my $domains_collection;
  if($c->session->{user}->{role_id} == 1){
    $domains_collection = $db->query('select u.login, u.email, d.* from domains d left join users u on u.id = d.user_id')->hashes;
  }else{
    $domains_collection = $db->query('select u.login, u.email, d.* from domains d left join users u on u.id = d.user_id where d.user_id = ? or d.id in (select domain_id from user_access where user_id = ?)', $c->session->{user}->{id}, $c->session->{user}->{id})->hashes;
  }
  $domains_collection->each(sub {
    my ($e, $num) = @_;
    $e->{name} = domain_to_unicode($e->{name}) if ($e->{name} =~/xn--.+/i);
    $domains->{$e->{name}} = $e;
    $e->{login} = '_no owner' unless ($e->{login});
    push(@{$domain_group->{$e->{login}}}, { id => $e->{id}, name => $e->{name} });
  });

  my $users;
  my $users_collection;
  if($c->session->{user}->{role_id} == 1){
    $users_collection = $db->query('select u.id as u_id, u.login, u.email, u.created_at, r.name from users u left join roles_users ur on u.id = ur.user_id left join roles r on r.id = ur.role_id;')->hashes;
    $users = $users_collection->to_array;
  }
  
  $c->stash(
    domains => $domains,
    domain_group => $domain_group,
    users => $users
  );
  $c->render;
}

sub user_create {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $p = $c->req->params->to_hash;
  my $salt = sprintf("oPsa-3-lt%s", localtime );
  my $salt_hex = sha1_hex($salt);
  my $pass_with_salt = "--$salt_hex--$p->{'nu-password'}--";
  my $pass_hex = sha1_hex($pass_with_salt);
  $db->query("insert into users (login, email, crypted_password, salt, created_at, state) values (?,?,?,?,?,?)", $p->{'nu-name'}, $p->{'nu-email'}, $pass_hex, $salt_hex, 'now()', 'active');
  my $user_id = $db->query("select id from users where login = ?", $p->{'nu-name'})->hash->{id};
  my $role = 2;
  $role = 1 if ($p->{'nu-privelege'} eq 'admin');
  $db->query("insert into roles_users (role_id, user_id) values (?,?)", $role, $user_id);
  $c->helpers->hist(undef,'user',sprintf("Create user %s",$p->{'nu-name'}));
  $c->redirect_to('/dns#s-user-create');
}

sub user_check_username {
  my $c = shift;
  my $p = $c->req->params->to_hash;
  my $usernames = $c->app->pg->db->query("select id from users where login = ? ", $p->{'nu-name'})->hash;
  return $c->render( json => {valid =>  'false'}) if ($usernames);
  $c->render( json => {valid =>  'true'});
}

sub user_edit {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $user_id = $c->stash->{user_id};
  my $user = $db->query("select u.*, ru.role_id from users u left join roles_users ru on u.id = ru.user_id where id = ?", $user_id)->hash;
  $c->stash(user => $user);
  $c->render;
}

sub user_update {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $user_id = $c->stash->{user_id};
  my $p = $c->req->params->to_hash;
  if($p->{'nu-privelege'} and $p->{'nu-email'}){
    $db->query('update users set email = ? where id = ?', $p->{'nu-email'}, $user_id);
    $db->query('update roles_users set role_id = ? where user_id = ?', $p->{'nu-privelege'} eq 'owner'?2:1, $user_id);
    $c->helpers->hist($user_id,'user','Update user profile');
  }
  if($p->{'nu-password'} and $p->{'nu-repassword'}){
    my $salt_hex = $db->query("select salt from users where id = ?", $user_id)->hash->{salt};
    my $pass_with_salt = "--$salt_hex--$p->{'nu-password'}--";
    my $pass_hex = sha1_hex($pass_with_salt);
    $db->query('update users set crypted_password = ? where id = ?', $pass_hex, $user_id);
    $c->helpers->hist($user_id,'user','Update user password');
  }
  $c->redirect_to("/user/$user_id/edit");
}

sub user_delete {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $user_id = $c->stash->{user_id};

  my $username = $db->query('select login from users where id = ?', $user_id)->hash->{login};
  $db->query('delete from users where id= ?', $user_id);
  $db->query('delete from roles_users where user_id= ?', $user_id);
  $c->redirect_to("/dns#s-user-list");
  $c->helpers->hist(undef,'user',sprintf("Delete user %s",$username));
}

sub domain_create {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $p = $c->req->params->to_hash;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  my $serial_date = sprintf("%04d%02d%02d", $year+1900, $mon+1, $mday);
  my $serials = $db->query("select notified_serial from domains where notified_serial::varchar like ?", $serial_date.'%')->hashes->size;
  my $notified_serial = sprintf("%s%02d", $serial_date, $serials);
  $db->query("insert into domains (name, master, type, notified_serial, ttl, created_at, user_id) values(?,?,?,?,?,?,?)",
    $p->{'nd-name'}, '195.3.252.33', $p->{'nd-type'} eq 'master'?'MASTER':'SLAVE', $notified_serial, '86400', 'now()', $c->session->{user}->{id});
  my $new_domain_id = $db->query('select id from domains where name = ?', $p->{'nd-name'})->hash->{id};
  my $content = sprintf("%s %s %s %d %d %d %d", $p->{'nd-ns'}, $p->{'nd-contact'}, $notified_serial, $p->{'nd-refresh'}, $p->{'nd-retry'}, $p->{'nd-expire'}, $p->{'nd-minimum'});
  $db->query('insert into records(domain_id, name, type, content, ttl, created_at) values (?,?,?,?,?,?)', $new_domain_id, $p->{'nd-name'}, 'SOA', $content, '86400', 'now()');
  $c->helpers->hist(undef,'domain',sprintf("Create domain %s",$p->{'nd-name'}));
  $c->redirect_to("/dns#s-domain-list-$new_domain_id");
}

sub domain_edit {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $domain_id = $c->stash->{domain_id};

  my $domain = $db->query('select * from domains where id = ?', $domain_id)->hash;
  my $soa = $db->query("select * from records where domain_id = ? and type='SOA'", $domain_id)->hash;

  $c->stash( domain => $domain, soa => $soa );
  $c->render;
}

sub domain_history {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $domain_id = $c->stash->{domain_id};

  my $domain = $db->query('select * from domains where id = ?', $domain_id)->hash;

  my $history = $db->query("select * from history h left join users u on u.id = h.user_id where target_type = 'domain' and target_id = ?", $domain_id)->hashes;
  $c->stash( domain => $domain,  history => $history);
  $c->render;
}

sub domain_update {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $domain_id = $c->stash->{domain_id};
  my $p = $c->req->params->to_hash;

  $db->query('update domains set name = ? where id = ?', $p->{'nd-name'}, $domain_id);
  $c->helpers->hist($domain_id,'domain','Update domain');
  # serial
  $c->helpers->upgrade_serial($domain_id);
  $c->redirect_to("/domain/$domain_id/edit");
}

sub domain_record {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $domain_id = $c->stash->{domain_id};
  
  my $domain = $db->query('select * from domains where id = ?', $domain_id)->hash;
  my $owner="no owner";
  if($domain->{user_id}){
    $owner = $db->query('select * from users where id = ?', $domain->{user_id})->hash;
    $owner = $owner->{login} if($owner);
  }

  my $record_collection = $db->query('select * from records where domain_id = ?', $domain_id)->hashes;
  my $record;
  my @soa;
  $record_collection->each(sub {
    my ($e, $num) = @_;
    $e->{name} = domain_to_unicode($e->{name}) if ($e->{name} =~/xn--.+/i);
    if($e->{type} eq 'SOA'){
      @soa = split(' ', $e->{content});
      
    }else{
      push (@{$record}, $e);
    }
  });
  my @record_types = ('A', 'AAAA', 'CNAME', 'LOC', 'MX', 'NS', 'PTR', 'SPF', 'SRV', 'TXT');
  $c->stash( domain => $domain, record => $record, owner => $owner, soa => \@soa, types => \@record_types );
  $c->render;
}

sub record_create {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $p = $c->req->params->to_hash;
  my $domain_id = $c->stash->{domain_id};

  my $prio = undef;
  $prio = $p->{'nr-prio'} if ($p->{'nr-type'} eq 'MX' or $p->{'nr-type'} eq 'SRV');
  $db->query("insert into records(domain_id, name, type, content, ttl, prio, created_at) values (?,?,?,?,?,?,?)", $domain_id, $p->{'nr-host'}, $p->{'nr-type'}, $p->{'nr-data'}, $p->{'nr-ttl'}, $prio, 'now()');

  $c->helpers->hist($domain_id,'domain',sprintf('Create record %s', $p->{'nr-host'}));
  $c->helpers->upgrade_serial($domain_id);
  $c->redirect_to("/domain/$domain_id/record");
}

sub record_delete {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $record_id = $c->stash->{record_id};
  my $domain_id = $db->query("select domain_id from records where id =?", $record_id)->hash->{domain_id};
  my $recordname = $db->query("select name from records where id = ?", $record_id)->hash->{name};

  $db->query("delete from records where id = ?", $record_id);
  $c->helpers->hist($domain_id,'domain',sprintf('Delete record %s', $recordname));
  $c->helpers->upgrade_serial($domain_id);
  $c->redirect_to("/domain/$domain_id/record");
}

sub record_edit {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $record_id = $c->stash->{record_id};

  my $record = $db->query("select * from records where id = ?", $record_id)->hash;
  my $domain = $db->query("select * from domains where id = ?", $record->{domain_id})->hash;
  $c->stash(record => $record, domain => $domain);
  $c->render;
}

sub record_save {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $record_id = $c->stash->{record_id};
  my $p = $c->req->params->to_hash;
  my $domain_id = $db->query("select domain_id from records where id =?", $record_id)->hash->{domain_id};

  my $prio = undef;
  $prio = $p->{'nr-prio'} if $p->{'nr-prio'};
  $db->query("update records set content = ?, ttl = ?, name = ?, prio = ? where id = ?", $p->{'nr-data'}, $p->{'nr-ttl'}, $p->{'nr-host'}, $prio, $record_id);

  $c->helpers->hist($domain_id,'domain',sprintf('Update record %s', $p->{'nr-host'}));
  $c->helpers->upgrade_serial($domain_id);
  $c->redirect_to("/record/$record_id/edit");
}

sub domain_priveleges {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $domain_id = $c->stash->{domain_id};
  
  my $domain = $db->query('select * from domains where id = ?', $domain_id)->hash;
  my $users_q = $db->query('select * from users')->hashes;
  my $managers = $db->query('select * from user_access where domain_id = ?', $domain_id)->hashes;

  my $mgt;
  $managers->each(sub {
    my ($e, $num) = @_;
    $mgt->{$e->{user_id}} = 1;
  });

  my $users;
  $users_q->each(sub {
    my ($e, $num) = @_;
    next if ($e->{id} == $c->session->{user}->{id});
    $users->{$e->{id}}->{name} = $e->{login};
    $users->{$e->{id}}->{mgt} = $mgt->{$e->{id}}?$mgt->{$e->{id}}:0;
  });
  
  $c->stash( domain => $domain, users => $users);
  $c->render;
}

sub domain_priveleges_save {
  my $c = shift;
  my $db = $c->app->pg->db;
  my $domain_id = $c->stash->{domain_id};
  my $user_id = $c->stash->{user_id};
  my $username = $db->query('select login from users where id = ?', $user_id)->hash->{login};

  my $access = $db->query('select * from user_access where user_id = ? and domain_id = ?', $user_id, $domain_id)->hash;
  if($access){
    $c->helpers->hist($domain_id,'domain',sprintf('Remove privelege to user %s',$username));
    $db->query("delete from user_access where user_id = ? and domain_id = ?", $user_id, $domain_id);
  }else{
    $c->helpers->hist($domain_id,'domain',sprintf('Grant privelege to user %s',$username));
    $db->query("insert into user_access(user_id,domain_id,t) values(?,?,?)", $user_id, $domain_id, 'now()');
  }
  $c->redirect_to("/domain/$domain_id/priveleges");
}


1;
