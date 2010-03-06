package error;

#So this function doesn't logically belong here, but oh well
sub makeDate {
  my @printMonth = ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');

  my $year = shift;
  my $month = shift;
  my $day = shift;
  
  my $date;
  if (defined $month) {
    $date .= $printMonth[$month-1];
    if (defined $day) {
      $date .= " " . $day;
    }
  }
  return $date;
}


sub handleFatalError {
    print "Content-type: text/html\n\n";
    print "ERROR!!! " . shift;
}

1;
