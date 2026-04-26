import pyodbc
from app.db import get_db_connection
from datetime import datetime

def listar_movimientos(id_empleado, id_usuario, ip):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Llamar al SP con el id del empleado seleccionado
        cursor.execute(
            "EXEC dbo.ListarMovimientos @inIdEmpleado=?, @inIdUsuario=?, @inIP=?",
            id_empleado, id_usuario, ip
        )

        # Primer resultset: datos del empleado (una sola fila)
        empleado = cursor.fetchone()

        # Pasar al segundo resultset: lista de movimientos
        cursor.nextset()
        movimientos = cursor.fetchall()

        # Pasar al tercer resultset: codigo de resultado
        cursor.nextset()
        result_code = cursor.fetchone()[0]

    except pyodbc.Error:
        # Si falla la conexion o ejecucion, retornar valores vacios
        empleado    = None
        movimientos = []
        result_code = 50008

    finally:
        conn.close()

    return empleado, movimientos, result_code

# Funcion para listar los tipos de movimientos
def listar_tipos_movimiento():
    conn   = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("EXEC dbo.ListarTiposMovimiento")

        tipos = cursor.fetchall()

        cursor.nextset()
        result_code = cursor.fetchone()[0]

    except pyodbc.Error:
        tipos       = []
        result_code = 50008

    finally:
        conn.close()

    return tipos, result_code


def insertar_movimiento(
        id_empleado, id_tipo_movimiento,
        monto, id_usuario, ip
    ):
    conn   = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            """
            EXEC dbo.InsertarMovimiento
                @inIdEmpleado       = ?,
                @inIdTipoMovimiento = ?,
                @inMonto            = ?,
                @inIdUsuario        = ?,
                @inIpPostIn         = ?,
                @inPostTime         = ?
            """,
            id_empleado,
            id_tipo_movimiento,
            monto,
            id_usuario,
            ip,
            datetime.now()
        )

        # Lee todos los resultsets y se queda con el ultimo valor de 'resultado'
        result_code = 50008
        while True:
            row      = cursor.fetchone()
            columnas = [col[0] for col in cursor.description]
            if (row is not None and 'resultado' in columnas):
                result_code = row[0]   # sobreescribe hasta el ultimo
            if (not cursor.nextset()):
                break

        conn.commit()

    except pyodbc.Error as e:
        print(f"ERROR insertar_movimiento: {e}")
        result_code = 50008

    finally:
        conn.close()

    return result_code