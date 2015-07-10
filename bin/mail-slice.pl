#!/usr/bin/env perl

use v5.10;

use autodie;
use strict;
use warnings;

use DBI;
use Data::Dumper;
use Path::Class;
use Time::Local;
use POSIX qw( strftime );
use URI;

use constant HOST     => 'localhost';
use constant USER     => 'weblog';
use constant PASS     => 'aksluu123u';
use constant DB       => 'weblog';
use constant MAIL_LOG => "/var/log/mail.log";

$| = 1;

my $dbh = dbh(DB);

my @spam = ();

while (<>) {
  chomp;
  die $_ unless m{^uid=(\d+) \s+ 
                  (\d\d\d\d)-(\d\d)-(\d\d) \s+ 
                  (\d\d):(\d\d):(\d\d) \s+ 
                  ([a-z0-9]+): \s+ 
                  from=<.+?>
             }xi;
  my ( $uid, $year, $month, $day, $hour, $min, $sec, $mail_id, $from )
   = ( $1, $2, $3, $4, $5, $6, $7, $8, $9 );
  my $ts = time2mysql( $year, $month, $day, $hour, $min, $sec, -3600 );
  my $uname = getpwuid($uid);
  push @spam,
   {ts      => $ts,
    uname   => $uname,
    mail_id => $mail_id
   };
}

my %mail_log = ();

{
  my $ids = join "|", sort map { $_->{mail_id} } @spam;
  my $re = qr{\b($ids)\b}i;
  open my $fh, "<", MAIL_LOG;
  while (<$fh>) {
    chomp;
    next unless $_ =~ $re;
    say $_;
    push @{ $mail_log{$1} }, $_;
  }
}

for my $rec (@spam) {
  my ( $ts, $uname, $mail_id ) = @{$rec}{ "ts", "uname", "mail_id" };
  say "";
  say "ITEM: $ts sender:$uname id:$mail_id";
  say "";
  my $log = $mail_log{$mail_id} // [];
  say for @$log;
  say "";
  my $slice = $dbh->selectall_arrayref(
    join( " ",
      "SELECT `time`, `ip`, `method`, `uri`, `status`",
      "FROM `weblog_entry`",
      "WHERE `time` BETWEEN DATE_SUB(?, INTERVAL 10 SECOND) AND DATE_ADD(?, INTERVAL 2 SECOND)",
      "ORDER BY `time`, `id`" ),
    { Slice => {} },
    $ts, $ts
  );

  for my $row (@$slice) {
    my $tick = $row->{time} lt $ts ? "<" : $row->{time} gt $ts ? ">" : "=";
    printf "%s | %s | %-15s | %-6s | %03d | %s\n",
     $tick, @{$row}{ "time", "ip", "method", "status", "uri" };
  }
}

sub time2mysql {
  my ( $year, $month, $day, $hour, $min, $sec, $adj ) = @_;
  my $time = timegm( $sec, $min, $hour, $day, $month - 1, $year ) + $adj;
  return strftime "%Y-%m-%d %H:%M:%S", gmtime $time;
}

sub dbh {
  my $db = shift;
  return DBI->connect(
    sprintf( 'DBI:mysql:database=%s;host=%s', $db, HOST ),
    USER, PASS, { RaiseError => 1 } );
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

