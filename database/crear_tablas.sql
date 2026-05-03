/*Creacion de la tabla Puesto*/

CREATE TABLE dbo.Puesto
(
	id INT IDENTITY(1,1) PRIMARY KEY
	, Nombre VARCHAR(50) NOT NULL
	, SalarioxHora MONEY NOT NULL
);
GO

/*Creacion de la tabla TipoMovimiento*/
/*id se hizo identity aunque no se especifica en el enunciado, ya 
que en los XML de prueba se muestra que el id es autoincremental,
por lo que se asume que es identity*/

CREATE TABLE dbo.TipoMovimiento
(
	id           INT         NOT NULL PRIMARY KEY
	, Nombre     VARCHAR(50) NOT NULL
	, TipoAccion VARCHAR(20) NOT NULL
);
GO

/*Creacion de tabla Usuario*/

CREATE TABLE dbo.Usuario
(
	id INT  NOT NULL PRIMARY KEY
	, Username VARCHAR(50) NOT NULL
	, Password VARCHAR(100) NOT NULL
);
GO

/*Creacion de tabla Empleado*/

CREATE TABLE dbo.Empleado
(
	id INT IDENTITY(1,1) NOT NULL PRIMARY KEY
	, Nombre VARCHAR(100) NOT NULL
	, IdPuesto INT NOT NULL
	, ValorDocumentoIdentidad VARCHAR(50) NOT NULL
	, FechaContratacion DATE NOT NULL
	, SaldoVacaciones decimal(10,2) NOT NULL DEFAULT 0
	, EsActivo BIT NOT NULL DEFAULT 1 --Se asume que esta activo
	,	CONSTRAINT FK_Empleado_Puesto FOREIGN KEY (idPuesto)
			REFERENCES dbo.Puesto(id)
);
GO

/*Creacion de tabla Movimiento*/

CREATE TABLE dbo.Movimiento
(
	id INT IDENTITY(1,1) NOT NULL PRIMARY KEY
	, IdEmpleado INT NOT NULL
	, IdTipoMovimiento INT NOT NULL
	, Fecha DATE NOT NULL
	, Monto DECIMAL(10,2) NOT NULL
	, NuevoSaldo DECIMAL(10,2) NOT NULL
	, IdUsuario INT NOT NULL
	, IpPostIn VARCHAR(50) NOT NULL
	, PostTime DATETIME NOT NULL
	,   CONSTRAINT FK_Movimiento_Empleado FOREIGN KEY (idEmpleado)
			REFERENCES dbo.Empleado(id)
	,   CONSTRAINT FK_Movimiento_TipoMovimiento FOREIGN KEY (idTipoMovimiento)
			REFERENCES dbo.TipoMovimiento(id)
	,   CONSTRAINT FK_Movimiento_Usuario FOREIGN KEY (idUsuario)
			REFERENCES dbo.Usuario(id)
);
GO

/*Creacion de tabla TipoEvento*/

CREATE TABLE dbo.TipoEvento
(
	id INT PRIMARY KEY
	, Nombre VARCHAR(100) NOT NULL
);
GO

/*Creacion de tabla BitacoraEvento*/

CREATE TABLE dbo.BitacoraEvento
(
	id INT IDENTITY(1,1) PRIMARY KEY
	, IdTipoEvento INT NOT NULL
	, Descripcion VARCHAR(500) NOT NULL
	, IdUsuario INT NOT NULL
	, IpPostIn VARCHAR(50) NOT NULL
	, PostTime DATETIME NOT NULL
	,	CONSTRAINT FK_Bitacora_TipoEvento FOREIGN KEY (idTipoEvento)
			REFERENCES dbo.TipoEvento(id)
	,	CONSTRAINT FK_Bitacora_Usuario FOREIGN KEY (idUsuario)
			REFERENCES dbo.Usuario(id)
);
GO

/*Creacion de tabla Error*/

CREATE TABLE dbo.Error
(
	id INT IDENTITY(1,1) PRIMARY KEY
	, Codigo INT NOT NULL
	, Descripcion VARCHAR(500) NOT NULL
);
GO

/*Creacion de tabla DBError*/

CREATE TABLE dbo.DBError
(
	id INT IDENTITY(1,1) PRIMARY KEY
	, UserName VARCHAR(100)
	, Number INT
	, [State] INT
	, Severity INT
	, Line INT
	, [Procedure] VARCHAR(200)
	, [Message] VARCHAR(500)
	, [DateTime] DATETIME
);
GO
