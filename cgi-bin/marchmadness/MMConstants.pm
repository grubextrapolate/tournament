#!/usr/bin/perl -wT
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

# Declare some commonly used variables
use vars qw($dbdatabase $dbserver $dbport $dbusername $dbpassword);

$dbdatabase = "MM_DB_NAME";
$dbserver = "MM_DB_HOST_OR_IP";
$dbport = "3306";
$dbusername = "MM_DB_USER";
$dbpassword = "MM_DB_PASSWORD";

use vars qw(@weekdays @days @months %monthh @years @hours @mins @ap);

@weekdays = ('Sun', 'Mon', 'Tues', 'Wed', 'Thurs', 'Fri', 'Sat');
@days = ('01', '02', '03', '04', '05', '06', '07', '08', '09', '10',
         '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
         '21', '22', '23', '24', '25', '26', '27', '28', '29', '30',
         '31');
@months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug',
           'Sep', 'Oct', 'Nov', 'Dec');
%monthh = ('Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04',
           'May' => '05', 'Jun' => '06', 'Jul' => '07', 'Aug' => '08',
           'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12');
@years = ('1996', '1997', '1998', '1999', '2000', '2001', '2002',
          '2003', '2004', '2005');
@hours = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
@mins = ('00', '05', '10', '15', '20', '25', '30', '35', '40', '45',
         '50', '55');
@ap = ('AM', 'PM');

my $trim;
sub trim {
   my @out = @_;
   for (@out) {
      if ($_) {
         s/^\s+//;
         s/\s+$//;
      }
   }
   return wantarray ? @out : $out[0];
}

my $shorten;
sub shorten {
   my $src = shift;
   my $len = shift;
   my $ret;

   if (length $src > $len) {
      $ret = substr($src, 0, $len - 3);
      $ret .= "...";
   } else {
      $ret = $src;
   }
   return $ret;
}

my @time2hmp;
sub time2hmp {

   my $time = shift;

   $time =~ m/(\d\d):(\d\d):\d\d/;
   my ($hour, $min, $ap) = ($1, $2, 0);
   $hour -= 0;

   if ($hour == 0) {
      $ap = "AM";
      $hour = 12;
   } elsif ($hour > 0 && $hour < 12) {
      $ap = "AM";
   } elsif ($hour == 12) {
      $ap = "PM";
   } elsif ($hour > 12) {
      $ap = "PM";
      $hour -= 12;
   }

   return ($hour, $min, $ap);
}

my $hmp2time;
sub hmp2time {

   my ($hour, $min, $ap) = @_;
#   if (! $ap) { $ap = "AM"; }
#   if (! $min) { $min = 0; }
#   if (! $hour) { $hour = 0; }
   $hour -= 0;
   my $time;

   if ($hour == 12 && $ap eq "AM") {
      $hour = 0;
   } elsif ($ap eq "AM") {
   } elsif ($hour == 12 && $ap eq "PM") {
   } elsif ($ap eq "PM") {
      $hour += 12;
   }

   return $hour . ":" . $min . ":00";
}

my @date2ymd;
sub date2ymd {
   my $date = shift;

   $date =~ m/(\d\d\d\d)-(\d\d)-(\d\d)/;
   my ($year, $month, $day) = ($1, $2, $3);

   return ($year, $month, $day);
}

my $dmy2date;
sub dmy2date {
   my ($day, $month, $year) = @_;

   my $date = "";
   if ($day && $month && $year) {
      $date = $year . "-" . $month . "-" . $day;
   }

   return $date;
}

my $yesno;
sub yesno {
   my $val = shift;
   my $ret = "";

   if ($val) {
      $ret = "Yes";
   } else {
      $ret = "No";
   }

   return $ret;
}

# Exit normally;
1;

