package com.moto.procam.camera

data class SensorCapabilities(
    val cameraId: String,
    val maxWidth: Int,
    val maxHeight: Int,
    val supportsRaw: Boolean,
    val availableResolutions: List<Map<String, Int>>,
)
