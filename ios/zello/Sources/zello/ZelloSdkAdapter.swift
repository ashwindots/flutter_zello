import Foundation
#if canImport(PushToTalk)
import PushToTalk
#endif

/// Adapter that hides the concrete Zello iOS SDK + Apple PushToTalk symbols.
/// Replace the marked `TODO` blocks once you wire the real SDK in.
final class ZelloSdkAdapter {

    typealias Listener = ([String: Any?]) -> Void

    private let appKey: String
    private let channelDisplayName: String
    private let useApplePushToTalk: Bool

    private var listener: Listener?

    // TODO: confirm against Zello iOS SDK vX
    // private var session: ZCCSession?
    // private var sessionDelegate: SessionDelegateBridge?

    #if canImport(PushToTalk)
    private var ptChannelManager: PTChannelManager?
    private var ptChannelUUID: UUID?
    #endif

    init(appKey: String,
         channelDisplayName: String,
         useApplePushToTalk: Bool) {
        self.appKey = appKey
        self.channelDisplayName = channelDisplayName
        self.useApplePushToTalk = useApplePushToTalk
    }

    func attachListener(_ l: @escaping Listener) {
        self.listener = l
        // TODO: confirm against Zello iOS SDK vX -- attach delegate to session.
    }

    func detachListener() {
        self.listener = nil
        // TODO: confirm against Zello iOS SDK vX -- detach delegate.
    }

    func connect(network: String, token: String, username: String?) throws {
        emit([
            "type": "connectionStateChanged",
            "state": "connecting",
        ])

        // TODO: confirm against Zello iOS SDK vX -- build & connect session:
        // let s = ZCCSession(address: network, authToken: token,
        //                    username: username, password: nil, channel: nil)
        // s.delegate = sessionDelegateBridge
        // s.connect()
        // self.session = s

        if useApplePushToTalk {
            try registerApplePTTChannel()
        }
    }

    func disconnect() throws {
        // TODO: confirm against Zello iOS SDK vX -- session?.disconnect()
        emit([
            "type": "connectionStateChanged",
            "state": "disconnected",
        ])
    }

    func startTalking(channel: String) throws {
        // TODO: confirm against Zello iOS SDK vX -- session?.startVoiceMessage(channel:)
        emit([
            "type": "outgoingTalkStateChanged",
            "isTalking": true,
            "channel": channel,
        ])
    }

    func stopTalking() throws {
        // TODO: confirm against Zello iOS SDK vX -- session?.endVoiceMessage()
        emit([
            "type": "outgoingTalkStateChanged",
            "isTalking": false,
        ])
    }

    func sendTextMessage(channel: String, text: String) throws {
        // TODO: confirm against Zello iOS SDK vX -- session?.sendText(text, to: channel)
    }

    func setStatus(_ status: String) throws {
        // TODO: confirm against Zello iOS SDK vX -- session?.status = mapStatus(status)
    }

    func getChannelState(channel: String) -> [String: Any?] {
        // TODO: confirm against Zello iOS SDK vX -- query session for channel info.
        return [
            "name": channel,
            "isConnected": false,
            "isConnecting": false,
            "usersOnline": 0,
        ]
    }

    func dispose() {
        // TODO: confirm against Zello iOS SDK vX -- tear session down.
        #if canImport(PushToTalk)
        if let mgr = ptChannelManager, let uuid = ptChannelUUID {
            mgr.leaveChannel(channelUUID: uuid) { _ in }
        }
        ptChannelManager = nil
        ptChannelUUID = nil
        #endif
        listener = nil
    }

    // MARK: - Apple PushToTalk

    private func registerApplePTTChannel() throws {
        #if canImport(PushToTalk)
        if #available(iOS 16.0, *) {
            PTChannelManager.channelManager(
                delegate: ApplePTTBridge.shared,
                restorationDelegate: ApplePTTBridge.shared
            ) { [weak self] manager, error in
                guard let self = self, let manager = manager, error == nil else { return }
                self.ptChannelManager = manager
                let uuid = UUID()
                self.ptChannelUUID = uuid
                let descriptor = PTChannelDescriptor(
                    name: self.channelDisplayName,
                    image: nil
                )
                manager.requestJoinChannel(channelUUID: uuid,
                                           descriptor: descriptor)
            }
        }
        #endif
    }

    private func emit(_ payload: [String: Any?]) {
        listener?(payload)
    }
}

#if canImport(PushToTalk)
@available(iOS 16.0, *)
final class ApplePTTBridge: NSObject, PTChannelManagerDelegate, PTChannelRestorationDelegate {
    static let shared = ApplePTTBridge()

    // The full PT delegate contract is large; the methods below are the
    // minimum set most apps need. Extend as you wire real Zello TX/RX.

    func channelManager(_ channelManager: PTChannelManager,
                        didJoinChannel channelUUID: UUID,
                        reason: PTChannelJoinReason) {}

    func channelManager(_ channelManager: PTChannelManager,
                        didLeaveChannel channelUUID: UUID,
                        reason: PTChannelLeaveReason) {}

    func channelManager(_ channelManager: PTChannelManager,
                        receivedEphemeralPushToken pushToken: Data) {}

    func channelManager(_ channelManager: PTChannelManager,
                        didActivate audioSession: AVAudioSession) {}

    func channelManager(_ channelManager: PTChannelManager,
                        didDeactivate audioSession: AVAudioSession) {}

    func channelDescriptor(restoredChannelUUID channelUUID: UUID) -> PTChannelDescriptor {
        PTChannelDescriptor(name: "Zello", image: nil)
    }
}
#endif
