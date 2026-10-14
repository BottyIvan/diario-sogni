package it.diariosogni.diario_sogni

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.antonkarpenko.ffmpegkit.FFmpegKit
import com.antonkarpenko.ffmpegkit.ReturnCode
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

// Conversion belongs to the engine/application, never to the visible Activity.
object LocalAudioConverter {
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    fun convert(context: Context, input: String, output: String, result: MethodChannel.Result) {
        executor.execute {
            try {
                val root = File(context.applicationInfo.dataDir).canonicalPath + File.separator
                require(File(input).canonicalPath.startsWith(root) && File(output).canonicalPath.startsWith(root))
                val session = FFmpegKit.executeWithArguments(arrayOf("-y", "-i", input,
                    "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", output))
                if (!ReturnCode.isSuccess(session.returnCode)) throw IllegalStateException("Conversione audio non riuscita")
                main.post { result.success(output) }
            } catch (error: Exception) {
                main.post { result.error("AUDIO_CONVERSION", "Conversione audio non riuscita", null) }
            }
        }
    }
}
