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