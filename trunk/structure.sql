-- phpMyAdmin SQL Dump
-- version 3.2.4
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Mar 06, 2010 at 12:19 PM
-- Server version: 5.1.43
-- PHP Version: 5.2.9

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: 'joesdine_points'
--

-- --------------------------------------------------------

--
-- Table structure for table 'age_group'
--

CREATE TABLE age_group (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  age_groups_id int(10) unsigned NOT NULL,
  `text` varchar(255) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY `text` (`text`),
  UNIQUE KEY idx_unique_age_group (age_groups_id,`text`),
  KEY age_groups_id (age_groups_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table 'age_groups'
--

CREATE TABLE age_groups (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  description varchar(255) NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table 'circuit'
--

CREATE TABLE circuit (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  `year` int(10) unsigned NOT NULL,
  active tinyint(1) NOT NULL,
  visible tinyint(1) NOT NULL,
  age_groups_id int(10) unsigned NOT NULL COMMENT 'Which age groups to use for this circuit',
  PRIMARY KEY (id),
  KEY age_groups_id (age_groups_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table 'events'
--

CREATE TABLE `events` (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  url varchar(255) DEFAULT NULL,
  circuit_id int(10) unsigned NOT NULL,
  cvra_event tinyint(1) NOT NULL,
  date_year int(10) unsigned NOT NULL,
  date_month int(10) unsigned DEFAULT NULL,
  date_day int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (id),
  KEY circuit_id (circuit_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table 'people'
--

CREATE TABLE people (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  age_group int(10) unsigned NOT NULL,
  gender enum('Male','Female') NOT NULL,
  circuit_id int(10) unsigned NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY unique_person (`name`,age_group,gender,circuit_id),
  KEY age_group (age_group),
  KEY sex (gender),
  KEY circuit_id (circuit_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table 'races'
--

CREATE TABLE races (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  event_id int(10) unsigned NOT NULL,
  circuit_id int(10) unsigned NOT NULL,
  volunteer_points int(10) unsigned NOT NULL,
  run_points int(10) unsigned NOT NULL,
  distance varchar(255) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY circuit_id (circuit_id),
  KEY event_id (event_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table 'results'
--

CREATE TABLE results (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  `timestamp` datetime NOT NULL,
  person_id int(10) unsigned NOT NULL,
  race_id int(10) unsigned NOT NULL,
  `type` enum('volunteer','race') NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY duplicate_results (person_id,race_id),
  KEY person_id (person_id),
  KEY race_id (race_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table 'spam'
--

CREATE TABLE spam (
  id int(10) unsigned NOT NULL AUTO_INCREMENT,
  `timestamp` datetime NOT NULL,
  ipaddress varchar(255) DEFAULT NULL,
  user_id int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  cookie tinyint(1) NOT NULL,
  zipcode varchar(255) DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `age_group`
--
ALTER TABLE `age_group`
  ADD CONSTRAINT age_group_ibfk_1 FOREIGN KEY (age_groups_id) REFERENCES age_groups (id);

--
-- Constraints for table `circuit`
--
ALTER TABLE `circuit`
  ADD CONSTRAINT circuit_ibfk_1 FOREIGN KEY (age_groups_id) REFERENCES age_groups (id);

--
-- Constraints for table `events`
--
ALTER TABLE `events`
  ADD CONSTRAINT events_ibfk_1 FOREIGN KEY (circuit_id) REFERENCES circuit (id);

--
-- Constraints for table `people`
--
ALTER TABLE `people`
  ADD CONSTRAINT people_ibfk_1 FOREIGN KEY (age_group) REFERENCES age_group (id),
  ADD CONSTRAINT people_ibfk_2 FOREIGN KEY (circuit_id) REFERENCES circuit (id);

--
-- Constraints for table `races`
--
ALTER TABLE `races`
  ADD CONSTRAINT races_ibfk_1 FOREIGN KEY (circuit_id) REFERENCES circuit (id),
  ADD CONSTRAINT races_ibfk_2 FOREIGN KEY (event_id) REFERENCES `events` (id);

--
-- Constraints for table `results`
--
ALTER TABLE `results`
  ADD CONSTRAINT results_ibfk_1 FOREIGN KEY (person_id) REFERENCES people (id),
  ADD CONSTRAINT results_ibfk_2 FOREIGN KEY (race_id) REFERENCES races (id);
