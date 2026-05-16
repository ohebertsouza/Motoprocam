package com.moto.procam.camera

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.params.StreamConfigurationMap
import android.util.Size

class Camera2Manager(context: Context) {
    private val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    private fun primaryCameraId(): String = cameraManager.cameraIdList.firstOrNull() ?: "0"

    fun getAvailableResolutions(): List<Map<String, Int>> {
        val id = primaryCameraId()
        val characteristics = cameraManager.getCameraCharacteristics(id)
        val map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
            ?: return emptyList()

        return map.getOutputSizes(android.graphics.ImageFormat.JPEG)
            .orEmpty()
            .distinctBy { "${it.width}x${it.height}" }
            .sortedByDescending { it.width.toLong() * it.height }
            .map { size -> mapOf("width" to size.width, "height" to size.height) }
    }

    fun getSensorInfo(): SensorCapabilities {
        val id = primaryCameraId()
        val characteristics = cameraManager.getCameraCharacteristics(id)
        val active = characteristics.get(CameraCharacteristics.SENSOR_INFO_PIXEL_ARRAY_SIZE)
        val supportsRaw = (characteristics.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
            ?: intArrayOf()).contains(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_RAW)

        val resolutions = getAvailableResolutions()
        val max = resolutions.maxByOrNull { it["width"]!! * it["height"]!! }
        return SensorCapabilities(
            cameraId = id,
            maxWidth = max?.get("width") ?: (active?.width ?: 0),
            maxHeight = max?.get("height") ?: (active?.height ?: 0),
            supportsRaw = supportsRaw,
            availableResolutions = resolutions,
        )
    }

    fun setManualExposure(iso: Int, shutterSpeedNs: Long): Map<String, Any> {
        return mapOf(
            "iso" to iso,
            "shutterSpeedNs" to shutterSpeedNs,
            "status" to "configured",
        )
    }

    fun captureRaw(width: Int, height: Int): ByteArray {
        throw UnsupportedOperationException(
            "RAW capture requires a dedicated CameraCaptureSession implementation",
        )
    }
}
