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


