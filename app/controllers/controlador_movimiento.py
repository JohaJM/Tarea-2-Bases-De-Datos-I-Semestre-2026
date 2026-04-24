from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.model.modelo_movimiento import listar_movimientos
from app.model.modelo_empleado import obtener_mensaje_error

movimiento_bp = Blueprint('movimiento', __name__)


@movimiento_bp.route('/movimientos', methods=['GET'])
def listar_movimientos_view():

    # Verificar que haya sesion activa
    if ('id_usuario' not in session):
        return redirect(url_for('auth.login_view'))

    # Obtener el id del empleado seleccionado desde la URL
    # llega por GET desde el boton Movimientos del index.html
    id_empleado = request.args.get('id_empleado')

    # Verificar que venga un id valido
    if (not id_empleado):
        flash('No se selecciono ningun empleado')
        return redirect(url_for('empleado.listar_empleados_view'))

    id_usuario = session['id_usuario']
    ip         = request.remote_addr

    # Llamar al model para obtener datos del empleado y sus movimientos
    empleado, movimientos, result_code = listar_movimientos(id_empleado, id_usuario, ip)

    if (result_code != 0):
        mensaje = obtener_mensaje_error(result_code)
        flash(mensaje)

    return render_template(
        'movimientos.html',
        empleado    = empleado,
        movimientos = movimientos,
        id_empleado = id_empleado #para pasarlo al boton de inserta movimiento OJO: creo que no afecta lo de mantener ids ocultas porque nunca se le muestra al usuario
    )