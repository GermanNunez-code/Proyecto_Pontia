import pandas as pd
import numpy as np
import json

# Direccion de archivo
url = r'C:\Users\Joan\Desktop\Pontia\Jupyter\Detección de Fraude\es_fraude.json'

# leer el archivo json
with open(url, 'r') as archivo:
    data = json.load(archivo)

# convertir el archivo a dataframe y renombrar columnas
df = pd.DataFrame(list(data.items()), columns=['fraude_id', 'es_fraude'])

# informacion de datos
df.info()
print('\n')

print(df.shape)
print('\n')

# cantidad de False
cantidad_false = (df['es_fraude'] == False).sum()
print(f'La cantidad de casos sin fraude es de: {cantidad_false}')
print('\n')

# cantidad de False
cantidad_true = (df['es_fraude'] == True).sum()
print(f'La cantidad de casos con fraude es de: {cantidad_true}')
print('\n')

# promedio fraude (se calcula de la siguiente manera ya que python interpreta el True como 1 y el false como 0)
promedio_fraude = (df['es_fraude'].mean())
print(f'El promedio de casos de fraude es de: {promedio_fraude}')
print('\n')

# impresion de df
print(df)


# Con los datos obtenidos llegamos a la conclusion de que la cantidad de casos de fraude es poco significativa,
#   lo que nos hace ver que las medidas de seguridad están funcionando correctamente.



