#!/usr/bin/perl -wT
# This is teamimport.pl, which imports team info
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
# divisionid seed teamname
#
# where divisionid is integer, seed is integer, and teamname is a string 
# (the rest of the line).

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

   my ($did, $seed, $name) = split(/ /, $line, 3);
   if ($name && $seed && $did) {

      my $sql = "INSERT INTO teams SET ";
      $sql .= "name = " . $dbh->quote($name);
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

   }
}
close INFILE;

# Disconnect, even though it isn't really necessary
$dbh->disconnect;
