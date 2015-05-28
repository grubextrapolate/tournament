#!/usr/bin/perl -wT
# This is newpicks.pl, which can be used to make picks


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

print $query->start_html(-title => "make picks",
			 -bgcolor => "#FFFFFF");

if ($query->request_method eq "GET") {

   print "<h2>Choose player and tournament:</h2>\n";
   print qq(<form method="POST" action="newpicks.pl">\n);

   # ------------------------------------------------------------
   # Connect to the database
   my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
   die "DBI error from connect: ", $DBI::errstr unless $dbh;

#   my $sql = "SELECT * FROM tournaments ORDER BY year DESC";
   my $sql = "SELECT * FROM tournaments ";
   $sql .= "WHERE (cutoff + INTERVAL 0 HOUR) > (NOW() + INTERVAL 4 HOUR) ";
   $sql .= " ORDER BY year DESC";

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

   $sql = "SELECT * FROM players ORDER BY name";

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

         $players{$row->{id}} = $row->{name};
         push @player_ids, $row->{id};
      }
   }

   # Finish that database call
   $sth->finish;

   print "<p>" . $query->popup_menu(-name => "tourneys",
                                    -values => \@tourney_ids,
                                    -labels => \%tourneys) . "<br>\n";

   print $query->popup_menu(-name => "players",
                            -values => \@player_ids,
                            -labels => \%players) . "<br>\n";

   if (scalar @tourney_ids)
   {
      print $query->submit(-name => "submit",
                           -value => "continue") . "</p>\n";
   }
   else
   {
      print $query->submit(-name => "submit",
                           -disabled => 1,
                           -value => "continue") . "</p>\n";
   }

   print "</form>\n";

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

} elsif ($query->request_method eq "POST") {

   if ($query->param('submit') eq "continue") {

      my $player = $query->param('players');
      my $tid = $query->param('tourneys');
      if ($player && $tid) {

         my $tname;
         my $pname;
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

         $sql = "SELECT * FROM players ";
         $sql .= "WHERE id = " . $dbh->quote($player);

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
               $pname = $row->{name};
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

                     $teams{$row2->{id}} = "($row2->{seed}) $row2->{name}";
                     push @team_ids, $row2->{id};
                     $allteams{$row2->{id}} = "($row2->{seed}) $row2->{name}, $row->{name}";
                     push @allteam_ids, $row2->{id};
                  }
                  $dteams{$row->{id}}->{names} = \%teams;
                  $dteams{$row->{id}}->{ids} = \@team_ids;
               }

               # Finish that database call
               $sth2->finish;
            }
         }

         # Finish that database call
         $sth->finish;

         # Disconnect, even though it isn't really necessary
         $dbh->disconnect;

         print qq(<form method="POST" action="newpicks.pl">\n);
         print qq(<h2>$tname</h2>\n);
         print qq(<p>Rules: pick 2 teams from each region and 4 additional\n);
         print qq(wildcard teams. when a team wins you get a score equal to\n);
         print qq(their seed+4 (so a win by a 3 seed would give 7 points).\n);
         print qq(<p>the "bonus" winner pick will give <strong>no points</strong> through the\n);
         print qq(individual games but will give a bonus of (seed + 4)*5 if\n);
         print qq{they win the tournament (so a win by a 3 seed would give\n};
         print qq{35 bonus points).</p>\n};
         print qq(<p>the person with the highest total score at the end of the\n);
         print qq(tournament wins.</p>\n);
         print qq(<strong>Note: </strong>Don't use this page if you need to\n);
         print qq(CHANGE one of your picks as you'll end up with duplicate\n);
         print qq(picks. <a href="mailto:grub\@extrapolation.net">email me</a>\n);
         print qq(BEFORE tip-off in the first game to make any changes.</p>\n);

         print $query->hidden(-name => 'tourneyid',
                              -value => $tid) . "\n";
         print $query->hidden(-name => 'playerid',
                              -value => $player) . "\n";

         foreach my $did (@dorder) {

            print qq(<h2>$divisions{$did}</h2>\n);

            print "<p>" . $query->hidden(-name => 'wildcard',
                                         -value => 0) . "\n";
            print $query->popup_menu(-name => "picks",
                                     -values => $dteams{$did}->{ids},
                                     -labels => $dteams{$did}->{names}) . "<br>\n";

            print $query->hidden(-name => 'wildcard',
                                 -value => 0) . "\n";
            print $query->popup_menu(-name => "picks",
                                     -values => $dteams{$did}->{ids},
                                     -labels => $dteams{$did}->{names}) . "</p>\n";

         }

         print qq(<h2>Wildcard</h2>\n);

         print "<p>";
         for (my $i = 1; $i <= 4; $i++)
         {
            print $query->hidden(-name => 'wildcard',
                                 -value => 1) . "\n";
            print $query->popup_menu(-name => "picks",
                                     -values => \@allteam_ids,
                                     -labels => \%allteams) . "<br>\n";
         }
         print "</p>";

         print qq(<h2>Bonus: Winner Pick</h2>\n);
         print "<p>" . $query->hidden(-name => 'wildcard',
                                      -value => 2) . "\n";
         print $query->popup_menu(-name => "picks",
                                  -values => \@allteam_ids,
                                  -labels => \%allteams) . "</p>\n";

         print "<p>\n";
         print $query->submit(-name => "submit", -value => "save picks");
         print "</p>\n";

         print "</form>\n";

      } else {
         print "<p>player and tournament mandatory!</p>\n";
      }

   } elsif ($query->param('submit') eq "save picks") {

      my $tid = $query->param('tourneyid');
      my $pid = $query->param('playerid');
      my @picks = $query->param('picks');
      my @wcflags = $query->param('wildcard');
      if ($tid && $pid && @picks && @wcflags) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         for (my $i = 0; $i < @picks; $i++) {

            my $sql = "INSERT INTO picks SET ";
            $sql .= "playerid = " . $dbh->quote($pid);
            $sql .= ", tourneyid = " . $dbh->quote($tid);
            $sql .= ", teamid = " . $dbh->quote($picks[$i]);
            $sql .= ", wildcard = " . $dbh->quote($wcflags[$i]);

            # Send the query
            my $sth = $dbh->prepare($sql);
            die "DBI error with prepare:", $sth->errstr unless $sth;

            # Execute the query
            my $result = $sth->execute;
            die "DBI error with execute:", $sth->errstr unless $result;

            # Finish that database call
            $sth->finish;

         }

         # Disconnect, even though it isn't really necessary
         $dbh->disconnect;

         print "<p>save picks successful!</p>\n";
         print qq(<p>go to <a href="display.pl?tournament=$tid">current );
         print qq(standings</a> or <a href="bracket.pl?tournament=$tid">);
         print qq(current bracket</a></p>\n);

      } else {
#print "tid=\"$tid\", pid=\"$pid\"\n";
#print "picks=" . (join ",", @picks) . "\n";
#print "wcflags=" . (join ",", @wcflags) . "\n";
         print "<p>information missing!</p>\n";
      }

   } else {
      print "<p>unknown submit type</p>\n";
   }

} else {
   print "<p>Sorry, but we only recognize GET and POST.</p>\n";

}

print $query->end_html;

