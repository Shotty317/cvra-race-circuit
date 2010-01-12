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
  my $template = HTML::Template->new(filename  => 'rules.tmpl', @consts::TMPL_OPT);

  my $sth = $dbh->prepare("SELECT text FROM age_group ORDER by text");
  
  $sth->execute();
  
  my @ageGroups;
  while(my @data = $sth->fetchrow_array()) {
    push (@ageGroups, {ageGroup => shift @data});
  }
  $sth->finish;
  
  $dbh->disconnect();
  
  $template->param(ageGroups => \@ageGroups);
  
  print header(-"Cache-Control"=>"no-cache",
               -expires =>  '+0s');
  $template->output(print_to => *STDOUT);
};

&error::handleFatalError($@) if ($@);

exit;
