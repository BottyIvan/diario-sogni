package it.diariosogni.diario_sogni

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var archive: SharedArchive? = null
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (archive?.onResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        val cached = FlutterEngineCache.getInstance().get("dream-engine")
        if (cached != null) return cached
        val engine = FlutterEngine(applicationContext)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        FlutterEngineCache.getInstance().put("dream-engine", engine)
        return engine
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        archive = SharedArchive(this, flutterEngine.dartExecutor.binaryMessenger)
        val appContext = applicationContext
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "it.diariosogni/background")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "startTranscription" -> {
                            val intent = Intent(appContext, TranscriptionService::class.java)
                            if (Build.VERSION.SDK_INT >= 26) appContext.startForegroundService(intent)
                            else appContext.startService(intent)
                            val preferences = appContext.getSharedPreferences("notification-setup", MODE_PRIVATE)
                            if (Build.VERSION.SDK_INT >= 33 &&
                                checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED &&
                                !preferences.getBoolean("asked", false) && !isFinishing && !isDestroyed) {
                                preferences.edit().putBoolean("asked", true).apply()
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 310)
                            }
                            result.success(null)
                        }
                        "stopTranscription" -> {
                            appContext.stopService(Intent(appContext, TranscriptionService::class.java))
                            result.success(null)
                        }
                        "convertAudio" -> {
                            val input = call.argument<String>("input")
                            val output = call.argument<String>("output")
                            if (input == null || output == null) result.error("AUDIO_PATH", "Percorso audio non disponibile", null)
                            else LocalAudioConverter.convert(appContext, input, output, result)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("BACKGROUND_SERVICE", "Servizio di trascrizione non disponibile", null)
                }
            }
    }
}
