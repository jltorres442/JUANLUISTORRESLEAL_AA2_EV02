-- ====================================================================
-- PROYECTO : Homecenter Envíos - Sistema de realización y seguimiento
--            de pedidos.
-- BASE     : homecenter_db
-- MOTOR    : MySQL 8.0+ / MariaDB 10.5+
-- ORIGEN   : Evidencia GA6-220501096-AA2-EV03 (script_db_homecenter.sql)
--
-- CAMBIOS RESPECTO AL SCRIPT ORIGINAL
--   1. Las llaves primarias usan AUTO_INCREMENT para que la aplicación
--      no tenga que calcular los identificadores.
--   2. Los actores que inician sesión (Cliente, Vendedor, Logistica y
--      Transportista) ahora almacenan: numero_identificacion, telefono
--      y contrasena (hash PBKDF2, nunca texto plano).
--   3. Transportista.id_envio admite NULL: un transportista puede estar
--      registrado sin tener un envío asignado en este momento.
--   4. Se agregan restricciones CHECK sobre los estados permitidos.
-- ====================================================================

DROP DATABASE IF EXISTS homecenter_db;
CREATE DATABASE homecenter_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE homecenter_db;

-- --------------------------------------------------------------------
-- 1. TABLA: Cliente
--    Persona que realiza pedidos en Homecenter.
-- --------------------------------------------------------------------
CREATE TABLE Cliente (
    id_cliente            INT          NOT NULL AUTO_INCREMENT,
    numero_identificacion VARCHAR(20)  NOT NULL,
    nombre                VARCHAR(100) NOT NULL,
    email                 VARCHAR(150) NOT NULL,
    contrasena            VARCHAR(255) NOT NULL,
    telefono              VARCHAR(20)  NOT NULL,
    direccion             VARCHAR(200) NOT NULL,
    fecha_registro        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cliente),
    UNIQUE KEY uq_cliente_email (email),
    UNIQUE KEY uq_cliente_identificacion (numero_identificacion)
);

-- --------------------------------------------------------------------
-- 2. TABLA: Vendedor
--    Asesor comercial que registra los pedidos.
-- --------------------------------------------------------------------
CREATE TABLE Vendedor (
    id_vendedor           INT          NOT NULL AUTO_INCREMENT,
    numero_identificacion VARCHAR(20)  NOT NULL,
    nombre                VARCHAR(100) NOT NULL,
    email                 VARCHAR(150) NOT NULL,
    contrasena            VARCHAR(255) NOT NULL,
    telefono              VARCHAR(20)  NOT NULL,
    registro_pedido       TINYINT(1)   NOT NULL DEFAULT 1,
    PRIMARY KEY (id_vendedor),
    UNIQUE KEY uq_vendedor_email (email),
    UNIQUE KEY uq_vendedor_identificacion (numero_identificacion)
);

-- --------------------------------------------------------------------
-- 3. TABLA: Pedido
-- --------------------------------------------------------------------
CREATE TABLE Pedido (
    id_pedido   INT           NOT NULL AUTO_INCREMENT,
    fecha       DATE          NOT NULL,
    total       DECIMAL(12,2) NOT NULL,
    estado      VARCHAR(50)   NOT NULL,
    id_cliente  INT           NOT NULL,
    id_vendedor INT           NOT NULL,
    PRIMARY KEY (id_pedido),
    CONSTRAINT fk_pedido_cliente  FOREIGN KEY (id_cliente)
        REFERENCES Cliente (id_cliente)   ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pedido_vendedor FOREIGN KEY (id_vendedor)
        REFERENCES Vendedor (id_vendedor) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_total_pedido  CHECK (total >= 0.0),
    CONSTRAINT chk_estado_pedido CHECK (estado IN
        ('PENDIENTE', 'EN_PREPARACION', 'DESPACHADO', 'ENTREGADO', 'CANCELADO'))
);

-- --------------------------------------------------------------------
-- 4. TABLA: Factura (relación 1:1 con Pedido)
-- --------------------------------------------------------------------
CREATE TABLE Factura (
    id_factura    INT           NOT NULL AUTO_INCREMENT,
    fecha_emision DATE          NOT NULL,
    monto_total   DECIMAL(12,2) NOT NULL,
    id_pedido     INT           NOT NULL,
    PRIMARY KEY (id_factura),
    UNIQUE KEY uq_factura_pedido (id_pedido),
    CONSTRAINT fk_factura_pedido FOREIGN KEY (id_pedido)
        REFERENCES Pedido (id_pedido) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_monto_factura CHECK (monto_total >= 0.0)
);

-- --------------------------------------------------------------------
-- 5. TABLA: Logistica
--    Personal de bodega que prepara y despacha los envíos.
-- --------------------------------------------------------------------
CREATE TABLE Logistica (
    id_logistica          INT          NOT NULL AUTO_INCREMENT,
    numero_identificacion VARCHAR(20)  NOT NULL,
    nombre                VARCHAR(100) NOT NULL,
    email                 VARCHAR(150) NOT NULL,
    contrasena            VARCHAR(255) NOT NULL,
    telefono              VARCHAR(20)  NOT NULL,
    PRIMARY KEY (id_logistica),
    UNIQUE KEY uq_logistica_email (email),
    UNIQUE KEY uq_logistica_identificacion (numero_identificacion)
);

-- --------------------------------------------------------------------
-- 6. TABLA: Envio_Pedido (relación 1:1 con Pedido)
-- --------------------------------------------------------------------
CREATE TABLE Envio_Pedido (
    id_envio          INT          NOT NULL AUTO_INCREMENT,
    fecha_envio       DATE         NOT NULL,
    direccion_entrega VARCHAR(250) NOT NULL,
    estado            VARCHAR(50)  NOT NULL,
    id_pedido         INT          NOT NULL,
    id_logistica      INT          NOT NULL,
    PRIMARY KEY (id_envio),
    UNIQUE KEY uq_envio_pedido (id_pedido),
    CONSTRAINT fk_envio_pedido    FOREIGN KEY (id_pedido)
        REFERENCES Pedido (id_pedido)       ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_envio_logistica FOREIGN KEY (id_logistica)
        REFERENCES Logistica (id_logistica) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_estado_envio CHECK (estado IN
        ('PROGRAMADO', 'EN_RUTA', 'ENTREGADO', 'CON_INCIDENCIA'))
);

-- --------------------------------------------------------------------
-- 7. TABLA: Transportista
-- --------------------------------------------------------------------
CREATE TABLE Transportista (
    id_transportista      INT          NOT NULL AUTO_INCREMENT,
    numero_identificacion VARCHAR(20)  NOT NULL,
    nombre                VARCHAR(100) NOT NULL,
    email                 VARCHAR(150) NOT NULL,
    contrasena            VARCHAR(255) NOT NULL,
    telefono              VARCHAR(20)  NOT NULL,
    licencia              VARCHAR(50)  NOT NULL,
    id_envio              INT          NULL,
    PRIMARY KEY (id_transportista),
    UNIQUE KEY uq_transportista_email (email),
    UNIQUE KEY uq_transportista_identificacion (numero_identificacion),
    CONSTRAINT fk_transportista_envio FOREIGN KEY (id_envio)
        REFERENCES Envio_Pedido (id_envio) ON DELETE SET NULL ON UPDATE CASCADE
);

-- --------------------------------------------------------------------
-- 8. TABLA: Incidencia (N incidencias por envío)
-- --------------------------------------------------------------------
CREATE TABLE Incidencia (
    id_incidencia INT         NOT NULL AUTO_INCREMENT,
    descripcion   TEXT        NOT NULL,
    estado        VARCHAR(50) NOT NULL,
    id_envio      INT         NOT NULL,
    PRIMARY KEY (id_incidencia),
    CONSTRAINT fk_incidencia_envio FOREIGN KEY (id_envio)
        REFERENCES Envio_Pedido (id_envio) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_estado_incidencia CHECK (estado IN
        ('ABIERTA', 'EN_PROCESO', 'RESUELTA'))
);

-- --------------------------------------------------------------------
-- 9. TABLA: Notificacion (N notificaciones por transportista)
-- --------------------------------------------------------------------
CREATE TABLE Notificacion (
    id_notificacion  INT      NOT NULL AUTO_INCREMENT,
    mensaje          TEXT     NOT NULL,
    fecha_hora       DATETIME NOT NULL,
    id_transportista INT      NOT NULL,
    PRIMARY KEY (id_notificacion),
    CONSTRAINT fk_notificacion_transportista FOREIGN KEY (id_transportista)
        REFERENCES Transportista (id_transportista) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ====================================================================
-- DATOS DE PRUEBA
-- Todas las cuentas de ejemplo usan la contraseña:  Homecenter2026*
-- (el valor almacenado es su hash PBKDF2WithHmacSHA256, 65 536 iteraciones)
-- ====================================================================
SET @clave_demo = 'pbkdf2$65536$JU8jALW4gNGGvytKw3C1eg==$eWxri/p/FK+ohZhkPJ8li2B2bjjWtjPquBN9nfUYH7Q=';

INSERT INTO Cliente (numero_identificacion, nombre, email, contrasena, telefono, direccion) VALUES
    ('1020304050', 'María Fernanda Rojas', 'maria.rojas@correo.com',   @clave_demo, '3104567890', 'Cra. 15 # 93-47, Bogotá'),
    ('1032456789', 'Carlos Andrés Pérez',  'carlos.perez@correo.com',  @clave_demo, '3157894561', 'Cl. 72 # 10-34, Bogotá'),
    ('52876543',   'Luisa Gómez Vargas',   'luisa.gomez@correo.com',   @clave_demo, '3009876543', 'Av. 68 # 24-10, Bogotá');

INSERT INTO Vendedor (numero_identificacion, nombre, email, contrasena, telefono, registro_pedido) VALUES
    ('79654321', 'Andrés Castillo', 'andres.castillo@homecenter.com', @clave_demo, '3201112233', 1),
    ('1019876543', 'Paula Méndez',  'paula.mendez@homecenter.com',    @clave_demo, '3112223344', 1);

INSERT INTO Logistica (numero_identificacion, nombre, email, contrasena, telefono) VALUES
    ('80123456', 'Jorge Ramírez', 'jorge.ramirez@homecenter.com', @clave_demo, '3183334455');

INSERT INTO Pedido (fecha, total, estado, id_cliente, id_vendedor) VALUES
    ('2026-09-20', 1250000.00, 'ENTREGADO',      1, 1),
    ('2026-09-25',  389900.00, 'DESPACHADO',     2, 1),
    ('2026-09-28',  749500.00, 'EN_PREPARACION', 3, 2),
    ('2026-09-29',   89900.00, 'PENDIENTE',      1, 2);

INSERT INTO Factura (fecha_emision, monto_total, id_pedido) VALUES
    ('2026-09-20', 1250000.00, 1),
    ('2026-09-25',  389900.00, 2);

INSERT INTO Envio_Pedido (fecha_envio, direccion_entrega, estado, id_pedido, id_logistica) VALUES
    ('2026-09-21', 'Cra. 15 # 93-47, Bogotá', 'ENTREGADO',      1, 1),
    ('2026-09-26', 'Cl. 72 # 10-34, Bogotá',  'CON_INCIDENCIA', 2, 1);

INSERT INTO Transportista (numero_identificacion, nombre, email, contrasena, telefono, licencia, id_envio) VALUES
    ('1098765432', 'Diego Martínez', 'diego.martinez@homecenter.com', @clave_demo, '3145556677', 'C2-1098765432', 2),
    ('1011223344', 'Sandra López',   'sandra.lopez@homecenter.com',   @clave_demo, '3176667788', 'C1-1011223344', NULL);

INSERT INTO Incidencia (descripcion, estado, id_envio) VALUES
    ('Cliente no presente en la dirección de entrega. Se reprograma la visita.', 'ABIERTA', 2);

INSERT INTO Notificacion (mensaje, fecha_hora, id_transportista) VALUES
    ('Se le asignó el envío #2 con destino Cl. 72 # 10-34.', '2026-09-26 07:30:00', 1),
    ('Recuerde confirmar la entrega con foto y firma.',        '2026-09-26 07:31:00', 1);
