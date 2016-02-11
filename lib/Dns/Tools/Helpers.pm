package Dns::Tools::Helpers;

use strict;
use warnings;

use base 'Mojolicious::Plugin';
use Mojo::Base 'Mojolicious';
use Data::Dumper qw( Dumper );
use Mojo::JSON qw(decode_json encode_json);
use Net::IDN::Encode ':all';

sub register {
  my ($c, $app) = @_;

  $app->helper( make_my_date => sub {
    my ( $c, $date ) = @_;
    $date=~/^(\d{4})-(\d{2})-(\d{2})/;
    my $res=sprintf("%02d.%02d.%02d",$3,$2,$1);
    return $res;
  });

  $app->helper( make_my_time => sub {
    my ($c, $time) = @_;
    $time =~/^(\d{4})-(\d{2})-(\d{2})\W(\d{2}):(\d{2})/;
    my $res = sprintf("%02d.%02d.%d %02d:%02d",$3,$2,$1,$4,$5);
    return $res;
  });

  $app->helper( make_my_interval => sub {
    my ($c, $interval) = @_;
    my $loc;
    $loc->{1} = {
      day => 'день',
      mon => 'месяц',
      year => 'год'
    };
    $loc->{2} = {
      day => 'дня',
      mon => 'месяца',
      year => 'года',
      days => 'дня',
      mons => 'месяца',
      years => 'года'
    };
    $loc->{5} = {
      day => 'дней',
      mon => 'месяцев',
      year => 'лет',
      days => 'дней',
      mons => 'месяцев',
      years => 'лет'
    };
    $interval =~/^(\d+)\W(\w+)$/;
    my $digits = $1;
    my $word = $2;
    $digits =~ /(\d)$/;
    my $l;
    if($1 == 1 ) {
      $l = 1;
    }elsif($1 > 1 and $1 < 5){
      $l = 2;
    }elsif($1 >= 5 and $1 <= 9 or $1 == 0){
      $l = 5;
    }
    if($digits >= 10 and $digits <= 20){
      $l = 5;
    }
    my $res = sprintf("%d %s",$digits,$loc->{$l}->{$word});
    return $res;
  });

  $app->helper( hist => sub {
    my ($c, $target, $type ,$message) = @_;
    $c->app->pg->db->query("insert into history(user_id,target_id,target_type,t,message) values(?,?,?,?,?)",
      $c->session->{user}->{id}, $target, $type, 'now()', $message);
    return 1;
  });

  $app->helper( upgrade_serial => sub {
    my ($c, $domain_id) = @_;
    my $soa = $c->app->pg->db->query("select id,content from records where domain_id = ? and type = 'SOA'", $domain_id)->hash;
    my @parts = split(' ', $soa->{content});

    my (undef,undef,undef,$mday,$mon,$year,undef,undef,undef) = localtime();
    my $current_date = sprintf("%04d%02d%02d", $year+1900, $mon+1, $mday);

    if ($current_date*100 < $parts[2]){
      $parts[2] += 1;
      $c->app->pg->db->query("update records set content = ? where id = ?", join(' ', @parts), $soa->{id});
      return 1;
    }

    my $serial = $parts[2];

    unless ($serial =~/^\d{10}$/){
      $parts[2] = sprintf("%s%02d",$current_date, 00);
      $c->app->pg->db->query("update records set content = ? where id = ?", join(' ', @parts), $soa->{id});
      return 1;
    }

    my $number = substr $serial, 8, 2;
    my $serial_date = substr $serial, 0, 8; 
    $number += 1;

    if ($serial_date ne $current_date){
      $serial_date = $current_date;
      $number = sprintf("00");
    }

    $parts[2] = sprintf("%s%02d",$serial_date, $number);
    $c->app->pg->db->query("update records set content = ? where id = ?", join(' ', @parts), $soa->{id});
    return 1;
  });

  $app->helper( rename => sub {
    my ( $c, $record, $domain ) = @_;
    return '@' if ($record eq $domain);
    $record =~ /^(\S+)\.$domain$/;
    return domain_to_unicode($1);
  });

  $app->helper( to_unicode => sub {
    my ( $c, $data ) = @_;
    $data = domain_to_unicode($data) if ($data =~/xn--.+/i);
    return $data;
  });

  $app->helper( to_ascii => sub {
    my ( $c, $data ) = @_;
    $data = domain_to_ascii($data);
    return $data;
  });

}

1;
