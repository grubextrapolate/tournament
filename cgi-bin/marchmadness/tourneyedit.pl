#!/usr/bin/perl -wT
# This is tourneyedit.pl, which edits tournament info

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
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
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
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
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
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
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
         print "last update: " . $query->textfield(-name => "tlast",
                                            -default => $row->{lastupdate},
                                            -override => 1,
                                            -size => 22,
                                            -maxlength => 19) . "<br>\n";
         print "cutoff: " . $query->textfield(-name => "tcut",
                                            -default => $row->{cutoff},
                                            -override => 1,
                                            -size => 22,
                                            -maxlength => 19) . "<br>\n";

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
      my $tlast = $query->param('tlast');
      my $tcut = $query->param('tcut');

      if ($id && $name && $tyear && $tlast && $tcut) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "UPDATE tournaments SET ";
         $sql .= "name = " . $dbh->quote($name);
         $sql .= ", year = " . $dbh->quote($tyear);
         $sql .= ", lastupdate = " . $dbh->quote($tlast);
         $sql .= ", cutoff = " . $dbh->quote($tcut);
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

