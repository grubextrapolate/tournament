CREATE TABLE players (
   id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
   name VARCHAR(50) NOT NULL,
   email VARCHAR (50),
   notify TINYINT NOT NULL,
   symbol VARCHAR(2) NOT NULL UNIQUE
);

CREATE TABLE tournaments (
   id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
   name VARCHAR(200) NOT NULL,
   year INT NOT NULL,
   lastupdate DATETIME NOT NULL
);

CREATE TABLE divisions (
   id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
   tourneyid INT NOT NULL,
   name VARCHAR(200) NOT NULL
);

CREATE TABLE teams (
   id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
   divisionid TINYINT NOT NULL,
   name VARCHAR(100) NOT NULL,
   seed TINYINT NOT NULL
);

CREATE TABLE picks (
   id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
   playerid INT NOT NULL,
   tourneyid INT NOT NULL,
   teamid INT NOT NULL,
   wildcard TINYINT NOT NULL
);

CREATE TABLE scores (
   id INT PRIMARY KEY NOT NULL AUTO_INCREMENT,
   tourneyid INT NOT NULL,
   teamid1 INT NOT NULL,
   score1 INT NOT NULL,
   teamid2 INT NOT NULL,
   score2 INT NOT NULL
);