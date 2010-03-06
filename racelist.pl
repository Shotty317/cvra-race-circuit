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

  #connect to the database
  my $dbh = DBI->connect(@consts::DB_OPT);
  
  #create our html template
  my $template = HTML::Template->new(filename  => 'racelist.tmpl', @consts::TMPL_OPT);
  
  my $sth = $dbh->prepare("SELECT races.name, events.name, events.id, events.url, date_year, date_month, date_day, volunteer_points, run_points, distance, events.cvra_event, circuit.year FROM races INNER JOIN(circuit) ON races.circuit_id = circuit.id INNER JOIN(events) ON races.event_id = events.id WHERE circuit.active=1 ORDER by date_year, date_month, date_day, events.id");
  
  $sth->execute();

  my $year;
  my @races;
  while(my @data = $sth->fetchrow_array()) {
     push (@races, {raceName => shift @data,
                    eventName => shift @data,
                    eventId => shift @data,
                    url => shift @data,
                    date => &error::makeDate(shift @data, shift @data, shift @data),
                    volunteerPoints => shift @data,
                    racePoints => shift @data,
                    distance => shift @data,
                    cvra => shift @data});
    $year = shift @data;
  }
  $sth->finish;
  $dbh->disconnect();

  if (scalar @races eq 0) {
    $template->param(noCircuit => 1);
  }

  my @events;
  my @event;
  my $lastEventId = undef;
  for (my $i=0; $i < scalar @races; $i++) {
    if (defined $lastEventId and ($races[$i]{'eventId'} ne $lastEventId)) {
      # Make a copy of the array so our reference doesn't end up pointing to the next event
      my @event2 = @event;
      push(@events, { event => \@event2,
                      size => scalar @event gt 1 ? scalar @event : undef,
                      eventName => $races[$i-1]{'eventName'},
                      url => $races[$i-1]{'url'},
                      date => $races[$i-1]{'date'},
                      cvra => $races[$i-1]{'cvra'}});
      @event = ();
    }
    push(@event, {raceName => $races[$i]{'raceName'},
                  volunteerPoints => $races[$i]{'volunteerPoints'},
                  racePoints => $races[$i]{'racePoints'},
                  distance => $races[$i]{'distance'}});
    $lastEventId = $races[$i]{'eventId'};
  }

  push(@events, { event => \@event,
                  size => scalar @event,
                  eventName => $races[scalar @races - 1]{'eventName'},
                  url => $races[scalar @races - 1]{'url'},
                  date => $races[scalar @races - 1]{'date'},
                  cvra => $races[scalar @races - 1]{'cvra'}});

  $template->param(events => \@events,
                   year => $year);
  
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
