-- phpMyAdmin SQL Dump
-- version 2.11.9.4
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Feb 10, 2009 at 05:20 AM
-- Server version: 5.0.67
-- PHP Version: 5.2.3

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `joesdine_points`
--

-- --------------------------------------------------------

--
-- Table structure for table `age_group`
--

CREATE TABLE IF NOT EXISTS `age_group` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `text` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `text` (`text`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `age_group`
--

INSERT INTO `age_group` (`id`, `text`) VALUES
(1, '20-29'),
(2, '30-39'),
(3, '40-49'),
(4, '50-59'),
(5, '60-69'),
(6, '70+');

-- --------------------------------------------------------

--
-- Table structure for table `circuit`
--

CREATE TABLE IF NOT EXISTS `circuit` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `year` int(10) unsigned NOT NULL,
  `active` tinyint(1) NOT NULL,
  `visible` tinyint(1) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

--
-- Dumping data for table `circuit`
--

INSERT INTO `circuit` (`id`, `year`, `active`, `visible`) VALUES
(1, 2009, 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `people`
--

CREATE TABLE IF NOT EXISTS `people` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `age_group` int(10) unsigned NOT NULL,
  `sex` enum('m','f') NOT NULL,
  `circuit_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `unique_person` (`name`,`age_group`,`sex`,`circuit_id`),
  KEY `age_group` (`age_group`),
  KEY `sex` (`sex`),
  KEY `circuit_id` (`circuit_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=35 ;

--
-- Dumping data for table `people`
--

INSERT INTO `people` (`id`, `name`, `age_group`, `sex`, `circuit_id`) VALUES
(1, 'Billy Bob', 1, 'm', 1),
(4, 'boy2', 2, 'm', 1),
(5, 'boy3', 3, 'm', 1),
(6, 'boy4', 4, 'm', 1),
(9, 'boy5', 5, 'm', 1),
(10, 'boy6', 6, 'm', 1),
(11, 'girl1', 1, 'f', 1),
(13, 'girl1  b', 1, 'f', 1),
(12, 'girl1 a', 1, 'f', 1),
(14, 'girl1 c', 1, 'f', 1),
(15, 'girl2 a', 2, 'f', 1),
(16, 'girl2 b', 2, 'f', 1),
(17, 'girl2 c', 2, 'f', 1),
(18, 'girl2 d', 2, 'f', 1),
(19, 'girl3 a', 3, 'f', 1),
(20, 'girl3 b', 3, 'f', 1),
(21, 'girl3 c', 3, 'f', 1),
(22, 'girl3 d', 3, 'f', 1),
(23, 'girl4 a', 4, 'f', 1),
(24, 'girl4 b', 4, 'f', 1),
(25, 'girl4 c', 4, 'f', 1),
(26, 'girl4 d', 4, 'f', 1),
(27, 'girl5 a', 5, 'f', 1),
(28, 'girl5 b', 5, 'f', 1),
(29, 'girl5 c', 5, 'f', 1),
(30, 'girl5 d', 5, 'f', 1),
(31, 'girl6 a', 6, 'f', 1),
(33, 'girl6 c', 6, 'f', 1),
(34, 'girl6 d', 6, 'f', 1),
(32, 'gitl6 b', 6, 'f', 1),
(2, 'John Doe', 1, 'm', 1),
(3, 'Mr. Smith', 1, 'm', 1);

-- --------------------------------------------------------

--
-- Table structure for table `races`
--

CREATE TABLE IF NOT EXISTS `races` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `date` varchar(255) default NULL,
  `circuit_id` int(10) unsigned NOT NULL,
  `volunteer_points` int(10) unsigned NOT NULL,
  `run_points` int(10) unsigned NOT NULL,
  `distance` varchar(255) default NULL,
  `cvra_event` tinyint(1) NOT NULL,
  `order` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `circuit_id_2` (`circuit_id`,`order`),
  KEY `circuit_id` (`circuit_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=4 ;

--
-- Dumping data for table `races`
--

INSERT INTO `races` (`id`, `name`, `date`, `circuit_id`, `volunteer_points`, `run_points`, `distance`, `cvra_event`, `order`) VALUES
(1, 'Freeze Fest', 'Feb', 1, 10, 15, '5K', 0, 0),
(2, 'Springville', 'March', 1, 10, 15, '5K', 0, 1),
(3, 'Run for the Schools', 'October', 1, 10, 50, 'Half Marathon', 0, 2);

-- --------------------------------------------------------

--
-- Table structure for table `results`
--

CREATE TABLE IF NOT EXISTS `results` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `person_id` int(10) unsigned NOT NULL,
  `race_id` int(10) unsigned NOT NULL,
  `type` enum('volunteer','race') NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `duplicate_results` (`person_id`,`race_id`,`type`),
  KEY `person_id` (`person_id`),
  KEY `race_id` (`race_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=7 ;

--
-- Dumping data for table `results`
--

INSERT INTO `results` (`id`, `person_id`, `race_id`, `type`) VALUES
(1, 12, 1, 'race'),
(2, 12, 2, 'race'),
(3, 12, 3, 'race'),
(4, 13, 1, 'race'),
(5, 14, 3, 'volunteer'),
(6, 15, 3, 'race');

--
-- Constraints for dumped tables
--

--
-- Constraints for table `people`
--
ALTER TABLE `people`
  ADD CONSTRAINT `people_ibfk_2` FOREIGN KEY (`circuit_id`) REFERENCES `circuit` (`id`),
  ADD CONSTRAINT `people_ibfk_1` FOREIGN KEY (`age_group`) REFERENCES `age_group` (`id`);

--
-- Constraints for table `races`
--
ALTER TABLE `races`
  ADD CONSTRAINT `races_ibfk_1` FOREIGN KEY (`circuit_id`) REFERENCES `circuit` (`id`);

--
-- Constraints for table `results`
--
ALTER TABLE `results`
  ADD CONSTRAINT `results_ibfk_1` FOREIGN KEY (`person_id`) REFERENCES `people` (`id`),
  ADD CONSTRAINT `results_ibfk_2` FOREIGN KEY (`race_id`) REFERENCES `races` (`id`);
