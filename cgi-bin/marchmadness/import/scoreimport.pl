#!/usr/bin/perl -wT
# This is scoreimport.pl, which imports score info
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
use DBI;

use lib qw(..);
use MMConstants;

# Remove buffering
$| = 1;

# read from file. each line should be formatted as:
#
# teamname2 score2 - teamname2 score2 (foo)
#
# where teamname1 and teamname2 are strings, score1 and score2 
# are integer, and foo is ignored.

# first argument is filename
my $infile = $ARGV[0];

# ------------------------------------------------------------
# Connect to the database
my $dbh = DBI->connect("DBI:mysql:$dbdatabase:$dbserver:$dbport",
                       $dbusername, $dbpassword);
die "DBI error from connect: ", $DBI::errstr unless $dbh;

open INFILE, $infile;

while(<INFILE>) {
   my $line = $_;
   chomp($line);

   $line =~ m/([a-zA-Z\ \.\+]*?) (\d+) - ([a-zA-Z\ \.\+]*?) (\d+) \(.*?\)/;
   my $teamname1 = $1;
   my $teamname2 = $3;
   my $score1 = $2;
   my $score2 = $4;

   my $sql = "SELECT id FROM teams WHERE ";
   $sql .= "name = " . $dbh->quote($teamname1);

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

   my $teamid1;
   if ($row->{id}) {
      $teamid1 = $row->{id};
   } else {
      die("can't find team id for \"$teamname1\"\n");
   }

   # Finish that database call
   $sth->finish;

   $sql = "SELECT id FROM teams WHERE ";
   $sql .= "name = " . $dbh->quote($teamname2);

   # Prepare the query
   $sth = $dbh->prepare($sql);
   die "DBI error with prepare:", $sth->errstr unless $sth;

   # Execute the query
   $result = $sth->execute;
   die "DBI error with execute:", $sth->errstr unless $result;

   $rc = $sth->rows;
   # If we received rows from the SELECT, print them out
   if ($rc) {
      $row = $sth->fetchrow_hashref;
   }

   my $teamid2;
   if ($row->{id}) {
      $teamid2 = $row->{id};
   } else {
      die("can't find team id for \"$teamname2\"\n");
   }

   # Finish that database call
   $sth->finish;

   if ($teamid1 && $teamid2 && $score1 && $score2) {

      $sql = "INSERT INTO scores SET ";
      $sql .= "teamid1 = " . $dbh->quote($teamid1);
      $sql .= ", score1 = " . $dbh->quote($score1);
      $sql .= ", teamid2 = " . $dbh->quote($teamid2);
      $sql .= ", score2 = " . $dbh->quote($score2);
      $sql .= ", tourneyid = " . $dbh->quote("3");

      # Prepare the query
      $sth = $dbh->prepare($sql);
      die "DBI error with prepare:", $sth->errstr unless $sth;

      # Execute the query
      $result = $sth->execute;
      die "DBI error with execute:", $sth->errstr unless $result;

      # Finish that database call
      $sth->finish;

   }
}
close INFILE;

# Disconnect, even though it isn't really necessary
$dbh->disconnect;
