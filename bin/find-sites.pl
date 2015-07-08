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
$dbh->do("TRUNCATE `$_`")
 for 'weblog_site', 'weblog_alias', 'weblog_log';

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
    #    print Dumper($vhost);
    my $name   = $vhost->directive( -name => "ServerName" )->value;
    my $dir_dr = $vhost->directive( -name => "DocumentRoot" );
    my $doc_root = $dir_dr ? $dir_dr->value : undef;
    say "  $name $doc_root";
    $dbh->do(
      "INSERT INTO `weblog_site` (`sitename`, `hostname`, `vhost`, `root`) VALUES (?, ?, ?, ?)",
      {}, $name, $name, $vhost->value, $doc_root
    );
    my $site_id = $dbh->last_insert_id( undef, undef, undef, undef );

    my @alias
     = map { $_->value } $vhost->directive( -name => "ServerAlias" );

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
      my @info = log_info($path);
      for my $info (@info) {
        $dbh->do(
          "INSERT INTO `weblog_log` (`site_id`, `kind`, `log_dir`, `log_like`) VALUES (?, ?, ?, ?)",
          {}, $site_id, $kind, $info->{log_dir}, $info->{log_like}
        );
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

