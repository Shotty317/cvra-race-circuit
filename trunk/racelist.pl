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
  
  my $sth = $dbh->prepare("SELECT name, url, date, volunteer_points, run_points, distance, cvra_event, circuit.year FROM races INNER JOIN(circuit) ON races.circuit_id = circuit.id AND circuit.active=1 ORDER by races.order");
  
  $sth->execute();
  
  my $year;
  my @races;
  while(my @data = $sth->fetchrow_array()) {
    push (@races, {name => shift @data,
                   url => shift @data,
                   date => shift @data,
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
  
  $template->param(races => \@races,
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
