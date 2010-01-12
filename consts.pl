package consts;

################################################################################
#
# DATABASE CONSTANTS
#
################################################################################

#the database connection string
$DBNAME = '';

# the username for the gallery
$USERNAME = '';

# password for gallery
$PASSWORD = '';

# options to pass to DBI->connect
@DB_OPT = ($DBNAME, $USERNAME, $PASSWORD, 
           { PrintError => 0,
             RaiseError => 1,
             AutoCommit => 0
           });

################################################################################
#
# HTML::Templates CONSTANTS
#
################################################################################

# the path to the templates
$TMPL_PATH = '';

# options to pass to HTML::template
@TMPL_OPT = ( path              => $TMPL_PATH, 
              case_sensitive    => 1,
              global_vars       => 1,
              die_on_bad_params => 0,
              loop_context_vars => 'true');
