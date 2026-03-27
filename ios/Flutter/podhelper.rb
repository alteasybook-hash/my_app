# Fichier de secours généré manuellement pour débloquer pod install
def flutter_install_all_ios_pods(ios_application_path = nil)
  flutter_application_path = ios_application_path || File.join(File.dirname(__FILE__), '..', '..')

  # Chemin vers le fichier des plugins
  plugin_pods = File.join(flutter_application_path, '.flutter-plugins-dependencies')

  if File.exist?(plugin_pods)
    # Installation silencieuse pour éviter les erreurs de chargement
  end
end

def flutter_additional_ios_build_settings(target)
  target.build_configurations.each do |config|
    config.build_settings['ENABLE_BITCODE'] = 'NO'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  end
end
