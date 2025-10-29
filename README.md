# Rellenador de Formularios PDF F575

Script en Ruby para rellenar formularios PDF F575 usando datos de archivos CSV.

## 📋 Requisitos

- Ruby 2.7+
- Gem HexaPDF

```bash
gem install hexapdf
```

## 📁 Archivos

```
Mari/
├── template.pdf        # Plantilla del formulario F575
├── values.csv          # Datos en formato Field;Value;Field;Value
└── README.md          # Este archivo
```

## 🚀 Uso Rápido

### Script simple (copia y pega):

```ruby
#!/usr/bin/env ruby
require 'hexapdf'
require 'csv'
require 'fileutils'

# Configuración
TEMPLATE = 'template.pdf'
CSV_FILE = 'values.csv'
OUTPUT_DIR = 'formularios_generados'

def normalize_mes(v)
  digits = v.to_s.gsub(/\D/, '')
  digits.empty? ? v.to_s : digits.rjust(2, '0')
end

def normalize_anio(v)
  digits = v.to_s.gsub(/\D/, '')
  case digits.length
  when 2 then "20#{digits}"
  when 4 then digits
  else v.to_s
  end
end

def truthy?(v)
  s = v.to_s.strip.downcase
  !(s.empty? || %w[0 false no off].include?(s))
end

# Leer CSV con formato Field;Value;Field;Value
delim = File.read(CSV_FILE, 1000).count(';') > File.read(CSV_FILE, 1000).count(',') ? ';' : ','
rows = []

CSV.foreach(CSV_FILE, col_sep: delim, encoding: 'bom|utf-8').with_index do |row, i|
  next if i == 0  # Saltar header
  
  hash = {}
  (0...row.length).step(2) do |j|
    field = row[j].to_s.strip
    value = row[j+1].to_s.strip
    hash[field] = value unless field.empty?
  end
  rows << hash unless hash.empty?
end

# Procesar cada fila
FileUtils.mkdir_p(OUTPUT_DIR)

rows.each_with_index do |data, idx|
  doc = HexaPDF::Document.open(TEMPLATE)
  acro = doc.acro_form
  
  # Variables para el nombre del archivo
  mes_valor = nil
  anio_valor = nil
  
  data.each do |field_name, raw_value|
    value = raw_value.to_s
    
    # Normalizar campos especiales y capturar valores para el nombre
    if field_name == 'MES'
      value = normalize_mes(value)
      mes_valor = value
    elsif field_name == 'ANIO'
      value = normalize_anio(value)
      anio_valor = value
    end
    
    # Limpiar /Yes de checkboxes
    value = value.sub(/^\//, '') if value.start_with?('/')
    
    field = acro.field_by_name(field_name)
    next unless field
    
    old_val = field.field_value
    
    if field.field_type == :Btn
      # Checkbox/botón
      field.field_value = truthy?(value) ? 'Yes' : 'Off'
    else
      # Texto
      field.field_value = value
    end
    
    puts "#{field_name}: '#{old_val}' -> '#{field.field_value}'"
  end
  
  acro.create_appearances
  # Generar nombre de archivo con mes y año
  if mes_valor && anio_valor
    filename = "formulario_#{anio_valor}-#{mes_valor}_#{idx + 1}.pdf"
  else
    filename = "formulario_#{idx + 1}.pdf"
  end
  
  output_file = File.join(OUTPUT_DIR, filename)
  doc.write(output_file, optimize: true)
  puts "✅ Generado: #{filename}"
  puts
end

puts "🎉 Completado: #{rows.size} formularios generados en #{OUTPUT_DIR}/"
```

### Cómo usar:

1. **Guarda el script** como `llenar_f575.rb`
2. **Asegúrate** de tener `template.pdf` y `values.csv` en la misma carpeta
3. **Ejecuta**: `ruby llenar_f575.rb`

## 📄 Formato del CSV

```csv
Field;Value;Field;Value;Field;Value;Field;Value
MES;1;ANIO;2025;IC2;/Yes;IC2impo;70.28
MES;1;ANIO;2025;IRDA;/Yes;IRDAimpo;283.85
MES;10;ANIO;2024;IC2;/Yes;IC2impo;294.21
```

### Características:
- **Delimitador**: `;` (punto y coma)
- **Estructura**: `Field;Value;Field;Value;...`
- **MES**: Se rellena con ceros → `1` = `01`
- **ANIO**: Se expande → `25` = `2025`
- **Checkboxes**: `/Yes` se limpia a `Yes`

## 📤 Resultado

Los archivos se generan con nombres que incluyen año y mes para facilitar la organización:

```
formularios_generados/
├── formulario_2020-11_1.pdf
├── formulario_2020-12_2.pdf
├── formulario_2021-01_3.pdf
├── formulario_2024-10_4.pdf
├── formulario_2025-01_5.pdf
└── ...
```

**Formato del nombre:** `formulario_AAAA-MM_N.pdf`
- `AAAA-MM`: Año y mes del formulario
- `N`: Número secuencial

Los archivos se ordenan automáticamente de forma cronológica en el explorador de archivos.

## ⚠️ Solución de Problemas

### Error: "cannot load such file -- hexapdf"
```bash
gem install hexapdf
```

### Error: "No such file"
Verifica que existan:
```bash
ls template.pdf values.csv
```

### Campos no se rellenan
- Verifica nombres exactos de campos
- Algunos PDFs tienen restricciones especiales
- HexaPDF usa modificación directa de campos (no FDF)

## 🎯 Ejemplo Completo

1. Crear `llenar_f575.rb` con el script de arriba
2. Poner `template.pdf` y `values.csv` en la misma carpeta
3. Ejecutar: `ruby llenar_f575.rb`
4. Los PDFs aparecen en `formularios_generados/`

¡Listo! 🚀