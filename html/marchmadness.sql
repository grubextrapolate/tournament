CREATE TABLE `players` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(50) NOT NULL default '',
  `email` varchar(50) default NULL,
  `notify` tinyint(4) NOT NULL default '0',
  `symbol` char(2) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `symbol` (`symbol`)
);

CREATE TABLE `tournaments` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(200) NOT NULL default '',
  `year` int(11) NOT NULL default '0',
  `lastupdate` datetime NOT NULL default '0000-00-00 00:00:00',
  `cutoff` datetime NOT NULL,
  PRIMARY KEY  (`id`)
);

CREATE TABLE `divisions` (
  `id` int(11) NOT NULL auto_increment,
  `tourneyid` int(11) NOT NULL default '0',
  `name` varchar(200) NOT NULL default '',
  `position` tinyint(4) NOT NULL default '0',
  PRIMARY KEY  (`id`)
);

CREATE TABLE `teams` (
  `id` int(11) NOT NULL auto_increment,
  `divisionid` tinyint(4) NOT NULL default '0',
  `name` varchar(100) NOT NULL default '',
  `seed` tinyint(4) NOT NULL default '0',
  `alias` varchar(15) NOT NULL,
  PRIMARY KEY  (`id`)
);

CREATE TABLE `picks` (
  `id` int(11) NOT NULL auto_increment,
  `playerid` int(11) NOT NULL default '0',
  `tourneyid` int(11) NOT NULL default '0',
  `teamid` int(11) NOT NULL default '0',
  `wildcard` tinyint(4) NOT NULL default '0',
  PRIMARY KEY  (`id`)
);

CREATE TABLE `scores` (
  `id` int(11) NOT NULL auto_increment,
  `tourneyid` int(11) NOT NULL default '0',
  `teamid1` int(11) NOT NULL default '0',
  `score1` int(11) NOT NULL default '0',
  `teamid2` int(11) NOT NULL default '0',
  `score2` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`)
);
