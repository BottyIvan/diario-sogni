package it.diariosogni.diario_sogni

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.io.ByteArrayOutputStream

/** Access only the explicitly selected tree; no broad storage permission. */
class SharedArchive(private val activity: Activity, messenger: BinaryMessenger) {
    private val context = activity.applicationContext
    private val resolver = context.contentResolver
    private val prefs = context.getSharedPreferences("dream-archive", 0)
    companion object { private val worker = Executors.newSingleThreadExecutor() }
    private val main = Handler(Looper.getMainLooper())
    private var pending: MethodChannel.Result? = null
    private val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION

    init {
        MethodChannel(messenger, "it.diariosogni/archive").setMethodCallHandler { call, result ->
            if (call.method == "choose") {
                if (pending != null) { result.error("BUSY", "Scelta cartella già aperta", null); return@setMethodCallHandler }
                pending = result
                try {
                    activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                        addFlags(flags or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
                    }, 421)
                } catch (error: Exception) {
                    pending = null
                    result.error("FOLDER_PICKER", "Scelta cartella non disponibile", null)
                }
                return@setMethodCallHandler
            }
            worker.execute {
                try {
                    val value: Any? = when (call.method) {
                        "restore" -> prefs.getString("label", null)
                        "disconnect" -> {
                            prefs.getString("tree", null)?.let {
                                try { resolver.releasePersistableUriPermission(Uri.parse(it), flags) } catch (_: Exception) {}
                            }
                            prefs.edit().clear().commit()
                            null
                        }
                        "list" -> children(folder()).map { it.second }
                        "read" -> {
                            val name = name(call.argument<String>("name"))
                            val doc = children(folder()).firstOrNull { it.second == name }?.first
                                ?: throw IllegalStateException("File non disponibile")
                            resolver.openInputStream(doc)?.use {
                                val output = ByteArrayOutputStream()
                                val buffer = ByteArray(65536)
                                while (true) {
                                    val count = it.read(buffer)
                                    if (count < 0) break
                                    if (output.size() + count > 100 * 1024 * 1024) throw IllegalStateException("File oltre 100 MB")
                                    output.write(buffer, 0, count)
                                }
                                output.toByteArray()
                            } ?: throw IllegalStateException("File non leggibile")
                        }
                        "write" -> {
                            val name = name(call.argument<String>("name"))
                            val bytes = call.argument<ByteArray>("bytes") ?: throw IllegalArgumentException("Dati mancanti")
                            val parent = folder()
                            val mime = if (name.endsWith(".json")) "application/json" else "application/octet-stream"
                            val doc = children(parent).firstOrNull { it.second == name }?.first
                                ?: DocumentsContract.createDocument(resolver, parent, mime, name)
                                ?: throw IllegalStateException("Creazione file fallita")
                            resolver.openOutputStream(doc, "wt")?.use { it.write(bytes); it.flush() }
                                ?: throw IllegalStateException("File non scrivibile")
                            null
                        }
                        "remove" -> {
                            val name = name(call.argument<String>("name"))
                            children(folder()).firstOrNull { it.second == name }?.first?.let {
                                if (!DocumentsContract.deleteDocument(resolver, it)) throw IllegalStateException("Eliminazione fallita")
                            }
                            null
                        }
                        else -> throw IllegalArgumentException("Operazione sconosciuta")
                    }
                    main.post { result.success(value) }
                } catch (error: Exception) {
                    main.post { result.error("ARCHIVE_FOLDER", "Cartella non accessibile. Verifica permessi, connessione e spazio disponibile.", null) }
                }
            }
        }
    }

    fun onResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != 421) return false
        val callback = pending ?: return true
        pending = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) { callback.success(null); return true }
        try {
            val uri = data.data!!
            resolver.takePersistableUriPermission(uri, data.flags and flags)
            val doc = DocumentsContract.buildDocumentUriUsingTree(uri, DocumentsContract.getTreeDocumentId(uri))
            var label = "Cartella condivisa"
            resolver.query(doc, arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use {
                if (it.moveToFirst()) label = it.getString(0)
            }
            prefs.edit().putString("tree", uri.toString()).putString("label", label).apply()
            callback.success(label)
        } catch (_: Exception) { callback.error("FOLDER_ACCESS", "Accesso alla cartella non consentito", null) }
        return true
    }

    private fun name(value: String?): String {
        if (value == null || !Regex("^[a-zA-Z0-9_.-]{1,200}$").matches(value) || value.contains(".."))
            throw IllegalArgumentException("Nome non valido")
        return value
    }

    private fun folder(): Uri {
        val tree = Uri.parse(prefs.getString("tree", null) ?: throw IllegalStateException("Scegli una cartella"))
        val parent = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
        val entries = children(parent)
        if (prefs.getString("label", null) == "Diario dei sogni" ||
            entries.any { it.second == "diario-sogni-archive.json" }) return parent
        return entries.firstOrNull { it.second == "Diario dei sogni" }?.first
            ?: DocumentsContract.createDocument(resolver, parent, DocumentsContract.Document.MIME_TYPE_DIR, "Diario dei sogni")
            ?: throw IllegalStateException("Creazione cartella fallita")
    }

    private fun children(parent: Uri): List<Pair<Uri, String>> {
        val result = mutableListOf<Pair<Uri, String>>()
        val uri = DocumentsContract.buildChildDocumentsUriUsingTree(parent, DocumentsContract.getDocumentId(parent))
        resolver.query(uri, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME), null, null, null)?.use {
            while (it.moveToNext()) result.add(Pair(DocumentsContract.buildDocumentUriUsingTree(parent, it.getString(0)), it.getString(1)))
        } ?: throw IllegalStateException("Cartella non leggibile")
        return result
    }
}
