package com.moto.procam

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val channelName = "motoprocam/camera2"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCapabilities" -> result.success(getCapabilities())
                    else -> result.notImplemented()
                }
            }
    }

    private fun getCapabilities(): Map<String, Any> {
        val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        var rawSupported = false
        var manualSensorSupported = false

        for (cameraId in cameraManager.cameraIdList) {
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val capabilities = characteristics.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES) ?: intArrayOf()
            if (capabilities.contains(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_RAW)) {
                rawSupported = true
            }
            if (capabilities.contains(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_MANUAL_SENSOR)) {
                manualSensorSupported = true
            }
        }

        return mapOf(
            "deviceModel" to Build.MODEL,
            "androidVersion" to Build.VERSION.SDK_INT,
            "rawSupported" to rawSupported,
            "manualSensorSupported" to manualSensorSupported
        )
    }
}
