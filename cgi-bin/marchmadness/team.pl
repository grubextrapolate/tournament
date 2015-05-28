#!/usr/bin/perl -wT
# This is team.pl, which displays standing info

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

my %teams;
my @team_ids;
my %divisions;
my %players;
my %seeds;
my %dids;
my %wins;
my %elims;
my %scores;
my %ranks;
my %wcwins;
my %wcscores;
my @games;
my %pick_syms;

# ------------------------------------------------------------
# Create an instance of CGI
my $query = new CGI;

my $tid = $query->param('team') || 0;

# Send a MIME header
print $query->header("text/html");

if (($query->request_method eq "GET") && ($tid == 0)) {

   print $query->start_html(-title => "choose a tournament",
                            -bgcolor => "#FFFFFF");

   print qq(<form method="post" action="team.pl">\n);

   # ------------------------------------------------------------
   # Connect to the database
   my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
   die "DBI error from connect: ", $DBI::errstr unless $dbh;

   my $sql = "SELECT y.name AS tname, y.year AS tyear, d.name AS dname,";
   $sql .= " t.id, t.name, t.seed";
   $sql .= " FROM tournaments AS y, divisions AS d, teams AS t";
   $sql .= " WHERE d.id = t.divisionid";
   $sql .= " AND d.tourneyid = y.id";
   $sql .= " ORDER BY y.year DESC, d.position, t.seed";

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

         $teams{$row->{id}} = "($row->{seed}) $row->{name}, ";
         $teams{$row->{id}} .= "$row->{tname}, $row->{tyear}, ";
         $teams{$row->{id}} .= "$row->{dname} region";
         push @team_ids, $row->{id};
      }
   }

   # Finish that database call
   $sth->finish;

   print "<p>" . $query->popup_menu(-name => "team",
                                    -values => \@team_ids,
                                    -labels => \%teams) . "\n";

   print $query->submit(-name => "submit",
                        -value => "view team") . "\n</p>";

   print "</form>\n";

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

} elsif ((($query->request_method eq "POST") && ($tid != 0)) ||
         (($query->request_method eq "GET") && ($tid != 0))) {

   my $tname;
   my $dname;
   my $team;
   my $tcutoff;

   print $query->start_html(-title => "team information",
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

   $sql = "SELECT * FROM teams";

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
         $teams{$row->{id}} = "($row->{seed})$row->{name}";
         push @team_ids, $row->{id};
         if ($row->{id} == $tid) {
            $team = $row;
         }
      }
   }

   # Finish that database call
   $sth->finish;

   $sql = "SELECT d.name AS dname, t.name AS tname, t.year, t.cutoff";
   $sql .= " FROM tournaments AS t, divisions AS d";
   $sql .= " WHERE d.tourneyid = t.id";
   $sql .= " AND d.id = " . $dbh->quote($team->{divisionid});

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

      $tname = "$row->{tname}, $row->{year}";
      $dname = $row->{dname};
      $tcutoff = $row->{cutoff};
   }

   # Finish that database call
   $sth->finish;

   print "<h2>($team->{seed})$team->{name}</h2>\n";
   print "<h3>$tname, $dname Region</h3>\n";

   $sql = "SELECT * FROM picks ";
   $sql .= "WHERE teamid = " . $dbh->quote($tid);

   # Send the query
   $sth = $dbh->prepare($sql);
   die "DBI error with prepare:", $sth->errstr unless $sth;

   # Execute the query
   $result = $sth->execute;
   die "DBI error with execute:", $sth->errstr unless $result;

   # If we received artists from the SELECT, print them out
   $rc = $sth->rows;
   if ($rc) {

      print "<p>Players who chose this team:</p>\n";
if (pastCutoff($tcutoff))
{
      print "<ul>\n";

      # Iterate through artist IDs and names
      my $row;
      while ($row = $sth->fetchrow_hashref) {

         print "<li>" . $players{$row->{playerid}}->{name};
         if ($row->{wildcard} == 1) {
            print "(wildcard)";
         } elsif ($row->{wildcard} == 2) {
            print "(winner)";
         }
         print "</li>\n";
      }

      print "</ul>\n";
}
else
{
      print "<p>unavailable until after tipoff</p>\n";
}

   }

   # Finish that database call
   $sth->finish;

   $sql = "SELECT * FROM scores ";
   $sql .= "WHERE teamid1 = " . $dbh->quote($tid);
   $sql .= " OR teamid2 = " . $dbh->quote($tid);

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
         } else {
            $wins{$row->{teamid2}}++;
            $elims{$row->{teamid1}}++;
            $game = "$teams{$row->{teamid2}} $row->{score2} - ";
            $game .= "$teams{$row->{teamid1}} $row->{score1}";
         }
         push @games, $game;
      }
   }

   # Finish that database call
   $sth->finish;

   print qq(<h2>Game Scores</h2>\n);

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

