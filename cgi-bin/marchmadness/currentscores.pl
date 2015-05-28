#!/usr/bin/perl -wT
# This is currentscores.pl, which shows current games and can be used to save
# scores.

use strict;
use diagnostics;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use HTTP::Date;

use LWP::UserAgent;
use HTTP::Request;
use POSIX qw(strftime mktime);

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

my $tid = $query->param('tourneys') || 0;
my $extraurl = $query->param('extra') || ""; # add for date: &extra=/20150320

# Send a MIME header
print $query->header("text/html");

print $query->start_html(-title => "current scores",
                         -meta => { 'viewport' => "width=320; initial-scale=1.0;" },
                         -bgcolor => "#FFFFFF");

if ($query->request_method eq "GET" && $tid == 0) {

   print "<h2>Choose tournament:</h2>\n";
   print qq(<form method="GET" action="currentscores.pl">\n);

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

} elsif ($query->request_method eq "GET" && $tid != 0) {


   my $tomorrow  = "";
   my $yesterday = "";
   my $label     = "Current";
   if ($extraurl =~ m|^/(\d{4})(\d{2})(\d{2})$|)
   {
      my $sec = mktime(0, 0, 0, $3, $2 - 1, $1 - 1900);
      $tomorrow  = strftime("%Y%m%d", localtime($sec + 86400));
      $yesterday = strftime("%Y%m%d", localtime($sec - 86400));
      $label     = $1 . $2 . $3;
   }
   else
   {
      $tomorrow  = strftime("%Y%m%d", localtime(time() + 43200));
      $yesterday = strftime("%Y%m%d", localtime(time() - 129600));
   }
   print <<END;
<style type="text/css">
#textbox {
   padding: 5px;
   text-decoration: none;
   font-size: 75%;
}

.alignleft {
   float: left;
}

.alignright {
   float: right;
}
</style>
END

   print "<h3>$label Scores</h3>\n";
   print qq(<div id="textbox"><div class="alignleft"><a href="currentscores.pl?tourneys=$tid&submit=continue&extra=/$yesterday">&lt;&lt;$yesterday</a></div>\n);
   print qq(<div class="alignright"><a href="currentscores.pl?tourneys=$tid&submit=continue&extra=/$tomorrow">$tomorrow&gt;&gt;</a></div><div style="clear: both;"></div></div>\n);

   # ------------------------------------------------------------
   # Connect to the database
   my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
   die "DBI error from connect: ", $DBI::errstr unless $dbh;

   my $url = "http://www.cbssports.com/collegebasketball/box-scoreboards" . $extraurl;
   my @info = @{&fetchScores($url)};
   &getTeamIDs(\@info, $dbh, $tid);
   &checkSavedScores(\@info, $dbh, $tid);
   &getPicks(\@info, $dbh, $tid);

   my $i = 1;
   print qq(<table width="100%" border="1" cellspacing="0" cellpadding="2">\n);
   foreach my $game (@info)
   {
      if ($i++ % 2 == 0)
      {
         print qq(<tr bgcolor="#eeeeee">\n);
      }
      else
      {
         print qq(<tr>\n);
      }
      print qq(<td width="80%">);
      print "(" . $game->{seed1} . ") ";
      if ($game->{tid1})
      {
         print qq(<a href="team.pl?team=);
         print $game->{tid1} . qq(">);
         print $game->{team1} . "</a> [" . $game->{pick1} . "]<br>";
      }
      else
      {
         print $game->{team1} . "<br>";
      }
      print "(" . $game->{seed2} . ") ";
      if ($game->{tid2})
      {
         print qq(<a href="team.pl?team=);
         print $game->{tid2} . qq(">);
         print $game->{team2} . "</a> [" . $game->{pick2} . "]";
      }
      else
      {
         print $game->{team2};
      }
      print qq(</td>\n<td width="10%" align="right">);
      if ($game->{score1} && $game->{score2})
      {
         print $game->{score1} . "<br>" . $game->{score2};
      }
      print qq(</td>\n<td width="10%">);
      print $game->{info};
      if (!($game->{entered}) && ($game->{info} =~ /^Final/))
      {
         print qq(<form method="POST" action="newscore.pl">\n);
         print $query->hidden(-name => 'tourneyid',
                              -value => $tid) . "\n";
         print $query->hidden(-name => 'team1',
                              -value => $game->{tid1}) . "\n";
         print $query->hidden(-name => 'team2',
                              -value => $game->{tid2}) . "\n";
         print $query->hidden(-name => 'score1',
                              -value => $game->{score1}) . "\n";
         print $query->hidden(-name => 'score2',
                              -value => $game->{score2}) . "\n";
if ($game->{tid1} && $game->{tid2})
{
         print $query->submit(-name => "submit", -value => "save score");
}
else
{
         print $query->submit(-name => "submit", -value => "save score", -disabled => "submit");
}
         print "</form>\n";
      }
      print qq(</td>\n</tr>\n);
   }
   print qq(</table>\n);

   # Disconnect
   $dbh->disconnect;

   print qq(<p><a href="display.pl?tournament=$tid">current standings</a><br>);
   print qq(<a href="bracket.pl?tournament=$tid">current bracket</a></p>);

} else {
   print "<p>Sorry, but we only recognize GET.</p>\n";
}

print $query->end_html;


# Fetches a url and returns the page as an array ref where each array element
# is a line from the page. Returns undef if there was a problem fetching the
# URL.
# =============================================================================
my $fetchURL;
sub fetchURL
{
   my $url = shift;
   my $ret = undef;

   my $ua = new LWP::UserAgent;

   if ($url && ($url ne ""))
   {
      my $request = new HTTP::Request('GET', $url);
      my $response = $ua->request($request);

      if ($response->is_success)
      {
         my @lines = split('\n', $response->content);
         $ret = \@lines;
      }
   }

   return $ret;
}

my $fetchScores;
sub fetchScores
{
   my $url = shift;
   my @games = undef;

   my $inTable = 0;
   my $numGames = 0;
   my @page = @{&fetchURL($url)};
   foreach my $oline (@page)
   {
      if ($oline =~ /id="saagBoxScoreboards"/)
      {
#         $inTable = 1;
#      }
#      elsif ($line =~ /class="footer"/)
#      {
#         $inTable = 0;
#      }
#      else
#      {
#         if ($inTable)
#         {
            # teams: <td class="team">&nbsp;(\d+) ([a-zA-Z .]+)</span>...
            # scores: <td class="score">(\d*)<br />(\d*)</td>
            # info: <TD WIDTH=10% nowrap><a href...>period<BR>time</a></TD></tr>
            #       <td class="status"><a href...>Final<br> </a></TD></tr>
            #       <TD WIDTH=10% nowrap><a href...><script>...1111347000...

         my @tables = split /<li class="[preostlive]+Event">/, $oline;

         foreach my $line (@tables)
         {
            $line =~ s/<span class="winarrow">&laquo;<\/span>//g;
            $line =~ s/<span class="winner">(\d+)<\/span>/$1/g;

            if ($line =~ /<span class="awayRank">(\d*)<\/span><span class="homeRank">(\d*)<\/span><\/td><td class="team"><a href[^>]+>([^<]+)<\/a><br \/><a href[^>]+>([^<]+)<\/a>/)
            {
               my %tmphsh;
               $tmphsh{seed1} = $1;
               $tmphsh{seed2} = $2;
               $tmphsh{team1} = $3;
               $tmphsh{team2} = $4;
               $games[$numGames] = \%tmphsh;
            }
            if ($line =~ /<td class="score"><a href[^>]+>(\d*)<br \/>(\d*)<\/a><\/td>/)
            {
               if (defined($1)) {
                  $games[$numGames]->{score1} = $1;
               }
               else
               {
                  $games[$numGames]->{score1} = 0;
               }
               if (defined($2)) {
                  $games[$numGames]->{score2} = $2;
               }
               else
               {
                  $games[$numGames]->{score2} = 0;
               }
            }
            if ($line =~ /<td class="status"><a href[^>]+>(.*)/)
            {
               $line = $1;
               if ($line =~ /^F<\/a><\/td>/)
               {
                  $games[$numGames]->{info} = "Final";
#                  $numGames++;
               }
               elsif ($line =~ /^F\/([a-zA-Z\d]+)<\/a><\/td>/)
               {
                  $games[$numGames]->{info} = "Final, " . $1;
#                  $numGames++;
               }
#               elsif ($line =~ /^<span gmt="(\d{10})" class="updateTime">/)
               elsif ($line =~ /^<span class="gmtTime" data-gmt="(\d{10})" /)
               {
                  $games[$numGames]->{info} = strftime("%l:%M%p", localtime($1 + 10800));
#                  $games[$numGames]->{info} = strftime("%l:%M%p", localtime($1));
#                  $numGames++;
               }
               elsif ($line =~ /([\d\:\.]+)<br \/>([\da-zA-Z]+)/)
               {
                  $games[$numGames]->{info} = "$1 $2";
#                  $numGames++;
               }
                  $numGames++;
            }
         }
      }
   }

   return \@games;
}

my $getTeamIDs;
sub getTeamIDs
{
   my $games = shift;
   my $dbh   = shift;
   my $tid   = shift;

   foreach my $game (@{$games})
   {
      my $sql = "SELECT t.* FROM teams AS t, divisions AS d";
      $sql .= " WHERE d.tourneyid = " . $dbh->quote($tid);
      $sql .= " AND d.id = t.divisionid";
      $sql .= " AND t.seed = " . $dbh->quote($game->{seed1});
      $sql .= " AND t.alias = " . $dbh->quote($game->{team1});

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
         my $row = $sth->fetchrow_hashref;
         $game->{tid1}  = $row->{id};
         $game->{team1} = $row->{name};
      }
      $sth->finish;

      $sql = "SELECT t.* FROM teams AS t, divisions AS d";
      $sql .= " WHERE d.tourneyid = " . $dbh->quote($tid);
      $sql .= " AND d.id = t.divisionid";
      $sql .= " AND t.seed = " . $dbh->quote($game->{seed2});
      $sql .= " AND t.alias = " . $dbh->quote($game->{team2});

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
         $game->{tid2}  = $row->{id};
         $game->{team2} = $row->{name};
      }
      $sth->finish;
   }
}

my $checkSavedScores;
sub checkSavedScores
{
   my $games = shift;
   my $dbh   = shift;
   my $tid   = shift;

   foreach my $game (@{$games})
   {
      if ($game->{tid1} && $game->{tid2})
      {
         my $sql = "SELECT * FROM scores";
         $sql .= " WHERE tourneyid = " . $dbh->quote($tid);
         $sql .= " AND (teamid1 = " . $dbh->quote($game->{tid1});
         $sql .= " AND teamid2 = " . $dbh->quote($game->{tid2});
         $sql .= ") OR (teamid2 = " . $dbh->quote($game->{tid1});
         $sql .= " AND teamid1 = " . $dbh->quote($game->{tid2});
         $sql .= ")";

         # Send the query
         my $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         my $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # If we received artists from the SELECT, print them out
         my $rc = $sth->rows;
         if ($rc) {
            $game->{entered} = 1;
         }
         $sth->finish;
      }
   }
}

my $getPicks;
sub getPicks
{
   my $games = shift;
   my $dbh   = shift;
   my $tid   = shift;

   foreach my $game (@{$games})
   {
      if ($game->{tid1})
      {
         $game->{pick1} = "";

         my $sql = "SELECT DISTINCT p.symbol, t.cutoff";
         $sql .= " FROM players AS p, picks AS k, tournaments AS t";
         $sql .= " WHERE k.tourneyid = " . $dbh->quote($tid);
         $sql .= " AND k.tourneyid = t.id";
         $sql .= " AND k.teamid = " . $dbh->quote($game->{tid1});
         $sql .= " AND k.playerid = p.id ";
         $sql .= " ORDER BY p.symbol";

         # Send the query
         my $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         my $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # If we received artists from the SELECT, print them out
         my $rc = $sth->rows;
         if ($rc) {

            my $row;
            while ($row = $sth->fetchrow_hashref)
            {
my $tcutoff = $row->{cutoff};

if (pastCutoff($tcutoff))
{
               $game->{pick1} .= $row->{symbol};
}
            }
         }
         $sth->finish;
      }

      if ($game->{tid2})
      {
         $game->{pick2} = "";

         my $sql = "SELECT DISTINCT p.symbol, t.cutoff";
         $sql .= " FROM players AS p, picks AS k, tournaments AS t";
         $sql .= " WHERE k.tourneyid = " . $dbh->quote($tid);
         $sql .= " AND k.tourneyid = t.id";
         $sql .= " AND k.teamid = " . $dbh->quote($game->{tid2});
         $sql .= " AND k.playerid = p.id ";
         $sql .= " ORDER BY p.symbol";

         # Send the query
         my $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         my $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         # If we received artists from the SELECT, print them out
         my $rc = $sth->rows;
         if ($rc) {

            my $row;
            while ($row = $sth->fetchrow_hashref)
            {
my $tcutoff = $row->{cutoff};

if (pastCutoff($tcutoff))
{
               $game->{pick2} .= $row->{symbol};
}
            }
         }
         $sth->finish;
      }
   }
}

