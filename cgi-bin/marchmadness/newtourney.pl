#!/usr/bin/perl -wT
# This is newtourney.pl, which can be used to create a new tournament
# and enter all division and team info.
#
# Copyright (C) 2004 Russ Burdick, grub@extrapolation.net
#
# This file is part of tournament.
#
# tournament is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# tournament is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with tournament; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#

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
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";
   print "Tournament Year: " . $query->textfield(-name => "tyear",
                                         -size => 5,
                                         -maxlength => 4) . "</p>\n";

   print "<p>Division Name: " . $query->textfield(-name => "dname",
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";
   print "(1): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(2): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(3): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(4): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(5): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(6): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(7): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(8): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(9): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(10): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(11): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(12): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(13): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(14): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(15): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(16): " . $query->textfield(-name => "d1seed",
                                         -size => 50,
                                         -maxlength => 100) . "</p>\n";

   print "<p>Division Name: " . $query->textfield(-name => "dname",
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";
   print "(1): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(2): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(3): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(4): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(5): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(6): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(7): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(8): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(9): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(10): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(11): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(12): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(13): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(14): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(15): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(16): " . $query->textfield(-name => "d2seed",
                                         -size => 50,
                                         -maxlength => 100) . "</p>\n";

   print "<p>Division Name: " . $query->textfield(-name => "dname",
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";
   print "(1): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(2): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(3): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(4): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(5): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(6): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(7): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(8): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(9): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(10): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(11): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(12): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(13): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(14): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(15): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(16): " . $query->textfield(-name => "d3seed",
                                         -size => 50,
                                         -maxlength => 100) . "</p>\n";

   print "<p>Division Name: " . $query->textfield(-name => "dname",
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";
   print "(1): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(2): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(3): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(4): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(5): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(6): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(7): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(8): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(9): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(10): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(11): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(12): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(13): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(14): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(15): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "<br>\n";
   print "(16): " . $query->textfield(-name => "d4seed",
                                         -size => 50,
                                         -maxlength => 100) . "</p>\n";

   print "<p>\n";
   print $query->submit(-name => "submit", -value => "add tournament");
   print $query->reset(-value => "reset form");
   print "</p>\n";

   print "</form>\n";

} elsif ($query->request_method eq "POST") {

      my $tname = $query->param('tname');
      my $tyear = $query->param('tyear');

      my @dnames = $query->param('dname');
      my @d1seeds = $query->param('d1seed');
      my @d2seeds = $query->param('d2seed');
      my @d3seeds = $query->param('d3seed');
      my @d4seeds = $query->param('d4seed');

      if ($tname && $tyear && @dnames && @d1seeds && @d2seeds && 
          @d3seeds && @d4seeds) {

         my $tid = 0;
         my $did = 0;
         my @teams;

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                                $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "INSERT INTO tournaments SET ";
         $sql .= "name = " . $dbh->quote($tname);
         $sql .= ", year = " . $dbh->quote($tyear);

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
               $sql .= ", divisionid = " . $dbh->quote($did);
               $sql .= ", seed = " . $dbh->quote($j+1);

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

