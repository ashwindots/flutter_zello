import Flutter
import UIKit
import AVFoundation
#if canImport(PushToTalk)
import PushToTalk
#endif

/// Flutter plugin entry point for iOS.
///
/// Owns the MethodChannel + EventChannel pair, the AVAudioSession
/// configuration, and (when entitled) the Apple PushToTalk `PTChannelManager`.
/// All Zello SDK calls are isolated in `ZelloSdkAdapter` so any SDK-version
/// symbol drift only needs a fix in one file.
public class ZelloPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    // Keep in sync with lib/src/channels.dart
    private static let methodChannelName = "com.zello.flutter/method"
    private static let eventChannelName  = "com.zello.flutter/events"

    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel

    private var eventSink: FlutterEventSink?
    private var adapter: ZelloSdkAdapter?
    private var useApplePTT: Bool = true

    public static func register(with registrar: FlutterPluginRegistrar) {
        let method = FlutterMethodChannel(name: methodChannelName,
                                          binaryMessenger: registrar.messenger())
        let events = FlutterEventChannel(name: eventChannelName,
                                         binaryMessenger: registrar.messenger())
        let plugin = ZelloPlugin(method: method, events: events)
        registrar.addMethodCallDelegate(plugin, channel: method)
        events.setStreamHandler(plugin)
    }

    private init(method: FlutterMethodChannel, events: FlutterEventChannel) {
        self.methodChannel = method
        self.eventChannel = events
        super.init()
    }

    // MARK: - FlutterStreamHandler

    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        adapter?.attachListener { [weak self] payload in
            self?.emit(payload)
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        adapter?.detachListener()
        self.eventSink = nil
        return nil
    }

    // MARK: - FlutterPlugin

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call, result: result)
        case "connect":
            handleConnect(call, result: result)
        case "disconnect":
            safe(result) { try self.adapter?.disconnect(); return nil }
        case "startTalking":
            safe(result) {
                let channel: String = try self.requireArg(call, "channel")
                try self.adapter?.startTalking(channel: channel)
                return nil
            }
        case "stopTalking":
            safe(result) { try self.adapter?.stopTalking(); return nil }
        case "sendTextMessage":
            safe(result) {
                let channel: String = try self.requireArg(call, "channel")
                let text: String = try self.requireArg(call, "text")
                try self.adapter?.sendTextMessage(channel: channel, text: text)
                return nil
            }
        case "setStatus":
            safe(result) {
                let status: String = try self.requireArg(call, "status")
                try self.adapter?.setStatus(status)
                return nil
            }
        case "getChannelState":
            safe(result) {
                let channel: String = try self.requireArg(call, "channel")
                return self.adapter?.getChannelState(channel: channel) ?? [:]
            }
        case "dispose":
            safe(result) { self.teardown(); return nil }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method handlers

    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        safe(result) {
            let args = (call.arguments as? [String: Any?]) ?? [:]
            guard let appKey = args["appKey"] as? String else {
                throw ZelloPluginError.invalidArgument("appKey is required")
            }
            self.useApplePTT = (args["enableApplePushToTalk"] as? Bool) ?? true
            let label = (args["channelDisplayName"] as? String) ?? "Zello"

            try self.configureAudioSession()

            self.adapter?.dispose()
            let a = ZelloSdkAdapter(
                appKey: appKey,
                channelDisplayName: label,
                useApplePushToTalk: self.useApplePTT
            )
            a.attachListener { [weak self] payload in self?.emit(payload) }
            self.adapter = a
            return nil
        }
    }

    private func handleConnect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        safe(result) {
            guard let a = self.adapter else {
                throw ZelloPluginError.illegalState("not_initialized",
                                                    "Zello.initialize() not called")
            }
            let network: String = try self.requireArg(call, "network")
            let token: String = try self.requireArg(call, "token")
            let args = (call.arguments as? [String: Any?]) ?? [:]
            let username = args["username"] as? String
            try a.connect(network: network, token: token, username: username)
            return nil
        }
    }

    // MARK: - Helpers

    private func configureAudioSession() throws {
        let s = AVAudioSession.sharedInstance()
        try s.setCategory(.playAndRecord,
                          mode: .voiceChat,
                          options: [.allowBluetooth,
                                    .allowBluetoothA2DP,
                                    .defaultToSpeaker])
        try s.setActive(true)
    }

    private func requireArg<T>(_ call: FlutterMethodCall, _ key: String) throws -> T {
        let args = (call.arguments as? [String: Any?]) ?? [:]
        guard let v = args[key] as? T else {
            throw ZelloPluginError.invalidArgument("\(key) is required")
        }
        return v
    }

    private func safe(_ result: @escaping FlutterResult,
                      _ block: @escaping () throws -> Any?) {
        DispatchQueue.main.async {
            do {
                result(try block())
            } catch let ZelloPluginError.invalidArgument(msg) {
                result(FlutterError(code: "invalid_argument",
                                    message: msg, details: nil))
            } catch let ZelloPluginError.illegalState(code, msg) {
                result(FlutterError(code: code, message: msg, details: nil))
            } catch {
                result(FlutterError(code: "native_error",
                                    message: error.localizedDescription,
                                    details: nil))
            }
        }
    }

    private func emit(_ payload: [String: Any?]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(payload)
        }
    }

    private func teardown() {
        adapter?.dispose()
        adapter = nil
        try? AVAudioSession.sharedInstance().setActive(false,
                                                       options: [.notifyOthersOnDeactivation])
    }
}

enum ZelloPluginError: Error {
    case invalidArgument(String)
    case illegalState(String, String)
}
