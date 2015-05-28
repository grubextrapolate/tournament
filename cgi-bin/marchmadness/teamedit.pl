#!/usr/bin/perl -wT
# This is teamedit.pl, which edits team info

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
my %divisions;
my @division_ids;
my %tourneys;
my @tourney_ids;

# ------------------------------------------------------------
# Create an instance of CGI
my $query = new CGI;

# Send a MIME header
print $query->header("text/html");

print $query->start_html(-title => "edit team",
			 -bgcolor => "#FFFFFF");

      my $tid = $query->param('tourneys');

if ($query->request_method eq "GET") {

   print "<h2>Edit a Team:</h2>\n";
   print qq(<form method="POST" action="teamedit.pl">\n);

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

   $sql = "SELECT * FROM divisions";
   if ($tid)
   {
      $sql .= " WHERE tourneyid = " . $dbh->quote($tid);
   }
   $sql .= " ORDER BY tourneyid,name";

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

         $divisions{$row->{id}} = "$tourneys{$row->{tourneyid}}, $row->{name}";
         push @division_ids, $row->{id};
      }
   }

   # Finish that database call
   $sth->finish;

   $sql = "SELECT teams.* FROM teams, divisions";
   $sql .= " WHERE divisions.id = teams.divisionid";
   if ($tid)
   {
      $sql .= " AND divisions.tourneyid = " . $dbh->quote($tid);
   }
   $sql .= " ORDER BY teams.divisionid, teams.seed, teams.name";

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
         $entries{$row->{'id'}} = "(" . $row->{'seed'} . ") "
                                . $row->{'name'} . ", "
                                . $divisions{$row->{'divisionid'}};
         push @entry_ids, $row->{'id'};
      }

      print "<p>" . $query->popup_menu(-name => "entries",
                                   -values => \@entry_ids,
                                   -labels => \%entries) . "\n";

      print $query->submit(-name => "submit", 
                           -value => "edit entry") . "\n";
      print $query->submit(-name => "submit",
                           -value => "delete entry") . "\n</p>";

   } else {
      print "<P>No teams to display!</P>\n";
   }

   # Finish that database call
   $sth->finish;

   print "</form>\n";

   print qq(<form method="GET" action="teamedit.pl">\n);

      print "<p>" . $query->popup_menu(-name => "tourneys",
                                   -values => \@tourney_ids,
                                   -labels => \%tourneys) . "\n";

      print $query->submit(-name => "submit",
                           -value => "filter") . "\n</p><hr>";

   print "</form>\n";

   print qq(<h2>Create New team:</h2>\n);
   print qq(<form method="POST" action="teamedit.pl">\n);

   print "<p>name: " . $query->textfield(-name => "name",
                                         -size => 50,
                                         -maxlength => 200) . "<br>\n";

   print "alias: " . $query->textfield(-name => "alias",
                                         -size => 15,
                                         -maxlength => 15) . "<br>\n";

   print "seed: " . $query->textfield(-name => "seed",
                                         -size => 5,
                                         -maxlength => 2) . "<br>\n";

   print "division: " . $query->popup_menu(-name => "divisions",
                                             -values => \@division_ids,
                                             -labels => \%divisions) . "<br>\n";

   print $query->submit(-name => "submit", -value => "add new entry");
   print $query->reset(-value => "reset form");
   print "</p><hr>\n";

   print "</form>\n";

   # Disconnect, even though it isn't really necessary
   $dbh->disconnect;

} elsif ($query->request_method eq "POST") {

   if ($query->param('submit') eq "add new entry") {

      my $name = $query->param('name');
      my $alias = $query->param('alias');
      my $seed = $query->param('seed');
      my $did = $query->param('divisions');
      if ($name && $seed && $did && $alias) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "INSERT INTO teams SET ";
         $sql .= "name = " . $dbh->quote($name);
         $sql .= ", alias = " . $dbh->quote($alias);
         $sql .= ", seed = " . $dbh->quote($seed);
         $sql .= ", divisionid = " . $dbh->quote($did);

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
         print "<p>name, seed, and division mandatory!</p>\n";
      }

   } elsif ($query->param('submit') eq "delete entry") {

      my $id = $query->param('entries');
      if ($id) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "DELETE FROM teams WHERE ";
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

         print qq(<form method="post" action="teamedit.pl">\n);

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
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

   $sql = "SELECT * FROM divisions ORDER BY tourneyid,name";

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

         $divisions{$row->{id}} = "$tourneys{$row->{tourneyid}}, $row->{name}";
         push @division_ids, $row->{id};
      }
   }

   # Finish that database call
   $sth->finish;

         $sql = "SELECT * FROM teams WHERE ";
         $sql .= "id = " . $dbh->quote($id);

         # Prepare the query
         $sth = $dbh->prepare($sql);
         die "DBI error with prepare:", $sth->errstr unless $sth;

         # Execute the query
         $result = $sth->execute;
         die "DBI error with execute:", $sth->errstr unless $result;

         my $row;
         $rc = $sth->rows;
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

         print "alias: " . $query->textfield(-name => "alias",
                                            -default => $row->{alias},
                                            -override => 1,
                                            -size => 15,
                                            -maxlength => 15) . "<br>\n";

         print "seed: " . $query->textfield(-name => "seed",
                                            -default => $row->{seed},
                                            -override => 1,
                                            -size => 5,
                                            -maxlength => 2) . "<br>\n";

         print "division: " . $query->popup_menu(-name => "divisions",
                                                   -default => $row->{divisionid},
                                                   -override => 1,
                                                   -values => \@division_ids,
                                                   -labels => \%divisions) . "<br>\n";

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
      my $alias = $query->param('alias');
      my $seed = $query->param('seed');
      my $did = $query->param('divisions');
      if ($id && $name && $seed && $did) {

         # ------------------------------------------------------------
         # Connect to the database
         my $dbh = DBI->connect($dsn, $dbusername, $dbpassword);
         die "DBI error from connect: ", $DBI::errstr unless $dbh;

         my $sql = "UPDATE teams SET ";
         $sql .= "name = " . $dbh->quote($name);
         $sql .= ", alias = " . $dbh->quote($alias);
         $sql .= ", seed = " . $dbh->quote($seed);
         $sql .= ", divisionid = " . $dbh->quote($did);
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
         print "<p>id, name, and tournament mandatory!</p>\n";
      }

   } else {
      print "<p>unknown submit type</p>\n";
   }

} else {
   print "<p>Sorry, but we only recognize GET and POST.</p>\n";

}

print $query->end_html;

