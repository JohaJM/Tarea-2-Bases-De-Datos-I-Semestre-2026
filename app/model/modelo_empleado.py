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

"""
Funcion que tenia antes, la quite porque parece
que me da error al insertar un nuevo empleado, pero la deje comentada por si se quiere revisar el error despues.
def insertar_empleado(nombre, cedula, id_puesto, id_usuario, ip):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Llamar al SP de insercion con los datos del formulario
        cursor.execute(
            "EXEC dbo.InsertarEmpleado @inNombre=?, @inValorDocumentoIdentidad=?, @inIdPuesto=?, @inIdUsuario=?, @inIP=?",
            nombre, cedula, id_puesto, id_usuario, ip
        )

        # Leer resultsets hasta encontrar el del SP (puede haber uno de bitacora primero)
        resultado = cursor.fetchone()

        while (resultado is not None and len(resultado) == 1 and resultado[0] == 0):
            cursor.nextset()
            resultado = cursor.fetchone()

        if (resultado is not None):
            result_code = resultado[0]
        else:
            result_code = 0

        conn.commit()
    except pyodbc.Error:
        result_code = 50008

    finally:
        conn.close()

    return result_code"""
    
    
def insertar_empleado(nombre, cedula, id_puesto, id_usuario, ip):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            "EXEC dbo.InsertarEmpleado @inNombre=?, @inValorDocumentoIdentidad=?, @inIdPuesto=?, @inIdUsuario=?, @inIP=?",
            nombre, cedula, id_puesto, id_usuario, ip
        )

        result_code = 0
        while True:
            resultado = cursor.fetchone()
            if (resultado is not None):
                # Verificar si esta fila tiene la columna 'resultCode'
                columnas = [col[0] for col in cursor.description]
                if ('resultCode' in columnas):
                    result_code = resultado[0]
            if (not cursor.nextset()):
                break

        conn.commit()

    except pyodbc.Error as e:
        print(f"Error pyodbc: {e}")
        result_code = 50008

    finally:
        conn.close()

    return result_code

# Esta funcion se conecta con el SP sp_ObtenerMensajeError para traducir los codigos de error a mensajes.
def obtener_mensaje_error(codigo):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Llamar al SP con el codigo de error recibido
        cursor.execute(
            "EXEC dbo.ObtenerMensajeError @inCodigo=?",
            codigo
        )

        resultado   = cursor.fetchone()
        descripcion = resultado[0]
        result_code = resultado[1]

        # Si no encontro el codigo, mostrar el codigo directamente
        if (result_code != 0 or descripcion is None):
            descripcion = f'Error codigo: {codigo}'

    except pyodbc.Error:
        descripcion = f'Error codigo: {codigo}'

    finally:
        conn.close()

    return descripcion