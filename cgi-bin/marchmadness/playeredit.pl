#!/usr/bin/perl -wT
# This is playeredit.pl, which edits player info

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

   print "<h2>Edit a Player:</h2>\n";
   print qq(<form method="POST" action="playeredit.pl">\n);

   # ------------------------------------------------------------
   # Connect to the database
   my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
   die "DBI error from connect: ", $DBI::errstr unless $dbh;

   my $sql = "SELECT * FROM players ORDER BY name";

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

         $entries{$row->{id}} = "$row->{name}, $row->{email}, $row->{symbol}, $row->{notify}";
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
      print "<P>No players to display!</P>\n";
   }

   # Finish that database call
   $sth->finish;

   print "</form>\n";

   print qq(<h2>Create New Player:</h2>\n);
   print qq(<form method="POST" action="playeredit.pl">\n);

   print "<p>name: " . $query->textfield(-name => "name",
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";
   print "email: " . $query->textfield(-name => "email",
                                       -size => 50,
                                       -maxlength => 200) . "<br>\n";
   print "notify: " . $query->textfield(-name => "notify",
                                        -size => 3,
                                        -maxlength => 1) . "<br>\n";
   print "symbol: " . $query->textfield(-name => "symbol",
                                        -size => 3,
                                        -maxlength => 1) . "<br>\n";

   print $query->submit(-name => "submit", -value => "add new entry");
   print $query->reset(-value => "reset form");
   print "</p><hr>\n";

   print "</form>\n";

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

} elsif ($query->request_method eq "POST") {

   if ($query->param('submit') eq "add new entry") {

      my $name = $query->param('name');
      my $email = $query->param('email') || "";
      my $notify = $query->param('notify') || 0;
      my $symbol = $query->param('symbol');
      if ($name && $symbol) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "INSERT INTO players SET ";
         $sql .= "name = " . $dbh->quote($name);
         $sql .= ", symbol = " . $dbh->quote($symbol);
         if ($email) { $sql .= ", email = " . $dbh->quote($email); }
         if ($notify) { $sql .= ", notify = " . $dbh->quote($notify); }

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
         print "<p>name and symbol mandatory!</p>\n";
      }

   } elsif ($query->param('submit') eq "delete entry") {

      my $id = $query->param('entries');
      if ($id) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "DELETE FROM players WHERE ";
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

         print qq(<form method="post" action="playeredit.pl">\n);

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "SELECT * FROM players WHERE ";
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
         print "email: " . $query->textfield(-name => "email",
                                             -default => $row->{email},
                                             -override => 1,
                                             -size => 50,
                                             -maxlength => 200) . "<br>\n";
         print "notify: " . $query->textfield(-name => "notify",
                                              -default => $row->{notify},
                                              -override => 1,
                                              -size => 3,
                                              -maxlength => 1) . "<br>\n";
         print "symbol: " . $query->textfield(-name => "symbol",
                                              -default => $row->{symbol},
                                              -override => 1,
                                              -size => 4,
                                              -maxlength => 2) . "<br>\n";

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
      my $email = $query->param('email') || "";
      my $notify = $query->param('notify') || 0;
      my $symbol = $query->param('symbol');
      if ($id && $name && $symbol) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "UPDATE players SET ";
         $sql .= "name = " . $dbh->quote($name);
         $sql .= ", email = " . $dbh->quote($email);
         $sql .= ", notify = " . $dbh->quote($notify);
         $sql .= ", symbol = " . $dbh->quote($symbol);
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
         print "<p>id, name, and symbol mandatory!</p>\n";
      }

   } else {
      print "<p>unknown submit type</p>\n";
   }

} else {
   print "<p>Sorry, but we only recognize GET and POST.</p>\n";

}

print $query->end_html;

