GO
/*
    ListarEmpleados
    Recibe:
    @inFiltroNombre - filtro opcional por nombre
    @inFiltroCedula - filtro opcional por cedula
    @inIdUsuario - id del usuario en sesion
    @inIP - IP desde donde se hace la consulta
    Retorna: Lista de empleados activos que cumplen el filtro.
             Si no hay filtro, retorna todos los empleados activos.
*/
CREATE PROCEDURE dbo.ListarEmpleados
    @inFiltroNombre VARCHAR(255) = NULL
,   @inFiltroCedula VARCHAR(255) = NULL
,   @inIdUsuario    INT          = 0
,   @inIP           VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @outResultCode INT = 0
    DECLARE @ahora DATETIME = GETDATE()

    BEGIN TRY

        SELECT
            T.id
        ,   T.Nombre
        ,   T.ValorDocumentoIdentidad
        ,   T.FechaContratacion
        ,   T.SaldoVacaciones
        ,   P.Nombre AS NombrePuesto
        FROM dbo.Empleado AS T
        INNER JOIN dbo.Puesto AS P ON (T.idPuesto = P.id)
        WHERE (T.EsActivo = 1)
            AND (@inFiltroNombre IS NULL OR T.Nombre LIKE '%' + @inFiltroNombre + '%')
            AND (@inFiltroCedula IS NULL OR T.ValorDocumentoIdentidad LIKE '%' + @inFiltroCedula + '%')
        ORDER BY T.Nombre ASC

        /*
        Evento 11 = Consulta con filtro por nombre
        Evento 12 = Consulta con filtro por cedula
        Se registra solo el evento que corresponde segun el filtro recibido.*/

        IF (@inFiltroNombre IS NOT NULL)
        BEGIN
            EXEC dbo.RegistrarBitacora
                @inIdTipoEvento = 11
            ,   @inDescripcion  = @inFiltroNombre
            ,   @inIdUsuario    = @inIdUsuario
            ,   @inIpPostIn     = @inIP
            ,   @inPostTime     = @ahora
        END
        ELSE IF (@inFiltroCedula IS NOT NULL)
        BEGIN
            EXEC dbo.RegistrarBitacora
                @inIdTipoEvento = 12
            ,   @inDescripcion  = @inFiltroCedula
            ,   @inIdUsuario    = @inIdUsuario
            ,   @inIpPostIn     = @inIP
            ,   @inPostTime     = @ahora
        END

    END TRY
    BEGIN CATCH

        SET @outResultCode = 50008

        INSERT INTO dbo.DBError
        (
            UserName
        ,   Number
        ,   [State]
        ,   Severity
        ,   Line
        ,   [Procedure]
        ,   [Message]
        ,   [DateTime]
        )
        VALUES
        (
            SUSER_NAME()
        ,   ERROR_NUMBER()
        ,   ERROR_STATE()
        ,   ERROR_SEVERITY()
        ,   ERROR_LINE()
        ,   ERROR_PROCEDURE()
        ,   ERROR_MESSAGE()
        ,   GETDATE()
        )

    END CATCH

    SELECT @outResultCode AS resultCode

END
GO


/*
    InsertarEmpleado
    Recibe:
    @inNombre - nombre del empleado
    @inValorDocumentoIdentidad - cedula del empleado
    @inIdPuesto - id del puesto asignado
    @inIdUsuario- id del usuario en sesion
    @inIP- IP desde donde se hace la operacion
    Retorna: @outResultCode: 0 si exitoso, >50000 si hubo error
    Valida:  que no exista otro empleado con mismo nombre o cedula
*/
CREATE PROCEDURE dbo.InsertarEmpleado
    @inNombre                   VARCHAR(150)
,   @inValorDocumentoIdentidad  VARCHAR(20)
,   @inIdPuesto                 INT
,   @inIdUsuario                INT         = 0
,   @inIP                       VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @outResultCode  INT          = 0
    DECLARE @desc           VARCHAR(500) = ''  -- descripcion para bitacora
    DECLARE @ahora   DATETIME   = GETDATE()

    BEGIN TRY

        IF EXISTS (
            SELECT 1
            FROM dbo.Empleado AS E
            WHERE (E.ValorDocumentoIdentidad = @inValorDocumentoIdentidad)
                AND (E.EsActivo = 1)
        )
        BEGIN
            SET @outResultCode = 50004
            SET @desc = 'ValDoc: ' + @inValorDocumentoIdentidad + ' Nombre: ' + @inNombre

            /* Insercion no exitosa: Evento 5 - cedula duplicada*/
            EXEC dbo.RegistrarBitacora
                @inIdTipoEvento = 5
            ,   @inDescripcion  = @desc
            ,   @inIdUsuario    = @inIdUsuario
            ,   @inIpPostIn     = @inIP
            ,   @inPostTime     = @ahora

            GOTO Fin
        END

        IF EXISTS (
            SELECT 1
            FROM dbo.Empleado AS E
            WHERE (E.Nombre = @inNombre)
                AND (E.EsActivo = 1)
        )
        BEGIN
            SET @outResultCode = 50005
            SET @desc = 'ValDoc: ' + @inValorDocumentoIdentidad + ' Nombre: ' + @inNombre

            /* Insercion no exitosa: Evento 5 - nombre duplicado*/
            EXEC dbo.RegistrarBitacora
                @inIdTipoEvento = 5
            ,   @inDescripcion  = @desc
            ,   @inIdUsuario    = @inIdUsuario
            ,   @inIpPostIn     = @inIP
            ,   @inPostTime     = @ahora

            GOTO Fin
        END

        BEGIN TRANSACTION

            INSERT INTO dbo.Empleado
            (
                idPuesto
            ,   ValorDocumentoIdentidad
            ,   Nombre
            ,   FechaContratacion
            ,   SaldoVacaciones
            ,   EsActivo
            )
            VALUES
            (
                @inIdPuesto
            ,   @inValorDocumentoIdentidad
            ,   @inNombre
            ,   GETDATE()
            ,   0
            ,   1
            )

        COMMIT TRANSACTION

        SET @desc = 'ValDoc: ' + @inValorDocumentoIdentidad + ' Nombre: ' + @inNombre

        /* Insercion exitosa: Evento 6*/
        EXEC dbo.RegistrarBitacora
            @inIdTipoEvento = 6
        ,   @inDescripcion  = @desc
        ,   @inIdUsuario    = @inIdUsuario
        ,   @inIpPostIn     = @inIP
        ,   @inPostTime     = @ahora

    END TRY
    BEGIN CATCH

        IF (@@TRANCOUNT > 0)
            ROLLBACK TRANSACTION

        SET @outResultCode = 50008

        INSERT INTO dbo.DBError
        (
            UserName
        ,   Number
        ,   [State]
        ,   Severity
        ,   Line
        ,   [Procedure]
        ,   [Message]
        ,   [DateTime]
        )
        VALUES
        (
            SUSER_NAME()
        ,   ERROR_NUMBER()
        ,   ERROR_STATE()
        ,   ERROR_SEVERITY()
        ,   ERROR_LINE()
        ,   ERROR_PROCEDURE()
        ,   ERROR_MESSAGE()
        ,   GETDATE()
        )

    END CATCH

    Fin:
    SELECT @outResultCode AS resultCode

END
GO

/*
    Login
    Recibe:
    @inUsername - nombre de usuario
    @inPassword - contrasena del usuario
    @inIP       - IP desde donde se intenta el login
    Retorna: @outResultCode: 0 si exitoso, >50000 si hubo error
             idUsuario y username si el login fue exitoso
    Valida:  que el username exista y que el password sea correcto
*/
CREATE PROCEDURE dbo.Login
    @inUsername VARCHAR(100)
,   @inPassword VARCHAR(100)
,   @inIP       VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @outResultCode  INT          = 0
    DECLARE @idUsuario      INT          = 0
    DECLARE @usernameOut    VARCHAR(100) = ''
    DECLARE @ahora           DATETIME      = GETDATE()

    BEGIN TRY

        /* Logica de bloqueo por intentos fallidos - Evento 3*/
        DECLARE @intentosFallidos INT = 0

        SELECT @intentosFallidos = COUNT(*)
        FROM dbo.BitacoraEvento AS B
        WHERE (B.IdUsuario = (SELECT id FROM dbo.Usuario AS U WHERE (U.Username = @inUsername)))
            AND (B.idTipoEvento = 2)
            AND (B.PostTime >= DATEADD(MINUTE, -20, GETDATE()))

        IF (@intentosFallidos >= 5)
        BEGIN
            SET @outResultCode = 50003

            EXEC dbo.RegistrarBitacora
                @inIdTipoEvento = 3
            ,   @inDescripcion  = ''
            ,   @inIdUsuario    = 0
            ,   @inIpPostIn     = @inIP
            ,   @inPostTime     = @ahora

            GOTO Fin
        END

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Usuario AS U
            WHERE (U.Username = @inUsername)
        )
        BEGIN
            SET @outResultCode = 50001

            /* Login no exitoso: Evento 2 - username no existe*/
            EXEC dbo.RegistrarBitacora
                @inIdTipoEvento = 2
            ,   @inDescripcion  = 'Username no existe'
            ,   @inIdUsuario    = 0
            ,   @inIpPostIn     = @inIP
            ,   @inPostTime     = @ahora

            GOTO Fin
        END

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Usuario AS U
            WHERE (U.Username = @inUsername)
                AND (U.Password = @inPassword)
        )
        BEGIN
            SET @outResultCode = 50002

            /* Login no exitoso: Evento 2 - password incorrecto*/
            EXEC dbo.RegistrarBitacora
                @inIdTipoEvento = 2
            ,   @inDescripcion  = 'Password incorrecto'
            ,   @inIdUsuario    = 0
            ,   @inIpPostIn     = @inIP
            ,   @inPostTime     = @ahora

            GOTO Fin
        END

        SELECT
            @idUsuario   = U.id
        ,   @usernameOut = U.Username
        FROM dbo.Usuario AS U
        WHERE (U.Username = @inUsername)
            AND (U.Password = @inPassword)

        --Login Exitoso: Evento 1
        EXEC dbo.RegistrarBitacora
            @inIdTipoEvento = 1
        ,   @inDescripcion  = 'Exitoso'
        ,   @inIdUsuario    = @idUsuario
        ,   @inIpPostIn     = @inIP
        ,   @inPostTime     = @ahora

    END TRY
    BEGIN CATCH

        SET @outResultCode = 50008

        INSERT INTO dbo.DBError
        (
            UserName
        ,   Number
        ,   [State]
        ,   Severity
        ,   Line
        ,   [Procedure]
        ,   [Message]
        ,   [DateTime]
        )
        VALUES
        (
            SUSER_NAME()
        ,   ERROR_NUMBER()
        ,   ERROR_STATE()
        ,   ERROR_SEVERITY()
        ,   ERROR_LINE()
        ,   ERROR_PROCEDURE()
        ,   ERROR_MESSAGE()
        ,   GETDATE()
        )

    END CATCH

    Fin:
    SELECT
        @outResultCode AS resultCode
    ,   @idUsuario     AS idUsuario
    ,   @usernameOut   AS username

END
GO


/*
    ListarMovimientos
    Recibe:
    @inIdEmpleado - id del empleado a consultar
    @inIdUsuario  - id del usuario en sesion
    @inIP  - IP desde donde se hace la consulta
    Retorna: Datos del empleado y lista de sus movimientos
             ordenados por fecha descendente
*/
CREATE PROCEDURE dbo.ListarMovimientos
    @inIdEmpleado   INT
,   @inIdUsuario    INT         = 0
,   @inIP           VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @outResultCode INT = 0

    BEGIN TRY

        SELECT
            E.ValorDocumentoIdentidad
        ,   E.Nombre
        ,   E.SaldoVacaciones
        FROM dbo.Empleado AS E
        WHERE (E.id = @inIdEmpleado)
            AND (E.EsActivo = 1)

        SELECT
            M.Fecha
        ,   TM.Nombre  AS NombreTipoMovimiento
        ,   M.Monto
        ,   M.NuevoSaldo
        ,   U.Username AS NombreUsuario
        ,   M.IpPostIn
        ,   M.PostTime
        FROM dbo.Movimiento AS M
        INNER JOIN dbo.TipoMovimiento AS TM ON (M.idTipoMovimiento = TM.id)
        INNER JOIN dbo.Usuario AS U ON (M.idUsuario = U.id)
        WHERE (M.idEmpleado = @inIdEmpleado)
        ORDER BY M.Fecha DESC

        /* Listar movimientos no tiene tipo de evento definido en R7
           No se registra en bitacora */

    END TRY
    BEGIN CATCH

        SET @outResultCode = 50008

        INSERT INTO dbo.DBError
        (
            UserName
        ,   Number
        ,   [State]
        ,   Severity
        ,   Line
        ,   [Procedure]
        ,   [Message]
        ,   [DateTime]
        )
        VALUES
        (
            SUSER_NAME()
        ,   ERROR_NUMBER()
        ,   ERROR_STATE()
        ,   ERROR_SEVERITY()
        ,   ERROR_LINE()
        ,   ERROR_PROCEDURE()
        ,   ERROR_MESSAGE()
        ,   GETDATE()
        )

    END CATCH

    SELECT @outResultCode AS resultCode

END
GO


/*
    Logout
    Recibe:
    @inIdUsuario - id del usuario que cierra sesion
    @inIP        - IP desde donde se hace el logout
    Retorna: @outResultCode: 0 si exitoso, >50000 si hubo error
*/
CREATE PROCEDURE dbo.Logout
    @inIdUsuario    INT
,   @inIP           VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @outResultCode INT = 0
    DECLARE @ahora DATETIME = GETDATE()

    BEGIN TRY

        /* Logout exitoso: Evento 4*/
        EXEC dbo.RegistrarBitacora
            @inIdTipoEvento = 4
        ,   @inDescripcion  = ''
        ,   @inIdUsuario    = @inIdUsuario
        ,   @inIpPostIn     = @inIP
        ,   @inPostTime     = @ahora

    END TRY
    BEGIN CATCH

        SET @outResultCode = 50008

        INSERT INTO dbo.DBError
        (
            UserName
        ,   Number
        ,   [State]
        ,   Severity
        ,   Line
        ,   [Procedure]
        ,   [Message]
        ,   [DateTime]
        )
        VALUES
        (
            SUSER_NAME()
        ,   ERROR_NUMBER()
        ,   ERROR_STATE()
        ,   ERROR_SEVERITY()
        ,   ERROR_LINE()
        ,   ERROR_PROCEDURE()
        ,   ERROR_MESSAGE()
        ,   GETDATE()
        )

    END CATCH

    SELECT @outResultCode AS resultCode

END
GO

/*
SP: ObtenerMensajeError
¿Qué hace?: Dado un código de error,
indica el mensaje de error asociado
en la tabla Error.
*/

CREATE PROCEDURE [dbo].[ObtenerMensajeError]
	--Parametro de entrada
	@inCodigo INT
AS
BEGIN
	SET NOCOUNT ON;

	--Variables
	DECLARE @outResultCode INT;
	DECLARE @Descripcion VARCHAR(500);

	--Asume error de base de datos por defecto
	SET @outResultCode = 50008;

	BEGIN TRY

		--Busca la descripcion del error
		SELECT @Descripcion = E.Descripcion
		FROM dbo.Error AS E
		WHERE (E.Codigo = @inCodigo);

		--Verifica si encontro el codigo
		IF (@Descripcion IS NOT NULL)
		BEGIN
			SET @outResultCode = 0;
		END

	END TRY

	BEGIN CATCH

		--Inserta error en DBError
		INSERT INTO dbo.DBError
		(
			UserName
			, Number
			, [State]
			, Severity
			, Line
			, [Procedure]
			, [Message]
			, [DateTime]
		)
		VALUES
		(
			--Devuelve el nombre de identificacion de inicio
			--de sesion del usuario.
			SUSER_NAME()
			, ERROR_NUMBER()
			, ERROR_STATE()
			, ERROR_SEVERITY()
			, ERROR_LINE()
			, ERROR_PROCEDURE()
			, ERROR_MESSAGE()
			, GETDATE()
		);

	END CATCH

	--Retorno final
	SELECT 
		@Descripcion AS Descripcion
		, @outResultCode AS resultado;

END;
GO

/*
SP: RegistrarBitacora
¿Qué hace?: Inserta en la tabla BitacoraEvento
la información de cada evento que se realiza 
en el sistema.
*/

CREATE PROCEDURE [dbo].[RegistrarBitacora]
	--Parametros de entrada
	@inIdTipoEvento INT
	, @inDescripcion VARCHAR(500)
	, @inIdUsuario INT
	, @inIpPostIn VARCHAR(50)
	, @inPostTime DATETIME
AS
BEGIN

	SET NOCOUNT ON;

	--Variable
	DECLARE @outResultCode INT;
	SET @outResultCode = 50008; -- Error de BD por defecto

	BEGIN TRY

		INSERT INTO dbo.BitacoraEvento
		(
			IdTipoEvento
			, Descripcion
			, IdUsuario
			, IpPostIn
			, PostTime
		)
		VALUES
		(
			@inIdTipoEvento
			, @inDescripcion
			, @inIdUsuario
			, @inIpPostIn
			, @inPostTime
		);

		SET @outResultCode = 0;

	END TRY

	BEGIN CATCH

		--Registra error en DBError
		INSERT INTO dbo.DBError
			( UserName
			, Number
			, [State]
			, Severity
			, Line
			, [Procedure]
			, [Message]
			, [DateTime]
			)
		VALUES
			( SUSER_SNAME()
			, ERROR_NUMBER()
			, ERROR_STATE()
			, ERROR_SEVERITY()
			, ERROR_LINE()
			, ERROR_PROCEDURE()
			, ERROR_MESSAGE()
			, GETDATE()
			);

	END CATCH

	SELECT @outResultCode AS resultado;

END;
GO

/*
SP: ConsultarEmpleado
¿Qué hace?: permite consultar el valor de documento
de identidad, nombre, nombre del puesto y SaldoVacaciones
de un empleado
*/

CREATE PROCEDURE [dbo].[ConsultarEmpleado]
	--Parametros de entrada
	@inIdEmpleado INT
	, @inIdUsuario INT
	, @inIpPostIn VARCHAR(50)
	, @inPostTime DATETIME

	--Parametro de salida
	, @outResultCode INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	--Variables
	DECLARE @DescripcionBitacora VARCHAR(500);
	DECLARE @Nombre VARCHAR(100);
	DECLARE @ValorDocIdentidad VARCHAR(50);
	DECLARE @NombrePuesto VARCHAR(50);
	DECLARE @SaldoVacaciones DECIMAL(10,2);

	--Valor por defecto de error de BD
	SET @outResultCode = 50008;

	BEGIN TRY

		--Obtiene los datos
		SELECT
			@Nombre = E.Nombre
			, @ValorDocIdentidad = E.ValorDocumentoIdentidad
			, @SaldoVacaciones = E.SaldoVacaciones
			, @NombrePuesto = P.Nombre
		FROM dbo.Empleado AS E
		INNER JOIN dbo.Puesto AS P
			ON (E.IdPuesto = P.Id)
		WHERE (E.Id = @inIdEmpleado)
			AND (E.EsActivo = 1);

		--Valida que el empleado esta activo
		IF (@Nombre IS NULL)
		BEGIN
			SET @outResultCode = 50008;

			SET @DescripcionBitacora =
				'Consulta empleado fallida - IdEmpleado: '
				+ CAST(@inIdEmpleado AS VARCHAR(20))
				+ ', CodigoError: ' + CAST(@outResultCode AS VARCHAR(10));

			EXEC dbo.RegistrarBitacora
				@inIdTipoEvento = 11
				, @inDescripcion = @DescripcionBitacora
				, @inIdUsuario = @inIdUsuario
				, @inIpPostIn = @inIpPostIn
				, @inPostTime = @inPostTime;
		END
		ELSE
		BEGIN
			--Consulta exitosa
			SELECT
				@ValorDocIdentidad AS ValorDocumentoIdentidad
				, @Nombre AS Nombre
				, @NombrePuesto AS NombrePuesto
				, @SaldoVacaciones AS SaldoVacaciones;

			SET @outResultCode = 0;

			--Bitacora de consulta realizada con exito
			SET @DescripcionBitacora =
				'Consulta empleado - Documento: ' + ISNULL(@ValorDocIdentidad, '')
				+ ', Nombre: ' + ISNULL(@Nombre, '')
				+ ', Puesto: ' + ISNULL(@NombrePuesto, '')
				+ ', SaldoVacaciones: ' 
				+ ISNULL(CAST(@SaldoVacaciones AS VARCHAR(20)), '');

			EXEC dbo.RegistrarBitacora
				@inIdTipoEvento = 11
				, @inDescripcion = @DescripcionBitacora
				, @inIdUsuario = @inIdUsuario
				, @inIpPostIn = @inIpPostIn
				, @inPostTime = @inPostTime;
		END

	END TRY

	BEGIN CATCH

		SET @outResultCode = 50008;

		--Registra error en DBError
		INSERT INTO dbo.DBError
		(
			UserName
			, Number
			, [State]
			, Severity
			, Line
			, [Procedure]
			, [Message]
			, [DateTime]
		)
		VALUES
		(
			SUSER_SNAME()
			, ERROR_NUMBER()
			, ERROR_STATE()
			, ERROR_SEVERITY()
			, ERROR_LINE()
			, ERROR_PROCEDURE()
			, ERROR_MESSAGE()
			, GETDATE()
		);

		--Bitacora error tecnico
		EXEC dbo.RegistrarBitacora
			@inIdTipoEvento = 11
			, @inDescripcion = 'Error inesperado en la base de datos al consultar empleado'
			, @inIdUsuario = @inIdUsuario
			, @inIpPostIn = @inIpPostIn
			, @inPostTime = @inPostTime;

	END CATCH

	--Retorno para Python
	SELECT @outResultCode AS resultado;

END;
GO

/*
SP: EliminarEmpleado
¿Qué hace?: Realiza el borrado lógico de un
empleado (EsActivo = 0).
*/

CREATE PROCEDURE [dbo].[EliminarEmpleado]
	--Parametros de entrada
	@inIdEmpleado INT
	, @inIdUsuario INT
	, @inIpPostIn VARCHAR(50)
	, @inPostTime DATETIME

	--Parametro de salida
	, @outResultCode INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	--Variables
	DECLARE @DescripcionBitacora VARCHAR(500);
	DECLARE @Nombre VARCHAR(100);
	DECLARE @ValorDocIdentidad VARCHAR(50);
	DECLARE @NombrePuesto VARCHAR(50);
	DECLARE @SaldoVacaciones DECIMAL(10,2);

	--Valor por defecto de error de BD
	SET @outResultCode = 50008;

	BEGIN TRY

		--Obtiene datos
		SELECT
			@Nombre = E.Nombre
			, @ValorDocIdentidad = E.ValorDocumentoIdentidad
			, @SaldoVacaciones = E.SaldoVacaciones
			, @NombrePuesto = P.Nombre
		FROM dbo.Empleado AS E
		INNER JOIN dbo.Puesto AS P
			ON (E.IdPuesto = P.Id)
		WHERE (E.Id = @inIdEmpleado)
			AND (E.EsActivo = 1);

		--No existe o ya inactivo
		IF (@Nombre IS NULL)
		BEGIN
			SET @outResultCode = 50008;

			SET @DescripcionBitacora =
				'Borrado empleado fallido - IdEmpleado: '
				+ CAST(@inIdEmpleado AS VARCHAR(20))
				+ ', CodigoError: ' + CAST(@outResultCode AS VARCHAR(10));

			EXEC dbo.RegistrarBitacora
				@inIdTipoEvento = 9 --Se intento 
				, @inDescripcion = @DescripcionBitacora
				, @inIdUsuario = @inIdUsuario
				, @inIpPostIn = @inIpPostIn
				, @inPostTime = @inPostTime;
		END
		ELSE
		BEGIN
			BEGIN TRANSACTION;

				UPDATE dbo.Empleado
				SET EsActivo = 0
				WHERE (Id = @inIdEmpleado);

			COMMIT TRANSACTION;

			SET @outResultCode = 0;

			--Bitacora exito
			SET @DescripcionBitacora =
				'Borrado empleado - Documento: ' + ISNULL(@ValorDocIdentidad, '')
				+ ', Nombre: ' + ISNULL(@Nombre, '')
				+ ', Puesto: ' + ISNULL(@NombrePuesto, '')
				+ ', SaldoVacaciones: '
				+ ISNULL(CAST(@SaldoVacaciones AS VARCHAR(20)), '');

			EXEC dbo.RegistrarBitacora
				@inIdTipoEvento = 10
				, @inDescripcion = @DescripcionBitacora
				, @inIdUsuario = @inIdUsuario
				, @inIpPostIn = @inIpPostIn
				, @inPostTime = @inPostTime;
		END

	END TRY

	BEGIN CATCH

		IF (XACT_STATE() <> 0)
		BEGIN
			ROLLBACK TRANSACTION;
		END

		SET @outResultCode = 50008;

		INSERT INTO dbo.DBError
		(
			UserName
			, Number
			, [State]
			, Severity
			, Line
			, [Procedure]
			, [Message]
			, [DateTime]
		)
		VALUES
		(
			SUSER_SNAME()
			, ERROR_NUMBER()
			, ERROR_STATE()
			, ERROR_SEVERITY()
			, ERROR_LINE()
			, ERROR_PROCEDURE()
			, ERROR_MESSAGE()
			, GETDATE()
		);

		EXEC dbo.RegistrarBitacora
			@inIdTipoEvento = 11
			, @inDescripcion = 'Error inesperado en borrado de empleado'
			, @inIdUsuario = @inIdUsuario
			, @inIpPostIn = @inIpPostIn
			, @inPostTime = @inPostTime;

	END CATCH

	SELECT @outResultCode AS resultado;

END;
GO

/*
SP: RegistrarIntentoEliminarEmpleado
¿Qué hace?: Registra en bitácora el intento
de borrado de un empleado.
*/

CREATE PROCEDURE [dbo].[RegistrarIntentoEliminarEmpleado]
	--Parametros de entrada
	@inIdEmpleado INT
	, @inIdUsuario INT
	, @inIpPostIn VARCHAR(50)
	, @inPostTime DATETIME

	--Parametro de salida
	, @outResultCode INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DescripcionBitacora VARCHAR(500);
	DECLARE @Nombre VARCHAR(100);
	DECLARE @ValorDocIdentidad VARCHAR(50);
	DECLARE @NombrePuesto VARCHAR(50);
	DECLARE @SaldoVacaciones DECIMAL(10,2);

	SET @outResultCode = 50008;

	BEGIN TRY

		SELECT
			@Nombre = E.Nombre
			, @ValorDocIdentidad = E.ValorDocumentoIdentidad
			, @SaldoVacaciones = E.SaldoVacaciones
			, @NombrePuesto = P.Nombre
		FROM dbo.Empleado AS E
		INNER JOIN dbo.Puesto AS P
			ON (E.IdPuesto = P.Id)
		WHERE (E.Id = @inIdEmpleado)
			AND (E.EsActivo = 1);

		IF (@Nombre IS NOT NULL)
		BEGIN
			SET @DescripcionBitacora =
				'Intento de borrado - Documento: ' + ISNULL(@ValorDocIdentidad, '')
				+ ', Nombre: ' + ISNULL(@Nombre, '')
				+ ', Puesto: ' + ISNULL(@NombrePuesto, '')
				+ ', SaldoVacaciones: '
				+ ISNULL(CAST(@SaldoVacaciones AS VARCHAR(20)), '');

			EXEC dbo.RegistrarBitacora
				@inIdTipoEvento = 9
				, @inDescripcion = @DescripcionBitacora
				, @inIdUsuario = @inIdUsuario
				, @inIpPostIn = @inIpPostIn
				, @inPostTime = @inPostTime;

			SET @outResultCode = 0;
		END

	END TRY

	BEGIN CATCH

		SET @outResultCode = 50008;

		INSERT INTO dbo.DBError
		(
			UserName
			, Number
			, [State]
			, Severity
			, Line
			, [Procedure]
			, [Message]
			, [DateTime]
		)
		VALUES
		(
			SUSER_SNAME()
			, ERROR_NUMBER()
			, ERROR_STATE()
			, ERROR_SEVERITY()
			, ERROR_LINE()
			, ERROR_PROCEDURE()
			, ERROR_MESSAGE()
			, GETDATE()
		);

	END CATCH

	SELECT @outResultCode AS resultado;

END;
GO

/*
SP: ActualizarEmpleado
¿Qué hace?: Permite editar el ValorDocumentoIdentidad,
Nombre e IdPuesto de un empleado existente. Valida que
no exista otro empleado con el mismo documento de
identidad o el mismo nombre. 
*/

CREATE PROCEDURE [dbo].[ActualizarEmpleado]
	--Parametros de entrada
	@inIdEmpleado INT
	, @inNuevoValorDocIdentidad VARCHAR(50)
	, @inNuevoNombre VARCHAR(100)
	, @inNuevoIdPuesto INT
	, @inIdUsuario INT
	, @inIpPostIn VARCHAR(50)
	, @inPostTime DATETIME

	--Parametro de salida
	, @outResultCode INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	--Variable de control
	DECLARE @DescripcionBitacora VARCHAR(500);

	--Datos anteriores
	DECLARE @NombreAntes VARCHAR(100);
	DECLARE @DocIdentAntes VARCHAR(50);
	DECLARE @NombrePuestoAntes VARCHAR(50);
	DECLARE @SaldoVacaciones DECIMAL(10,2);

	--Nuevo puesto
	DECLARE @NombreNuevoPuesto VARCHAR(50);

	--Valor por defecto de error de BD
	SET @outResultCode = 50008;

	BEGIN TRY

		--Obtiene datos actuales para la bitacora
		SELECT
			@NombreAntes = E.Nombre
			, @DocIdentAntes = E.ValorDocumentoIdentidad
			, @SaldoVacaciones = E.SaldoVacaciones
			, @NombrePuestoAntes = P.Nombre
		FROM dbo.Empleado AS E
		INNER JOIN dbo.Puesto AS P
			ON (E.IdPuesto = P.Id)
		WHERE (E.Id = @inIdEmpleado)
			AND (E.EsActivo = 1);

		SELECT @NombreNuevoPuesto = P.Nombre
		FROM dbo.Puesto AS P
		WHERE (P.Id = @inNuevoIdPuesto);

		--Validacion de documento duplicado
		IF EXISTS
		(
			SELECT 1
			FROM dbo.Empleado AS E
			WHERE (E.ValorDocumentoIdentidad = @inNuevoValorDocIdentidad)
				AND (E.Id <> @inIdEmpleado)
				AND (E.EsActivo = 1)
		)
		BEGIN
			SET @outResultCode = 50006;
		END

		--Validacion de nombre duplicado
		ELSE IF EXISTS
		(
			SELECT 1
			FROM dbo.Empleado AS E
			WHERE (E.Nombre = @inNuevoNombre)
				AND (E.Id <> @inIdEmpleado)
				AND (E.EsActivo = 1)
		)
		BEGIN
			SET @outResultCode = 50007;
		END

		ELSE
		BEGIN
			--Tansaccion de actualizacion de empleado
			BEGIN TRANSACTION;

				UPDATE dbo.Empleado
				SET
					ValorDocumentoIdentidad = @inNuevoValorDocIdentidad
					, Nombre = @inNuevoNombre
					, IdPuesto = @inNuevoIdPuesto
				WHERE (Id = @inIdEmpleado);

			COMMIT TRANSACTION;

			SET @outResultCode = 0;
		END

		--Bitacora de actualizacion
		SET @DescripcionBitacora =
			'Documento identidad anterior: ' + ISNULL(@DocIdentAntes, '')
			+ ', Nombre anterior: ' + ISNULL(@NombreAntes, '')
			+ ', Puesto anterior: ' + ISNULL(@NombrePuestoAntes, '')
			+ ', Documento identidad nuevo: ' + ISNULL(@inNuevoValorDocIdentidad, '')
			+ ', Nombre nuevo: ' + ISNULL(@inNuevoNombre, '')
			+ ', Puesto nuevo: ' + ISNULL(@NombreNuevoPuesto, '')
			+ ', SaldoVacaciones: ' + ISNULL(CAST(@SaldoVacaciones AS VARCHAR(20)), '');

		IF (@outResultCode = 0)
		BEGIN
			EXEC dbo.RegistrarBitacora
				@inIdTipoEvento = 8
				, @inDescripcion = @DescripcionBitacora
				, @inIdUsuario = @inIdUsuario
				, @inIpPostIn = @inIpPostIn
				, @inPostTime = @inPostTime;
		END
		ELSE
		BEGIN
			SET @DescripcionBitacora = ISNULL(@DescripcionBitacora, '')
				+ ', CodigoError: ' + CAST(@outResultCode AS VARCHAR(10))
			EXEC dbo.RegistrarBitacora
				@inIdTipoEvento = 7
				, @inDescripcion = @DescripcionBitacora
				, @inIdUsuario = @inIdUsuario
				, @inIpPostIn = @inIpPostIn
				, @inPostTime = @inPostTime;
		END

	END TRY

	BEGIN CATCH

		IF (XACT_STATE() <> 0)
		BEGIN
			ROLLBACK TRANSACTION;
		END

		SET @outResultCode = 50008;

		--Registra error en DBError
		INSERT INTO dbo.DBError
		(
			UserName
			, Number
			, [State]
			, Severity
			, Line
			, [Procedure]
			, [Message]
			, [DateTime]
		)
		VALUES
		(
			SUSER_SNAME()
			, ERROR_NUMBER()
			, ERROR_STATE()
			, ERROR_SEVERITY()
			, ERROR_LINE()
			, ERROR_PROCEDURE()
			, ERROR_MESSAGE()
			, GETDATE()
		);

		--Bitacora de error inesperado
		EXEC dbo.RegistrarBitacora
			@inIdTipoEvento = 7
			, @inDescripcion = 'Error inesperado en actualización de empleado'
			, @inIdUsuario = @inIdUsuario
			, @inIpPostIn = @inIpPostIn
			, @inPostTime = @inPostTime;

	END CATCH

	--Retorno
	SELECT @outResultCode AS resultado;

END;
GO
