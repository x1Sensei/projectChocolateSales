-- Script de Creación de Base de Datos para Predicción de Ventas
-- Nota: Este script es ejecutado automáticamente por el ORM del backend, 
-- pero se adjunta para fines de documentación técnica.

-- 1. Tabla de Predicciones
CREATE TABLE IF NOT EXISTS predicciones (
    id SERIAL PRIMARY KEY,
    datos_entrada JSONB NOT NULL,  -- Almacena el JSON crudo enviado por Flutter
    venta_predicha FLOAT NOT NULL, -- El resultado de la IA
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ejemplo de Consulta para ver el historial:
-- SELECT * FROM predicciones ORDER BY fecha DESC LIMIT 10;
