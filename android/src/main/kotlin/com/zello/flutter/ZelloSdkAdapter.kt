package com.zello.flutter

import android.content.Context

/**
 * Thin adapter between the plugin's channel layer and the Zello Android SDK.
 *
 * All references to concrete Zello SDK classes are intentionally isolated
 * here — if you upgrade the SDK and a class/method renames, this is the only
 * file that needs to change.
 *
 * The adapter exposes a single [Listener] which is a `(Map<String, Any?>) -> Unit`
 * receiving event payloads in the exact shape `ZelloEventCodec.decode` expects
 * on the Dart side.
 *
 * NOTE: Symbols marked `TODO: confirm against Zello SDK vX` are placeholders.
 * Replace them with the real types from the Zello Channels SDK / Zello Work
 * SDK build you obtained from your Zello Work subscription.
 */
class ZelloSdkAdapter(
    private val context: Context,
    private val appKey: String,
    private val serviceLabel: String,
    private val useForegroundService: Boolean,
) {
    private var listener: Listener? = null

    // TODO: confirm against Zello SDK vX
    // private val session: com.zello.channel.sdk.Session = ...
    // private val sessionListener = object : com.zello.channel.sdk.SessionListener { ... }

    fun attachListener(l: Listener) {
        listener = l
        // TODO: confirm against Zello SDK vX -- register sessionListener with the SDK.
    }

    fun detachListener() {
        listener = null
        // TODO: confirm against Zello SDK vX -- unregister sessionListener.
    }

    fun connect(network: String, token: String, username: String?) {
        emit(
            mapOf(
                "type" to "connectionStateChanged",
                "state" to "connecting",
            )
        )
        // TODO: confirm against Zello SDK vX -- build and connect a Session:
        //   val context = SessionContext.Builder(context).build()
        //   session = Session.Builder(context)
        //       .address(...).authToken(token).username(username).channel(...)
        //       .build()
        //   session.connect()
        // The SDK's connection callbacks should call back into emit(...) with
        // payloads matching the Dart event codec.
    }

    fun disconnect() {
        // TODO: confirm against Zello SDK vX -- session?.disconnect()
        emit(
            mapOf(
                "type" to "connectionStateChanged",
                "state" to "disconnected",
            )
        )
    }

    fun startTalking(channel: String) {
        // TODO: confirm against Zello SDK vX -- session?.startVoiceMessage(channel)
        emit(
            mapOf(
                "type" to "outgoingTalkStateChanged",
                "isTalking" to true,
                "channel" to channel,
            )
        )
    }

    fun stopTalking() {
        // TODO: confirm against Zello SDK vX -- session?.endVoiceMessage()
        emit(
            mapOf(
                "type" to "outgoingTalkStateChanged",
                "isTalking" to false,
            )
        )
    }

    fun sendTextMessage(channel: String, text: String) {
        // TODO: confirm against Zello SDK vX -- session?.sendTextMessage(channel, text)
    }

    fun setStatus(status: String) {
        // TODO: confirm against Zello SDK vX -- session?.status = mapStatus(status)
    }

    fun getChannelState(channel: String): Map<String, Any?> {
        // TODO: confirm against Zello SDK vX -- query session for channel info.
        return mapOf(
            "name" to channel,
            "isConnected" to false,
            "isConnecting" to false,
            "usersOnline" to 0,
        )
    }

    fun dispose() {
        // TODO: confirm against Zello SDK vX -- session?.disconnect(); session = null
        listener = null
    }

    private fun emit(payload: Map<String, Any?>) {
        listener?.invoke(payload)
    }
}

typealias Listener = (Map<String, Any?>) -> Unit
