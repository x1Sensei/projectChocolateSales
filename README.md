# 🍫 Sistema de Predicción de Ventas - SoftMedia

Este proyecto es un sistema completo Full Stack para predecir ventas de chocolates utilizando Machine Learning (Regresión Lineal).

## 📂 Estructura del Proyecto

- **backend/**: API REST en Flask + Modelo de IA (Scikit-Learn).
- **frontend/**: Aplicación Móvil desarrollada en Flutter.
- **docker-compose.yml**: Orquestación de la Base de Datos PostgreSQL.
- **database_schema.sql**: Script de referencia para la estructura de la BD.

## 🚀 Instrucciones de Instalación

### 1. Base de Datos (PostgreSQL)
El sistema utiliza Docker para levantar la base de datos automáticamente.
```bash
sudo docker compose up -d
```
*Esto levantará PostgreSQL en el puerto 5435.*

### 2. Backend (Python Flask)
Requisitos: Python 3.9+
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 backend_server.py
```

### 3. Frontend (Flutter)
Requisitos: Flutter SDK
```bash
cd frontend
flutter pub get
flutter run
```

## 🧠 Funcionamiento
1. La App envía un JSON con (Vendedor, País, Producto, Cajas).
2. El Backend procesa los datos con `LabelEncoders`.
3. El Modelo `LinearRegression` estima la venta.
4. Se guarda el histórico en PostgreSQL.
