.#!/usr/bin/perl -wT
# This is bracket.pl, which displays bracket info
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

my %divisions;
my %division_seeds;
my %tourneys;
my @tourney_ids;
my %teams;
my %players;
my %seeds;
my %scores;
my %ranks;
my %wcwins;
my %wcscores;
my @games;
my @dwinners;
my %pick_syms;

# ------------------------------------------------------------
# Create an instance of CGI
my $query = new CGI;

my $tid = $query->param('tournament') || 0;

# Send a MIME header
print $query->header("text/html");

if (($query->request_method eq "GET") && ($tid == 0)) {

   print $query->start_html(-title => "choose a tournament",
                            -bgcolor => "#FFFFFF");

   print qq(<form method="post" action="bracket.pl">\n);

   # ------------------------------------------------------------
   # Connect to the database
   my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                          $dbusername, $dbpassword);
   die "DBI error from connect: ", $DBI::errstr unless $dbh;

   my $sql = "SELECT * FROM tournaments";

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

   print "<p>" . $query->popup_menu(-name => "tournament",
                                    -values => \@tourney_ids,
                                    -labels => \%tourneys) . "\n";

   print $query->submit(-name => "submit",
                        -value => "view standings") . "\n</p>";

   print "</form>\n";

} elsif ((($query->request_method eq "POST") && ($tid != 0)) ||
         (($query->request_method eq "GET") && ($tid != 0))) {

   my $tname;
   my $tupdate;

   print $query->start_html(-title => "tournament brackets",
                            -bgcolor => "#FFFFFF");

   # ------------------------------------------------------------
   # Connect to the database
   my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                          $dbusername, $dbpassword);
   die "DBI error from connect: ", $DBI::errstr unless $dbh;

   my $sql = "SELECT * FROM players";

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

         $players{$row->{id}} = $row;

      }
   }

   # Finish that database call
   $sth->finish;

   $sql = "SELECT * FROM tournaments ";
   $sql .= "WHERE id = " . $dbh->quote($tid);

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
      my $row = $sth->fetchrow_hashref;

      $tname = "$row->{name}, $row->{year}";
      $tupdate = $row->{lastupdate};
   }

   # Finish that database call
   $sth->finish;

   $sql = "SELECT * FROM divisions ";
   $sql .= "WHERE tourneyid = " . $dbh->quote($tid);

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
         push @{$division_seeds{$row->{id}}}, "";

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

               $teams{$row2->{id}} = $row2->{name};
               $seeds{$row2->{id}} = $row2->{seed};
               push @{$division_seeds{$row2->{divisionid}}}, $row2->{id};

               my $sql3 = "SELECT playerid FROM picks ";
               $sql3 .= "WHERE tourneyid = " . $dbh->quote($tid);
               $sql3 .= " AND teamid = " . $dbh->quote($row2->{id});

               # Send the query
               my $sth3 = $dbh->prepare($sql3);
               die "DBI error with prepare:", $sth3->errstr unless $sth3;

               # Execute the query
               my $result3 = $sth3->execute;
               die "DBI error with execute:", $sth3->errstr unless $result3;

               # If we received artists from the SELECT, print them out
               $pick_syms{$row2->{id}} = "[";
               my $rc3 = $sth3->rows;
               if ($rc3) {

                  # Iterate through artist IDs and names
                  my $row3;
                  while ($row3 = $sth3->fetchrow_hashref) {
                     $pick_syms{$row2->{id}} .= $players{$row3->{playerid}}->{symbol};
                  }
               }
               $pick_syms{$row2->{id}} .= "]";

               # Finish that database call
               $sth3->finish;


            }
         }

         # Finish that database call
         $sth2->finish;
      }
   }
   $teams{0} = "";
   $seeds{0} = 0;
   $pick_syms{0} = "[]";

   # Finish that database call
   $sth->finish;

   $sql = "SELECT * FROM scores ";
   $sql .= "WHERE tourneyid = " . $dbh->quote($tid);

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
         if ($seeds{$row->{teamid1}} < $seeds{$row->{teamid2}}) {
            my $tmpvar = "$row->{teamid1},$row->{teamid2}";
            $scores{$tmpvar} = "$row->{score1}-$row->{score2}";
         } else {
            my $tmpvar = "$row->{teamid2},$row->{teamid1}";
            $scores{$tmpvar} = "$row->{score2}-$row->{score1}";
         }
      }
   }

   # Finish that database call
   $sth->finish;

   print qq(<h2>$tname</h2>\n);
   print qq(<p>Last Updated $tupdate</p>\n);
   print qq(<p>number in round brackets is seed. symbols in square brackets indicate players who have picked this team.</p>\n);

   print qq(<p><a href="display.pl?tournament=3">view pool standings</a></p>\n);

   print qq{<p>( };
   my $j = keys %players;
   foreach my $play (keys %players) {
      print qq($players{$play}->{name}=$players{$play}->{symbol});
      if ($j != 1) { print ", "; }
      $j--;
   }
   print qq{ )</p>\n};

   my %tscores;
   foreach my $did (keys %divisions) {
      my $tscore = 0;
      my $twins = 0;
      my @round1;
      my @round2;
      my @round3;
      my @round4;
      my @round5;
      my $dwinner;

      print qq(<h3>$divisions{$did}</h3>\n);

      # translate seed pairings into order for first round
      push @round1, $division_seeds{$did}[1];
      push @round1, $division_seeds{$did}[16];
      push @round1, $division_seeds{$did}[8];
      push @round1, $division_seeds{$did}[9];
      push @round1, $division_seeds{$did}[5];
      push @round1, $division_seeds{$did}[12];
      push @round1, $division_seeds{$did}[4];
      push @round1, $division_seeds{$did}[13];
      push @round1, $division_seeds{$did}[6];
      push @round1, $division_seeds{$did}[11];
      push @round1, $division_seeds{$did}[3];
      push @round1, $division_seeds{$did}[14];
      push @round1, $division_seeds{$did}[7];
      push @round1, $division_seeds{$did}[10];
      push @round1, $division_seeds{$did}[2];
      push @round1, $division_seeds{$did}[15];

      for (my $i = 0; $i < 16; $i +=2) {
         if ($scores{"$round1[$i],$round1[$i+1]"}) { # game played
            $scores{"$round1[$i],$round1[$i+1]"} =~ m|(\d+)\-(\d+)|;
            my ($s1, $s2) = ($1, $2);
            $tscores{"r1$round1[$i]"} = $s1;
            $tscores{"r1$round1[$i+1]"} = $s2;
            if ($s1 > $s2) { # higher seed wins
               push @round2, $round1[$i];
            } else { # lower seed wins
               push @round2, $round1[$i+1];
            }
         } else { # game has not been played
            $tscores{"r1$round1[$i]"} = 0;
            $tscores{"r1$round1[$i+1]"} = 0;
            push @round2, 0;
         }
      }

      for (my $i = 0; $i < 8; $i +=2) {
         my $t1 = $round2[$i];
         my $t2 = $round2[$i+1];
         if ($seeds{$t1} < $seeds{$t2}) {
            if ($scores{"$round2[$i],$round2[$i+1]"}) { # game played
               $scores{"$round2[$i],$round2[$i+1]"} =~ m|(\d+)\-(\d+)|;
               my ($s1, $s2) = ($1, $2);
               $tscores{"r2$round2[$i]"} = $s1;
               $tscores{"r2$round2[$i+1]"} = $s2;
               if ($s1 > $s2) { # lower numbered seed wins
                  push @round3, $round2[$i];
               } else { # higher numbered seed wins
                  push @round3, $round2[$i+1];
               }
            } else { # game has not been played
               $tscores{"r2$round2[$i]"} = 0;
               $tscores{"r2$round2[$i+1]"} = 0;
               push @round3, 0;
            }
         } else {
            if ($scores{"$round2[$i+1],$round2[$i]"}) { # game played
               $scores{"$round2[$i+1],$round2[$i]"} =~ m|(\d+)\-(\d+)|;
               my ($s2, $s1) = ($1, $2);
               $tscores{"r2$round2[$i]"} = $s1;
               $tscores{"r2$round2[$i+1]"} = $s2;
               if ($s2 > $s1) { # lower numbered seed wins
                  push @round3, $round2[$i+1];
               } else { # higher numbered seed wins
                  push @round3, $round2[$i];
               }
            } else { # game has not been played
               $tscores{"r2$round2[$i]"} = 0;
               $tscores{"r2$round2[$i+1]"} = 0;
               push @round3, 0;
            }
         }
      }

      for (my $i = 0; $i < 4; $i +=2) {
         my $t1 = $round3[$i];
         my $t2 = $round3[$i+1];
         if ($seeds{$t1} < $seeds{$t2}) {
            if ($scores{"$round3[$i],$round3[$i+1]"}) { # game played
               $scores{"$round3[$i],$round3[$i+1]"} =~ m|(\d+)\-(\d+)|;
               my ($s1, $s2) = ($1, $2);
               $tscores{"r3$round3[$i]"} = $s1;
               $tscores{"r3$round3[$i+1]"} = $s2;
               if ($s1 > $s2) { # lower numbered seed wins
                  push @round4, $round3[$i];
               } else { # higher numbered seed wins
                  push @round4, $round3[$i+1];
               }
            } else { # game has not been played
               $tscores{"r3$round3[$i]"} = 0;
               $tscores{"r3$round3[$i+1]"} = 0;
               push @round4, 0;
            }
         } else {
            if ($scores{"$round3[$i+1],$round3[$i]"}) { # game played
               $scores{"$round3[$i+1],$round3[$i]"} =~ m|(\d+)\-(\d+)|;
               my ($s2, $s1) = ($1, $2);
               $tscores{"r3$round3[$i]"} = $s1;
               $tscores{"r3$round3[$i+1]"} = $s2;
               if ($s2 > $s1) { # lower numbered seed wins
                  push @round4, $round3[$i+1];
               } else { # higher numbered seed wins
                  push @round4, $round3[$i];
               }
            } else { # game has not been played
               $tscores{"r3$round3[$i]"} = 0;
               $tscores{"r3$round3[$i+1]"} = 0;
               push @round4, 0;
            }
         }
      }

      my $t1 = $round4[0];
      my $t2 = $round4[1];
      if ($seeds{$t1} < $seeds{$t2}) {
         if ($scores{"$round4[0],$round4[1]"}) { # game played
            $scores{"$round4[0],$round4[1]"} =~ m|(\d+)\-(\d+)|;
            my ($s1, $s2) = ($1, $2);
            $tscores{"r4$round4[0]"} = $s1;
            $tscores{"r4$round4[1]"} = $s2;
            if ($s1 > $s2) { # lower numbered seed wins
               $dwinner = $round4[0];
            } else { # higher numbered seed wins
               $dwinner = $round4[1];
            }
         } else { # game has not been played
            $tscores{"r4$round4[0]"} = 0;
            $tscores{"r4$round4[1]"} = 0;
            $dwinner = 0;
         }
      } else {
         if ($scores{"$round4[1],$round4[0]"}) { # game played
            $scores{"$round4[1],$round4[0]"} =~ m|(\d+)\-(\d+)|;
            my ($s2, $s1) = ($1, $2);
            $tscores{"r4$round4[0]"} = $s1;
            $tscores{"r4$round4[1]"} = $s2;
            if ($s2 > $s1) { # lower numbered seed wins
               $dwinner = $round4[1];
            } else { # higher numbered seed wins
               $dwinner = $round4[0];
            }
         } else { # game has not been played
            $tscores{"r4$round4[0]"} = 0;
            $tscores{"r4$round4[1]"} = 0;
            $dwinner = 0;
         }
      }
      push @dwinners, $dwinner;

      print <<END;

<table border="0" cellspacing="0" cellpadding="2" width="100%">
  <tr>
    <th width="20%">First Round</th>
    <th width="20%">Second Round</th>
    <th width="20%">Sweet Sixteen</th>
    <th width="20%">Elite Eight</th>
    <th width="20%">Final Four</th>
  </tr>

  <tr>
    <td bgcolor="#555555">($seeds{$round1[0]}) $teams{$round1[0]} $pick_syms{$round1[0]} - $tscores{"r1$round1[0]"}</td>
  </tr>
  <tr>
    <td bgcolor="#555555"></td>
    <td bgcolor="#777777">($seeds{$round2[0]}) $teams{$round2[0]} $pick_syms{$round2[0]} - $tscores{"r2$round2[0]"}</td>
  </tr>
  <tr>
    <td bgcolor="#555555">($seeds{$round1[1]}) $teams{$round1[1]} $pick_syms{$round1[1]} - $tscores{"r1$round1[1]"}</td>
    <td bgcolor="#777777"></td>
  </tr>

  <tr>
    <td></td>
    <td bgcolor="#777777"></td>
    <td bgcolor="#aaaaaa">($seeds{$round3[0]}) $teams{$round3[0]} $pick_syms{$round3[0]} - $tscores{"r3$round3[0]"}</td>
  </tr>

  <tr>
    <td bgcolor="#555555">($seeds{$round1[2]}) $teams{$round1[2]} $pick_syms{$round1[2]} - $tscores{"r1$round1[2]"}</td>
    <td bgcolor="#777777"></td>
    <td bgcolor="#aaaaaa"></td>
  </tr>
  <tr>
    <td bgcolor="#555555"></td>
    <td bgcolor="#777777">($seeds{$round2[1]}) $teams{$round2[1]} $pick_syms{$round2[1]} - $tscores{"r2$round2[1]"}</td>
    <td bgcolor="#aaaaaa"></td>
  </tr>
  <tr>
    <td bgcolor="#555555">($seeds{$round1[3]}) $teams{$round1[3]} $pick_syms{$round1[3]} - $tscores{"r1$round1[3]"}</td>
    <td></td>
    <td bgcolor="#aaaaaa"></td>
  </tr>

  <tr>
    <td></td>
    <td></td>
    <td bgcolor="#aaaaaa"></td>
    <td bgcolor="#dddddd">($seeds{$round4[0]}) $teams{$round4[0]} $pick_syms{$round4[0]} - $tscores{"r4$round4[0]"}</td>
  </tr>

  <tr>
    <td bgcolor="#555555">($seeds{$round1[4]}) $teams{$round1[4]} $pick_syms{$round1[4]} - $tscores{"r1$round1[4]"}</td>
    <td></td>
    <td bgcolor="#aaaaaa"></td>
    <td bgcolor="#dddddd"></td>
  </tr>
  <tr>
    <td bgcolor="#555555"></td>
    <td bgcolor="#777777">($seeds{$round2[2]}) $teams{$round2[2]} $pick_syms{$round2[2]} - $tscores{"r2$round2[2]"}</td>
    <td bgcolor="#aaaaaa"></td>
    <td bgcolor="#dddddd"></td>
  </tr>
  <tr>
    <td bgcolor="#555555">($seeds{$round1[5]}) $teams{$round1[5]} $pick_syms{$round1[5]} - $tscores{"r1$round1[5]"}</td>
    <td bgcolor="#777777"></td>
    <td bgcolor="#aaaaaa"></td>
    <td bgcolor="#dddddd"></td>
  </tr>

  <tr>
    <td></td>
    <td bgcolor="#777777"></td>
    <td bgcolor="#aaaaaa">($seeds{$round3[1]}) $teams{$round3[1]} $pick_syms{$round3[1]} - $tscores{"r3$round3[1]"}</td>
    <td bgcolor="#dddddd"></td>
  </tr>

  <tr>
    <td bgcolor="#555555">($seeds{$round1[6]}) $teams{$round1[6]} $pick_syms{$round1[6]} - $tscores{"r1$round1[6]"}</td>
    <td bgcolor="#777777"></td>
    <td></td>
    <td bgcolor="#dddddd"></td>
  </tr>
  <tr>
    <td bgcolor="#555555"></td>
    <td bgcolor="#777777">($seeds{$round2[3]}) $teams{$round2[3]} $pick_syms{$round2[3]} - $tscores{"r2$round2[3]"}</td>
    <td></td>
    <td bgcolor="#dddddd"></td>
  </tr>
  <tr>
    <td bgcolor="#555555">($seeds{$round1[7]}) $teams{$round1[7]} $pick_syms{$round1[7]} - $tscores{"r1$round1[7]"}</td>
    <td></td>
    <td></td>
    <td bgcolor="#dddddd"></td>
  </tr>

  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td bgcolor="#dddddd"></td>
    <td bgcolor="#eeeeee">($seeds{$dwinner}) $teams{$dwinner} $pick_syms{$dwinner}</td>
  </tr>

  <tr>
    <td bgcolor="#555555">($seeds{$round1[8]}) $teams{$round1[8]} $pick_syms{$round1[8]} - $tscores{"r1$round1[8]"}</td>
    <td></td>
    <td></td>
    <td bgcolor="#dddddd"></td>
  </tr>
  <tr>
    <td bgcolor="#555555"></td>
    <td bgcolor="#777777">($seeds{$round2[4]}) $teams{$round2[4]} $pick_syms{$round2[4]} - $tscores{"r2$round2[4]"}</td>
    <td></td>
    <td bgcolor="#dddddd"></td>
  </tr>
  <tr>
    <td bgcolor="#555555">($seeds{$round1[9]}) $teams{$round1[9]} $pick_syms{$round1[9]} - $tscores{"r1$round1[9]"}</td>
    <td bgcolor="#777777"></td>
    <td></td>
    <td bgcolor="#dddddd"></td>
  </tr>

  <tr>
    <td></td>
    <td bgcolor="#777777"></td>
    <td bgcolor="#aaaaaa">($seeds{$round3[2]}) $teams{$round3[2]} $pick_syms{$round3[2]} - $tscores{"r3$round3[2]"}</td>
    <td bgcolor="#dddddd"></td>
  </tr>

  <tr>
    <td bgcolor="#555555">($seeds{$round1[10]}) $teams{$round1[10]} $pick_syms{$round1[10]} - $tscores{"r1$round1[10]"}</td>
    <td bgcolor="#777777"></td>
    <td bgcolor="#aaaaaa"></td>
    <td bgcolor="#dddddd"></td>
  </tr>
  <tr>
    <td bgcolor="#555555"></td>
    <td bgcolor="#777777">($seeds{$round2[5]}) $teams{$round2[5]} $pick_syms{$round2[5]} - $tscores{"r2$round2[5]"}</td>
    <td bgcolor="#aaaaaa"></td>
    <td bgcolor="#dddddd"></td>
  </tr>
  <tr>
    <td bgcolor="#555555">($seeds{$round1[11]}) $teams{$round1[11]} $pick_syms{$round1[11]} - $tscores{"r1$round1[11]"}</td>
    <td></td>
    <td bgcolor="#aaaaaa"></td>
    <td bgcolor="#dddddd"></td>
  </tr>

  <tr>
    <td></td>
    <td></td>
    <td bgcolor="#aaaaaa"></td>
    <td bgcolor="#dddddd">($seeds{$round4[1]}) $teams{$round4[1]} $pick_syms{$round4[1]} - $tscores{"r4$round4[1]"}</td>
  </tr>

  <tr>
    <td bgcolor="#555555">($seeds{$round1[12]}) $teams{$round1[12]} $pick_syms{$round1[12]} - $tscores{"r1$round1[12]"}</td>
    <td></td>
    <td bgcolor="#aaaaaa"></td>
  </tr>
  <tr>
    <td bgcolor="#555555"></td>
    <td bgcolor="#777777">($seeds{$round2[6]}) $teams{$round2[6]} $pick_syms{$round2[6]} - $tscores{"r2$round2[6]"}</td>
    <td bgcolor="#aaaaaa"></td>
  </tr>
  <tr>
    <td bgcolor="#555555">($seeds{$round1[13]}) $teams{$round1[13]} $pick_syms{$round1[13]} - $tscores{"r1$round1[13]"}</td>
    <td bgcolor="#777777"></td>
    <td bgcolor="#aaaaaa"></td>
  </tr>

  <tr>
    <td></td>
    <td bgcolor="#777777"></td>
    <td bgcolor="#aaaaaa">($seeds{$round3[3]}) $teams{$round3[3]} $pick_syms{$round3[3]} - $tscores{"r3$round3[3]"}</td>
  </tr>

  <tr>
    <td bgcolor="#555555">($seeds{$round1[14]}) $teams{$round1[14]} $pick_syms{$round1[14]} - $tscores{"r1$round1[14]"}</td>
    <td bgcolor="#777777"></td>
  </tr>
  <tr>
    <td bgcolor="#555555"></td>
    <td bgcolor="#777777">($seeds{$round2[7]}) $teams{$round2[7]} $pick_syms{$round2[7]} - $tscores{"r2$round2[7]"}</td>
  </tr>
  <tr>
    <td bgcolor="#555555">($seeds{$round1[15]}) $teams{$round1[15]} $pick_syms{$round1[15]} - $tscores{"r1$round1[15]"}</td>
  </tr>

</table>

END

   }

      my $twinner = 0;
      for (my $i = 0; $i < 4; $i +=2) {
         my $t1 = $dwinners[$i];
         my $t2 = $dwinners[$i+1];
         if ($seeds{$t1} < $seeds{$t2}) {
            if ($scores{"$dwinners[$i],$dwinners[$i+1]"}) { # game played
               $scores{"$dwinners[$i],$dwinners[$i+1]"} =~ m|(\d+)\-(\d+)|;
               my ($s1, $s2) = ($1, $2);
               $tscores{"r6$dwinners[$i]"} = $s1;
               $tscores{"r6$dwinners[$i+1]"} = $s2;
               if ($s1 > $s2) { # lower numbered seed wins
                  push @dwinners, $dwinners[$i];
               } else { # higher numbered seed wins
                  push @dwinners, $dwinners[$i+1];
               }
            } else { # game has not been played
               $tscores{"r6$dwinners[$i]"} = 0;
               $tscores{"r6$dwinners[$i+1]"} = 0;
               push @dwinners, 0;
            }
         } else {
            if ($scores{"$dwinners[$i+1],$dwinners[$i]"}) { # game played
               $scores{"$dwinners[$i+1],$dwinners[$i]"} =~ m|(\d+)\-(\d+)|;
               my ($s2, $s1) = ($1, $2);
               $tscores{"r6$dwinners[$i]"} = $s1;
               $tscores{"r6$dwinners[$i+1]"} = $s2;
               if ($s2 > $s1) { # lower numbered seed wins
                  push @dwinners, $dwinners[$i+1];
               } else { # higher numbered seed wins
                  push @dwinners, $dwinners[$i];
               }
            } else { # game has not been played
               $tscores{"r6$dwinners[$i]"} = 0;
               $tscores{"r6$dwinners[$i+1]"} = 0;
               push @dwinners, 0;
            }
         }
      }

      my $t1 = $dwinners[4];
      my $t2 = $dwinners[5];
      if ($seeds{$t1} < $seeds{$t2}) {
         if ($scores{"$dwinners[4],$dwinners[5]"}) { # game played
            $scores{"$dwinners[4],$dwinners[5]"} =~ m|(\d+)\-(\d+)|;
            my ($s1, $s2) = ($1, $2);
            $tscores{"r7$dwinners[4]"} = $s1;
            $tscores{"r7$dwinners[5]"} = $s2;
            if ($s1 > $s2) { # lower numbered seed wins
               $twinner = $dwinners[4];
            } else { # higher numbered seed wins
               $twinner = $dwinners[5];
            }
         } else { # game has not been played
            $tscores{"r7$dwinners[4]"} = 0;
            $tscores{"r7$dwinners[5]"} = 0;
            $twinner = 0;
         }
      } else {
         if ($scores{"$dwinners[5],$dwinners[4]"}) { # game played
            $scores{"$dwinners[5],$dwinners[4]"} =~ m|(\d+)\-(\d+)|;
            my ($s2, $s1) = ($1, $2);
            $tscores{"r7$dwinners[4]"} = $s1;
            $tscores{"r7$dwinners[5]"} = $s2;
            if ($s2 > $s1) { # lower numbered seed wins
               $twinner = $dwinners[5];
            } else { # higher numbered seed wins
               $twinner = $dwinners[4];
            }
         } else { # game has not been played
            $tscores{"r7$dwinners[4]"} = 0;
            $tscores{"r7$dwinners[5]"} = 0;
            $twinner = 0;
         }
      }
   print <<END;

<h2></h2>

<table border="0" cellspacing="0" cellpadding="2" width="100%">
  <tr>
    <th width="20%">Final Four</th>
    <th width="20%">National Championship</th>
    <th width="20%">National Champion</th>
    <th width="20%">National Championship</th>
    <th width="20%">Final Four</th>
  </tr>

  <tr>
    <td bgcolor="#555555">($seeds{$dwinners[0]}) $teams{$dwinners[0]} $pick_syms{$dwinners[0]} - $tscores{"r6$dwinners[0]"}</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td bgcolor="#555555"></td>
    <td bgcolor="#777777">($seeds{$dwinners[4]}) $teams{$dwinners[4]} $pick_syms{$dwinners[4]} - $tscores{"r7$dwinners[4]"}</td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td bgcolor="#555555">($seeds{$dwinners[1]}) $teams{$dwinners[1]} $pick_syms{$dwinners[1]} - $tscores{"r6$dwinners[1]"}</td>
    <td></td>
    <td bgcolor="#cccccc">($seeds{$twinner}) $teams{$twinner} $pick_syms{$twinner}</td>
    <td></td>
    <td bgcolor="#555555">($seeds{$dwinners[2]}) $teams{$dwinners[2]} $pick_syms{$dwinners[2]} - $tscores{"r6$dwinners[2]"}</td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td bgcolor="#777777">($seeds{$dwinners[5]}) $teams{$dwinners[5]} $pick_syms{$dwinners[5]} - $tscores{"r7$dwinners[5]"}</td>
    <td bgcolor="#555555"></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td bgcolor="#555555">($seeds{$dwinners[3]}) $teams{$dwinners[3]} $pick_syms{$dwinners[3]} - $tscores{"r6$dwinners[3]"}</td>
  </tr>

</table>

END

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

} else {
   print "<p>Sorry, but we only recognize GET and POST.</p>\n";

}

print $query->end_html;

