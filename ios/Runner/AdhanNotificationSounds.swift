import AVFoundation
import Flutter
import Foundation

/// Converts a downloaded adhan recording to a short (at most 29 seconds) linear-PCM `.caf` clip
/// and keeps it in `Library/Sounds` — the one place, besides the app bundle, that
/// `UNNotificationSound(named:)` resolves at runtime. The full recording stays where it was
/// downloaded, untouched; this only prepares the short clip the notification itself can play.
///
/// Implements the `hadeeths/adhan_sound` channel for iOS (see `AdhanSounds.kt` for the Android
/// side, which lists the full recording in the shared notification sounds instead — Android has
/// no 30-second limit, so does not need this conversion at all).
enum AdhanNotificationSounds {
  private static let channelName = "hadeeths/adhan_sound"

  /// The system caps a notification sound at 30 seconds; a second of slack keeps the result
  /// comfortably under that even after encoding rounding.
  private static let maxDuration: Double = 29

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isSupported":
        result(true)
      case "register":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String,
          let name = args["name"] as? String
        else {
          result(FlutterError(code: "bad_arguments", message: "path and name are required", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          let fileName = prepare(sourcePath: path, name: name)
          DispatchQueue.main.async { result(fileName) }
        }
      case "unregister":
        if let args = call.arguments as? [String: Any], let name = args["name"] as? String {
          removeSound(named: name)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Converts the recording at `sourcePath` and saves it as `<name>.caf` in `Library/Sounds`.
  /// Returns the file name (what `UNNotificationSound(named:)` expects), or nil, logged, if the
  /// conversion failed — the reminder then falls back to the system sound (see
  /// `docs/ADHAN_SOUNDS.md`); the already-downloaded full recording is unaffected either way.
  private static func prepare(sourcePath: String, name: String) -> String? {
    guard let soundsDirectory = soundsDirectory() else {
      NSLog("AdhanNotificationSounds: could not find Library/Sounds")
      return nil
    }
    let fileName = "\(name).caf"
    let destinationURL = soundsDirectory.appendingPathComponent(fileName)
    do {
      try FileManager.default.createDirectory(at: soundsDirectory, withIntermediateDirectories: true)
      if FileManager.default.fileExists(atPath: destinationURL.path) {
        try FileManager.default.removeItem(at: destinationURL)
      }
      try convert(sourcePath: sourcePath, destinationURL: destinationURL)
      return fileName
    } catch {
      NSLog("AdhanNotificationSounds: conversion failed for \(name): \(error)")
      try? FileManager.default.removeItem(at: destinationURL)
      return nil
    }
  }

  private static func removeSound(named name: String) {
    guard let url = soundsDirectory()?.appendingPathComponent("\(name).caf") else { return }
    try? FileManager.default.removeItem(at: url)
  }

  private static func soundsDirectory() -> URL? {
    guard let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
      return nil
    }
    return library.appendingPathComponent("Sounds")
  }

  /// Reads `sourcePath` (any format `AVAudioFile` can decode, here always MP3), trims it to
  /// `maxDuration`, downmixes to mono 16-bit linear PCM (the format already proven for the short
  /// bundled clips, see `docs/ADHAN_SOUNDS.md`), and writes it to `destinationURL` as a `.caf`.
  private static func convert(sourcePath: String, destinationURL: URL) throws {
    let sourceFile = try AVAudioFile(forReading: URL(fileURLWithPath: sourcePath))
    let sourceFormat = sourceFile.processingFormat
    let sampleRate = sourceFormat.sampleRate
    let frameCount = AVAudioFrameCount(
      min(Double(sourceFile.length), maxDuration * sampleRate)
    )
    guard
      frameCount > 0,
      let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount)
    else {
      throw ConversionError.emptyOrUnreadable
    }
    try sourceFile.read(into: sourceBuffer, frameCount: frameCount)

    let outputSettings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVSampleRateKey: sampleRate,
      AVNumberOfChannelsKey: 1,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
    ]
    let outputFile = try AVAudioFile(
      forWriting: destinationURL,
      settings: outputSettings,
      commonFormat: .pcmFormatInt16,
      interleaved: true
    )

    guard
      let outputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: sampleRate,
        channels: 1,
        interleaved: true
      )
    else {
      throw ConversionError.formatCreationFailed
    }

    if sourceFormat.commonFormat == outputFormat.commonFormat,
      sourceFormat.channelCount == outputFormat.channelCount
    {
      try outputFile.write(from: sourceBuffer)
      return
    }

    guard let converter = AVAudioConverter(from: sourceFormat, to: outputFormat) else {
      throw ConversionError.converterCreationFailed
    }
    guard
      let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount)
    else {
      throw ConversionError.bufferCreationFailed
    }
    var conversionError: NSError?
    var consumed = false
    converter.convert(to: convertedBuffer, error: &conversionError) { _, outStatus in
      if consumed {
        outStatus.pointee = .noDataNow
        return nil
      }
      consumed = true
      outStatus.pointee = .haveData
      return sourceBuffer
    }
    if let conversionError = conversionError { throw conversionError }
    try outputFile.write(from: convertedBuffer)
  }

  private enum ConversionError: Error {
    case emptyOrUnreadable
    case formatCreationFailed
    case converterCreationFailed
    case bufferCreationFailed
  }
}
