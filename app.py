from flask import Flask
from app.controllers.controlador_auth import auth_bp
from app.controllers.controlador_empleado import empleado_bp

app = Flask(__name__, template_folder='app/templates')

# Clave secreta necesaria para manejar sesiones en Flask
app.secret_key = 'tarea2_bd1_2026'

# Registro de Blueprints
app.register_blueprint(auth_bp)
app.register_blueprint(empleado_bp)


if __name__ == '__main__':
    app.run(debug=True)