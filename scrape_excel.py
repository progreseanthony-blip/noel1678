import pandas as pd
import json

file_path = 'Estimación de Dias por servicio Unidad Pies cuadrado.xlsx'
try:
    # Try to load with openpyxl engine
    xl = pd.ExcelFile(file_path, engine='openpyxl')
    print(f"Sheets: {xl.sheet_names}")
    
    # Load 'Estimación tiempo' sheet
    df = xl.parse('Estimación tiempo')
    
    # Convert to JSON for easy reading
    json_data = df.to_json(orient='records')
    print("---DATA_START---")
    print(json_data)
    print("---DATA_END---")
except Exception as e:
    print(f"Error: {e}")
