import pyodbc
from app.db import get_db_connection

# Leer el archivo XML como string
with open('database/datosCarga.xml', 'r', encoding='utf-8') as f:
    xml_content = f.read()

# Eliminar todo lo que haya antes de <Datos> incluyendo la declaracion XML
inicio = xml_content.find('<Datos>')
xml_content = xml_content[inicio:]

print(f"Longitud del XML: {len(xml_content)}")
print(f"Primeros 50 caracteres: {xml_content[:50]}")

# Conectar a la BD y ejecutar el SP
conn = get_db_connection()
cursor = conn.cursor()

try:
    cursor.execute("EXEC dbo.CargarDatos @inXML=?", xml_content)
    resultado = cursor.fetchone()
    conn.commit()

    print(f"ResultCode: {resultado[0]}")

except pyodbc.Error as e:
    print(f"Error de BD: {e}")
    conn.rollback()

finally:
    cursor.close()
    conn.close()