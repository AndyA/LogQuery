-- MySQL dump 10.13  Distrib 5.5.43, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: weblog
-- ------------------------------------------------------
-- Server version	5.5.43-0+deb7u1-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `weblog_alias`
--

DROP TABLE IF EXISTS `weblog_alias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `weblog_alias` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `site_id` int(10) unsigned NOT NULL,
  `hostname` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `weblog_alias`
--

LOCK TABLES `weblog_alias` WRITE;
/*!40000 ALTER TABLE `weblog_alias` DISABLE KEYS */;
/*!40000 ALTER TABLE `weblog_alias` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `weblog_entry`
--

DROP TABLE IF EXISTS `weblog_entry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `weblog_entry` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `log_id` int(10) unsigned NOT NULL,
  `ip` varchar(20) NOT NULL,
  `ident` varchar(80) DEFAULT NULL,
  `user_id` varchar(80) DEFAULT NULL,
  `time` datetime NOT NULL,
  `method` varchar(10) NOT NULL,
  `path` varchar(256) NOT NULL,
  `path_full` text NOT NULL,
  `http_version` varchar(20) NOT NULL,
  `status` int(5) unsigned NOT NULL,
  `size` int(10) unsigned NOT NULL,
  `referrer` varchar(256) NOT NULL,
  `referrer_full` text NOT NULL,
  `user_agent` varchar(256) NOT NULL,
  `uri` varchar(256) NOT NULL,
  `uri_no_query` varchar(256) NOT NULL,
  `hour` int(5) unsigned NOT NULL,
  `day` int(5) unsigned NOT NULL,
  `date` date NOT NULL,
  PRIMARY KEY (`id`),
  KEY `log_id` (`log_id`),
  KEY `ip` (`ip`),
  KEY `ident` (`ident`),
  KEY `user_id` (`user_id`),
  KEY `time` (`time`),
  KEY `method` (`method`),
  KEY `path` (`path`),
  KEY `http_version` (`http_version`),
  KEY `status` (`status`),
  KEY `size` (`size`),
  KEY `referrer` (`referrer`),
  KEY `user_agent` (`user_agent`),
  KEY `uri` (`uri`),
  KEY `uri_no_query` (`uri_no_query`),
  KEY `hour` (`hour`),
  KEY `day` (`day`),
  KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `weblog_entry`
--

LOCK TABLES `weblog_entry` WRITE;
/*!40000 ALTER TABLE `weblog_entry` DISABLE KEYS */;
/*!40000 ALTER TABLE `weblog_entry` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `weblog_file`
--

DROP TABLE IF EXISTS `weblog_file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `weblog_file` (
  `log_id` int(10) unsigned NOT NULL,
  `filename` varchar(100) NOT NULL,
  `pos` int(10) unsigned NOT NULL,
  PRIMARY KEY (`log_id`,`filename`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `weblog_file`
--

LOCK TABLES `weblog_file` WRITE;
/*!40000 ALTER TABLE `weblog_file` DISABLE KEYS */;
/*!40000 ALTER TABLE `weblog_file` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `weblog_log`
--

DROP TABLE IF EXISTS `weblog_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `weblog_log` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `site_id` int(10) unsigned NOT NULL,
  `kind` varchar(255) NOT NULL,
  `log_dir` varchar(255) NOT NULL,
  `log_like` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `site_id` (`site_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `weblog_log`
--

LOCK TABLES `weblog_log` WRITE;
/*!40000 ALTER TABLE `weblog_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `weblog_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `weblog_site`
--

DROP TABLE IF EXISTS `weblog_site`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `weblog_site` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sitename` varchar(100) NOT NULL,
  `hostname` varchar(100) NOT NULL,
  `vhost` varchar(100) NOT NULL,
  `scheme` varchar(20) NOT NULL,
  `root` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `weblog_site`
--

LOCK TABLES `weblog_site` WRITE;
/*!40000 ALTER TABLE `weblog_site` DISABLE KEYS */;
/*!40000 ALTER TABLE `weblog_site` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-07-08 12:38:37
