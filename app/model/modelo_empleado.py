import pyodbc
from app.db import get_db_connection
from datetime import datetime

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

# Esta funcion se conecta con el SP ObtenerMensajeError
# para traducir los codigos de error a mensajes.
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

# Esta funcion se conecta con el SP ConsultarEmpleado
# para obtener los datos de un empleado especifico.
def consultar_empleado(id_empleado, id_usuario, ip):
    # Abre la conexión a la base de datos
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Ejecuta el SP consultarEmpleado
        cursor.execute(
            """
            EXEC dbo.ConsultarEmpleado
                @inIdEmpleado=?,
                @inIdUsuario=?,
                @inIpPostIn=?,
                @inPostTime=?
            """,
            id_empleado,
            id_usuario,
            ip,
            datetime.now()
        )

        # Primer resultset devuelve los datos del empleado o None si no existe
        columna = cursor.fetchone()
        if columna:
            empleado = (
                columna[0],
                columna[1],
                columna[2],
                columna[3]
            )
        else:
            empleado = None

        # Pasa al siguiente resultset para obtener el código de resultado
        cursor.nextset()
        columna_codigo = cursor.fetchone()
        result_code = columna_codigo[0] if columna_codigo else 50008

    except pyodbc.Error as e:
        # Si algo falla con la BD, devuelve su respectivo codigo de error
        print(f"ERROR consultar_empleado: {e}")
        empleado = None
        result_code = 50008

    finally:
        # Cierra la conexión
        conn.close()

    return empleado, result_code

# Esta funcion se conecta con el SP ActualizarEmpleado
# para actualizar los datos de un empleado especifico.
def actualizar_empleado(
        id_empleado, nuevo_doc_identidad,
        nuevo_nombre, nuevo_id_puesto,
        id_usuario, ip
    ):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            """
            EXEC dbo.ActualizarEmpleado
                @inIdEmpleado               = ?,
                @inNuevoValorDocIdentidad   = ?,
                @inNuevoNombre              = ?,
                @inNuevoIdPuesto            = ?,
                @inIdUsuario                = ?,
                @inIpPostIn                 = ?,
                @inPostTime                 = ?
            """,
            id_empleado,
            nuevo_doc_identidad,
            nuevo_nombre,
            nuevo_id_puesto,
            id_usuario,
            ip,
            datetime.now()
        )

        # Lee el resultset con el codigo de resultado
        columna_resultado = cursor.fetchone()
        result_code = columna_resultado[0] if columna_resultado else 50008

        conn.commit()

    except pyodbc.Error as e:
        print(f"ERROR actualizar_empleado: {e}")
        result_code = 50008

    finally:
        conn.close()

    return result_code

# Estas funciones se conectan con los SP RegistrarIntentoEliminarEmpleado
# y EliminarEmpleado para registrar los instentos de eliminacion
# y borrado logico de un empleado.
def registrar_intento_eliminar(id_empleado, id_usuario, ip):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            """
            EXEC dbo.RegistrarIntentoEliminarEmpleado
                @inIdEmpleado  = ?,
                @inIdUsuario   = ?,
                @inIpPostIn    = ?,
                @inPostTime    = ?
            """,
            id_empleado,
            id_usuario,
            ip,
            datetime.now()
        )

        columna_resultado = cursor.fetchone()
        result_code = columna_resultado[0] if columna_resultado else 50008

    except pyodbc.Error as e:
        print(f"ERROR registrar_intento_eliminar: {e}")
        result_code = 50008

    finally:
        conn.close()

    return result_code


def eliminar_empleado(id_empleado, id_usuario, ip):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute(
            """
            EXEC dbo.EliminarEmpleado
                @inIdEmpleado  = ?,
                @inIdUsuario   = ?,
                @inIpPostIn    = ?,
                @inPostTime    = ?
            """,
            id_empleado,
            id_usuario,
            ip,
            datetime.now()
        )

        columna_resultado = cursor.fetchone()
        result_code = columna_resultado[0] if columna_resultado else 50008
        conn.commit()

    except pyodbc.Error as e:
        print(f"ERROR eliminar_empleado: {e}")
        result_code = 50008

    finally:
        conn.close()

    return result_code