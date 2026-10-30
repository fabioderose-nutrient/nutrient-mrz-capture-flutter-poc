package io.nutrient.poc.mrzcapture

import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import com.pspdfkit.document.PdfDocumentLoader
import com.pspdfkit.document.processor.NewPage
import com.pspdfkit.document.processor.PageImage
import com.pspdfkit.document.processor.PagePosition
import com.pspdfkit.document.processor.PdfProcessor
import com.pspdfkit.document.processor.PdfProcessorTask
import com.pspdfkit.document.processor.ocr.OcrLanguage
import com.pspdfkit.utils.Size
import java.io.File

/**
 * On-device OCR using Nutrient Android SDK (`io.nutrient:nutrient-ocr`).
 *
 *   image file → PageImage from Uri → single-page PDF
 *      → PdfProcessorTask.performOcrOnPages({0}, ENGLISH)
 *      → PdfDocument.getPageText(0)
 *
 * Raw page text is returned to Dart; MRZ parsing (ICAO 9303) is in
 * [lib/services/mrz_parser.dart]. No network calls.
 */
class NutrientOcrBridge(private val ctx: Context) {

    fun ocrImage(imagePath: String): String {
        val file = File(imagePath)
        require(file.exists()) { "Image not found: $imagePath" }

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(imagePath, bounds)
        val pageSize = Size(bounds.outWidth.toFloat(), bounds.outHeight.toFloat())

        val pageImage = PageImage(ctx, Uri.fromFile(file), PagePosition.CENTER)

        val page = NewPage.emptyPage(pageSize)
            .withPageItem(pageImage)
            .build()

        // Step 1: image → PDF (no OCR). Splitting from OCR avoids a native
        // crash that happens when newPage + performOcrOnPages run in one task.
        val basePdf = File(ctx.cacheDir, "base_${System.currentTimeMillis()}.pdf")
        PdfProcessor.processDocument(PdfProcessorTask.newPage(page), basePdf)

        // Step 2: re-open + OCR.
        val ocrPdf = File(ctx.cacheDir, "ocr_${System.currentTimeMillis()}.pdf")
        val sourceDoc = PdfDocumentLoader.openDocument(ctx, Uri.fromFile(basePdf))
        val ocrTask = PdfProcessorTask.fromDocument(sourceDoc)
            .performOcrOnPages(setOf(0), OcrLanguage.ENGLISH)
        PdfProcessor.processDocument(ocrTask, ocrPdf)

        val pdf = PdfDocumentLoader.openDocument(ctx, Uri.fromFile(ocrPdf))
        return pdf.getPageText(0)
    }
}
