package it.diariosogni.diario_sogni

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors
import kotlin.math.roundToInt

/** Application-scoped Android decoder: no Activity or external FFmpeg binary. */
object LocalAudioConverter {
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    fun convert(context: Context, input: String, output: String, result: MethodChannel.Result) {
        executor.execute {
            var safeOutput: File? = null
            try {
                val root = File(context.applicationInfo.dataDir).canonicalPath + File.separator
                require(File(input).canonicalPath.startsWith(root) && File(output).canonicalPath.startsWith(root))
                safeOutput = File(output)
                decode(input, output)
                main.post { result.success(output) }
            } catch (_: Exception) {
                safeOutput?.delete()
                main.post { result.error("AUDIO_CONVERSION", "Conversione audio non riuscita", null) }
            }
        }
    }

    private fun decode(input: String, output: String) {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        var codecStarted = false
        try {
            extractor.setDataSource(input)
            val track = (0 until extractor.trackCount).firstOrNull {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
            } ?: throw IllegalStateException("Traccia audio non disponibile")
            extractor.selectTrack(track)
            val format = extractor.getTrackFormat(track)
            val mime = format.getString(MediaFormat.KEY_MIME)!!
            format.setInteger(MediaFormat.KEY_PCM_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            val decoder = MediaCodec.createDecoderByType(mime)
            codec = decoder
            decoder.configure(format, null, null, 0)
            decoder.start()
            codecStarted = true
            RandomAccessFile(output, "rw").use { file ->
                val writer = PcmWriter(file)
                var rate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                var encoding = AudioFormat.ENCODING_PCM_16BIT
                var inputEnded = false
                var outputEnded = false
                var lastProgress = System.nanoTime()
                val info = MediaCodec.BufferInfo()
                while (!outputEnded) {
                    if (System.nanoTime() - lastProgress > 30_000_000_000L) throw IllegalStateException("Decoder non risponde")
                    if (!inputEnded) {
                        val index = decoder.dequeueInputBuffer(10000)
                        if (index >= 0) {
                            val buffer = decoder.getInputBuffer(index) ?: throw IllegalStateException("Buffer non disponibile")
                            buffer.clear()
                            val count = extractor.readSampleData(buffer, 0)
                            if (count < 0) {
                                decoder.queueInputBuffer(index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                inputEnded = true
                            } else {
                                decoder.queueInputBuffer(index, 0, count, extractor.sampleTime, 0)
                                extractor.advance()
                            }
                            lastProgress = System.nanoTime()
                        }
                    }
                    val index = decoder.dequeueOutputBuffer(info, 10000)
                    when {
                        index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            val decoded = decoder.outputFormat
                            rate = decoded.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                            channels = decoded.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                            encoding = if (decoded.containsKey(MediaFormat.KEY_PCM_ENCODING)) decoded.getInteger(MediaFormat.KEY_PCM_ENCODING)
                                else AudioFormat.ENCODING_PCM_16BIT
                            lastProgress = System.nanoTime()
                        }
                        index >= 0 -> {
                            try {
                                if (info.size > 0 && info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0) {
                                    val buffer = decoder.getOutputBuffer(index) ?: throw IllegalStateException("Audio decodificato non disponibile")
                                    buffer.position(info.offset)
                                    buffer.limit(info.offset + info.size)
                                    writer.accept(buffer.slice().order(ByteOrder.LITTLE_ENDIAN), rate, channels, encoding)
                                }
                                outputEnded = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                                lastProgress = System.nanoTime()
                            } finally { decoder.releaseOutputBuffer(index, false) }
                        }
                    }
                }
                writer.finish()
            }
        } finally {
            if (codecStarted) try { codec?.stop() } catch (_: Exception) {}
            codec?.release()
            extractor.release()
        }
    }

    /** Streaming mono conversion and linear resampling to signed 16-bit/16 kHz WAV. */
    private class PcmWriter(private val file: RandomAccessFile) {
        private val buffer = ByteBuffer.allocate(32768).order(ByteOrder.LITTLE_ENDIAN)
        private var sourceRate = 0
        private var frame = -1L
        private var previous = 0.0
        private var nextOutput = 0.0
        private var samples = 0L
        init { file.setLength(0); file.write(ByteArray(44)) }

        fun accept(pcm: ByteBuffer, rate: Int, channels: Int, encoding: Int) {
            require(rate > 0 && channels in 1..32)
            if (sourceRate == 0) sourceRate = rate
            require(sourceRate == rate)
            val width = when (encoding) {
                AudioFormat.ENCODING_PCM_8BIT -> 1
                AudioFormat.ENCODING_PCM_16BIT -> 2
                AudioFormat.ENCODING_PCM_FLOAT, AudioFormat.ENCODING_PCM_32BIT -> 4
                AudioFormat.ENCODING_PCM_24BIT_PACKED -> 3
                else -> throw IllegalStateException("Formato PCM non supportato")
            }
            require(pcm.remaining() % (width * channels) == 0)
            val step = rate / 16000.0
            while (pcm.remaining() >= width * channels) {
                var sum = 0.0
                repeat(channels) {
                    sum += when (encoding) {
                        AudioFormat.ENCODING_PCM_8BIT -> ((pcm.get().toInt() and 255) - 128) / 128.0
                        AudioFormat.ENCODING_PCM_16BIT -> pcm.short / 32768.0
                        AudioFormat.ENCODING_PCM_FLOAT -> pcm.float.toDouble()
                        AudioFormat.ENCODING_PCM_32BIT -> pcm.int / 2147483648.0
                        else -> {
                            val a = pcm.get().toInt() and 255
                            val b = pcm.get().toInt() and 255
                            val c = pcm.get().toInt()
                            (a or (b shl 8) or (c shl 16)) / 8388608.0
                        }
                    }
                }
                val value = sum / channels
                require(value.isFinite())
                frame++
                if (frame == 0L) { emit(value); nextOutput = step }
                else while (nextOutput <= frame.toDouble()) {
                    val fraction = nextOutput - (frame - 1).toDouble()
                    emit(previous + (value - previous) * fraction)
                    nextOutput += step
                }
                previous = value
            }
        }

        private fun emit(value: Double) {
            if (buffer.remaining() < 2) flush()
            buffer.putShort((value * 32768.0).roundToInt().coerceIn(-32768, 32767).toShort())
            samples++
            require(samples * 2 <= Int.MAX_VALUE - 36)
        }
        private fun flush() { file.write(buffer.array(), 0, buffer.position()); buffer.clear() }
        fun finish() {
            require(samples > 0)
            flush()
            val bytes = (samples * 2).toInt()
            val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
            header.put("RIFF".toByteArray()).putInt(bytes + 36).put("WAVEfmt ".toByteArray())
            header.putInt(16).putShort(1).putShort(1).putInt(16000).putInt(32000).putShort(2).putShort(16)
            header.put("data".toByteArray()).putInt(bytes)
            file.seek(0); file.write(header.array()); file.fd.sync()
        }
    }
}
