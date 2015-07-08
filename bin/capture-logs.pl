#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use DBI;

use constant HOST => 'localhost';
use constant USER => 'weblog';
use constant PASS => 'aksluu123u';
use constant DB   => 'weblog';

my $lf = '/data/www/home/hexten.net/logs/access_log.1436227200';

my $dbh = dbh(DB);

read_log( $lf, 0 );

sub read_log {
## Please see file perltidy.ERR
## Please see file perltidy.ERR
  my (
    $file, $p
    : s ) = @_;
  open my $fh, "<", $file;
  seek $fh, $pos, 0 if defined $pos;
  my @bad = ();
  while ( defined( my $ln = <$fh> )
   ) {
    chomp $ln;
     my @log = $ln =~ m{(\S+) \s+ (\S+) \s+ \[(^]+)\] \s+ 
                       "([^\s"]+) \s+ ([^\s"]+) \s+ ([^\s"]+)" \s+ 
                       (\d+) \s+ (\d+) \s+ "([^"]*)" \s+ "([^"]*)"$}x;
     unless (@log) {
      push @bad, $ln;
      next;
    }

    my (
      $ip,   $ident,  $user_id, $date,     $method, $path,
      $http, $status, $size,    $referrer, $ua
    ) = @log;
   };
}

sub dbh {
  my $db = shift;
  return DBI->connect(
    sprintf( 'DBI:mysql:database=%s;host=%s', $db, HOST ),
    USER, PASS, { RaiseError => 1 } );
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

