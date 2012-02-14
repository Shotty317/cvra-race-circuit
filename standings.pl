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
  
  if ($query->param('mode') && $query->param('mode') eq "browse")
  {
    &browseStandings();
  }
  else
  {
    &makeStandings($query);
  }
};

&error::handleFatalError($@) if ($@);

exit;

sub browseStandings()
{
  #connect to the database
  my $dbh = DBI->connect(@consts::DB_OPT);
  
  #create our html template
  my $template = HTML::Template->new(filename  => 'browse-standings.tmpl', @consts::TMPL_OPT);
  
  my $sth = $dbh->prepare("SELECT id, year, active FROM circuit WHERE visible=1 ORDER BY year DESC");
  
  $sth->execute();
  
  my @years;
  while(my @data = $sth->fetchrow_array()) {
    push (@years, {id => shift @data,
                   year => shift @data,
                   active => shift @data});
  }
  $sth->finish;
  $dbh->disconnect();
  
  $template->param(years => \@years);
  
  print header(-"Cache-Control"=>"no-cache",
               -expires =>  '+0s');
  $template->output(print_to => *STDOUT);
}

sub makeStandings {
  my $query = shift || die;
  
  #connect to the database
  my $dbh = DBI->connect(@consts::DB_OPT);
  
  #create our html template
  my $template = HTML::Template->new(filename  => 'standings.tmpl', @consts::TMPL_OPT);
  
  my ($circuitId, $year, $active, $sth);
  if ($query->param('circuit'))
  {
    $sth = $dbh->prepare("SELECT id, year, active FROM circuit WHERE id=? AND visible=1");
    $sth->execute($query->param('circuit'));
  }
  else
  {
    # find the active circuit
    $sth = $dbh->prepare("SELECT id, year, active FROM circuit WHERE active=1");
    $sth->execute();
  }
  
  if (my @data = $sth->fetchrow_array())
  {
    $circuitId = shift @data;
    $year = shift @data;
    $active = shift @data;
  }
  else
  {
    # No active circuit, jut browse the old ones
    &browseStandings();
    return;
  }
  $sth->finish();
  
  # Points
  $sth = $dbh->prepare("SELECT age_group.text, people.gender, people.id, people.name, SUM(volunteer_points), SUM(run_points) FROM races INNER JOIN(results) ON results.race_id = races.id INNER JOIN people ON (results.person_id = people.id) INNER JOIN age_group ON (people.age_group = age_group.id) AND results.type=? AND races.circuit_id=? GROUP BY results.person_id");
  
  $sth->execute("race", $circuitId);
  
  my %results;
  while(my @data = $sth->fetchrow_array()) {
    my $ageGroup = shift @data;
    my $gender = shift @data;
    my $personId = shift @data;
    my $name = shift @data;
    shift @data; #skip volunteer points
    my $points = shift @data;
    
    $results{$ageGroup}{$gender}{$personId} = {name => $name,
                                               runPoints => $points};
  }
  
  # volunteer points
  $sth->execute("volunteer", $circuitId);
  while(my @data = $sth->fetchrow_array()) {
    my $ageGroup = shift @data;
    my $gender = shift @data;
    my $personId = shift @data;
    my $name = shift @data;
    my $points = shift @data;
    shift @data; #skip run points
    
    $results{$ageGroup}{$gender}{$personId}{name} = $name;
    $results{$ageGroup}{$gender}{$personId}{volunteerPoints} = $points;
  }
  
  $sth->finish();
  $dbh->disconnect();
  
  my @ageGroups;
  while ( (my $ageGroup, my $gender) = each(%results))
  {
#      print "Doing age group: $ageGroup\n";
    my @genders;
	
    while ( (my $genderName, my $persons) = each(%$gender))
    {
#	  print "  Doing gender $genderName\n";
	    my @people;
	    
	    while ( (my $personId, my $person) = each (%$persons))
	    {
#             print "    Doing person $currentPerson{name}\n";
        my %currentPerson = %$person;
        my $racePoints = $currentPerson{runPoints} || 0;
        my $volunteerPoints = $currentPerson{volunteerPoints} || 0;
        push(@people, {personId => $personId,
                       name => $currentPerson{name},
                       racePoints => $racePoints,
                       volunteerPoints => $volunteerPoints,
                       totalPoints => $racePoints + $volunteerPoints});
        
	    }
	    @people = sort {    $b->{totalPoints} <=> $a->{totalPoints} 
                       || $b->{volunteerPoints} <=> $a->{volunteerPoints}} (@people);
	    push (@genders, {people => \@people,
                       gender => $genderName});
    }
    
    # If one gender does not have any results, it breaks the display
    # Thefore add a dummy holder for that gender/age group
    if (scalar @genders eq 1)
    {
	    my $genderToAdd = ($genders[0]{gender} eq 'Female') ? 'Male' : 'Female';
	    push (@genders, {empty => 1,
                       gender => $genderToAdd});
    }
    
    @genders = sort {$a->{gender} cmp $b->{gender}} (@genders);
    push (@ageGroups, {genders => \@genders,
                       ageGroup => $ageGroup}); 
  }
  @ageGroups = sort {$a->{ageGroup} cmp $b->{ageGroup}} (@ageGroups);
  
  
  $template->param(ageGroups => \@ageGroups,
                   year => $year,
                   active => $active);
  if (defined $query->param('submitRace'))
  {
    $template->param(submitted => 1);
  }
  
  print header(-"Cache-Control"=>"no-cache",
               -expires =>  '+0s');
  $template->output(print_to => *STDOUT);
} 
