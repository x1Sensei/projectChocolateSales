from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
import psycopg2
from psycopg2.extras import RealDictCursor
import json
import os

app = Flask(__name__)
CORS(app)  # Permite que Flutter se comunique con este servidor

print("🚀 Iniciando Servidor de Predicción de Chocolates...")

# --- CARGA DEL MODELO Y ENCODERS ---
try:
    # Cargamos el "cerebro" (modelo) y el "diccionario" (encoders)
    model = joblib.load('modelo_final.pkl')
    encoders = joblib.load('codificadores.pkl')
    print("✅ Modelo y Encoders cargados correctamente.")
except Exception as e:
    print(f"❌ Error cargando modelo: {e}")
    print("   Asegúrate de haber ejecutado 'train_model.py' primero.")
    exit()

# --- CONFIGURACIÓN DE BASE DE DATOS ---
DB_CONFIG = {
    "host": "localhost",
    "port": 5435,      # El puerto externo que definimos en Docker
    "user": "admin",
    "password": "admin",
    "database": "escuela_db"
}

def init_db():
    """Crea la tabla de predicciones si no existe"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS predicciones (
                id SERIAL PRIMARY KEY,
                datos_entrada JSONB,
                venta_predicha FLOAT,
                fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        cur.close()
        conn.close()
        print("✅ Base de Datos conectada y tabla verificada.")
    except Exception as e:
        print(f"❌ Error conectando a la BD: {e}")

# --- ENDPOINTS (RUTAS) ---

@app.route('/predict', methods=['POST'])
def predict():
    """
    Recibe un JSON con: sales_person, country, product, boxes
    Devuelve: { score: 1234.56 }
    """
    try:
        data = request.json
        print(f"📩 Recibiendo datos: {data}")

        # 1. Preparamos el DataFrame con los datos recibidos
        input_df = pd.DataFrame([{
            'Sales Person': data['sales_person'],
            'Country': data['country'],
            'Product': data['product'],
            'Boxes Shipped': float(data['boxes'])
        }])

        # 2. Convertimos texto a números usando los encoders guardados
        # Es vital usar transform, NO fit_transform (usamos lo aprendido en el entrenamiento)
        for col, le in encoders.items():
            # Manejo de error si llega una categoría nueva que no conocemos
            if input_df[col].iloc[0] not in le.classes_:
                # Asignamos la clase más común o un valor por defecto si es desconocido
                # Para simplificar, usaremos el primer valor conocido
                input_df[col] = le.transform([le.classes_[0]])
            else:
                input_df[col] = le.transform(input_df[col])

        # 3. Predicción
        prediction_amount = model.predict(input_df)[0]

        # 4. Guardar en Base de Datos
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO predicciones (datos_entrada, venta_predicha) VALUES (%s, %s)",
            (json.dumps(data), float(prediction_amount))
        )
        conn.commit()
        cur.close()
        conn.close()

        return jsonify({"score": round(prediction_amount, 2)})

    except Exception as e:
        print(f"🔥 Error en predicción: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/history', methods=['GET'])
def get_history():
    """Devuelve las últimas 10 predicciones"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT * FROM predicciones ORDER BY fecha DESC LIMIT 10")
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify(rows)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    init_db() # Inicializar tabla al arrancar
    # host='0.0.0.0' hace que el servidor sea visible en tu red local (necesario para el celular/emulador)
    app.run(host='0.0.0.0', port=5000, debug=True)