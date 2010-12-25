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
  
  #connect to the database
  my $dbh = DBI->connect(@consts::DB_OPT);
  
  if (defined $query->param('submit'))
  {
    &handleFormSubmit($dbh, $query);
  }
  else
  {
    &makeInputForm($dbh);
  }
  
  $dbh->disconnect();
};

&error::handleFatalError($@) if ($@);

exit;

sub handleFormSubmit
{
  my $dbh = shift || die;
  my $query = shift || die;
  
  my @error = ();
  my $personId = '';
  
  my $zipCode = $query->param('zipcode') || '';
  
  # Zip code is a form field that is hidden so users should not see it. Therefore it should be left blank.
  # Spam zombies don't know this though, so if anyone fills in a value for this field, assume they are a 
  # spambot
  if ($zipCode ne '')
  {
    # log the spam so that we have a feel for amount of zombies and if legitimate users are accidently getting denied
    my $sth = $dbh->prepare("INSERT INTO spam(timestamp, ipaddress, user_id, name, cookie, zipcode) VALUES(NOW(),?,?,?,?,?)");
    
    my $userId = $query->param('returningUserList');
    
    my $name;
    $name .= $query->param('firstName') . ' ' if (defined $query->param('firstName'));
    $name .= $query->param('lastName') if (defined $query->param('lastName'));
    
    my %cookies = fetch CGI::Cookie();
    my $hasCookie = (defined $cookies{personId}) ? 1 : 0;
    
    $sth->execute($ENV{'REMOTE_ADDR'}, $userId, $name, $hasCookie, $zipCode);
    $sth->finish();
    $dbh->commit();
    
    # Since $error is not set, we will redirect to the success page, even though it's not really a success.
    # This is to try and fool zombies as much as possible
  }
  else
  {
    # passes preliminary spam check
    my $returningUser = $query->param('returningUser');
    
    if (!defined $returningUser)
    {
	    push(@error, {str=>"Please select either 'Returning User' or 'First Time User' when selecting or entering your name."});
    }
    elsif ($returningUser eq "firstTimeUser")
    {
	    my $firstName = $query->param('firstName') || '';
	    my $lastName = $query->param('lastName') || '';
	    my $gender = $query->param('gender') || '';
	    my $ageGroup = $query->param('ageGroup') || '';
      
	    # Validate/sanitize the input
	    if($firstName ne '') {
        $firstName =~ s/</&lt;/g;
	    } else {
        push(@error, {str=>"First name required"});
	    }

	    if ($lastName ne '') {
        $lastName =~ s/</&lt;/g;
	    } else {
        push(@error, {str=>"Last name required"});
	    }
	    
	    if ($gender eq '') {
        push(@error, {str=>"Gender required"});
	    }
      
	    if ($ageGroup eq '' || $ageGroup eq '--') {
        push(@error, {str=>"Age group required"});
	    }
      
	    if (scalar @error eq 0)
	    {
        # Form seems valid for new user, try creating them
        # If we really want to prevent spam, we should probably rate limit creating new people
        my $name = $firstName . ' ' . $lastName;
        
        eval {
          my $sth = $dbh->prepare("INSERT INTO people (name, age_group, gender, circuit_id) VALUES (?, ?, ?, (SELECT id FROM circuit WHERE active=1))");
          $sth->execute($name, $ageGroup, $gender);
          $sth->finish();
        };
        
        if ($@)
        {
          # error inserting row into table. Most likely a duplicate person
          push(@error, {str=>"There was an error adding you to the CVRA Race Circuit system. This seems to be from a duplicate entry. If you have previously entered points for this year, please select your name from the list on the right, rather than typing in your name again."});
        }
        else
        {
          # Person successfully added, get the id used to create them
          $personId = $dbh->last_insert_id(undef, undef, qw(people id));
        }
	    }
    }
    elsif ($returningUser eq "returningUser")
    {
	    my $userId = $query->param('returningUserList') || '';
      
	    if ($userId eq '')
	    {
        push(@error, {str=>"For a returning user, please select your name from the list on the right"});
	    }
      
	    if (scalar @error eq 0)
	    {
        $personId = $userId;
	    }
    }
    else
    {
      push (@error, {str=>"Invalid type of new/returning user. Either you are trying to do something funny or this is a bug in the CVRA Race Circuit system"});
    }
    
    my $raceId = $query->param('raceList') || '';
    my $activityType = $query->param('activityType') || '';

    #Validate Input
    if ($raceId eq '')
    {
	    push (@error, {str=>"Select a race from the list"});
    }
    
    if ($activityType eq '')
    {
	    push (@error, {str=>"Select an activity for the race"});
    }
    elsif ($activityType ne 'race' && $activityType ne 'volunteer')
    {
	    push (@error, {str=>"Invalid activity for the race. Either you are trying to do something funny or this is a bug in the CVRA Race Circuit system"});
    }
    
    if (scalar @error eq 0)
    {
      # TODO: verify that circuit being submitted to is active

	    eval
	    {
        # Everything looks kosher, try writing to DB
        my $sth = $dbh->prepare("INSERT INTO results (timestamp, person_id, race_id, type) VALUES(NOW(), ?, ?, ?)");
        $sth->execute($personId, $raceId, $activityType);
        $sth->finish();
	    };
      
	    if ($@)
	    {
        # Error inserting into table. Most likely a duplicate race
        push (@error, {str=>"There was an error adding your race to the points system. Please ensure that you have not already submitted this race. Also, you cannot earn double points for both volunteering and racing at the same event."});
        $dbh->rollback();
	    }
	    else
	    {
        $dbh->commit();
	    }
    }
  }
  
  # Now the everything is processed, redirect to standings if successful. Or else display the form again if there were errors
  if (scalar @error eq 0)
  {
    # Success
    my $circuitId = '';
    my $rememberMe = $query->param('rememberMe') || '';
    if ($rememberMe eq 'true')
    {
	    # Get the current circuit id
	    my $sth = $dbh->prepare("SELECT id FROM circuit WHERE active=1");
	    $sth->execute();
      
	    if (my @data = $sth->fetchrow_array())
	    {
        $circuitId = shift @data;
	    }
      
	    $sth->finish();
    }
    
    my ($personCookie, $circuitCookie, $rememberCookie);
    if ($rememberMe eq 'true' && $circuitId ne '')
    {
	    # If we can't read the circuit Id from some reason, just don't set the cookie, rather than giving the user some
	    # confusing error
	    $personCookie = $query->cookie(-name  => 'personId',
                                     -value => $personId,
                                     -expires  =>'+365d');
	    $circuitCookie = $query->cookie(-name  => 'circuitId',
                                      -value => $circuitId,
                                      -expires  =>'+365d');
	    $rememberCookie = $query->cookie(-name  => 'rememberMe',
                                       -value => 'true',
                                       -expires  =>'+365d');
    }
    else
    {
	    $personCookie = $query->cookie(-name  => 'personId',
                                     -value => -1,
                                     -expires  =>'+365d');
	    $circuitCookie = $query->cookie(-name  => 'circuitId',
                                      -value => -1,
                                      -expires  =>'+365d');
	    $rememberCookie = $query->cookie(-name  => 'rememberMe',
                                       -value => 'false',
                                       -expires  =>'+365d');
    }
    
    print $query->redirect(-uri =>"standings.pl?submitRace=1",
                           -cookie=>[$personCookie, $circuitCookie, $rememberCookie]);
  }
  else
  {
    #On an error, pass through values that were already submitted so they are in the form
    my %formValues;
    $formValues{returningUser} =     $query->param('returningUser')     if (defined $query->param('returningUser'));
    $formValues{firstName} =         $query->param('firstName')         if (defined $query->param('firstName'));
    $formValues{lastName} =          $query->param('lastName')          if (defined $query->param('lastName'));
    $formValues{gender} =            $query->param('gender')            if (defined $query->param('gender'));
    $formValues{ageGroup} =          $query->param('ageGroup')          if (defined $query->param('ageGroup'));
    $formValues{returningUserList} = $query->param('returningUserList') if (defined $query->param('returningUserList'));
    $formValues{raceId} =            $query->param('raceList')          if (defined $query->param('raceList'));
    $formValues{activityType} =      $query->param('activityType')      if (defined $query->param('activityType'));
    $formValues{rememberMe} =        $query->param('rememberMe')        if (defined $query->param('rememberMe'));
    
    &makeInputForm($dbh, \@error, \%formValues);
  }
}

sub makeInputForm
{   
  my $dbh = shift || die;
  my $error = shift;
  my $formValuesRef = shift;
  
  my ($activeCircuitId, $ageGroupsId);

  #create our html template
  my $template = HTML::Template->new(filename  => 'submit.tmpl', @consts::TMPL_OPT);

  # Verify there is an active circuit
  my $sth = $dbh->prepare("SELECT id, age_groups_id FROM circuit WHERE active=1");
  $sth->execute();

  if (my @data = $sth->fetchrow_array()) {
    $activeCircuitId = shift @data;
    $ageGroupsId = shift @data;
  }
  else
  {
    $template->param(noCircuit=>1);
  }

  # Age group list
  $sth = $dbh->prepare("SELECT id, text FROM age_group WHERE age_groups_id = ? ORDER by text");
  
  $sth->execute($ageGroupsId);
  
  my @ageGroups;
  while(my @data = $sth->fetchrow_array()) {
    my %ageGroup = (id => shift @data,
                    text => shift @data);
    if (   defined $formValuesRef->{ageGroup}
        && $formValuesRef->{ageGroup} eq $ageGroup{id})
    {
	    $ageGroup{selected} = 1;
    }
    
    push (@ageGroups, \%ageGroup);
  }
  $sth->finish;
  
  # Returning User list
  $sth = $dbh->prepare("SELECT people.id, name, age_group.text FROM people INNER JOIN(age_group) ON people.age_group = age_group.id WHERE circuit_id=? ORDER BY name");
  
  $sth->execute($activeCircuitId);
  
  my %cookies = fetch CGI::Cookie();
  my @people;
    
  while(my @data = $sth->fetchrow_array()) {
    my %person;
    $person{id} = shift @data;
    $person{name} = shift @data;
    $person{ageGroup} = shift @data;

    #first check for form error selected person
    if (   defined $formValuesRef->{returningUserList}
	      && $formValuesRef->{returningUserList} eq $person{id})
    {
	    $person{selected} = 1;
    }
    
    # Then check if they are set in the cookie
    if ((!defined $cookies{rememberMe} || $cookies{rememberMe}->value eq 'true')
        && defined $cookies{circuitId}
        && $activeCircuitId eq $cookies{circuitId}->value
        && defined $cookies{personId}
        && $person{id} eq $cookies{personId}->value)
    {
	    $person{selected}=1;
    }
    push (@people, \%person);
  }
  $sth->finish;
  
  # Races list
  $sth = $dbh->prepare("SELECT races.id, races.name, events.name, date_year, date_month, date_day, distance, cvra_event FROM races INNER JOIN(events) ON events.id = races.event_id WHERE events.circuit_id=? ORDER BY date_year, date_month, date_day, events.id");
  
  $sth->execute($activeCircuitId);
  
  my @races;
  while(my @data = $sth->fetchrow_array()) {
    my %race = (id => shift @data,
                raceName => shift @data,
                eventName => shift @data,
                date => &error::makeDate(shift @data, shift @data, shift @data),
                distance => shift @data,
                cvra => shift @data);
    if (   defined $formValuesRef->{raceId}
        && $formValuesRef->{raceId} eq $race{id})
    {
	    $race{selected} = 1;
    }
    push (@races, \%race);
  }
  $sth->finish;
  
  $dbh->disconnect();
  
  if (   defined $cookies{circuitId} 
      && $cookies{circuitId}->value eq $activeCircuitId
      && (!defined $cookies{rememberMe} || $cookies{rememberMe}->value eq 'true'))
  {
    $template->param(returningUser => 1);
    $template->param(rememberMe => 1);
  }
  
  if (!defined $cookies{rememberMe} || $cookies{circuitId}->value ne $activeCircuitId)
  {
    $template->param(firstTimeUser => 1);
    # TODO: this will display wrong if it's a first time user who unclicks remember me and then submitts an error page
    # Not handling this corner case right now as it is unlikely to happen or be a big problem if it does
    $template->param(rememberMe => 1);
  }
  
  # Add other form values from possible error submittal
  if (defined $formValuesRef->{rememberMe} && $formValuesRef->{rememberMe} eq 'true') {
    $template->param(rememberMe => 1);
  }
  if (defined $formValuesRef->{firstName}) {
    $template->param(firstNameValue => $formValuesRef->{firstName});
  }
  if (defined $formValuesRef->{lastName}) {
    $template->param(lastNameValue => $formValuesRef->{lastName});
  }
  if (defined $formValuesRef->{gender}) {
    if ($formValuesRef->{gender} eq 'male') {
	    $template->param(maleChecked => 1);
    } elsif ($formValuesRef->{gender} eq 'female') {
	    $template->param(femaleChecked => 1);
    }
  }
  if (defined $formValuesRef->{activityType}) {
    if ($formValuesRef->{activityType} eq 'race') {
	    $template->param(activityRaceChecked => 1);
    } elsif ($formValuesRef->{activityType} eq 'volunteer') {
	    $template->param(activityVolunteerChecked => 1);
    }
  }
  if (defined $formValuesRef->{returningUser}) {
    if ($formValuesRef->{returningUser} eq 'true') {
	    $template->param(returningUserChecked => 1);
    } elsif ($formValuesRef->{returningUser} eq 'false') {
	    $template->param(firstTimeUserChecked => 1);
    }
  }
  
  $template->param(ageGroups => \@ageGroups,
                   users => \@people,
                   races => \@races);
  if (defined $error)
  {
    $template->param(error => \@{$error});
  }
  print header(-"Cache-Control"=>"no-cache",
               -expires =>  '+0s');
  $template->output(print_to => *STDOUT);
}

{
  # code to supress warning
  my (@i);
  @i = @consts::DB_OPT;
  @i = @consts::TMPL_OPT;
}