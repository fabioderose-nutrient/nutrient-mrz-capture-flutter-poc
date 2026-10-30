package io.nutrient.poc.mrzcapture

import android.os.Bundle
import com.pspdfkit.Nutrient
import com.pspdfkit.initialization.InitializationOptions
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterFragmentActivity() {

    private val channelName = "io.nutrient.poc.mrzcapture/nutrient_ocr"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Required before any use of PdfProcessor / OCR / viewer APIs.
        // Eval mode — fully functional with a watermark on viewer output.
        Nutrient.initialize(applicationContext, InitializationOptions())
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val ocr = NutrientOcrBridge(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ocrImage" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("ARG", "missing path", null)
                            return@setMethodCallHandler
                        }
                        thread {
                            try {
                                val text = ocr.ocrImage(path)
                                runOnUiThread { result.success(text) }
                            } catch (t: Throwable) {
                                runOnUiThread {
                                    result.error("OCR", t.message ?: "unknown", null)
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
