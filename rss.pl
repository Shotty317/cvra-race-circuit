#!/ramdisk/bin/perl -T

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

BEGIN {
  my $homedir = ( getpwuid($>) )[7];
  my @user_include;
  foreach my $path (@INC) {
    if ( -d $homedir . '/perl' . $path ) {
      push @user_include, $homedir . '/perl' . $path;
    }
  }
  unshift @INC, @user_include;
}

use CGI ':standard';
use CGI::Carp qw(fatalsToBrowser);
use CGI::Cookie;
use Data::Dumper;
use DBI;
use HTML::Template;
use POSIX qw(strftime);

use lib qw(/home/joesdine/public_html/points);

require 'consts.pl';
require 'error.pl';

#connect to the database
my $dbh = DBI->connect(@consts::DB_OPT);
  
#create our html template
my $template = HTML::Template->new(filename  => 'results.rss.tmpl', @consts::TMPL_OPT);
  
my ($circuitId, $year, $active);

my $sth = $dbh->prepare("SELECT id, year, active FROM circuit WHERE active=1");
$sth->execute();

my @results;
  
if (my @data = $sth->fetchrow_array())
{
  $circuitId = shift @data;
  $year = shift @data;
  $active = shift @data;


  $sth->finish();
  
  # Points
  $sth = $dbh->prepare("SELECT age_group.text, people.gender, people.id, people.name, events.name, races.name, races.distance, results.type, results.id, DATE_FORMAT(results.timestamp,'%a, %d %b %Y %T') FROM races INNER JOIN(results) ON results.race_id = races.id INNER JOIN people ON (results.person_id = people.id) INNER JOIN age_group ON (people.age_group = age_group.id) INNER JOIN events ON (races.event_id = events.id) WHERE races.circuit_id=? ORDER BY results.timestamp DESC LIMIT 50");
  
  $sth->execute($circuitId);
  
  while(my @data = $sth->fetchrow_array()) {
    push(@results, {ageGroup => shift @data,
                    gender => shift @data,
                    personId => shift @data,
                    name => shift @data,
                    eventName => shift @data,
                    raceName => shift @data,
                    distance => shift @data,
                    type => (shift @data eq "race" ? "raced" : "volunteered"),
                    guid => "http://cvra.net/circuit/results/" . shift @data,
                    pubDate => (shift @data) . " CDT"});
  }
}

$sth->finish;
$dbh->disconnect();

$template->param(results => \@results);
if (scalar @results > 0) {
  $template->param(lastBuildDate => $results[0]{pubDate});
}
  
print header(-"Cache-Control"=>"no-cache",
             -expires =>  '+0s',
             -type => "application/rss+xml");
$template->output(print_to => *STDOUT);

