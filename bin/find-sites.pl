#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use Apache::Admin::Config;
use Data::Dumper;
use DBI;
use Path::Class;

use constant HOST => 'localhost';
use constant USER => 'weblog';
use constant PASS => 'aksluu123u';
use constant DB   => 'weblog';

my $dbh = dbh(DB);

for my $conf (@ARGV) {
  load_config( $dbh, $conf );
}

sub load_config {
  my ( $dbh, $file ) = @_;
  say $file;
  my $conf = Apache::Admin::Config->new($file)
   or die $Apache::Admin::Config::ERROR;
  $dbh->do("START TRANSACTION");
  for my $vhost ( $conf->section( -name => "VirtualHost" ) ) {
    my $servername = $vhost->directive( -name => "ServerName" );
    next unless defined $servername;
    my $name     = $servername->value;
    my $dir_dr   = $vhost->directive( -name => "DocumentRoot" );
    my $doc_root = $dir_dr ? $dir_dr->value : undef;
    my $scheme   = "http";
    if ( defined( my $ssl = $vhost->directive( -name => "SSLEngine" ) ) ) {
      $scheme = "https" if $ssl->value =~ /^on$/i;
    }
    say "  $scheme://$name";

    my ($site_id)
     = $dbh->selectrow_array(
      "SELECT `id` FROM `weblog_site` WHERE `hostname` = ? AND `scheme` = ?",
      {}, $name, $scheme );

    unless ( defined $site_id ) {
      $dbh->do(
        "INSERT INTO `weblog_site` (`sitename`, `hostname`, `vhost`, `scheme`, `root`) VALUES (?, ?, ?, ?, ?)",
        {}, $name, $name, $vhost->value, $scheme, $doc_root
      );
      $site_id = $dbh->last_insert_id( undef, undef, undef, undef );
    }

    my @alias
     = map { $_->value } $vhost->directive( -name => "ServerAlias" );

    $dbh->do( "DELETE FROM `weblog_alias` WHERE `site_id` = ?",
      {}, $site_id );

    if (@alias) {
      $dbh->do(
        join( " ",
          "INSERT INTO `weblog_alias` (`site_id`, `hostname`) VALUES",
          join( ", ", map "(?, ?)", @alias ) ),
        {},
        map { $site_id, $_ } @alias
      );
    }

    my @log = ();
    for my $log ( $vhost->directive( -name => "CustomLog" ) ) {
      my ( $path, $kind ) = split /\s+/, $log->value, 2;
      $path =~ s/^"(.+)"$/$1/;
      say "  $path $kind";
      my @info = log_info($path);
      for my $info (@info) {
        my ($log_id)
         = $dbh->selectrow_array(
          "SELECT `id` FROM `weblog_log` WHERE `log_dir` = ? AND `log_like` = ?",
          {}, $info->{log_dir}, $info->{log_like} );

        unless ( defined $log_id ) {
          $dbh->do(
            "INSERT INTO `weblog_log` (`site_id`, `kind`, `log_dir`, `log_like`) VALUES (?, ?, ?, ?)",
            {}, $site_id, $kind, $info->{log_dir}, $info->{log_like}
          );
        }
      }
    }

  }
  $dbh->do("COMMIT");

}

sub log_info {
  my $log_file = file(shift);
  my @out      = ();
  my $log_dir  = $log_file->parent;
  return () unless -d $log_dir;
  my $log_like = $log_file->basename;
  push @out, { log_dir => $log_dir, log_like => qr/^\Q$log_like\E$/ }
   if -f $log_file;
  my @logs = map { $_->basename } $log_dir->children;
  push @out, { log_dir => $log_dir, log_like => qr/^\Q$log_like\E\.\d+$/ }
   if grep { /^\Q$log_like\E\.\d+$/ } @logs;
  return @out;
}

sub dbh {
  my $db = shift;
  return DBI->connect(
    sprintf( 'DBI:mysql:database=%s;host=%s', $db, HOST ),
    USER, PASS, { RaiseError => 1 } );
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

