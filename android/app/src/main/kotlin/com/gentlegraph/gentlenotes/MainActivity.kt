package com.gentlegraph.gentlenotes

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val TAG = "GentleNotesNative"
    private val CHANNEL = "com.gentlegraph.gentlenotes/pdf_share"
    private var sharedPdfPath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate intent: $intent")
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent intent: $intent")
        handleIntent(intent)
        sendPdfPathToFlutter()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Method channel call: ${call.method}")
            if (call.method == "getSharedPdfPath") {
                Log.d(TAG, "getSharedPdfPath returned: $sharedPdfPath")
                result.success(sharedPdfPath)
                sharedPdfPath = null
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getFileName(uri: Uri): String {
        var result: String? = null
        if (uri.scheme == "content") {
            val cursor = contentResolver.query(uri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val index = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index != -1) {
                        result = it.getString(index)
                    }
                }
            }
        }
        if (result == null) {
            result = uri.path
            val cut = result?.lastIndexOf('/') ?: -1
            if (cut != -1) {
                result = result?.substring(cut + 1)
            }
        }
        var name = result ?: "shared_pdf.pdf"
        if (!name.lowercase().endsWith(".pdf")) {
            name += ".pdf"
        }
        Log.d(TAG, "Resolved filename: $name")
        return name
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            Log.d(TAG, "Intent is null")
            return
        }
        val action = intent.action
        val type = intent.type
        val data: Uri? = intent.data
        Log.d(TAG, "handleIntent action: $action, type: $type, data: $data")

        if (Intent.ACTION_VIEW == action && data != null) {
            val isPdf = type == "application/pdf" || data.path?.lowercase()?.endsWith(".pdf") == true
            if (isPdf) {
                try {
                    val cacheDir = cacheDir
                    val fileName = getFileName(data)
                    val tempFile = File(cacheDir, fileName)
                    Log.d(TAG, "Target cache file: ${tempFile.absolutePath}")
                    if (tempFile.exists()) {
                        tempFile.delete()
                    }
                    contentResolver.openInputStream(data)?.use { input ->
                        FileOutputStream(tempFile).use { output ->
                            input.copyTo(output)
                        }
                    }
                    sharedPdfPath = tempFile.absolutePath
                    Log.d(TAG, "Successfully cached PDF to: $sharedPdfPath")
                } catch (e: Exception) {
                    Log.e(TAG, "Error handling PDF sharing intent: ", e)
                    e.printStackTrace()
                }
            } else {
                Log.d(TAG, "Not a PDF file (action: $action, type: $type, path: ${data.path})")
            }
        }
    }

    private fun sendPdfPathToFlutter() {
        Log.d(TAG, "sendPdfPathToFlutter: $sharedPdfPath")
        flutterEngine?.let { engine ->
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("onPdfShared", sharedPdfPath)
        } ?: Log.d(TAG, "flutterEngine is null, cannot invoke onPdfShared")
    }
}
