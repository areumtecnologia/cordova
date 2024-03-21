#!/bin/bash

# Passo 1: Identificar o dispositivo booted
device_info=$(xcrun simctl list devices | grep "(Booted)" | head -n 1)
echo "INFO: $device_info"

# Verificar se um dispositivo foi encontrado
if [ -z "$device_info" ]; then
  echo "Nenhum dispositivo iOS iniciado encontrado. Por favor, inicie um simulador primeiro."
  exit 1
fi

# Extrair o nome do modelo do dispositivo (removendo espaços extras no final)
device_name=$(echo "$device_info" | awk -F '[(]' '{print $1}' | sed 's/ *$//g')
device_id=$(echo "$device_info" | awk -F '[(|)]' '{print $2}')
echo "Dispositivo encontrado: $device_name ($device_id)"

# Passo 2: Construir o projeto Cordova para o dispositivo específico
# Nota: Certifique-se de substituir "device_name" pelo formato correto esperado pelo Cordova se necessário
sudo cordova build ios --target="$device_name"

if [ $? -ne 0 ]; then
  echo "Erro ao construir o projeto Cordova para iOS."
  exit 1
fi

# Determinar dinamicamente o caminho para o .app e o bundle identifier
app_path=$(find platforms/ios/build/Debug-iphonesimulator -name "*.app" | head -n 1)
if [ -z "$app_path" ]; then
  echo "Não foi possível encontrar o arquivo .app. Verifique se o build foi bem-sucedido e tente novamente."
  exit 1
fi

# Extrair o bundle identifier diretamente do arquivo .app
# Requer PlistBuddy, uma ferramenta para manipular arquivos .plist
bundle_identifier=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app_path/Info.plist")
if [ -z "$bundle_identifier" ]; then
  echo "Não foi possível extrair o bundle identifier do arquivo .app."
  exit 1
fi

echo "Caminho do aplicativo: $app_path"
echo "Bundle Identifier: $bundle_identifier"

# Passo 3: Instalar o aplicativo no dispositivo
xcrun simctl install "$device_id" "$app_path"

# Passo 4: Executar o aplicativo
xcrun simctl launch "$device_id" "$bundle_identifier"
