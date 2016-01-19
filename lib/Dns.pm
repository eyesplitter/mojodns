package Dns;
use Mojo::Base 'Mojolicious';
use Cwd;
use Mojo::Pg;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use lib 'lib/party';

has pg => sub {
  my $self = shift;
  state $pg = Mojo::Pg->new($self->config->{'db'});
  return $pg;
};

has home => sub {
    my $path = getcwd;
    return Mojo::Home->new(File::Spec->rel2abs($path));
};

has config_file => sub {
  my $self = shift;
  return $self->home->rel_file('dns.conf');
};

sub load_config {
  my $app = shift;

  $app->plugin( JSONConfig => {
    file => $app->config_file,
    default => {
      db => {
        dsn => 'dbi:Pg:host=127.0.0.1;database=dns',
        user => 'dns',
        password => 'dns',
        option => {
          pg_enable_utf8 => 1
        }
      },
      hypnotoad => {
        listen => [ "http://127.0.0.1:8080" ],
        workers => 1,
        user => 'www'
      },
      secrets => ['8d322ed7461439c77880f763c148aac4'],
    }
  });

  my $secrets = $app->config->{secrets}; 
  $app->secrets($secrets); 
}

sub startup {
  my $self = shift;

  $self->load_config;

  $self->plugin('Dns::Tools::Helpers');
  $self->plugin('Dns::Tools::Routes');

  #$self->plugin('AssetPack');
  #$self->app->asset( 
  #  "app.css" => (
  #    "/css/my.css",
  #    "/css/bootstrap.min.css",
  #    "/css/bs.sidebar.css",
  #    "/css/select2.min.css"
  #  ) 
  #);
  #$self->app->asset(
  #  "app.js" => (
  #    "/js/jquery-2.1.4.min.js",
  #    "/js/bootstrap.min.js",
  #    "/js/select2.full.min.js",
  #    "/js/bootstrapValidator.min.js",
  #    "/js/run.js"
  #  ) 
  #);
  #$self->app->asset->purge;

  $self->plugin('authentication' => {
    'autoload_user' => 1,
    'session_key' => 'sifg874hnpa9sa8dsfFnfabv8a0caab823h',
    'load_user' => sub {
      my ($app, $uid) = @_;
      my $q = $self->pg->db->query('select u.id, login, email, role_id from users u left join roles_users ru on ru.user_id = u.id where id = ?', $uid)->hash;
      return $q;
    },
    'validate_user' => sub {
      my ($app, $username, $password, $extradata) = @_; 
      my $salt_q = $self->pg->db->query('select salt from users where login = ?', $username)->hash;
      return unless($salt_q);
      my $salt = $salt_q->{salt};
      my $crypted_pass = sprintf('--%s--%s--', $salt, $password);
      my $crypted_pass_hex = sha1_hex($crypted_pass); 
      say $crypted_pass_hex;
      my $q = $self->pg->db->query('select * from users where login = ? and crypted_password = ?', $username, $crypted_pass_hex)->hash;
      return $q->{id};
    },
  });
  $self->sessions(Mojolicious::Sessions->new);
}

1;
