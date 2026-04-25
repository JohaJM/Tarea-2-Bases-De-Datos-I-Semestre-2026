from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.model.modelo_empleado import (
    listar_empleados, listar_puestos,
    insertar_empleado, obtener_mensaje_error,
    consultar_empleado, actualizar_empleado)

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

@empleado_bp.route('/consultar_empleado', methods=['GET'])
def consultar_empleado_view():

    # Valida sesion
    if ('id_usuario' not in session):
        return redirect(url_for('auth.login_view'))

    id_usuario = session['id_usuario']
    ip = request.remote_addr

    # Obtiene id desde la URL
    id_empleado = request.args.get('id_empleado')

    if (not id_empleado):
        flash('No se seleccionó ningún empleado')
        return redirect(url_for('empleado.listar_empleados_view'))
    id_empleado = int(id_empleado) #cambio
    # Llama al modelo
    empleado, result_code = consultar_empleado(id_empleado, id_usuario, ip)

    if (result_code != 0):
        mensaje = obtener_mensaje_error(result_code)
        flash(mensaje)
        return redirect(url_for('empleado.listar_empleados_view'))

    return render_template(
        'consultar_empleado.html',
        empleado = empleado
    )

@empleado_bp.route('/editar_empleado', methods=['GET'])
def editar_empleado_view_get():

    # Valida sesion activa
    if ('id_usuario' not in session):
        return redirect(url_for('auth.login_view'))

    id_usuario = session['id_usuario']
    ip         = request.remote_addr

    # Obtiene id del empleado desde la URL (viene del boton Actualizar en index)
    id_empleado = request.args.get('id_empleado')

    if (not id_empleado):
        flash('No se seleccionó ningún empleado')
        return redirect(url_for('empleado.listar_empleados_view'))

    id_empleado = int(id_empleado)

    # Consulta los datos actuales del empleado para prellenar el formulario
    empleado, result_code = consultar_empleado(id_empleado, id_usuario, ip)

    if (result_code != 0):
        mensaje = obtener_mensaje_error(result_code)
        flash(mensaje)
        return redirect(url_for('empleado.listar_empleados_view'))

    # Carga puestos para el dropdown
    puestos, _ = listar_puestos()

    return render_template(
        'editar_empleado.html',
        empleado    = empleado,
        puestos     = puestos,
        id_empleado = id_empleado
    )

@empleado_bp.route('/editar_empleado', methods=['POST'])
def editar_empleado_view_post():

    # Valida sesion activa
    if ('id_usuario' not in session):
        return redirect(url_for('auth.login_view'))

    id_usuario = session['id_usuario']
    ip = request.remote_addr

    # Obtiene datos del formulario
    id_empleado         = request.form.get('id_empleado')
    nuevo_doc_identidad = request.form.get('cedula', '').strip()
    nuevo_nombre        = request.form.get('nombre', '').strip()
    nuevo_id_puesto     = request.form.get('id_puesto')

    if (not id_empleado):
        flash('No se seleccionó ningún empleado')
        return redirect(url_for('empleado.listar_empleados_view'))

    id_empleado = int(id_empleado)

    # Validaciones en capa logica (R3/R4)
    if (not nuevo_nombre.replace(' ', '').isalpha()):
        mensaje = obtener_mensaje_error(50009)
        flash(mensaje)
        return redirect(url_for(
            'empleado.editar_empleado_view_get',
            id_empleado = id_empleado
        ))

    if (not nuevo_doc_identidad.replace(' ', '').isalnum()):
        mensaje = obtener_mensaje_error(50010)
        flash(mensaje)
        return redirect(url_for(
            'empleado.editar_empleado_view_get',
            id_empleado = id_empleado
        ))

    # Llama al modelo para ejecutar el SP
    result_code = actualizar_empleado(
        id_empleado,
        nuevo_doc_identidad,
        nuevo_nombre,
        nuevo_id_puesto,
        id_usuario,
        ip
    )

    if (result_code == 0):
        flash('Empleado actualizado correctamente')
        return redirect(url_for('empleado.listar_empleados_view'))
    else:
        mensaje = obtener_mensaje_error(result_code)
        flash(mensaje)
        return redirect(url_for(
            'empleado.editar_empleado_view_get',
            id_empleado = id_empleado
        ))

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