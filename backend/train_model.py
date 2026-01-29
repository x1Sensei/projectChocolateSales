import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import LabelEncoder
import joblib

print("🍫 Iniciando entrenamiento del modelo de Chocolates...")

# 1. Cargar datos
try:
    df = pd.read_csv('Chocolate Sales.csv')
    print(f"   - Datos cargados: {len(df)} registros encontrados.")
except FileNotFoundError:
    print("❌ ERROR: No encuentro 'Chocolate Sales.csv' en la carpeta backend.")
    exit()

# 2. Limpieza de datos
# Quitamos el signo $ y las comas de la columna 'Amount' para volverla número
df['Amount'] = df['Amount'].astype(str).str.replace(r'[$,]', '', regex=True).astype(float)

# Eliminamos la columna 'Date' ya que prediciremos en base a características, no fechas
# Eliminamos filas vacías si las hay
df = df.drop(columns=['Date']).dropna()

# Definimos Features (X) y Target (y)
# X = Vendedor, País, Producto, Cajas
# y = Monto (Amount)
features = ['Sales Person', 'Country', 'Product', 'Boxes Shipped']
X = df[features].copy()
y = df['Amount']

# 3. Codificación de variables Categóricas (Texto -> Número)
print("   - Codificando variables de texto a números...")
encoders = {}
categorical_cols = ['Sales Person', 'Country', 'Product']

for col in categorical_cols:
    le = LabelEncoder()
    # Ajustamos el encoder con los datos y transformamos la columna
    X[col] = le.fit_transform(X[col])
    # Guardamos el encoder en el diccionario para usarlo luego en el servidor
    encoders[col] = le

# 4. Entrenamiento del Modelo
print("   - Entrenando Regresión Lineal...")
model = LinearRegression()
model.fit(X, y)

# 5. Guardar archivos .pkl
joblib.dump(model, 'modelo_final.pkl')
joblib.dump(encoders, 'codificadores.pkl')

print("✅ ÉXITO: 'modelo_final.pkl' y 'codificadores.pkl' generados correctamente.")
print(f"   - Coeficientes del modelo: {model.coef_}")