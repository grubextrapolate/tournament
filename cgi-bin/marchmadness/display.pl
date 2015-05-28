#!/usr/bin/perl -wT
# This is display.pl, which displays standing info

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use HTTP::Date;

use lib qw(.);
use MMConstants;

# Remove buffering
$| = 1;

my %divisions;
my %tourneys;
my @tourney_ids;
my %teams;
my %players;
my %seeds;
my %dids;
my %wins;
my %pwins;
my %elims;
my %scores;
my %ranks;
my %wcwins;
my %wcscores;
my @games;
my %pick_syms;

sub sortByRank
{
             $scores{$b} <=> $scores{$a}
                         ||
              $pwins{$b} <=> $pwins{$a}
                         ||
    $players{$a}->{name} cmp $players{$b}->{name};
}

# ------------------------------------------------------------
# Create an instance of CGI
my $query = new CGI;

my $tid = $query->param('tournament') || 0;

# Send a MIME header
print $query->header("text/html");

if (($query->request_method eq "GET") && ($tid == 0)) {

   print $query->start_html(-title => "choose a tournament",
                         -meta => { 'viewport' => "width=320; initial-scale=1.0;" },
                            -bgcolor => "#FFFFFF");

   print qq(<form method="post" action="display.pl">\n);

   # ------------------------------------------------------------
   # Connect to the database
   my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
   die "DBI error from connect: ", $DBI::errstr unless $dbh;

   my $sql = "SELECT * FROM tournaments";
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

   print "<p>" . $query->popup_menu(-name => "tournament",
                                    -values => \@tourney_ids,
                                    -labels => \%tourneys) . "\n";

   print $query->submit(-name => "submit",
                        -value => "view standings") . "\n</p>";

   print "</form>\n";

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

} elsif ((($query->request_method eq "POST") && ($tid != 0)) ||
         (($query->request_method eq "GET") && ($tid != 0))) {

   my $tname;
   my $tupdate;
   my $tcutoff;

   print $query->start_html(-title => "tournament standings",
                         -meta => { 'viewport' => "width=320; initial-scale=1.0;" },
                            -bgcolor => "#FFFFFF");

   # ------------------------------------------------------------
   # Connect to the database
   my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
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
      $tcutoff = $row->{cutoff};
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

         my $sql2 = "SELECT * FROM teams ";
         $sql2 .= "WHERE divisionid = " . $dbh->quote($row->{id});

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
               $dids{$row2->{id}} = $row2->{divisionid};

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
               my $rc3 = $sth3->rows;
               if ($rc3) {

                  # Iterate through artist IDs and names
                  my $row3;
                  $pick_syms{$row2->{id}} = "";
                  while ($row3 = $sth3->fetchrow_hashref) {
                     if (!($pick_syms{$row2->{id}} =~ /$players{$row3->{playerid}}->{symbol}/))
                     {
                        $pick_syms{$row2->{id}} .= $players{$row3->{playerid}}->{symbol};
                     }
                  }
               }

               # Finish that database call
               $sth3->finish;
            }
         }

         # Finish that database call
         $sth2->finish;
      }
   }

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
         my $game;
         if ($row->{score1} > $row->{score2}) {
            $wins{$row->{teamid1}}++;
            $elims{$row->{teamid2}}++;
            $game = "$teams{$row->{teamid1}} $row->{score1} - ";
            $game .= "$teams{$row->{teamid2}} $row->{score2}";
            if ($pick_syms{$row->{teamid1}} && $pick_syms{$row->{teamid2}}) {
               $game .= " (+$pick_syms{$row->{teamid1}} -$pick_syms{$row->{teamid2}})";
            } elsif ($pick_syms{$row->{teamid1}}) {
               $game .= " (+$pick_syms{$row->{teamid1}})";
            } elsif ($pick_syms{$row->{teamid2}}) {
               $game .= " (-$pick_syms{$row->{teamid2}})";
            } else {
               $game .= " ()";
            }
         } else {
            $wins{$row->{teamid2}}++;
            $elims{$row->{teamid1}}++;
            $game = "$teams{$row->{teamid2}} $row->{score2} - ";
            $game .= "$teams{$row->{teamid1}} $row->{score1}";
            if ($pick_syms{$row->{teamid2}} && $pick_syms{$row->{teamid1}}) {
               $game .= " (+$pick_syms{$row->{teamid2}} -$pick_syms{$row->{teamid1}})";
            } elsif ($pick_syms{$row->{teamid2}}) {
               $game .= " (+$pick_syms{$row->{teamid2}})";
            } elsif ($pick_syms{$row->{teamid1}}) {
               $game .= " (-$pick_syms{$row->{teamid1}})";
            } else {
               $game .= " ()";
            }
         }
         push @games, $game;
      }
   }

   # Finish that database call
   $sth->finish;

   foreach my $pid (keys %players) {
      my $tscore = 0;
      my $twins = 0;

      $sql = "SELECT * FROM picks ";
      $sql .= "WHERE tourneyid = " . $dbh->quote($tid);
      $sql .= " AND playerid = " . $dbh->quote($pid);

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

            if (!$wins{$row->{teamid}}) { $wins{$row->{teamid}} = 0; }
            if (!$wcwins{$pid}) { $wcwins{$pid} = 0; }
            if (!$wcscores{$pid}) { $wcscores{$pid} = 0; }
            my $score = 0;
            if ($row->{wildcard} == 2)
            {
               if ($wins{$row->{teamid}} == 6)
               {
                  $score = ($seeds{$row->{teamid}} + 4) * 5;
                  $tscore += $score;
               }
            }
            else
            {
               $score = ($seeds{$row->{teamid}} + 4) * $wins{$row->{teamid}};
               $tscore += $score;
               $twins += $wins{$row->{teamid}};
            }

            if ($row->{wildcard} == 1) {
               $wcwins{$pid} += $wins{$row->{teamid}};
               $wcscores{$pid} += $score;
            }
         }
         $scores{$pid} = $tscore;
         $pwins{$pid}  = $twins;
      }

      # Finish that database call
      $sth->finish;
   }

#   my $i = 0;
#   foreach my $pid (sort { $scores{$b} <=> $scores{$a} } keys %scores) {
#      $i++;
#      $ranks{$pid} = $i;
#   }
   my $tmphashref = &rank_players(\%scores);
   %ranks = %{$tmphashref};

   print <<END;
<h2>$tname</h2>

<p>* indicates team was a wildcard choice.<br>
# indicates team was a bonus "winner" choice.<br>
<strike>team</strike> indicates a team which has been eliminated.<br>
Last Updated $tupdate</p>
<p>Pick Selection Cutoff $tcutoff</p>

<p>Rules: pick 2 teams from each region and 4 additional wildcard teams.  when
a team wins you get a score equal to their seed+4 (so a win by a 3 seed would
give 7 points). the "bonus" winner pick will give <b>no points</b> through the
individual games but will give a bonus of (seed + 4)*5 if they win the
tournament (so a win by a 3 seed would give 35 bonus points). person with the
highest total score at the end of the tournament wins.</p>

<p><a href="bracket.pl?tournament=$tid">view brackets</a></p>

<table border="1">
  <tr>
    <th width="5%">Rank</th>
    <th width="5%">Name</th>
    <th width="70%">Picks</th>
    <th width="10%">Total Wins /<br>Wildcard Wins</th>
    <th width="10%">Total Score /<br>Wildcard Score</th>
  </tr>
END

   foreach my $pid (sort sortByRank keys %players) {
      my $tscore = 0;
      my $twins = 0;

      $sql = "SELECT p.* FROM picks AS p, teams AS t, divisions AS d ";
      $sql .= "WHERE p.tourneyid = " . $dbh->quote($tid);
      $sql .= " AND p.playerid = " . $dbh->quote($pid);
      $sql .= " AND p.teamid = t.id";
      $sql .= " AND t.divisionid = d.id";
      $sql .= " ORDER BY p.wildcard, d.position, t.seed";

      # Send the query
      $sth = $dbh->prepare($sql);
      die "DBI error with prepare:", $sth->errstr unless $sth;

      # Execute the query
      $result = $sth->execute;
      die "DBI error with execute:", $sth->errstr unless $result;

      # If we received artists from the SELECT, print them out
      $rc = $sth->rows;
      if ($rc) {

         print <<END;
  <tr>
    <td valign="top" align="center">$ranks{$pid}</td>
    <td valign="top">$players{$pid}->{name}</td>
    <td width="300">
END

if (pastCutoff($tcutoff))
{

         print <<END;
<table border="1" width="100%">
  <tr  bgcolor="#eeeeee">
    <th width="70%">Team</th>
    <th width="10%">Seed</th>
    <th width="10%">Wins</th>
    <th width="10%">Score</th>
  </tr>
END

         my $i = 1;
         # Iterate through artist IDs and names
         my $row;
         while ($row = $sth->fetchrow_hashref) {

            my $score = 0;
            if ($row->{wildcard} == 2)
            {
               if ($wins{$row->{teamid}} == 6)
               {
                  $score = ($seeds{$row->{teamid}} + 4) * 5;
                  $tscore += $score;
               }
            }
            else
            {
               $score = ($seeds{$row->{teamid}} + 4) * $wins{$row->{teamid}};
               $tscore += $score;
               $twins += $wins{$row->{teamid}};
            }

            if ($i++ % 2 == 0)
            {
               print qq(  <tr bgcolor="#eeeeee">\n);
            }
            else
            {
               print qq(  <tr>\n);
            }
            print qq(    <td>);
            if ($elims{$row->{teamid}}) { print qq(<strike>); }
            if ($row->{wildcard} == 1) { print "*"; }
            elsif ($row->{wildcard} == 2) { print "#"; }
            print qq(<a href="team.pl?team=$row->{teamid}">) .
                  $teams{$row->{teamid}} . "</a>";
            if ($elims{$row->{teamid}}) { print qq(</strike>); }
            print qq(</td>\n);
            print qq(    <td align="center">$seeds{$row->{teamid}}</td>\n);
#            if ($row->{wildcard} == 2)
#            {
#               print qq(    <td align="center">);
#               if ($wins{$row->{teamid}} == 6)
#               {
#                  print "1";
#               }
#               else
#               {
#                  print "0";
#               }
#               print qq(</td>\n);
#            }
#            else
#            {
               print qq(    <td align="center">$wins{$row->{teamid}}</td>\n);
#            }
            print qq(    <td align="center">$score</td>\n);
            print qq(  </tr>\n);

         }

         print <<END;
</table>
END
}
else
{
   print "picks have been entered - not visible until tipoff";
}

         print <<END;
    </td>
    <td valign="top" align="center">$twins / $wcwins{$pid}</td>
    <td valign="top" align="center">$tscore / $wcscores{$pid}</td>
  </tr>
END

      }

      # Finish that database call
      $sth->finish;
   }

   print qq(</table>\n);

   print qq(<h2>Game Scores</h2>\n);

   print qq{<p>( };
   my $j = keys %players;
   foreach my $play (sort { $players{$a}->{name} cmp $players{$b}->{name} } keys %players) {
      print qq($players{$play}->{name}=$players{$play}->{symbol});
      if ($j != 1) { print ", "; }
      $j--;
   }
   print qq{ ) +=win, -=elimination</p>\n};

   print qq(<pre>\n);
   foreach my $game (@games) {
      print "$game\n";
   }
   print qq(</pre>\n);

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

} else {
   print "<p>Sorry, but we only recognize GET and POST.</p>\n";

}

print $query->end_html;

my $rank_players;
sub rank_players
{
   my $scores = shift;
   my @ranked;
   my %rankh;

   foreach my $pid (sort { $scores->{$b} <=> $scores->{$a} } keys %{scores})
   {
      push @ranked, $pid;
   }

   my $i = 1;
   $rankh{$ranked[0]} = 1;
   for (my $j = 1; $j < @ranked; $j++)
   {
      if ($scores->{$ranked[$j]} != $scores->{$ranked[$j - 1]})
      {
         # only increment rank if higher score.
         $i++;
      }
      $rankh{$ranked[$j]} = $i;
   }

   return \%rankh;
}
