package error;
sub handleFatalError {
    print "Content-type: text/html\n\n";
    print "ERROR!!! " . shift;
}

1;
