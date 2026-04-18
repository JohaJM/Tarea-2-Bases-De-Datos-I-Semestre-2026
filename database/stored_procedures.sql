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

