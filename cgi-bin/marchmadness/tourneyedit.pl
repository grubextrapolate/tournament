#!/usr/bin/perl -wT
# This is tourneyedit.pl, which edits tournament info
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

my %entries;
my @entry_ids;

# ------------------------------------------------------------
# Create an instance of CGI
my $query = new CGI;

# Send a MIME header
print $query->header("text/html");

print $query->start_html(-title => "edit tournament",
			 -bgcolor => "#FFFFFF");

if ($query->request_method eq "GET") {

   print "<h2>Edit a Tournament:</h2>\n";
   print qq(<form method="POST" action="tourneyedit.pl">\n);

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

         $entries{$row->{id}} = "$row->{name}, $row->{year}";
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
      print "<P>No tournaments to display!</P>\n";
   }

   # Finish that database call
   $sth->finish;

   print "</form>\n";

   print qq(<h2>Create New Tournament:</h2>\n);
   print qq(<form method="POST" action="tourneyedit.pl">\n);

   print "<p>name: " . $query->textfield(-name => "name",
                                      -size => 50,
                                      -maxlength => 200) . "<br>\n";
   print "year: " . $query->textfield(-name => "year",
                                      -size => 6,
                                      -maxlength => 4) . "<br>\n";

   print $query->submit(-name => "submit", -value => "add new entry");
   print $query->reset(-value => "reset form");
   print "</p><hr>\n";

   print "</form>\n";

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

} elsif ($query->request_method eq "POST") {

   if ($query->param('submit') eq "add new entry") {

      my $name = $query->param('name');
      my $year = $query->param('year');
      if ($name && $year) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                                $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "INSERT INTO tournaments SET ";
         $sql .= "name = " . $dbh->quote($name);
         $sql .= ", year = " . $dbh->quote($year);
         $sql .= ", lastupdate = NOW()";

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
         print "<p>name and year mandatory!</p>\n";
      }

   } elsif ($query->param('submit') eq "delete entry") {

      my $id = $query->param('entries');
      if ($id) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                                $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "DELETE FROM tournaments WHERE ";
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

         print qq(<form method="post" action="tourneyedit.pl">\n);

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                                $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "SELECT * FROM tournaments WHERE ";
         $sql .= "id = " . $dbh->quote($id);

         # Prepare the query
         my $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         my $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         my $row;
         my $rc = $sth->rows;
         # If we received rows from the SELECT, print them out
         if ($rc) {

            $row = $sth->fetchrow_hashref;

         }

         # Finish that database call
         $sth->finish;

         print "<p>id: $row->{id}<br>\n";
         print $query->hidden(-name => 'entryid',
                          -value => $row->{id}) . "\n";

         print "name: " . $query->textfield(-name => "name",
                                            -default => $row->{name},
                                            -override => 1,
                                            -size => 50,
                                            -maxlength => 200) . "<br>\n";
         print "year: " . $query->textfield(-name => "tyear",
                                            -default => $row->{year},
                                            -override => 1,
                                            -size => 6,
                                            -maxlength => 4) . "<br>\n";

         my ($date_half, $time_half) = split(/ /, $row->{lastupdate});
         my ($year, $month, $day) = date2ymd($date_half);
         my ($hour, $min, $ap) = time2hmp($time_half);

         print "last updated: ";
         print $query->popup_menu(-name => "month",
                              -default => $months[$month-1],
                              -override => 1,
                              -values => \@months);
         print $query->popup_menu(-name => "day",
                              -default => $day,
                              -override => 1,
                              -values => \@days);
         print $query->popup_menu(-name => "year",
                              -default => $year,
                              -override => 1,
                              -values => \@years);

         print $query->popup_menu(-name => "hour",
                              -default => $hour,
                              -override => 1,
                              -values => \@hours);
         print $query->popup_menu(-name => "min",
                              -default => $min,
                              -override => 1,
                              -values => \@mins);
         print $query->popup_menu(-name => "ap",
                              -default => $ap,
                              -override => 1,
                              -values => \@ap);

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
      my $name = $query->param('name');
      my $tyear = $query->param('tyear');

      my $month = $query->param('month');
      my $day = $query->param('day');
      my $year = $query->param('year');
      my $hour = $query->param('hour');
      my $min = $query->param('min');
      my $ap = $query->param('ap');

      my $date_half = dmy2date($day, $monthh{$month}, $year);
      my $time_half = hmp2time($hour, $min, $ap);
      my $date = $date_half . " " . $time_half;

      if ($id && $name && $tyear && $date) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                                $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "UPDATE tournaments SET ";
         $sql .= "name = " . $dbh->quote($name);
         $sql .= ", year = " . $dbh->quote($tyear);
         $sql .= ", lastupdate = " . $dbh->quote($date);
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
         print "<p>id, name, and year mandatory!</p>\n";
      }

   } else {
      print "<p>unknown submit type</p>\n";
   }

} else {
   print "<p>Sorry, but we only recognize GET and POST.</p>\n";

}

print $query->end_html;

