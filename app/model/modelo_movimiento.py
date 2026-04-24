import pyodbc
from app.db import get_db_connection

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