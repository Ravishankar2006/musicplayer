//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import audio_service
import audio_session
import audiotags
import file_picker
import isar_flutter_libs
import just_audio
import just_waveform
import sqflite_darwin

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AudioServicePlugin.register(with: registry.registrar(forPlugin: "AudioServicePlugin"))
  AudioSessionPlugin.register(with: registry.registrar(forPlugin: "AudioSessionPlugin"))
  AudiotagsPlugin.register(with: registry.registrar(forPlugin: "AudiotagsPlugin"))
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  IsarFlutterLibsPlugin.register(with: registry.registrar(forPlugin: "IsarFlutterLibsPlugin"))
  JustAudioPlugin.register(with: registry.registrar(forPlugin: "JustAudioPlugin"))
  JustWaveformPlugin.register(with: registry.registrar(forPlugin: "JustWaveformPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
}
