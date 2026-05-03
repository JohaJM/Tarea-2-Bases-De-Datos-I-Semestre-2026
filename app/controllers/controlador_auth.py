
from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from app.model.modelo_auth import login, logout, verificar_bloqueo
from app.model.modelo_empleado import obtener_mensaje_error

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/', methods=['GET', 'POST'])
def login_view():

    if (request.method == 'POST'):
        # Obtener datos del formulario y la IP del cliente
        username = request.form['username']
        password = request.form['password']
        ip       = request.remote_addr
        
        #Validar que no vengan vacios
        if not username or not password:
            flash("Usuario y contraseña son requeridos")
            return redirect(url_for('auth.login_view'))

        # Llamar al model para ejecutar el SP
        result_code, id_usuario, username_out = login(username, password, ip)

        if (result_code == 0):
            # Login exitoso: guardar datos en sesion y redirigir
            session['id_usuario'] = id_usuario
            session['username']   = username_out or username  # Usar username del form si está vacío
            return redirect(url_for('empleado.listar_empleados_view'))
        else:
            # Login fallido: mostrar codigo de error al usuario
            mensaje = obtener_mensaje_error(result_code)
            flash(mensaje)  # Mostrar mensaje de error al usuario
            
            return redirect(url_for('auth.login_view') + f'?username={username}') #mando el username para que se mantenga en el form
    # IMPORTANTE: actualizaciones realizadas para la funcionalidad de deshabilitar un usuario
    # GET: verificar si el usuario esta bloqueado antes de mostrar el formulario
    username_previo = request.args.get('username', '')
    ip = request.remote_addr
    bloqueado= 0
    print(f"DEBUG: username={username_previo}, bloqueado={bloqueado}")

    if (username_previo):
        bloqueado = verificar_bloqueo(username_previo, ip)

    return render_template('login.html', bloqueado=bloqueado, username=username_previo)


@auth_bp.route('/logout')
def logout_view():
    # Obtener datos de sesion antes de limpiarla
    id_usuario = session.get('id_usuario', 0)
    ip         = request.remote_addr

    # Llamar al model para registrar el logout en bitacora
    logout(id_usuario, ip)

    # Limpiar la sesion y redirigir al login
    session.clear()
    return redirect(url_for('auth.login_view'))