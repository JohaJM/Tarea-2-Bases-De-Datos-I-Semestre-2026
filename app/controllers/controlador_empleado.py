from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.model.modelo_empleado import listar_empleados, listar_puestos, insertar_empleado, obtener_mensaje_error

empleado_bp = Blueprint('empleado', __name__)


@empleado_bp.route('/empleados', methods=['GET', 'POST'])
def listar_empleados_view():

    # Verificar que haya sesion activa
    if ('id_usuario' not in session):
        return redirect(url_for('auth.login_view'))

    id_usuario = session['id_usuario']
    ip         = request.remote_addr

    # Obtener el filtro del formulario si existe
    filtro      = request.args.get('filtro', '').strip()
    filtro_nombre  = None
    filtro_cedula  = None

    if (filtro):
        # Si el filtro es solo numeros, buscar por cedula
        # Si tiene letras, buscar por nombre
        if (filtro.isdigit()):
            filtro_cedula  = filtro
        else:
            filtro_nombre  = filtro

    # Llamar al model para obtener la lista de empleados
    empleados, result_code = listar_empleados(filtro_nombre, filtro_cedula, id_usuario, ip)

    if (result_code != 0):
        mensaje = obtener_mensaje_error(result_code)
        flash(mensaje)

    return render_template('index.html', empleados=empleados, filtro=filtro)


@empleado_bp.route('/insertar_empleado', methods=['GET', 'POST'])
def insertar_empleado_view():

    # Verificar que haya sesion activa
    if ('id_usuario' not in session):
        return redirect(url_for('auth.login_view'))

    id_usuario = session['id_usuario']
    ip         = request.remote_addr

    if (request.method == 'POST'):
        # Obtener datos del formulario
        nombre  = request.form['nombre'].strip()
        cedula  = request.form['cedula'].strip()
        id_puesto = request.form['id_puesto']
        
        #DEBUG TEMPORAL
        print(f"DEBUG: nombre={nombre}, cedula={cedula}, id_puesto={id_puesto}, id_usuario={session['id_usuario']}")

        # Llamar al model para insertar el empleado
        result_code = insertar_empleado(nombre, cedula, id_puesto, id_usuario, ip)

        if (result_code == 0):
            flash('Empleado insertado correctamente')
            return redirect(url_for('empleado.listar_empleados_view'))
        else:
            mensaje = obtener_mensaje_error(result_code)
            flash(mensaje)
            return redirect(url_for('empleado.insertar_empleado_view'))

    # GET: cargar puestos para el dropdown
    puestos, _ = listar_puestos()
    return render_template('insertar_empleado.html', puestos=puestos)

#PRUEBASS*/
@empleado_bp.route("/test")
def test():
    return render_template("index.html", empleados=[], filtro="")

@empleado_bp.route("/test_insertar")
def test_insertar():
    # Puestos de prueba hardcodeados para ver el diseno
    puestos_prueba = [
        (1, "Cajero"),
        (2, "Camarero"),
        (3, "Conductor"),
        (4, "Asistente")
    ]
    return render_template("insertar_empleado.html", puestos=puestos_prueba)