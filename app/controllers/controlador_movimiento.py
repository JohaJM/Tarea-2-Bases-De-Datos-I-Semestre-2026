from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.model.modelo_movimiento import listar_movimientos, listar_tipos_movimiento, insertar_movimiento
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

@movimiento_bp.route('/insertar_movimiento', methods=['GET', 'POST'])
def insertar_movimiento_view():

    if ('id_usuario' not in session):
        return redirect(url_for('auth.login_view'))

    # El id del empleado pasa como parametro en GET y como campo oculto en POST
    id_empleado = request.args.get('id_empleado') or request.form.get('id_empleado')

    if (not id_empleado):
        flash('No se selecciono ningun empleado')
        return redirect(url_for('empleado.listar_empleados_view'))

    id_usuario = session['id_usuario']
    ip         = request.remote_addr

    if (request.method == 'POST'):
        id_tipo_movimiento = request.form.get('id_tipo_movimiento')
        monto_str          = request.form.get('monto', '').strip()

        # Validacion del monto en capa logica antes de llamar al SP
        try:
            monto = float(monto_str)
            if (monto <= 0):
                raise ValueError
        except ValueError:
            flash('El monto debe ser un numero mayor a cero')
            return redirect(
                url_for('movimiento.insertar_movimiento_view', id_empleado=id_empleado)
            )

        result_code = insertar_movimiento(
            id_empleado, id_tipo_movimiento, monto, id_usuario, ip
        )

        if (result_code == 0):
            flash('Movimiento insertado correctamente')
            return redirect(
                url_for('movimiento.listar_movimientos_view', id_empleado=id_empleado)
            )
        else:
            mensaje = obtener_mensaje_error(result_code)
            flash(mensaje)
            return redirect(
                url_for('movimiento.insertar_movimiento_view', id_empleado=id_empleado)
            )

    # GET: cargar datos del empleado y tipos de movimiento para el formulario
    empleado, _, result_code = listar_movimientos(id_empleado, id_usuario, ip)

    if (result_code != 0 or empleado is None):
        flash('No se pudo cargar la informacion del empleado')
        return redirect(url_for('empleado.listar_empleados_view'))

    tipos_movimiento, _ = listar_tipos_movimiento()

    return render_template(
        'insertar_movimiento.html',
        empleado         = empleado,
        tipos_movimiento = tipos_movimiento,
        id_empleado      = id_empleado
    )