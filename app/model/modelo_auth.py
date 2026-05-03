import pyodbc
from app.db import get_db_connection

def login(username, password, ip):
    # Conectar a la BD
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Llamar al SP de Login
        cursor.execute(
            "EXEC dbo.Login @inUsername=?, @inPassword=?, @inIP=?",
            username, password, ip
        )

                # La bitacora devuelve su propio resultset primero, hay que saltarlo
        resultado = cursor.fetchone()

        # Mientras sea un resultset de 1 columna, es de la bitacora, saltarlo
        #IMPORTANTE: esto es un fix temporal, revisar después
        while (resultado is not None and len(resultado) == 1):
            cursor.nextset()
            resultado = cursor.fetchone()

        # Ahora si tenemos el resultado del Login con 3 columnas
        result_code  = resultado[0]
        id_usuario   = resultado[1]
        username_out = resultado[2]
        
        conn.commit()

    except pyodbc.Error:
        # Si falla la conexion o la ejecucion, se retorna error de BD
        #Esperemos no pase
        result_code  = 50008
        id_usuario   = 0
        username_out = ''

    finally:
        conn.close()

    return result_code, id_usuario, username_out


def logout(id_usuario, ip):
    # Conectar a la BD
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Llamar al SP de Logout
        cursor.execute(
            "EXEC dbo.Logout @inIdUsuario=?, @inIP=?",
            id_usuario, ip
        )

        # El SP devuelve solo el resultCode
        resultado   = cursor.fetchone()
        result_code = resultado[0]
        conn.commit()
        


    except pyodbc.Error:
        # Si falla la conexion o la ejecucion, se retorna error de BD
        result_code = 50008

    finally:
        conn.close()

    return result_code

# Función para verificar si el usuario esta bloqueado

def verificar_bloqueo(username, ip):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Llamar al SP para verificar si el usuario esta bloqueado
        cursor.execute(
            "EXEC dbo.VerificarBloqueo @inUsername=?, @inIP=?",
            username, ip
        )

        resultado   = cursor.fetchone()
        bloqueado   = resultado[0]
        result_code = resultado[1]

        if (result_code != 0):
            bloqueado = 0

    except pyodbc.Error:
        bloqueado = 0

    finally:
        conn.close()

    return bloqueado