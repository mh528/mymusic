# just_audio_background — AudioService and MediaButtonReceiver are referenced
# from AndroidManifest only; R8 strips them without these rules.
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.bgaudioservice.** { *; }

# just_audio — ExoPlayer internals loaded via reflection
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }

# Dart/Flutter plugin registrant (always needed)
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter deferred components use Play Core which may not be present — suppress warnings
-dontwarn com.google.android.play.core.**
