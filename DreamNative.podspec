Pod::Spec.new do |s|
  s.name = 'DreamNative'
  s.version = '0.4.2'
  s.summary = 'Local dream archive, audio conversion and Whisper CPU bridge.'
  s.homepage = 'https://github.com/SboMusic/diario-sogni'
  s.author = 'SboMusic'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.source = { :git => 'https://github.com/SboMusic/diario-sogni.git' }
  s.platform = :ios, '15.0'
  s.swift_version = '5.0'
  s.static_framework = true
  s.dependency 'Flutter'
  s.frameworks = 'AVFoundation', 'UIKit', 'UniformTypeIdentifiers'
  s.libraries = 'c++'
  s.resource_bundles = { 'DreamNative_Privacy' => ['ios/Native/PrivacyInfo.xcprivacy'] }
  
  # File sorgente inclusi nel target. Vengono evitati i glob di intestazione (*.h) 
  # nelle sottocartelle annidate per prevenire conflitti di nomi e duplicazioni di UUID in Xcode.
  s.source_files = [
    'ios/Native/*.swift',
    'ios/NativeSource/*.{c,cpp}',
    'vendor/whisper-native/main.{cpp,h}',
    'vendor/whisper-native/whisper.cpp/src/*.cpp',
    'vendor/whisper-native/whisper.cpp/ggml/src/*.{c,cpp}',
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/*.{c,cpp}',
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/arch/arm/*.{c,cpp}',
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/arch/x86/*.{c,cpp}',
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/amx/*.cpp'
  ]

  # Esclusione esplicita delle implementazioni duplicate dei kernel CPU 
  # per evitare collisioni di oggetti durante la compilazione nativa.
  s.exclude_files = [
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/quants.c',
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/repack.cpp',
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/arch/arm/quants.c',
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/arch/arm/repack.cpp',
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/arch/arm/cpu-feats.cpp',
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/arch/x86/quants.c',
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/arch/x86/repack.cpp',
    'vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu/arch/x86/cpu-feats.cpp'
  ]

  s.public_header_files = 'vendor/whisper-native/main.h'
  s.header_mappings_dir = 'vendor/whisper-native'
  s.preserve_paths = 'vendor/whisper-native/**/*', 'licenses/*', 'THIRD_PARTY_NOTICES.md'
  
  # Configurazione dei flag di compilazione C++ e standard di preprocessore
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'GCC_C_LANGUAGE_STANDARD' => 'gnu11',
    'HEADER_SEARCH_PATHS' => '$(inherited) "$(PODS_TARGET_SRCROOT)/vendor/whisper-native/whisper.cpp/include" "$(PODS_TARGET_SRCROOT)/vendor/whisper-native/whisper.cpp/src" "$(PODS_TARGET_SRCROOT)/vendor/whisper-native/whisper.cpp/ggml/include" "$(PODS_TARGET_SRCROOT)/vendor/whisper-native/whisper.cpp/ggml/src" "$(PODS_TARGET_SRCROOT)/vendor/whisper-native/whisper.cpp/ggml/src/ggml-cpu"',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GGML_USE_CPU GGML_VERSION=\"1.9.1\" GGML_COMMIT=\"whisper.cpp-v1.9.1\" WHISPER_VERSION=\"1.9.1\"',
    'OTHER_CFLAGS' => '$(inherited) -ffile-prefix-map=$(PODS_TARGET_SRCROOT)=. -fmacro-prefix-map=$(PODS_TARGET_SRCROOT)=. -fdebug-prefix-map=$(PODS_TARGET_SRCROOT)=.'
  }
  
  # Dart FFI risolve la funzione request() a livello di processo; la mantiene durante il linking statico.
  s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '$(inherited) -Wl,-u,_request' }
end