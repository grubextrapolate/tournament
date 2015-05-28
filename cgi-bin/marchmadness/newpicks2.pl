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
my %teams;
my %seeds;
my @dorder;
my $jslists = "";

my %tourneys;
my @tourney_ids;
my %players;
my @player_ids;

# ------------------------------------------------------------
# Create an instance of CGI
my $query = new CGI;

# Send a MIME header
print $query->header("text/html");

   print $query->start_html(-title => "choose a tournament",
                            -bgcolor => "#FFFFFF");

#if (($query->request_method eq "GET") && ($tid == 0)) {
if ($query->request_method eq "GET") {

   print "<h2>Choose player and tournament:</h2>\n";
   print qq(<form method="POST" action="newpicks2.pl">\n);

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
#   $sql = "SELECT *";
#         $sql .= " FROM players AS p, picks AS k, tournaments AS t";
#         $sql .= " WHERE k.tourneyid = " . $dbh->quote($tid);
#         $sql .= " AND k.tourneyid = t.id";
#         $sql .= " AND k.playerid = p.id ";
#   $sql .= " ORDER BY name";

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

#} elsif ((($query->request_method eq "POST") && ($tid != 0)) ||
#         (($query->request_method eq "GET") && ($tid != 0))) {
} elsif ($query->request_method eq "POST") {

      my $player = $query->param('players');
      my $tid = $query->param('tourneys');
      if ($player && $tid) {

   # open the html template
#   my $template = HTML::Template->new(filename => "$tmpldir/bracket.tmpl");
   my $template = HTML::Template->new(filename => "$tmpldir/picks.tmpl");

   my $tname;
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
      $tcutoff = $row->{cutoff};
   }

   # Finish that database call
   $sth->finish;

my $cur = time();
my $cut_sec = str2time($tcutoff, "-0400");
#my $fudge = -25620; # = -(7*60*60 + 7*60) = 7 hour+7min fast
#my $fudge = -420; # = -(0*60*60 + 7*60) = 0 hour+7min fast
my $fudge = 0; # = -(0*60*60 + 7*60) = 0 hour+7min fast
my $real_sec = $cur + $fudge;

my $now_str = time2str($real_sec);
my $cut_str = time2str($cut_sec);

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

            }
         }

         # Finish that database call
         $sth2->finish;
      }
   }
   $teams{0} = "";
   $seeds{0} = 0;

   # Finish that database call
   $sth->finish;

   $template->param("tname" => $tname);
   $template->param("tname" => $tname);
   $template->param("tcutoff" => $tcutoff);
   $template->param("tid" => $tid);
   $template->param("pid" => $player);

   my $j = 0;
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


#$jslists .= qq|var d${j}list_id = new Array(|
#          . join(",", map qq("$_"), @round1)
#          . qq|);\n|;
#$jslists .= qq|var d${j}list_seeds = new Array(|
#          . join(",", map qq("$_"), @seeds{@round1})
#          . qq|);\n|;
#$jslists .= qq|var d${j}list_names = new Array(|
#          . join(",", map qq("$_"), @teams{@round1})
#          . qq|);\n|;
#
#      $template->param("jslists" => $jslists);

for (my $k = 0; $k < 16; $k++)
{
   my $kk = $k+1;
      $template->param("d${j}r1g$kk" => qq(
<span class="checkboxes">RP<input type="checkbox" id="d${j}r1g$kk" name="d${j}r1g$kk" onchange="calc(this);"/>WC<input type="checkbox" id="d${j}r1g${kk}_wc" name="d${j}r1g${kk}_wc" onchange="calc(this);"/>OW<input type="checkbox" id="d${j}r1g${kk}_win" name="d${j}r1g${kk}_win" onchange="calc(this);"/></span>
<input type="hidden" id="d${j}r1g${kk}_id" name="d${j}r1g${kk}_id" value="$round1[$k]"/>
<input type="hidden" id="d${j}r1g${kk}_seed" name="d${j}r1g${kk}_seed" value="$seeds{$round1[$k]}"/>
($seeds{$round1[$k]}) <a href="team.pl?team=$round1[$k]">$teams{$round1[$k]}</a>
) );
}

for (my $k = 0; $k < 8; $k++)
{
   my $kk = $k+1;
      $template->param("d${j}r2g$kk" => qq(<select id="d${j}r2g$kk" name="d${j}r2g$kk" onchange="calc(this);"/>\n</select>\n) );
}

for (my $k = 0; $k < 4; $k++)
{
   my $kk = $k+1;
      $template->param("d${j}r3g$kk" => qq(<select id="d${j}r3g$kk" name="d${j}r3g$kk" onchange="calc(this);"/>\n</select>\n) );
}

for (my $k = 0; $k < 2; $k++)
{
   my $kk = $k+1;
   $template->param("d${j}r4g$kk" => qq(<select id="d${j}r4g$kk" name="d${j}r4g$kk" onchange="calc(this);"/>\n</select>\n) );
}

      $template->param("d${j}winner" => qq(<select id="d${j}winner" name="d${j}winner" onchange="calc(this);"/>\n</select>\n) );



   }

      # final four
      $template->param("d1winner2" => qq(<input type="text" id="d1winner2" name="d1winner2" value="" readonly/>\n) );
      $template->param("d2winner2" => qq(<input type="text" id="d2winner2" name="d2winner2" value="" readonly/>\n) );
      $template->param("d3winner2" => qq(<input type="text" id="d3winner2" name="d3winner2" value="" readonly/>\n) );
      $template->param("d4winner2" => qq(<input type="text" id="d4winner2" name="d4winner2" value="" readonly/>\n) );

      # championship round
      $template->param("d5winner" => qq(<select id="d5winner" name="d5winner" onchange="calc(this);"/>\n</select>\n) );
      $template->param("d6winner" => qq(<select id="d6winner" name="d6winner" onchange="calc(this);"/>\n</select>\n) );

      # tournament winner
      $template->param("twinner" => qq(<select id="twinner" name="twinner" onchange="calc(this);"/>\n</select>\n) );


#$jslists .= qq|var teamlist_id = new Array(|
#          . join(",", map qq("$_"), @round1)
#          . qq|);\n|;
#$jslists .= qq|var teamlist_seeds = new Array(|
#          . join(",", map qq("$_"), @seeds{@round1})
#          . qq|);\n|;
#$jslists .= qq|var teamlist_names = new Array(|
#          . join(",", map qq("$_"), @teams{@round1})
#          . qq|);\n|;

$jslists .= qq|var division_names = { |;
my $k = 1;
foreach my $did (@dorder)
{
   $jslists .= qq|$k: "$divisions{$did}", |;
   $k++;
}
$jslists .= qq|};\n|;

$jslists .= qq|var teamlist_names = { |;
foreach my $key (sort keys %teams)
{
   $jslists .= qq|$key: "($seeds{$key}) $teams{$key}", |;
}
$jslists .= qq|};\n|;

$jslists .= qq|var teamlist_names_noseed = { |;
foreach my $key (sort keys %teams)
{
   $jslists .= qq|$key: "$teams{$key}", |;
}
$jslists .= qq|};\n|;

$jslists .= qq|var teamlist_seeds = { |;
foreach my $key (sort keys %seeds)
{
   $jslists .= qq|$key: "$seeds{$key}", |;
}
$jslists .= qq|};\n|;

$jslists .= qq|var teamlist_id = { |;
foreach my $key (sort keys %teams)
{
   $jslists .= qq|"$teams{$key}": $key, |;
}
$jslists .= qq|};\n|;

      $template->param("jslists" => $jslists);


   print $template->output;

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

      } else {
         print "<p>player and tournament mandatory!</p>\n";
      }
} else {
   print "<p>Sorry, but we only recognize GET and POST.</p>\n";

}

print $query->end_html;

