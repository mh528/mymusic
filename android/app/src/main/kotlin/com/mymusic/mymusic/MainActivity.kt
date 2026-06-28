package com.mymusic.mymusic

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.mymusic/foreground"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForeground" -> {
                        val title = call.argument<String>("title") ?: "My Music"
                        val artist = call.argument<String>("artist") ?: ""
                        val intent = Intent(this, AudioForegroundService::class.java).apply {
                            action = AudioForegroundService.ACTION_START
                            putExtra(AudioForegroundService.EXTRA_TITLE, title)
                            putExtra(AudioForegroundService.EXTRA_ARTIST, artist)
                        }
                        startForegroundService(intent)
                        result.success(null)
                    }
                    "stopForeground" -> {
                        val intent = Intent(this, AudioForegroundService::class.java).apply {
                            action = AudioForegroundService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
