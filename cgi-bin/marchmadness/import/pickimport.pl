#!/usr/bin/perl -wT
# This is pickimport.pl, which imports pick info
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
# playerid tourneyid wildcard teamname
#
# where playerid is integer, tourneyid is integer, wildcard is integer, 
# and teamname is a string (rest of line)

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

   my ($playerid, $tourneyid, $wildcard, $teamname) = split(/ /, $line, 4);

   my $sql = "SELECT id FROM teams WHERE ";
   $sql .= "name = " . $dbh->quote($teamname);

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

   my $teamid;
   if ($row->{id}) {
      $teamid = $row->{id};
   } else {
      die("can't find team id for \"$teamname\"\n");
   }

   # Finish that database call
   $sth->finish;

   if ($playerid && $tourneyid && $teamid) {

      $sql = "INSERT INTO picks SET ";
      $sql .= "playerid = " . $dbh->quote($playerid);
      $sql .= ", tourneyid = " . $dbh->quote($tourneyid);
      $sql .= ", teamid = " . $dbh->quote($teamid);
      $sql .= ", wildcard = " . $dbh->quote($wildcard);

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
