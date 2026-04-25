USE BDTarea2;

/*Creacion de la tabla Puesto*/
GO

CREATE TABLE dbo.Puesto
(
	id INT IDENTITY(1,1) PRIMARY KEY
	, Nombre VARCHAR(50) NOT NULL
	, SalarioxHora MONEY NOT NULL
);

GO

/*Creacion de la tabla TipoMovimiento*/
/*id se hizo identity aunque no se especifica en el enunciado, ya 
que en los XML de prueba se muestra que el id es autoincremental, por lo que se asume que es identity*/
GO
CREATE TABLE dbo.TipoMovimiento
(
	id           INT         NOT NULL PRIMARY KEY
	, Nombre     VARCHAR(50) NOT NULL
	, TipoAccion VARCHAR(20) NOT NULL
);
GO

/*Creacion de tabla Usuario*/
GO
CREATE TABLE dbo.Usuario
(
	id INT  NOT NULL PRIMARY KEY
	, Username VARCHAR(50) NOT NULL
	, Password VARCHAR(50) NOT NULL
);
GO

/*Creacion de tabla Empleado*/
GO
CREATE TABLE dbo.Empleado
(
	id INT IDENTITY(1,1) NOT NULL PRIMARY KEY
	, Nombre VARCHAR(100) NOT NULL
	, IdPuesto INT NOT NULL
	, ValorDocumentoIdentidad VARCHAR(250) NOT NULL
	, FechaContratacion DATE NOT NULL
	, SaldoVacaciones decimal(10,2) NOT NULL
	, EsActivo BIT NOT NULL
	,   CONSTRAINT FK_Empleado_Puesto FOREIGN KEY (idPuesto)
        REFERENCES dbo.Puesto(id)
);
GO

/*Creacion de tabla Movimiento*/
GO
CREATE TABLE dbo.Movimiento
(
	id INT IDENTITY(1,1) NOT NULL PRIMARY KEY
	, IdEmpleado INT NOT NULL
	, IdTipoMovimiento INT NOT NULL
	, Fecha DATE NOT NULL
	, Monto DECIMAL(10,2) NOT NULL
	, NuevoSaldo DECIMAL(10,2) NOT NULL
	, IdPostByUser INT NOT NULL
	, PostInIP VARCHAR(50) NOT NULL
	, PostTime DATETIME NOT NULL
	,   CONSTRAINT FK_Movimiento_Empleado FOREIGN KEY (idEmpleado)
		REFERENCES dbo.Empleado(id)
	,   CONSTRAINT FK_Movimiento_TipoMovimiento FOREIGN KEY (idTipoMovimiento)
		REFERENCES dbo.TipoMovimiento(id)
	,   CONSTRAINT FK_Movimiento_Usuario FOREIGN KEY (idPostByUser)
		REFERENCES dbo.Usuario(id)
);
GO