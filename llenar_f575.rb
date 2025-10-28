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

puts "📄 Procesando #{rows.size} filas del CSV..."
puts

# Procesar cada fila
FileUtils.mkdir_p(OUTPUT_DIR)

rows.each_with_index do |data, idx|
  doc = HexaPDF::Document.open(TEMPLATE)
  acro = doc.acro_form
  
  puts "📋 Fila #{idx + 1}:"
  
  data.each do |field_name, raw_value|
    value = raw_value.to_s
    
    # Normalizar campos especiales
    if field_name == 'MES'
      value = normalize_mes(value)
    elsif field_name == 'ANIO'
      value = normalize_anio(value)
    end
    
    # Limpiar /Yes de checkboxes
    value = value.sub(/^\//, '') if value.start_with?('/')
    
    field = acro.field_by_name(field_name)
    next unless field
    
    old_val = field.field_value
    
    if field.field_type == :Btn
      # Checkbox/botón
      field.field_value = truthy?(value) ? 'Yes' : 'Off'
      symbol = truthy?(value) ? '✓' : '✗'
      puts "   #{field_name}: #{symbol}"
    else
      # Texto
      field.field_value = value
      puts "   #{field_name}: '#{old_val}' -> '#{value}'"
    end
  end
  
  acro.create_appearances
  output_file = File.join(OUTPUT_DIR, "formulario_#{idx + 1}.pdf")
  doc.write(output_file, optimize: true)
  puts "   → #{output_file}"
  puts
end

puts "🎉 Completado: #{rows.size} formularios generados en #{OUTPUT_DIR}/"