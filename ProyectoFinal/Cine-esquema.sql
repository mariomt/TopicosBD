/* ------Created by----- */
-- Ayala Daniel.
-- Murillo Mario.
/* -------------------- */




/* -------------------- */
--  DATABASE SCHEMA.
/* -------------------- */

DROP DATABASE IF EXISTS CINE;

CREATE DATABASE CINE;

USE CINE;

CREATE TABLE `ESTADOS` (
  `ID` int(11) NOT NULL,
  `NOMBRE` varchar(50) NOT NULL,
  `NOMBRE_CORTO` varchar(50) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `MUNICIPIOS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `NOMBRE` varchar(50) NOT NULL,
  `cve_mun` int(3) unsigned zerofill DEFAULT NULL,
  `ESTADO` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `FK_MunicipioEstado` (`ESTADO`),
  CONSTRAINT `FK_MunicipioEstado` FOREIGN KEY (`ESTADO`) REFERENCES `estados` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `CINES` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `MUNICIPIO` int(11) NOT NULL,
  `DIRECCION` varchar(255) NOT NULL,
  `VIP` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `FK_CineMunicipio` (`MUNICIPIO`),
  CONSTRAINT `FK_CineMunicipio` FOREIGN KEY (`MUNICIPIO`) REFERENCES `municipios` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `SALAS` (
  `ID` bigint(20) NOT NULL AUTO_INCREMENT,
  `NOMBRE` varchar(100) DEFAULT NULL,
  `PANTALLA` varchar(100) DEFAULT NULL,
  `CAPACIDAD` int(11) NOT NULL,
  `TIPO` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `SALA_CINE` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `ID_CINE` int(11) NOT NULL,
  `ID_SALA` bigint(20) NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `FK_SalacineCine` (`ID_CINE`),
  KEY `FK_SalacineSala` (`ID_SALA`),
  CONSTRAINT `FK_SalacineCine` FOREIGN KEY (`ID_CINE`) REFERENCES `cines` (`ID`),
  CONSTRAINT `FK_SalacineSala` FOREIGN KEY (`ID_SALA`) REFERENCES `salas` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `ASIENTOS` (
  `ID` bigint(20) NOT NULL AUTO_INCREMENT,
  `FILA` char(1) DEFAULT NULL,
  `NOASIENTO` tinyint(1) DEFAULT NULL,
  `ID_SALA` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `FK_SalaAsiento` (`ID_SALA`),
  CONSTRAINT `FK_SalaAsiento` FOREIGN KEY (`ID_SALA`) REFERENCES `salas` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `PELICULAS` (
  `ID` bigint(20) NOT NULL AUTO_INCREMENT,
  `TITULO` varchar(100) NOT NULL,
  `CATEGORIA` varchar(255) NOT NULL,
  `SINOPSIS` text NOT NULL,
  `DURACION` time DEFAULT NULL,
  `LENGUAJES` enum('SPANISH','ENGLISH') DEFAULT NULL,
  `EXPERIENCIAS` varchar(255) DEFAULT NULL,
  `FECHA_REGISTRO` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `FECHA_ESTRENO` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `FUNCIONES` (
  `ID` bigint(20) AUTO_INCREMENT,
  `ID_PELICULA` bigint(20) NOT NULL,
  `ID_SALA_CINE` int(11) NOT NULL,
  `Caracteristicas` varchar(100) NOT NULL,
  `FECHA_HORA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY(`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `BOLETOS` (
  `ID` bigint(20) AUTO_INCREMENT,
  `ID_FUNCION` bigint(20) NOT NULL,
  `ID_TIPO` int(11) NOT NULL,
  `FILA` char(1) NOT NULL,
  `ASIENTO` tinyint(1) NOT NULL,
  `ESTADO` tinyint(1) NOT NULL,
  PRIMARY KEY(`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `EMPLEADOS` (
  `ID` bigint(20) NOT NULL AUTO_INCREMENT,
  `RFC` varchar(20) DEFAULT NULL,
  `NOMBRE` varchar(50) DEFAULT NULL,
  `APELLIDOPAT` varchar(50) DEFAULT NULL,
  `APELLIDOMAT` varchar(50) DEFAULT NULL,
  `FECHA_NAC` varchar(50) DEFAULT NULL,
  `CELULAR` varchar(21) DEFAULT NULL,
  `ID_SALARIO` int(11) DEFAULT NULL,
  `ID_SUPERIOR` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `puestos` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `NOMBRE` varchar(50) NOT NULL,
  `DESCRIPCION` varchar(255) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `salarios` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `ID_CINE` int(11) DEFAULT NULL,
  `ID_PUESTO` int(11) DEFAULT NULL,
  `SALARIO` double(10,2) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `FK_SalarioPuesto` (`ID_PUESTO`),
  KEY `FK_SalarioCine` (`ID_CINE`),
  CONSTRAINT `FK_SalarioCine` FOREIGN KEY (`ID_CINE`) REFERENCES `cines` (`ID`),
  CONSTRAINT `FK_SalarioPuesto` FOREIGN KEY (`ID_PUESTO`) REFERENCES `puestos` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `CLIENTES` (
  `ID` bigint(20) NOT NULL AUTO_INCREMENT,
  `NOMBRE` varchar(255) NOT NULL,
  `APELLIDOPAT` varchar(50) NOT NULL,
  `APELLIDOMAT` varchar(50) NOT NULL,
  `FEC_NAC` date NOT NULL,
  `TELEFONO` varchar(21) NOT NULL,
  `CATEGORIA` smallint(6) NOT NULL,
  `PUNTOS` int(11) NOT NULL DEFAULT '0',
  `FECHA_REGISTRO` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;









ALTER TABLE `FUNCIONES` ADD CONSTRAINT `FK_FuncionPelicula` FOREIGN KEY (`ID_PELICULA`) REFERENCES `PELICULAS` (`ID`);
ALTER TABLE `EMPLEADOS` ADD CONSTRAINT `FK_EmpleadoSalario` FOREIGN KEY (`ID_SALARIO`) REFERENCES `salarios` (`ID`);