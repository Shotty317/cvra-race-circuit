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
    
    my @events;
    # Don't need to limit by circuit id, becuase a person Id is implicitly tied to a circuit ID
    $sth = $dbh->prepare("SELECT races.name, events.name, date_year, date_month, date_day, distance, volunteer_points, run_points, results.type FROM results INNER JOIN(races) ON results.race_id = races.id INNER JOIN(events) ON races.event_id = events.id WHERE person_id = ? ORDER BY date_year, date_month, date_day, events.id");
    $sth->execute($personId);
    while(my @data = $sth->fetchrow_array()) {
      my @event;
      my %race = (raceName => shift @data,
                  eventName => shift @data,
                  date => &error::makeDate(shift @data, shift @data, shift @data),
                  distance => shift @data);
      my $volunteerPoints = shift @data;
      my $runPoints = shift @data;
      my $pointType = shift @data;
      if ($pointType eq 'volunteer') {
        $race{volunteerPoints} = $volunteerPoints;
      }
      elsif ($pointType eq 'race')
      {
        $race{racePoints} = $runPoints;
      }
      else
      {
        die "Invalid pointType $pointType";
      }

      push (@event, \%race);
      push(@events, { event => \@event,
                      size => scalar @event,
                      eventName => $race{'eventName'},
                      url => $race{'url'},
                      date => $race{'date'},
                      cvra => $race{'cvra'}});
    }
    $sth->finish;
    $dbh->disconnect();

    $template->param(events => \@events);
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
