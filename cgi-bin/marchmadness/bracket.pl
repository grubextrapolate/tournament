#!/usr/bin/perl -wT
# This is bracket.pl, which displays bracket info

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use HTTP::Date;

use lib qw(.);
use HTML::Template;
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
my @dorder;
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

   # open the html template
   my $template = HTML::Template->new(filename => "$tmpldir/bracket.tmpl");

   my $tname;
   my $tupdate;
   my $tcutoff;

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

               my $sql3 = "SELECT DISTINCT playerid FROM picks ";
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
if (pastCutoff($tcutoff))
{
                  # Iterate through artist IDs and names
                  my $row3;
                  while ($row3 = $sth3->fetchrow_hashref) {
                     $pick_syms{$row2->{id}} .= $players{$row3->{playerid}}->{symbol};
                  }
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

   $template->param("tname" => $tname);
   $template->param("tname" => $tname);
   $template->param("tupdate" => $tupdate);
   $template->param("tcutoff" => $tcutoff);
   $template->param("tid" => $tid);

   my $tmp = "";
   my $j = keys %players;
   foreach my $play (sort { $players{$a}->{name} cmp $players{$b}->{name} } keys %players) {
      $tmp .= qq($players{$play}->{name}=$players{$play}->{symbol});
      if ($j != 1) { $tmp .= ", "; }
      $j--;
   }
   $template->param("playersymbols" => $tmp);

   my %tscores;
   $j = 0;
   foreach my $did (@dorder) {
      $j++;
      my $tscore = 0;
      my $twins = 0;
      my @round1;
      my @round2;
      my @round3;
      my @round4;
      my @round5;
      my $dwinner;

      $template->param("d${j}name" => $divisions{$did});

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

      $template->param("d${j}r1g1" => qq(($seeds{$round1[0]}) <a href="team.pl?team=$round1[0]">$teams{$round1[0]}</a> $pick_syms{$round1[0]} - ) . $tscores{"r1$round1[0]"});
      $template->param("d${j}r2g1" => qq(($seeds{$round2[0]}) <a href="team.pl?team=$round2[0]">$teams{$round2[0]}</a> $pick_syms{$round2[0]} - ) . $tscores{"r2$round2[0]"});
      $template->param("d${j}r1g2" => qq(($seeds{$round1[1]}) <a href="team.pl?team=$round1[1]">$teams{$round1[1]}</a> $pick_syms{$round1[1]} - ) . $tscores{"r1$round1[1]"});
      $template->param("d${j}r3g1" => qq(($seeds{$round3[0]}) <a href="team.pl?team=$round3[0]">$teams{$round3[0]}</a> $pick_syms{$round3[0]} - ) . $tscores{"r3$round3[0]"});
      $template->param("d${j}r1g3" => qq(($seeds{$round1[2]}) <a href="team.pl?team=$round1[2]">$teams{$round1[2]}</a> $pick_syms{$round1[2]} - ) . $tscores{"r1$round1[2]"});
      $template->param("d${j}r2g2" => qq(($seeds{$round2[1]}) <a href="team.pl?team=$round2[1]">$teams{$round2[1]}</a> $pick_syms{$round2[1]} - ) . $tscores{"r2$round2[1]"});
      $template->param("d${j}r1g4" => qq(($seeds{$round1[3]}) <a href="team.pl?team=$round1[3]">$teams{$round1[3]}</a> $pick_syms{$round1[3]} - ) . $tscores{"r1$round1[3]"});
      $template->param("d${j}r4g1" => qq(($seeds{$round4[0]}) <a href="team.pl?team=$round4[0]">$teams{$round4[0]}</a> $pick_syms{$round4[0]} - ) . $tscores{"r4$round4[0]"});
      $template->param("d${j}r1g5" => qq(($seeds{$round1[4]}) <a href="team.pl?team=$round1[4]">$teams{$round1[4]}</a> $pick_syms{$round1[4]} - ) . $tscores{"r1$round1[4]"});
      $template->param("d${j}r2g3" => qq(($seeds{$round2[2]}) <a href="team.pl?team=$round2[2]">$teams{$round2[2]}</a> $pick_syms{$round2[2]} - ) . $tscores{"r2$round2[2]"});
      $template->param("d${j}r1g6" => qq(($seeds{$round1[5]}) <a href="team.pl?team=$round1[5]">$teams{$round1[5]}</a> $pick_syms{$round1[5]} - ) . $tscores{"r1$round1[5]"});
      $template->param("d${j}r3g2" => qq(($seeds{$round3[1]}) <a href="team.pl?team=$round3[1]">$teams{$round3[1]}</a> $pick_syms{$round3[1]} - ) . $tscores{"r3$round3[1]"});
      $template->param("d${j}r1g7" => qq(($seeds{$round1[6]}) <a href="team.pl?team=$round1[6]">$teams{$round1[6]}</a> $pick_syms{$round1[6]} - ) . $tscores{"r1$round1[6]"});
      $template->param("d${j}r2g4" => qq(($seeds{$round2[3]}) <a href="team.pl?team=$round2[3]">$teams{$round2[3]}</a> $pick_syms{$round2[3]} - ) . $tscores{"r2$round2[3]"});
      $template->param("d${j}r1g8" => qq(($seeds{$round1[7]}) <a href="team.pl?team=$round1[7]">$teams{$round1[7]}</a> $pick_syms{$round1[7]} - ) . $tscores{"r1$round1[7]"});
      $template->param("d${j}winner" => qq(($seeds{$dwinner}) <a href="team.pl?team=$dwinner">$teams{$dwinner}</a> $pick_syms{$dwinner}));
      $template->param("d${j}r1g9" => qq(($seeds{$round1[8]}) <a href="team.pl?team=$round1[8]">$teams{$round1[8]}</a> $pick_syms{$round1[8]} - ) . $tscores{"r1$round1[8]"});
      $template->param("d${j}r2g5" => qq(($seeds{$round2[4]}) <a href="team.pl?team=$round2[4]">$teams{$round2[4]}</a> $pick_syms{$round2[4]} - ) . $tscores{"r2$round2[4]"});
      $template->param("d${j}r1g10" => qq(($seeds{$round1[9]}) <a href="team.pl?team=$round1[9]">$teams{$round1[9]}</a> $pick_syms{$round1[9]} - ) . $tscores{"r1$round1[9]"});
      $template->param("d${j}r3g3" => qq(($seeds{$round3[2]}) <a href="team.pl?team=$round3[2]">$teams{$round3[2]}</a> $pick_syms{$round3[2]} - ) . $tscores{"r3$round3[2]"});
      $template->param("d${j}r1g11" => qq(($seeds{$round1[10]}) <a href="team.pl?team=$round1[10]">$teams{$round1[10]}</a> $pick_syms{$round1[10]} - ) . $tscores{"r1$round1[10]"});
      $template->param("d${j}r2g6" => qq(($seeds{$round2[5]}) <a href="team.pl?team=$round2[5]">$teams{$round2[5]}</a> $pick_syms{$round2[5]} - ) . $tscores{"r2$round2[5]"});
      $template->param("d${j}r1g12" => qq(($seeds{$round1[11]}) <a href="team.pl?team=$round1[11]">$teams{$round1[11]}</a> $pick_syms{$round1[11]} - ) . $tscores{"r1$round1[11]"});
      $template->param("d${j}r4g2" => qq(($seeds{$round4[1]}) <a href="team.pl?team=$round4[1]">$teams{$round4[1]}</a> $pick_syms{$round4[1]} - ) . $tscores{"r4$round4[1]"});
      $template->param("d${j}r1g13" => qq(($seeds{$round1[12]}) <a href="team.pl?team=$round1[12]">$teams{$round1[12]}</a> $pick_syms{$round1[12]} - ) . $tscores{"r1$round1[12]"});
      $template->param("d${j}r2g7" => qq(($seeds{$round2[6]}) <a href="team.pl?team=$round2[6]">$teams{$round2[6]}</a> $pick_syms{$round2[6]} - ) . $tscores{"r2$round2[6]"});
      $template->param("d${j}r1g14" => qq(($seeds{$round1[13]}) <a href="team.pl?team=$round1[13]">$teams{$round1[13]}</a> $pick_syms{$round1[13]} - ) . $tscores{"r1$round1[13]"});
      $template->param("d${j}r3g4" => qq(($seeds{$round3[3]}) <a href="team.pl?team=$round3[3]">$teams{$round3[3]}</a> $pick_syms{$round3[3]} - ) . $tscores{"r3$round3[3]"});
      $template->param("d${j}r1g15" => qq(($seeds{$round1[14]}) <a href="team.pl?team=$round1[14]">$teams{$round1[14]}</a> $pick_syms{$round1[14]} - ) . $tscores{"r1$round1[14]"});
      $template->param("d${j}r2g8" => qq(($seeds{$round2[7]}) <a href="team.pl?team=$round2[7]">$teams{$round2[7]}</a> $pick_syms{$round2[7]} - ) . $tscores{"r2$round2[7]"});
      $template->param("d${j}r1g16" => qq(($seeds{$round1[15]}) <a href="team.pl?team=$round1[15]">$teams{$round1[15]}</a> $pick_syms{$round1[15]} - ) . $tscores{"r1$round1[15]"});



   }

      # final four
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
            # once we get to the final four, we can have equal seeds, which
            # will always fall into this block, so we need to watch for both
            # team orderings.
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
            } elsif ($scores{"$dwinners[$i],$dwinners[$i+1]"}) { # game played
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
         }
      }

      # championship round
      my $twinner = 0;
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


$template->param("d1winner" => qq(($seeds{$dwinners[0]}) <a href="team.pl?team=$dwinners[0]">$teams{$dwinners[0]}</a> $pick_syms{$dwinners[0]} - ) . $tscores{"r6$dwinners[0]"});
$template->param("d5winner" => qq(($seeds{$dwinners[4]}) <a href="team.pl?team=$dwinners[4]">$teams{$dwinners[4]}</a> $pick_syms{$dwinners[4]} - ) . $tscores{"r7$dwinners[4]"});
$template->param("d2winner" => qq(($seeds{$dwinners[1]}) <a href="team.pl?team=$dwinners[1]">$teams{$dwinners[1]}</a> $pick_syms{$dwinners[1]} - ) . $tscores{"r6$dwinners[1]"});
$template->param("twinner" => qq(($seeds{$twinner}) <a href="team.pl?team=$twinner">$teams{$twinner}</a> $pick_syms{$twinner}));
$template->param("d3winner" => qq(($seeds{$dwinners[2]}) <a href="team.pl?team=$dwinners[2]">$teams{$dwinners[2]}</a> $pick_syms{$dwinners[2]} - ) . $tscores{"r6$dwinners[2]"});
$template->param("d6winner" => qq(($seeds{$dwinners[5]}) <a href="team.pl?team=$dwinners[5]">$teams{$dwinners[5]}</a> $pick_syms{$dwinners[5]} - ) . $tscores{"r7$dwinners[5]"});
$template->param("d4winner" => qq(($seeds{$dwinners[3]}) <a href="team.pl?team=$dwinners[3]">$teams{$dwinners[3]}</a> $pick_syms{$dwinners[3]} - ) . $tscores{"r6$dwinners[3]"});

   print $template->output;

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

} else {
   print "<p>Sorry, but we only recognize GET and POST.</p>\n";

}

print $query->end_html;

