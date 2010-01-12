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

use lib qw(/home/joesdine/public_html/points);

require 'consts.pl';
require 'error.pl';

eval {
  #read values from query_string
  my $query = new CGI;
  
  my $personId = $query->param('person') || '';
  
  #create our html template
  my $template = HTML::Template->new(filename  => 'details.tmpl', @consts::TMPL_OPT);
  
  if ($personId ne '')
  {
    #connect to the database
    my $dbh = DBI->connect(@consts::DB_OPT);
    
    
    my $sth = $dbh->prepare("SELECT name, circuit.id, age_group.text, year FROM people INNER JOIN(circuit) ON (people.circuit_id = circuit.id) INNER JOIN(age_group) ON people.age_group = age_group.id WHERE people.id=?");
    
    $sth->execute($personId);
    
    if(my @data = $sth->fetchrow_array()) {
	    $template->param(name => shift @data,
                       circuitId => shift @data,
                       ageGroup => shift @data,
                       year => shift @data);
    }
    $sth->finish();
    
    my %races;

    # Volunteer Points

    # Don't need to limit by circuit id, becuase a person Id is implicitly tied to a circuit ID
    $sth = $dbh->prepare("SELECT races.id, races.name, races.date, races.order, distance, volunteer_points FROM results INNER JOIN(races) ON results.race_id = races.id WHERE person_id = ? AND results.type='volunteer'");
    $sth->execute($personId);
    while(my @data = $sth->fetchrow_array()) {
      my $raceId = shift @data;
      $races{$raceId} = {name => shift @data,
                         date => shift @data,
                         order => shift @data,
                         distance => shift @data,
                         volunteerPoints => shift @data};
    }
    $sth->finish;
    
    # Race Points
    $sth = $dbh->prepare("SELECT races.id, races.name, races.date, races.order, distance, run_points FROM results INNER JOIN(races) ON results.race_id = races.id WHERE person_id = ? AND results.type='race'");
    $sth->execute($personId);
    while(my @data = $sth->fetchrow_array()) {
      my $raceId = shift @data;
      $races{$raceId}{name} = shift @data;
      $races{$raceId}{date} = shift @data;
      $races{$raceId}{order} = shift @data;
      $races{$raceId}{distance} = shift @data;
      $races{$raceId}{racePoints} = shift @data;
    }
    $sth->finish;
    $dbh->disconnect();

    my @results;

    while ( (my $raceId, my $race) = each(%races))
    {
      push(@results, \%$race);
    }

    @results = sort {$a->{order} <=> $b->{order}} (@results);

    $template->param(races => \@results);
  }
  
  print header(-"Cache-Control"=>"no-cache",
               -expires =>  '+0s');
  $template->output(print_to => *STDOUT);
};

&error::handleFatalError($@) if ($@);

exit;
{
  # code to supress warning
  my (@i);
  @i = @consts::DB_OPT;
  @i = @consts::TMPL_OPT;
}
