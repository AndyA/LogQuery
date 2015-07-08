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

use constant HOST => 'localhost';
use constant USER => 'weblog';
use constant PASS => 'aksluu123u';
use constant DB   => 'weblog';

my $dbh = dbh(DB);

my %MONTH = (
  Jan => 0,
  Feb => 1,
  Mar => 2,
  Apr => 3,
  May => 4,
  Jun => 5,
  Jul => 6,
  Aug => 7,
  Sep => 8,
  Oct => 9,
  Nov => 10,
  Dec => 11
);

my %HANDLER = ( combined => \&handle_combined );

#say time2mysql("08/Jul/2015:01:05:33 +0100");
#exit;

capture_logs($dbh);

sub capture_logs {
  my $dbh     = shift;
  my $by_id   = "ORDER BY `id`";
  my $sites   = sel( $dbh, "SELECT * FROM `weblog_site` $by_id" );
  my $aliases = sel( $dbh, "SELECT * FROM `weblog_alias` $by_id" );
  my $logs    = sel( $dbh, "SELECT * FROM `weblog_log` $by_id" );
  my $files   = sel(
    $dbh, join " ",
    "SELECT * FROM `weblog_file`",
    "ORDER BY `filename`"
  );
  merge( $logs,  "id", files   => group( log_id  => $files ) );
  merge( $sites, "id", logs    => group( site_id => $logs ) );
  merge( $sites, "id", aliases => group( site_id => $aliases ) );

  for my $site (@$sites) {
    update_logs( $dbh, $site );
  }
}

sub update_logs {
  my ( $dbh, $site ) = @_;
  say $site->{sitename};
  for my $log ( @{ $site->{logs} } ) {
    my $handler = $HANDLER{ $log->{kind} };
    next unless defined $handler;
    my $like  = $log->{log_like};
    my %known = map { $_->{filename} => $_->{pos} } @{ $log->{files} };
    my %files = map { $_ => 0 } grep { /$like/ } read_dir( $log->{log_dir} );

    $dbh->do("START TRANSACTION");

    my @gone = diffkeys( \%known, \%files );
    if (@gone) {
      $dbh->do(
        join( " ",
          "DELETE FROM `weblog_file` WHERE `log_id` = ? AND `filename` IN (",
          join( ", ", map "?", @gone ), ")" ),
        {},
        $log->{id},
        @gone
      );
      delete @known{@gone};
    }

    my %pos = ( %files, %known );
    for my $file ( sort keys %pos ) {
      $pos{$file} = $handler->(
        $site, $dbh, $log->{id}, file( $log->{log_dir}, $file ),
        $pos{$file}
      );
    }
    if ( keys %pos ) {
      $dbh->do(
        join( " ",
          "REPLACE INTO `weblog_file` (`log_id`, `filename`, `pos`) VALUES",
          join( ", ", map "(?, ?, ?)", keys %pos ) ),
        {},
        map { $log->{id}, $_, $pos{$_} } keys %pos
      );
    }
    $dbh->do("COMMIT");
  }
}

sub time2mysql {
  my $tm = shift;
  die unless $tm =~ m{^ 
     (\d\d) / (\w+) / (\d{4}) : (\d\d) : (\d\d) : (\d\d) 
     \s+ ([-+]) (\d\d) (\d\d) $}x;
  my $tz = ( $8 * 60 + $9 ) * 60;
  $tz = -$tz if $7 eq "-";
  my $time = timegm( $6, $5, $4, $1, $MONTH{$2} // die, $3 ) - $tz;
  return strftime "%Y-%m-%d %H-%M-%S", gmtime $time;
}

sub handle_combined {
  my ( $site, $dbh, $log_id, $file, $pos ) = @_;
  say "  $file ($pos)";
  my $fh = $file->openr;
  $fh->seek( $pos, 0 ) if defined $pos;
  my @bad   = ();
  my @chunk = ();
  my %extra = (
    day  => [WEEKDAY => 'time'],
    date => [DATE    => 'time'],
    hour => [HOUR    => 'time']
  );
  my $flush = sub {
    return unless @chunk;
    my @keys  = sort keys %{ $chunk[0] };
    my @xkeys = sort keys %extra;
    my @xvals = map { $extra{$_}[1] } @xkeys;
    my $vals  = join ", ", ( map "?", @keys ),
     ( map $extra{$_}[0] . "(?)", @xkeys );
    $dbh->do(
      join( " ",
        "INSERT INTO `weblog_entry` (",
        join( ", ", map "`$_`", @keys, @xkeys ),
        ") VALUES ",
        join( ", ", map "($vals)", @chunk ) ),
      {},
      map { @{$_}{ @keys, @xvals } } @chunk
    );
    @chunk = ();
  };
  while ( defined( my $ln = <$fh> ) ) {
    chomp $ln;
    my @log = (
      $ln =~ m{^(\S+) \s+ (\S+) \s+ (\S+) \s+ \[([^\]]+)\] \s+ 
                "([^\s"]+) \s+ ([^\s"]+) \s+ ([^\s"]+)" \s+ 
                (\d+) \s+ (\d+) \s+ "([^"]*)" \s+ "([^"]*)"$ }x
    );
    unless (@log) {
      push @bad, $ln;
      next;
    }

    my (
      $ip,   $ident,  $user_id, $time,     $method, $path,
      $http, $status, $size,    $referrer, $ua
    ) = @log;

    my $uri
     = URI->new( $site->{scheme} . "://" . $site->{hostname} . $path );
    $uri->port($1) if $site->{vhost} =~ /:(\d+)$/;
    $uri = $uri->canonical;
    my $uri_no_query = $uri->clone;
    $uri_no_query->query(undef);

    push @chunk,
     {log_id        => $log_id,
      ip            => $ip,
      ident         => $ident,
      user_id       => $user_id,
      time          => time2mysql($time),
      method        => $method,
      path          => substr( $path, 0, 255 ),
      path_full     => $path,
      http_version  => $http,
      status        => $status,
      size          => $size,
      referrer      => substr( $referrer, 0, 255 ),
      referrer_full => $referrer,
      user_agent    => $ua,
      uri           => "$uri",
      uri_no_query  => "$uri_no_query"
     };
    $flush->() if @chunk >= 1000;
  }
  $flush->();
  return $fh->tell;
}

sub read_dir {
  my $dir = dir(shift);
  state %cache;
  my $name = "$dir";
  return @{ $cache{$name} //= [map { $_->basename } $dir->children] };
}

sub diffkeys {
  my ( $ha, $hb ) = @_;
  my %k = map { $_ => 1 } keys %$ha;
  delete $k{$_} for keys %$hb;
  return keys %k;
}

sub merge {
  my ( $array, $key, $fld, $stash ) = @_;
  for my $row (@$array) {
    $row->{$fld} = delete $stash->{ $row->{$key} } || [];
  }
  return $array;
}

sub sel {
  my ( $dbh, $sql, @bind ) = @_;
  $dbh->selectall_arrayref( $sql, { Slice => {} }, @bind );
}

sub group {
  my ( $key, $array ) = @_;
  my $out = {};
  for my $row (@$array) {
    push @{ $out->{ delete $row->{$key} } }, $row;
  }
  return $out;
}

sub dbh {
  my $db = shift;
  return DBI->connect(
    sprintf( 'DBI:mysql:database=%s;host=%s', $db, HOST ),
    USER, PASS, { RaiseError => 1 } );
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

