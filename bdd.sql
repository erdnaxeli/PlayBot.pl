SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


--
-- Structure de la table `playbot_codes`
--

CREATE TABLE IF NOT EXISTS `playbot_codes` (
  `user` varchar(255) NOT NULL,
  `code` varchar(25) NOT NULL,
  `nick` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`user`),
  UNIQUE KEY `code` (`code`),
  UNIQUE KEY `nick` (`nick`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


--
-- Structure de la table `playbot`
--

CREATE TABLE IF NOT EXISTS `playbot` (
  `date` date NOT NULL,
  `type` varchar(15) COLLATE utf8_unicode_ci NOT NULL,
  `url` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `sender_irc` varchar(99) COLLATE utf8_unicode_ci NOT NULL,
  `sender` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `file` varchar(150) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `chan` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `url` (`url`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='table du bot irc' AUTO_INCREMENT=652 ;
