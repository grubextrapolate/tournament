#!/usr/bin/perl -wT
# This is newscore.pl, which can be used to make picks

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;

use lib qw(.);
use MMConstants;

# Remove buffering
$| = 1;

my %tourneys;
my @tourney_ids;
my %players;
my @player_ids;
my @dorder;

# ------------------------------------------------------------
# Create an instance of CGI
my $query = new CGI;

# Send a MIME header
print $query->header("text/html");

print $query->start_html(-title => "add game score",
			 -bgcolor => "#FFFFFF");

if ($query->request_method eq "GET") {

   print "<h2>Choose tournament:</h2>\n";
   print qq(<form method="POST" action="newscore.pl">\n);

   # ------------------------------------------------------------
   # Connect to the database
   my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
   die "DBI error from connect: ", $DBI::errstr unless $dbh;

   my $sql = "SELECT * FROM tournaments ORDER BY year DESC";

   # Send the query
   my $sth = $dbh->prepare($sql);
   die "DBI error with prepare:", $sth->errstr unless $sth;

   # Execute the query
   my $result = $sth->execute;
   die "DBI error with execute:", $sth->errstr unless $result;

   # If we received artists from the SELECT, print them out
   my $rc = $sth->rows;
   if ($rc) {

      # Iterate through artist IDs and names
      my $row;
      while ($row = $sth->fetchrow_hashref) {

         $tourneys{$row->{id}} = "$row->{name}, $row->{year}";
         push @tourney_ids, $row->{id};
      }
   }

   # Finish that database call
   $sth->finish;

   print "<p>" . $query->popup_menu(-name => "tourneys",
                                    -values => \@tourney_ids,
                                    -labels => \%tourneys) . "<br>\n";

   print $query->submit(-name => "submit", 
                        -value => "continue") . "</p>\n";

   print "</form>\n";

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

} elsif ($query->request_method eq "POST") {

   if ($query->param('submit') eq "continue") {

      my $tid = $query->param('tourneys');
      if ($tid) {

         my $tname;
         my %divisions;
         my @division_ids;
         my %allteams;
         my @allteam_ids;
         my %dteams;

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "SELECT name, year FROM tournaments ";
         $sql .= "WHERE id = " . $dbh->quote($tid);

         # Send the query
         my $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         my $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # If we received artists from the SELECT, print them out
         my $rc = $sth->rows;
         if ($rc) {

            # Iterate through artist IDs and names
            my $row;
            while ($row = $sth->fetchrow_hashref) {
               $tname = "$row->{name}, $row->{year}";
            }
         }

         # Finish that database call
         $sth->finish;

         $sql = "SELECT * FROM divisions ";
         $sql .= "WHERE tourneyid = " . $dbh->quote($tid);
         $sql .= " ORDER BY position";

         # Send the query
         $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # If we received artists from the SELECT, print them out
         $rc = $sth->rows;
         if ($rc) {

            # Iterate through artist IDs and names
            my $row;
            while ($row = $sth->fetchrow_hashref) {

               push @dorder, $row->{id};
               $divisions{$row->{id}} = $row->{name};
               push @division_ids, $row->{id};

               my %teams;
               my @team_ids;

               my $sql2 = "SELECT * FROM teams ";
               $sql2 .= "WHERE divisionid = " . $dbh->quote($row->{id});
               $sql2 .= " ORDER BY seed";

               # Send the query
               my $sth2 = $dbh->prepare($sql2);
               die "DBI error with prepare:", $sth2->errstr unless $sth2;

               # Execute the query
               my $result2 = $sth2->execute;
               die "DBI error with execute:", $sth2->errstr unless $result2;

               # If we received artists from the SELECT, print them out
               my $rc2 = $sth2->rows;
               if ($rc2) {

                  # Iterate through artist IDs and names
                  my $row2;
                  while ($row2 = $sth2->fetchrow_hashref) {

                     $allteams{$row2->{id}} = "($row2->{seed}) $row2->{name}, $row->{name}";
                     push @allteam_ids, $row2->{id};
                  }
               }

               # Finish that database call
               $sth2->finish;
            }
         }

         # Finish that database call
         $sth->finish;

         # Disconnect, even though it isn't really necessary
         $dbh->disconnect;

         print qq(<form method="POST" action="newscore.pl">\n);
         print qq(<h2>$tname</h2>\n);
         print $query->hidden(-name => 'tourneyid',
                              -value => $tid) . "\n";

         print "<p>\n";
         print $query->popup_menu(-name => "team1",
                                  -values => \@allteam_ids,
                                  -labels => \%allteams) . "\n";

         print $query->textfield(-name => "score1",
                                 -size => 5,
                                 -maxlength => 3) . "<br>\n";

         print $query->popup_menu(-name => "team2",
                                  -values => \@allteam_ids,
                                  -labels => \%allteams) . "\n";

         print $query->textfield(-name => "score2",
                                 -size => 5,
                                 -maxlength => 3) . "<br>\n";

         print "<p>\n";
         print $query->submit(-name => "submit", -value => "save score");
         print "</p>\n";

         print "</form>\n";

      } else {
         print "<p>tournament mandatory!</p>\n";
      }

   } elsif ($query->param('submit') eq "save score") {

      my $tid   = $query->param('tourneyid');
      my $team1 = $query->param('team1');
      my $score1 = $query->param('score1');
      my $team2 = $query->param('team2');
      my $score2 = $query->param('score2');
      if ($tid && $team1 && $team2 && $score1 && $score2) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "INSERT INTO scores SET ";
         $sql .= "tourneyid = " . $dbh->quote($tid);
         $sql .= ", teamid1 = " . $dbh->quote($team1);
         $sql .= ", score1 = " . $dbh->quote($score1);
         $sql .= ", teamid2 = " . $dbh->quote($team2);
         $sql .= ", score2 = " . $dbh->quote($score2);

         # Send the query
         my $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         my $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # Finish that database call
         $sth->finish;

         $sql = "UPDATE tournaments SET";
         $sql .= " lastupdate = NOW()";
         $sql .= " WHERE id = " . $dbh->quote($tid);

         # Prepare the query
         $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # Finish that database call
         $sth->finish;

         # Disconnect, even though it isn't really necessary
         $dbh->disconnect;

         print "<p>save score successful!</p>\n";

      } else {
         print "<p>information missing!</p>\n";
      }

   } else {
      print "<p>unknown submit type</p>\n";
   }

} else {
   print "<p>Sorry, but we only recognize GET and POST.</p>\n";

}

print $query->end_html;

