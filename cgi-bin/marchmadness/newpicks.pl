#!/usr/bin/perl -wT
# This is newpicks.pl, which can be used to make picks
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

my %tourneys;
my @tourney_ids;
my %players;
my @player_ids;

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
   my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                          $dbusername, $dbpassword);
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

   print $query->submit(-name => "submit", 
                        -value => "continue") . "</p>\n";

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
         my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                                $dbusername, $dbpassword);
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
         $sql .= " ORDER BY id";

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
         print $query->hidden(-name => 'tourneyid',
                              -value => $tid) . "\n";
         print $query->hidden(-name => 'playerid',
                              -value => $player) . "\n";

         foreach my $did (keys %divisions) {

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
         print "<p>" . $query->hidden(-name => 'wildcard',
                                      -value => 1) . "\n";
         print $query->popup_menu(-name => "picks",
                                  -values => \@allteam_ids,
                                  -labels => \%allteams) . "<br>\n";

         print $query->hidden(-name => 'wildcard',
                                      -value => 1) . "\n";
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
         my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                                $dbusername, $dbpassword);
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

