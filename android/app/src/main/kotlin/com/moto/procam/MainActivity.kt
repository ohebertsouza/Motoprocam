package com.moto.procam

import com.moto.procam.camera.Camera2Manager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.moto.procam/camera2"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val camera2Manager = Camera2Manager(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAvailableResolutions" -> {
                        result.success(camera2Manager.getAvailableResolutions())
                    }
                    "getSensorInfo" -> {
                        val info = camera2Manager.getSensorInfo()
                        result.success(
                            mapOf(
                                "cameraId" to info.cameraId,
                                "maxWidth" to info.maxWidth,
                                "maxHeight" to info.maxHeight,
                                "supportsRaw" to info.supportsRaw,
                                "availableResolutions" to info.availableResolutions,
                            ),
                        )
                    }
                    "setManualExposure" -> {
                        val iso = call.argument<Int>("iso") ?: 100
                        val shutter = call.argument<Number>("shutterSpeedNs")?.toLong() ?: 10_000_000L
                        result.success(camera2Manager.setManualExposure(iso, shutter))
                    }
                    "captureRaw" -> {
                        val width = call.argument<Int>("width") ?: 0
                        val height = call.argument<Int>("height") ?: 0
                        try {
                            result.success(camera2Manager.captureRaw(width, height))
                        } catch (error: UnsupportedOperationException) {
                            result.error("RAW_NOT_IMPLEMENTED", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
