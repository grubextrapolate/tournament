#!/usr/bin/perl -wT
# This is pickedit.pl, which edits pick info

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
my %teams;
my @team_ids;
my %players;
my @player_ids;

# ------------------------------------------------------------
# Create an instance of CGI
my $query = new CGI;

# Send a MIME header
print $query->header("text/html");

print $query->start_html(-title => "edit pick",
			 -bgcolor => "#FFFFFF");

if ($query->request_method eq "GET") {

   print "<h2>Edit a pick:</h2>\n";
   print qq(<form method="POST" action="pickedit.pl">\n);

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

   $sql = "SELECT * FROM divisions ORDER BY tourneyid,name";

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

         $divisions{$row->{id}} = "$tourneys{$row->{tourneyid}}, $row->{name}";
         push @division_ids, $row->{id};
      }
   }

   # Finish that database call
   $sth->finish;

   $sql = "SELECT * FROM teams ORDER BY divisionid, seed, name";

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

         $teams{$row->{id}} = "($row->{seed}) $row->{name}";
         push @team_ids, $row->{id};
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

   $sql = "SELECT * FROM picks ORDER BY tourneyid, playerid, teamid";

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
         if ($row->{wildcard} == 1) {
            $entries{$row->{id}} = "$tourneys{$row->{tourneyid}}, $players{$row->{playerid}}, *$teams{$row->{teamid}}";
         } elsif ($row->{wildcard} == 2) {
            $entries{$row->{id}} = "$tourneys{$row->{tourneyid}}, $players{$row->{playerid}}, #$teams{$row->{teamid}}";
         } else {
            $entries{$row->{id}} = "$tourneys{$row->{tourneyid}}, $players{$row->{playerid}}, $teams{$row->{teamid}}";
         }
         push @entry_ids, $row->{id};
      }

      print "<p>" . $query->popup_menu(-name => "entries",
                                   -values => \@entry_ids,
                                   -labels => \%entries) . "\n";

      print $query->submit(-name => "submit", 
                           -value => "edit entry") . "\n";
      print $query->submit(-name => "submit",
                           -value => "delete entry") . "\n</p><hr>";

   } else {
      print "<P>No picks to display!</P>\n";
   }

   # Finish that database call
   $sth->finish;

   print "</form>\n";

   print qq(<h2>Create New pick:</h2>\n);
   print qq(<form method="POST" action="pickedit.pl">\n);

   print "<p>\n";
   print "player: " . $query->popup_menu(-name => "players",
                                         -values => \@player_ids,
                                         -labels => \%players) . "<br>\n";

   print "tournament: " . $query->popup_menu(-name => "tourneys",
                                             -values => \@tourney_ids,
                                             -labels => \%tourneys) . "<br>\n";

   print "team: " . $query->popup_menu(-name => "teams",
                                       -values => \@team_ids,
                                       -labels => \%teams) . "<br>\n";

   print "wildcard: " . $query->textfield(-name => "wildcard",
                                          -size => 5,
                                          -maxlength => 1) . "<br>\n";

   print $query->submit(-name => "submit", -value => "add new entry");
   print $query->reset(-value => "reset form");
   print "</p><hr>\n";

   print "</form>\n";

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

} elsif ($query->request_method eq "POST") {

   if ($query->param('submit') eq "add new entry") {

      my $player = $query->param('players');
      my $tid = $query->param('tourneys');
      my $team = $query->param('teams');
      my $wildcard = $query->param('wildcard') || 0;
      if ($player && $tid && $team) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "INSERT INTO picks SET ";
         $sql .= "playerid = " . $dbh->quote($player);
         $sql .= ", teamid = " . $dbh->quote($team);
         $sql .= ", wildcard = " . $dbh->quote($wildcard);
         $sql .= ", tourneyid = " . $dbh->quote($tid);

         # Prepare the query
         my $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         my $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # Finish that database call
         $sth->finish;

         # Disconnect, even though it isn't really necessary
         $dbh->disconnect;

         print "<p>add entry successful!</p>\n";

      } else {
         print "<p>player, team, and tournament mandatory!</p>\n";
      }

   } elsif ($query->param('submit') eq "delete entry") {

      my $id = $query->param('entries');
      if ($id) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "DELETE FROM picks WHERE ";
         $sql .= "id = " . $dbh->quote($id);

         # Prepare the query
         my $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         my $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # Finish that database call
         $sth->finish;

         # Disconnect, even though it isn't really necessary
         $dbh->disconnect;

         print "<p>delete entry successful!</p>\n";

      } else {
         print "<p>no id given!</p>\n";
      }

   } elsif ($query->param('submit') eq "edit entry") {

      my $id = $query->param('entries');
      if ($id) {

         print qq(<form method="post" action="pickedit.pl">\n);

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "SELECT * FROM tournaments ORDER BY year";

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

         $sql = "SELECT * FROM divisions ORDER BY tourneyid,name";

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

               $divisions{$row->{id}} = "$tourneys{$row->{tourneyid}}, $row->{name}";
               push @division_ids, $row->{id};
            }
         }

         # Finish that database call
         $sth->finish;

         $sql = "SELECT * FROM teams ORDER BY divisionid, seed, name";

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

               $teams{$row->{id}} = "($row->{seed}) $row->{name}";
               push @team_ids, $row->{id};
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

         $sql = "SELECT * FROM picks WHERE ";
         $sql .= "id = " . $dbh->quote($id);

         # Prepare the query
         $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         my $row;
         $rc = $sth->rows;
         # If we received rows from the SELECT, print them out
         if ($rc) {

            $row = $sth->fetchrow_hashref;

         }

         # Finish that database call
         $sth->finish;

         print "<p>id: $row->{id}<br>\n";
         print $query->hidden(-name => 'entryid',
                          -value => $row->{id}) . "\n";

         print "player: " . $query->popup_menu(-name => "players",
                                               -default => $row->{playerid},
                                               -override => 1,
                                               -values => \@player_ids,
                                               -labels => \%players) . "<br>\n";

         print "tournament: " . $query->popup_menu(-name => "tourneys",
                                                   -default => $row->{tourneyid},
                                                   -override => 1,
                                                   -values => \@tourney_ids,
                                                   -labels => \%tourneys) . "<br>\n";

         print "team: " . $query->popup_menu(-name => "teams",
                                             -default => $row->{teamid},
                                             -override => 1,
                                             -values => \@team_ids,
                                             -labels => \%teams) . "<br>\n";

         print "wildcard: " . $query->textfield(-name => "wildcard",
                                                -default => $row->{wildcard},
                                                -override => 1,
                                                -size => 5,
                                                -maxlength => 1) . "<br>\n";

         print $query->submit(-name => "submit", -value => "change entry");
         print $query->reset(-value => "reset form");
         print "</p><hr>\n";

         print "</form>\n";

         # Disconnect, even though it isn't really necessary
         $dbh->disconnect;

      } else {
         print "<p>no id given!</p>\n";
      }

   } elsif ($query->param('submit') eq "change entry") {

      my $id = $query->param('entryid');
      my $team = $query->param('teams');
      my $player = $query->param('players');
      my $wildcard = $query->param('wildcard');
      my $tid = $query->param('tourneys');
      if ($id && $player && $team && $tid) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "UPDATE picks SET ";
         $sql .= "playerid = " . $dbh->quote($player);
         $sql .= ", teamid = " . $dbh->quote($team);
         $sql .= ", wildcard = " . $dbh->quote($wildcard);
         $sql .= ", tourneyid = " . $dbh->quote($tid);
         $sql .=" WHERE id=" . $dbh->quote($id);

         # Prepare the query
         my $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         my $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # Finish that database call
         $sth->finish;

         # Disconnect, even though it isn't really necessary
         $dbh->disconnect;

         print "<p>change entry successful!</p>\n";

      } else {
         print "<p>id, team1, team2, and tournament mandatory!</p>\n";
      }

   } else {
      print "<p>unknown submit type</p>\n";
   }

} else {
   print "<p>Sorry, but we only recognize GET and POST.</p>\n";

}

print $query->end_html;

