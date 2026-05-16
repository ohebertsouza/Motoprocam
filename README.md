# Motoprocam

MotoProCam now uses a modular camera architecture focused on Moto Edge 30 compatibility:

- Advanced image processing pipeline (`lib/utils/iphone_processor_v2.dart`) with curves, LUT-like grading, shadow/highlight balancing, white balance tuning, and noise reduction.
- Portrait mode controls (`lib/screens/portrait_mode_screen.dart`) with real-time blur (0-100), depth strength, and portrait lighting presets.
- Pro mode controls (`lib/screens/pro_mode_screen.dart`) for ISO, shutter, Kelvin white balance, focus, metering mode, RAW toggle, and focus peaking toggle.
- Multi-camera lens detection/selection (`lib/services/device_camera_info.dart`, `lib/widgets/camera_lens_selector.dart`) for ultra-wide/main/tele/front profiles.
- Isolate-based processing (`lib/services/image_processing_service.dart`) to reduce UI blocking.
- Android Camera2 capability bridge (`android/app/src/main/kotlin/com/moto/procam/MainActivity.kt`) for RAW/manual sensor support detection.
