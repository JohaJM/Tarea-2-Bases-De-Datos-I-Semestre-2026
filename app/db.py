#Para la conexion con la base de datos SQL Server, 
# se utiliza la libreria pyodbc. 
# La funcion get_db_connection() establece la conexion utilizando 
# la cadena de conexion definida en config.py y devuelve el objeto de conexion.
import pyodbc
import config

def get_db_connection():
    conn = pyodbc.connect(config.CONNECTION_STRING)
    return conn