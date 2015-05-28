#!/usr/bin/perl -wT
# This is newtourney.pl, which can be used to create a new tournament
# and enter all division and team info.

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;

use lib qw(.);
use MMConstants;

# Remove buffering
$| = 1;

my %entries;
my @entry_ids;
my %divisions;
my @division_ids;
my %tourneys;
my @tourney_ids;
my @seedorder = (1, 16, 8, 9, 5, 12, 4, 13, 6, 11, 3, 14, 7, 10, 2, 15);

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
$year += 1900;
$mon++;
# timestamp format == "YYYY-MM-DD HH:MM:SS",
my $defaultcut = sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year, $mon, ($mday+4), 12, 0, 0);

# ------------------------------------------------------------
# Create an instance of CGI
my $query = new CGI;

# Send a MIME header
print $query->header("text/html");

print $query->start_html(-title => "create new tournament",
			 -bgcolor => "#FFFFFF");

if ($query->request_method eq "GET") {

   print qq(<h2>Create New Tournament</h2>\n);
   print qq(<form method="POST" action="newtourney.pl">\n);

   print "<p>Tournament Name: " . $query->textfield(-name => "tname",
                                         -default => "NCAA Division I Mens Basketball Tournament",
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";
   print "Tournament Year: " . $query->textfield(-name => "tyear",
                                         -default => $year,
                                         -size => 5,
                                         -maxlength => 4) . "<br>\n";

   print "Tournament Cutoff: " . $query->textfield(-name => "tcutoff",
                                         -default => $defaultcut,
                                         -size => 20,
                                         -maxlength => 19) . "</p>\n";

   print "<p>Division Name: " . $query->textfield(-name => "dname",
                                         -default => "Midwest",
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";
   foreach my $seed (@seedorder)
   {
      print "($seed): " . $query->textfield(-name => "d1seed",
                                            -size => 50,
                                            -maxlength => 100) . "<br>\n";
   }
   print "</p>\n";

   print "<p>Division Name: " . $query->textfield(-name => "dname",
                                         -default => "West",
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";
   foreach my $seed (@seedorder)
   {
      print "($seed): " . $query->textfield(-name => "d2seed",
                                            -size => 50,
                                            -maxlength => 100) . "<br>\n";
   }
   print "</p>\n";

   print "<p>Division Name: " . $query->textfield(-name => "dname",
                                         -default => "South",
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";
   foreach my $seed (@seedorder)
   {
      print "($seed): " . $query->textfield(-name => "d3seed",
                                            -size => 50,
                                            -maxlength => 100) . "<br>\n";
   }
   print "</p>\n";

   print "<p>Division Name: " . $query->textfield(-name => "dname",
                                         -default => "East",
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";
   foreach my $seed (@seedorder)
   {
      print "($seed): " . $query->textfield(-name => "d4seed",
                                            -size => 50,
                                            -maxlength => 100) . "<br>\n";
   }
   print "</p>\n";

   print "<p>\n";
   print $query->submit(-name => "submit", -value => "add tournament");
   print $query->reset(-value => "reset form");
   print "</p>\n";

   print "</form>\n";

} elsif ($query->request_method eq "POST") {

      my $tname   = $query->param('tname');
      my $tyear   = $query->param('tyear');
      my $tcutoff = $query->param('tcutoff');

      my @dnames  = $query->param('dname');
      my @d1seeds = $query->param('d1seed');
      my @d2seeds = $query->param('d2seed');
      my @d3seeds = $query->param('d3seed');
      my @d4seeds = $query->param('d4seed');

      if (    $tname && $tyear && $tcutoff
           && @dnames && @d1seeds && @d2seeds && @d3seeds && @d4seeds)
      {

         my $tid = 0;
         my $did = 0;
         my @teams;

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "INSERT INTO tournaments SET ";
         $sql .= "name = " . $dbh->quote($tname);
         $sql .= ", year = " . $dbh->quote($tyear);
         $sql .= ", cutoff = " . $dbh->quote($tcutoff);
         $sql .= ", lastupdate = NOW()";

         # Prepare the query
         my $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         my $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # Finish that database call
         $sth->finish;

         # need to know tourney id for division inserts
         $sql = "SELECT LAST_INSERT_ID()";

         # Send the query
         $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # If we received artists from the SELECT, print them out
         my $rc = $sth->rows;
         if ($rc) {

            # Iterate through artist IDs and names
            while (my @row = $sth->fetchrow) {
               $tid = $row[0];
            }
         }

         # Finish that database call
         $sth->finish;

         push @teams, \@d1seeds;
         push @teams, \@d2seeds;
         push @teams, \@d3seeds;
         push @teams, \@d4seeds;
         for (my $i = 0; $i < 4; $i++) {

            my $sql = "INSERT INTO divisions SET ";
            $sql .= "name = " . $dbh->quote($dnames[$i]);
            $sql .= ", tourneyid = " . $dbh->quote($tid);
            $sql .= ", position = " . $dbh->quote($i);

            # Prepare the query
            my $sth = $dbh->prepare($sql);
            die "DBI error with prepare:", $sth->errstr unless $sth;

            # Execute the query
            my $result = $sth->execute;
            die "DBI error with execute:", $sth->errstr unless $result;

            # Finish that database call
            $sth->finish;

            # need to know division id for team inserts
            $sql = "SELECT LAST_INSERT_ID()";

            # Send the query
            $sth = $dbh->prepare($sql);
            die "DBI error with prepare:", $sth->errstr unless $sth;

            # Execute the query
            $result = $sth->execute;
            die "DBI error with execute:", $sth->errstr unless $result;

            # If we received artists from the SELECT, print them out
            my $rc = $sth->rows;
            if ($rc) {

               # Iterate through artist IDs and names
               while (my @row = $sth->fetchrow) {
                  $did = $row[0];
               }
            }

            # Finish that database call
            $sth->finish;

            for (my $j = 0; $j < 16; $j++) {

               my $sql = "INSERT INTO teams SET ";
               $sql .= "name = " . $dbh->quote(@{$teams[$i]}[$j]);
               $sql .= ", alias = " . $dbh->quote(@{$teams[$i]}[$j]);
               $sql .= ", divisionid = " . $dbh->quote($did);
#               $sql .= ", seed = " . $dbh->quote($j+1);
               $sql .= ", seed = " . $dbh->quote($seedorder[$j]);

               # Prepare the query
               my $sth = $dbh->prepare($sql);
               die "DBI error with prepare:", $sth->errstr unless $sth;

               # Execute the query
               my $result = $sth->execute;
               die "DBI error with execute:", $sth->errstr unless $result;

               # Finish that database call
               $sth->finish;
            }
         }

         # Disconnect, even though it isn't really necessary
         $dbh->disconnect;

         print "<p>add entry successful!</p>\n";

      } else {
         print "<p>name, seed, and division mandatory!</p>\n";
      }

} else {
   print "<p>Sorry, but we only recognize GET and POST.</p>\n";

}

print $query->end_html;

