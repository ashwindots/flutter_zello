package com.zello.flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Flutter plugin entry point.
 *
 * Bridges Dart -> Zello native SDK via [MethodChannel], and SDK callbacks
 * -> Dart via a single broadcast [EventChannel]. All sink/result callbacks
 * are dispatched onto the platform main thread.
 *
 * The actual Zello SDK calls are isolated behind [ZelloSdkAdapter] so symbol
 * names (which depend on the SDK version you ship) can be corrected in one
 * place without touching channel plumbing.
 */
class ZelloPlugin : FlutterPlugin, MethodCallHandler,
    EventChannel.StreamHandler, ActivityAware {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    private var applicationContext: Context? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var adapter: ZelloSdkAdapter? = null
    private var foregroundServiceEnabled = true

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        teardown()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        applicationContext = null
    }

    // -- ActivityAware ---------------------------------------------------------

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    // -- EventChannel.StreamHandler -------------------------------------------

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        adapter?.attachListener(::emit)
    }

    override fun onCancel(arguments: Any?) {
        adapter?.detachListener()
        eventSink = null
    }

    // -- MethodCallHandler -----------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "connect" -> handleConnect(call, result)
            "disconnect" -> safe(result) { adapter?.disconnect(); null }
            "startTalking" -> safe(result) {
                val channel = call.argument<String>("channel")
                    ?: throw IllegalArgumentException("channel is required")
                adapter?.startTalking(channel); null
            }
            "stopTalking" -> safe(result) { adapter?.stopTalking(); null }
            "sendTextMessage" -> safe(result) {
                val channel = call.argument<String>("channel")
                    ?: throw IllegalArgumentException("channel is required")
                val text = call.argument<String>("text")
                    ?: throw IllegalArgumentException("text is required")
                adapter?.sendTextMessage(channel, text); null
            }
            "setStatus" -> safe(result) {
                val status = call.argument<String>("status")
                    ?: throw IllegalArgumentException("status is required")
                adapter?.setStatus(status); null
            }
            "getChannelState" -> safe(result) {
                val channel = call.argument<String>("channel")
                    ?: throw IllegalArgumentException("channel is required")
                adapter?.getChannelState(channel) ?: emptyMap<String, Any?>()
            }
            "dispose" -> safe(result) { teardown(); null }
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        safe(result) {
            val ctx = applicationContext
                ?: throw IllegalStateException("Plugin not attached to engine")
            val appKey = call.argument<String>("appKey")
                ?: throw IllegalArgumentException("appKey is required")
            foregroundServiceEnabled =
                call.argument<Boolean>("enableForegroundService") ?: true
            val displayName =
                call.argument<String>("channelDisplayName") ?: "Zello"

            adapter?.dispose()
            adapter = ZelloSdkAdapter(
                context = ctx,
                appKey = appKey,
                serviceLabel = displayName,
                useForegroundService = foregroundServiceEnabled,
            ).also { it.attachListener(::emit) }
            null
        }
    }

    private fun handleConnect(call: MethodCall, result: Result) {
        safe(result) {
            val a = adapter ?: throw IllegalStateException("not_initialized")
            val network = call.argument<String>("network")
                ?: throw IllegalArgumentException("network is required")
            val token = call.argument<String>("token")
                ?: throw IllegalArgumentException("token is required")
            val username = call.argument<String>("username")

            if (foregroundServiceEnabled) {
                val ctx = applicationContext!!
                ctx.startForegroundService(
                    Intent(ctx, ZelloForegroundService::class.java)
                )
            }
            a.connect(network, token, username)
            null
        }
    }

    // -- Helpers ---------------------------------------------------------------

    /** Run a block on the platform main thread, mapping exceptions to Result.error. */
    private inline fun safe(result: Result, crossinline block: () -> Any?) {
        mainHandler.post {
            try {
                result.success(block())
            } catch (iae: IllegalArgumentException) {
                result.error("invalid_argument", iae.message, null)
            } catch (ise: IllegalStateException) {
                result.error(ise.message ?: "illegal_state", ise.message, null)
            } catch (t: Throwable) {
                result.error("native_error", t.message ?: t.javaClass.simpleName, null)
            }
        }
    }

    /** Emit a typed event payload to Dart on the main thread. */
    private fun emit(payload: Map<String, Any?>) {
        mainHandler.post { eventSink?.success(payload) }
    }

    private fun teardown() {
        try {
            adapter?.dispose()
        } finally {
            adapter = null
            val ctx = applicationContext
            if (ctx != null && foregroundServiceEnabled) {
                ctx.stopService(Intent(ctx, ZelloForegroundService::class.java))
            }
        }
    }

    companion object {
        // Keep in sync with lib/src/channels.dart
        private const val METHOD_CHANNEL = "com.zello.flutter/method"
        private const val EVENT_CHANNEL = "com.zello.flutter/events"
    }
}
