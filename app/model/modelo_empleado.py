import pyodbc
from app.db import get_db_connection

def listar_empleados(filtro_nombre, filtro_cedula, id_usuario, ip):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Llamar al SP con los filtros opcionales
        cursor.execute(
            "EXEC dbo.ListarEmpleados @inFiltroNombre=?, @inFiltroCedula=?, @inIdUsuario=?, @inIP=?",
            filtro_nombre, filtro_cedula, id_usuario, ip
        )

        # Obtener la lista de empleados
        empleados = cursor.fetchall()

        # Saltar al siguiente resultset para leer el resultCode
        cursor.nextset()
        result_code = cursor.fetchone()[0]

    except pyodbc.Error:
        # Si falla la conexion o ejecucion, retornar lista vacia y error
        empleados   = []
        result_code = 50008

    finally:
        conn.close()

    return empleados, result_code


def listar_puestos():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Llamar al SP para obtener los puestos para el dropdown
        cursor.execute("EXEC dbo.ListarPuestos")

        puestos = cursor.fetchall()

        cursor.nextset()
        result_code = cursor.fetchone()[0]

    except pyodbc.Error:
        puestos     = []
        result_code = 50008

    finally:
        conn.close()

    return puestos, result_code

