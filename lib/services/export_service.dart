// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:excel/excel.dart' as xls;
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:share_plus/share_plus.dart';

// import '../models/member.dart';
// import '../models/attendance_record.dart';

// /// One row combining a member with their attendance for the exported date.
// class ExportRow {
//   final Member member;
//   final AttendanceRecord? record;
//   ExportRow(this.member, this.record);
// }

// class ExportService {
//   static Future<Directory> exportsDir() async {
//     final base = await getApplicationDocumentsDirectory();
//     final dir = Directory('${base.path}/SewadalHajariExports');
//     if (!await dir.exists()) {
//       await dir.create(recursive: true);
//     }
//     return dir;
//   }

//   static String _fileSafeDate(String date) => date.replaceAll('/', '-');

//   // ------------------------------------------------------------------
//   // Shared PDF document builder - used by both exportPdf and exportPng,
//   // so the PNG is always a pixel-accurate rasterization of the PDF.
//   // ------------------------------------------------------------------
//   static Future<Uint8List> _buildPdfBytes({
//     required String category,
//     required String day,
//     required String date,
//     required List<ExportRow> rows,
//     required String sanchalakName,
//     required String shikshakName,
//   }) async {
//     final doc = pw.Document();

//     // Split members into two side-by-side blocks, like the printed chart.
//     final splitIndex = (rows.length / 2).ceil();
//     final leftRows = rows.sublist(0, splitIndex);
//     final rightRows = rows.sublist(splitIndex);
//     final maxLen = leftRows.length > rightRows.length
//         ? leftRows.length
//         : rightRows.length;

//     List<String> rowData(ExportRow? r) {
//       if (r == null) return ['', '', '', '', ''];
//       final rec = r.record;
//       return [
//         r.member.srNo.toString(),
//         r.member.name,
//         '${r.member.perNo} ${r.member.snsdNo}'.trim(),
//         rec?.status ?? '',
//         rec?.pvTime ?? '',
//       ];
//     }

//     final headers = [
//       'Sr.No',
//       'Name',
//       'Per.No',
//       'Pre/Ab',
//       'PV/CV Time',
//       'Sr.No',
//       'Name',
//       'Per.No',
//       'Pre/Ab',
//       'PV/CV Time',
//     ];

//     final data = <List<String>>[];
//     for (var i = 0; i < maxLen; i++) {
//       final left = rowData(i < leftRows.length ? leftRows[i] : null);
//       final right = rowData(i < rightRows.length ? rightRows[i] : null);
//       data.add([...left, ...right]);
//     }

//     doc.addPage(
//       pw.MultiPage(
//         pageTheme: pw.PageTheme(
//           pageFormat: PdfPageFormat.a4,
//           margin: const pw.EdgeInsets.all(16),
//           // Force an opaque white page background. Without this, the PDF
//           // page is transparent, and when rasterized to PNG for sharing,
//           // viewers that don't support transparency (e.g. WhatsApp) render
//           // it as solid black - making all the black text invisible.
//           buildBackground: (context) => pw.FullPage(
//             ignoreMargins: true,
//             child: pw.Container(color: PdfColors.white),
//           ),
//         ),
//         header: (context) {
//           // Only show the full title/subtitle/day-date block on the first
//           // page. Without this check, MultiPage calls header() on every
//           // page, so the title would print again at the top of page 2+.
//           if (context.pageNumber > 1) {
//             return pw.SizedBox(height: 6);
//           }
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.center,
//             children: [
//               pw.Text(
//                 'WEEKLY SATSANG ATTENDANCE CHART - ${category.toUpperCase()}',
//                 style: pw.TextStyle(
//                     fontSize: 14, fontWeight: pw.FontWeight.bold),
//               ),
//               pw.SizedBox(height: 3),
//               pw.Text('IIT SURYA NAGAR - UNIT NO. 1740',
//                   style: const pw.TextStyle(fontSize: 10)),
//               pw.SizedBox(height: 6),
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Text('DAY: $day', style: const pw.TextStyle(fontSize: 9)),
//                   pw.Text('DATE: $date',
//                       style: const pw.TextStyle(fontSize: 9)),
//                 ],
//               ),
//               pw.SizedBox(height: 8),
//             ],
//           );
//         },
//         // NOTE: no `footer:` here on purpose. MultiPage's footer is pinned
//         // to the bottom of every page, which left a large empty gap between
//         // the table and the signature block whenever the table didn't fill
//         // the page. Instead, the signature block is now the last item in
//         // `build:` below, so it sits immediately after the table content.
//         build: (context) => [
//           pw.TableHelper.fromTextArray(
//             headers: headers,
//             data: data,
//             headerStyle:
//                 pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5),
//             headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
//             headerPadding:
//                 const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
//             cellStyle: const pw.TextStyle(fontSize: 6),
//             cellPadding:
//                 const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2.5),
//             cellAlignment: pw.Alignment.centerLeft,
//             border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.4),
//             // Narrower Pre/Ab and PV/CV Time columns; extra space given to Name.
//             columnWidths: {
//               0: const pw.FlexColumnWidth(0.5), // Sr.No
//               1: const pw.FlexColumnWidth(2.0), // Name
//               2: const pw.FlexColumnWidth(1.0), // Per.No
//               3: const pw.FlexColumnWidth(0.55), // Pre/Ab
//               4: const pw.FlexColumnWidth(0.85), // PV/CV Time
//               5: const pw.FlexColumnWidth(0.5),
//               6: const pw.FlexColumnWidth(2.0),
//               7: const pw.FlexColumnWidth(1.0),
//               8: const pw.FlexColumnWidth(0.55),
//               9: const pw.FlexColumnWidth(0.85),
//             },
//           ),
//           pw.SizedBox(height: 24),
//           pw.Row(
//             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//             children: [
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text('SANCHALAK', style: const pw.TextStyle(fontSize: 8)),
//                   pw.Text(sanchalakName,
//                       style: pw.TextStyle(
//                           fontSize: 8, fontWeight: pw.FontWeight.bold)),
//                   pw.Text('SIGN: ____________',
//                       style: const pw.TextStyle(fontSize: 8)),
//                 ],
//               ),
//               pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text('SHIKSHAK', style: const pw.TextStyle(fontSize: 8)),
//                   pw.Text(shikshakName,
//                       style: pw.TextStyle(
//                           fontSize: 8, fontWeight: pw.FontWeight.bold)),
//                   pw.Text('SIGN: ____________',
//                       style: const pw.TextStyle(fontSize: 8)),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );

//     return doc.save();
//   }

//   // ------------------------------------------------------------------
//   // PDF export - writes the shared PDF bytes to a .pdf file
//   // ------------------------------------------------------------------
//   static Future<File> exportPdf({
//     required String category, // 'Gents' or 'Ladies'
//     required String day,
//     required String date,
//     required List<ExportRow> rows,
//     required String sanchalakName,
//     required String shikshakName,
//   }) async {
//     final pdfBytes = await _buildPdfBytes(
//       category: category,
//       day: day,
//       date: date,
//       rows: rows,
//       sanchalakName: sanchalakName,
//       shikshakName: shikshakName,
//     );

//     final dir = await exportsDir();
//     final fileName = 'Hajari_${category}_${_fileSafeDate(date)}.pdf';
//     final file = File('${dir.path}/$fileName');
//     await file.writeAsBytes(pdfBytes);
//     return file;
//   }

//   // ------------------------------------------------------------------
//   // PNG export - rasterizes the PDF into a shareable image.
//   //
//   // IMPORTANT: with a large member list, the PDF can span more than one
//   // page. If we only rasterized the first page, everyone after the page
//   // break would silently disappear from the shared image. So instead we
//   // rasterize every page and stitch them vertically into one tall PNG -
//   // nothing is ever lost, regardless of how many members there are.
//   // ------------------------------------------------------------------
//   static Future<File> exportPng({
//     required String category,
//     required String day,
//     required String date,
//     required List<ExportRow> rows,
//     required String sanchalakName,
//     required String shikshakName,
//   }) async {
//     final pdfBytes = await _buildPdfBytes(
//       category: category,
//       day: day,
//       date: date,
//       rows: rows,
//       sanchalakName: sanchalakName,
//       shikshakName: shikshakName,
//     );

//     // Rasterize at a high DPI so the exported chart stays sharp/readable.
//     final rasterPages = await Printing.raster(pdfBytes, dpi: 220).toList();
//     final pngBytes = await _composePng(rasterPages);

//     final dir = await exportsDir();
//     final fileName = 'Hajari_${category}_${_fileSafeDate(date)}.png';
//     final file = File('${dir.path}/$fileName');
//     await file.writeAsBytes(pngBytes);
//     return file;
//   }

//   /// Scans a rasterized page from the bottom up and returns the y-coordinate
//   /// of the lowest non-white pixel row (i.e. where real content ends).
//   /// Used to crop away the blank space left below the content on a fixed
//   /// A4-height page.
//   static int _findContentBottom(PdfRaster raster) {
//     final pixels = raster.pixels; // raw RGBA bytes
//     final width = raster.width;
//     final height = raster.height;
//     const whiteThreshold = 250; // treat near-white as blank

//     for (int y = height - 1; y >= 0; y--) {
//       final rowStart = y * width * 4;
//       for (int x = 0; x < width; x++) {
//         final i = rowStart + x * 4;
//         if (pixels[i] < whiteThreshold ||
//             pixels[i + 1] < whiteThreshold ||
//             pixels[i + 2] < whiteThreshold) {
//           return y;
//         }
//       }
//     }
//     return height - 1;
//   }

//   /// Decodes each rasterized PDF page into a ui.Image, trims the blank
//   /// space below the content on the last page (where the fixed A4 page
//   /// height otherwise leaves a large empty gap under the signature row),
//   /// and draws every page's content onto one composite canvas - stacked
//   /// vertically if there's more than one page.
//   static Future<Uint8List> _composePng(List<PdfRaster> rasterPages) async {
//     Future<ui.Image> decode(PdfRaster raster) {
//       final completer = Completer<ui.Image>();
//       ui.decodeImageFromPixels(
//         raster.pixels,
//         raster.width,
//         raster.height,
//         ui.PixelFormat.rgba8888,
//         completer.complete,
//       );
//       return completer.future;
//     }

//     final images = <ui.Image>[];
//     for (final raster in rasterPages) {
//       images.add(await decode(raster));
//     }

//     // Only the LAST page needs bottom-trimming - earlier pages (if the
//     // list spans multiple pages) are filled with table rows and don't
//     // have trailing blank space.
//     const bottomPadding = 24; // small breathing room below the content
//     final lastRaster = rasterPages.last;
//     final contentBottom = _findContentBottom(lastRaster);
//     final trimmedLastHeight =
//         (contentBottom + bottomPadding).clamp(1, images.last.height);

//     final width =
//         images.map((img) => img.width).reduce((a, b) => a > b ? a : b);
//     int totalHeight = 0;
//     for (var i = 0; i < images.length; i++) {
//       totalHeight +=
//           (i == images.length - 1) ? trimmedLastHeight : images[i].height;
//     }

//     final recorder = ui.PictureRecorder();
//     final canvas = ui.Canvas(recorder);

//     canvas.drawRect(
//       ui.Rect.fromLTWH(0, 0, width.toDouble(), totalHeight.toDouble()),
//       ui.Paint()..color = const ui.Color(0xFFFFFFFF),
//     );

//     double yOffset = 0;
//     for (var i = 0; i < images.length; i++) {
//       final img = images[i];
//       final isLast = i == images.length - 1;
//       final drawHeight = isLast ? trimmedLastHeight : img.height;

//       canvas.drawImageRect(
//         img,
//         ui.Rect.fromLTWH(0, 0, img.width.toDouble(), drawHeight.toDouble()),
//         ui.Rect.fromLTWH(
//             0, yOffset, img.width.toDouble(), drawHeight.toDouble()),
//         ui.Paint(),
//       );
//       yOffset += drawHeight;
//     }

//     final picture = recorder.endRecording();
//     final composite = await picture.toImage(width, totalHeight);
//     final byteData =
//         await composite.toByteData(format: ui.ImageByteFormat.png);
//     return byteData!.buffer.asUint8List();
//   }

//   // ------------------------------------------------------------------
//   // Excel export - same columns, one sheet per category
//   // ------------------------------------------------------------------
//   static Future<File> exportExcel({
//     required String category,
//     required String day,
//     required String date,
//     required List<ExportRow> rows,
//   }) async {
//     final workbook = xls.Excel.createExcel();
//     final sheetName = category;
//     final sheet = workbook[sheetName];
//     workbook.setDefaultSheet(sheetName);
//     if (workbook.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
//       workbook.delete('Sheet1');
//     }

//     sheet.appendRow([
//       xls.TextCellValue(
//           'WEEKLY SATSANG ATTENDANCE CHART - ${category.toUpperCase()}')
//     ]);
//     sheet.appendRow([xls.TextCellValue('IIT SURYA NAGAR - UNIT NO. 1740')]);
//     sheet.appendRow([
//       xls.TextCellValue('DAY: $day'),
//       xls.TextCellValue('DATE: $date'),
//     ]);
//     sheet.appendRow([]);

//     sheet.appendRow([
//       xls.TextCellValue('Sr.No'),
//       xls.TextCellValue('Name'),
//       xls.TextCellValue('Per.No'),
//       xls.TextCellValue('Pre/Ab'),
//       xls.TextCellValue('PV/CV Time'),
//     ]);

//     for (final r in rows) {
//       final rec = r.record;
//       sheet.appendRow([
//         xls.IntCellValue(r.member.srNo),
//         xls.TextCellValue(r.member.name),
//         xls.TextCellValue('${r.member.perNo} ${r.member.snsdNo}'.trim()),
//         xls.TextCellValue(rec?.status ?? ''),
//         xls.TextCellValue(rec?.pvTime ?? ''),
//       ]);
//     }

//     final dir = await exportsDir();
//     final fileName = 'Hajari_${category}_${_fileSafeDate(date)}.xlsx';
//     final file = File('${dir.path}/$fileName');
//     final bytes = workbook.encode();
//     await file.writeAsBytes(bytes!);
//     return file;
//   }

//   static Future<void> shareFile(File file) async {
//     await Share.shareXFiles([XFile(file.path)],
//         text: 'Sewadal Hajari - ${file.path.split('/').last}');
//   }

//   static Future<List<File>> listSavedExports() async {
//     final dir = await exportsDir();
//     final files = dir
//         .listSync()
//         .whereType<File>()
//         .where((f) =>
//             f.path.endsWith('.pdf') ||
//             f.path.endsWith('.xlsx') ||
//             f.path.endsWith('.png'))
//         .toList();
//     files
//         .sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
//     return files;
//   }
// }

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/member.dart';
import '../models/attendance_record.dart';

/// One row combining a member with their attendance for the exported date.
class ExportRow {
  final Member member;
  final AttendanceRecord? record;
  ExportRow(this.member, this.record);
}

class ExportService {
  static Future<Directory> exportsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/SewadalHajariExports');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _fileSafeDate(String date) => date.replaceAll('/', '-');

  // ------------------------------------------------------------------
  // Custom report header (printed above "WEEKLY SATSANG ATTENDANCE CHART"
  // in every PDF, PNG and Excel file). Stored in a small text file so it
  // survives app restarts. Empty text = no header line.
  // ------------------------------------------------------------------
  static Future<File> _headerFile() async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}/report_header.txt');
  }

  /// Returns the saved header exactly as stored ('' if none).
  static Future<String> loadHeader() async {
    try {
      final f = await _headerFile();
      if (!await f.exists()) return '';
      return (await f.readAsString()).trim();
    } catch (_) {
      return '';
    }
  }

  static Future<void> saveHeader(String text) async {
    final f = await _headerFile();
    await f.writeAsString(text.trim());
  }

  // ------------------------------------------------------------------
  // Shared PDF document builder - used by both exportPdf and exportPng,
  // so the PNG is always a pixel-accurate rasterization of the PDF.
  // ------------------------------------------------------------------
  static Future<Uint8List> _buildPdfBytes({
    required String category,
    required String day,
    required String date,
    required List<ExportRow> rows,
    required String sanchalakName,
    required String shikshakName,
  }) async {
    final headerText = (await loadHeader()).toUpperCase();
    final doc = pw.Document();
    _addChartPage(
      doc,
      headerText: headerText,
      category: category,
      day: day,
      date: date,
      rows: rows,
      sanchalakName: sanchalakName,
      shikshakName: shikshakName,
    );
    return doc.save();
  }

  // ------------------------------------------------------------------
  // Combined PDF - Gents and Ladies added as consecutive pages of the
  // SAME document/file, instead of two separate files.
  // ------------------------------------------------------------------
  static Future<Uint8List> _buildCombinedPdfBytes({
    required String day,
    required String date,
    required List<ExportRow> gentsRows,
    required List<ExportRow> ladiesRows,
    required String gentsSanchalakName,
    required String gentsShikshakName,
    required String ladiesSanchalakName,
    required String ladiesShikshakName,
  }) async {
    final headerText = (await loadHeader()).toUpperCase();
    final doc = pw.Document();
    _addChartPage(
      doc,
      headerText: headerText,
      category: 'Gents',
      day: day,
      date: date,
      rows: gentsRows,
      sanchalakName: gentsSanchalakName,
      shikshakName: gentsShikshakName,
    );
    _addChartPage(
      doc,
      headerText: headerText,
      category: 'Ladies',
      day: day,
      date: date,
      rows: ladiesRows,
      sanchalakName: ladiesSanchalakName,
      shikshakName: ladiesShikshakName,
    );
    return doc.save();
  }

  /// Adds one category's chart (header + two-column table + signature
  /// block) as a page/pages onto an existing [doc]. Shared by the
  /// single-category export and the combined Gents+Ladies export.
  ///
  /// NOTE: this must NOT call doc.save() - the caller saves once, after
  /// all pages have been added.
  static void _addChartPage(
    pw.Document doc, {
    required String headerText,
    required String category,
    required String day,
    required String date,
    required List<ExportRow> rows,
    required String sanchalakName,
    required String shikshakName,
  }) {
    // Split members into two side-by-side blocks, like the printed chart.
    final splitIndex = (rows.length / 2).ceil();
    final leftRows = rows.sublist(0, splitIndex);
    final rightRows = rows.sublist(splitIndex);
    final maxLen =
        leftRows.length > rightRows.length ? leftRows.length : rightRows.length;

    List<String> rowData(ExportRow? r) {
      if (r == null) return ['', '', '', ''];
      final rec = r.record;
      return [
        r.member.srNo.toString(),
        r.member.name,
        '${r.member.perNo} ${r.member.snsdNo}'.trim(),
        rec?.pvTime ?? '',
      ];
    }

    final headers = [
      'Sr.No',
      'Name',
      'Per.No',
      'PV/CV Time',
      'Sr.No',
      'Name',
      'Per.No',
      'PV/CV Time',
    ];

    final data = <List<String>>[];
    for (var i = 0; i < maxLen; i++) {
      final left = rowData(i < leftRows.length ? leftRows[i] : null);
      final right = rowData(i < rightRows.length ? rightRows[i] : null);
      data.add([...left, ...right]);
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          // Force an opaque white page background. Without this, the PDF
          // page is transparent, and when rasterized to PNG for sharing,
          // viewers that don't support transparency (e.g. WhatsApp) render
          // it as solid black - making all the black text invisible.
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: PdfColors.white),
          ),
        ),
        header: (context) {
          // Only show the full title/subtitle/day-date block on the first
          // page. Without this check, MultiPage calls header() on every
          // page, so the title would print again at the top of page 2+.
          if (context.pageNumber > 1) {
            return pw.SizedBox(height: 6);
          }
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Custom header line - always uppercase and centered.
              if (headerText.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    headerText,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 6),
              ],
              pw.Text(
                'WEEKLY SATSANG ATTENDANCE CHART - ${category.toUpperCase()}',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 3),
              pw.Text('IIT SURYA NAGAR - UNIT NO. 1740',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DAY: $day', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('DATE: $date',
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
        // NOTE: no `footer:` here on purpose. MultiPage's footer is pinned
        // to the bottom of every page, which left a large empty gap between
        // the table and the signature block whenever the table didn't fill
        // the page. Instead, the signature block is now the last item in
        // `build:` below, so it sits immediately after the table content.
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerPadding:
                const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            cellStyle: const pw.TextStyle(fontSize: 6),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2.5),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.4),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.4), // Sr.No
              1: const pw.FlexColumnWidth(2.2), // Name
              2: const pw.FlexColumnWidth(1.0), // Per.No
              3: const pw.FlexColumnWidth(0.85), // PV/CV Time
              4: const pw.FlexColumnWidth(0.4),
              5: const pw.FlexColumnWidth(2.2),
              6: const pw.FlexColumnWidth(1.0),
              7: const pw.FlexColumnWidth(0.85),
            },
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('SANCHALAK', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(sanchalakName,
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('SIGN: ____________',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('SHIKSHAK', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(shikshakName,
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('SIGN: ____________',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // PDF export - writes the shared PDF bytes to a .pdf file
  // ------------------------------------------------------------------
  static Future<File> exportPdf({
    required String category, // 'Gents' or 'Ladies'
    required String day,
    required String date,
    required List<ExportRow> rows,
    required String sanchalakName,
    required String shikshakName,
  }) async {
    final pdfBytes = await _buildPdfBytes(
      category: category,
      day: day,
      date: date,
      rows: rows,
      sanchalakName: sanchalakName,
      shikshakName: shikshakName,
    );

    final dir = await exportsDir();
    final fileName = 'Hajari_${category}_${_fileSafeDate(date)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  // ------------------------------------------------------------------
  // PNG export - rasterizes the PDF into a shareable image.
  //
  // IMPORTANT: with a large member list, the PDF can span more than one
  // page. If we only rasterized the first page, everyone after the page
  // break would silently disappear from the shared image. So instead we
  // rasterize every page and stitch them vertically into one tall PNG -
  // nothing is ever lost, regardless of how many members there are.
  // ------------------------------------------------------------------
  static Future<File> exportPng({
    required String category,
    required String day,
    required String date,
    required List<ExportRow> rows,
    required String sanchalakName,
    required String shikshakName,
  }) async {
    final pdfBytes = await _buildPdfBytes(
      category: category,
      day: day,
      date: date,
      rows: rows,
      sanchalakName: sanchalakName,
      shikshakName: shikshakName,
    );

    // Rasterize at a high DPI so the exported chart stays sharp/readable.
    final rasterPages = await Printing.raster(pdfBytes, dpi: 220).toList();
    final pngBytes = await _composePng(rasterPages);

    final dir = await exportsDir();
    final fileName = 'Hajari_${category}_${_fileSafeDate(date)}.png';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pngBytes);
    return file;
  }

  /// Scans a rasterized page from the bottom up and returns the y-coordinate
  /// of the lowest non-white pixel row (i.e. where real content ends).
  /// Used to crop away the blank space left below the content on a fixed
  /// A4-height page.
  static int _findContentBottom(PdfRaster raster) {
    final pixels = raster.pixels; // raw RGBA bytes
    final width = raster.width;
    final height = raster.height;
    const whiteThreshold = 250; // treat near-white as blank

    for (int y = height - 1; y >= 0; y--) {
      final rowStart = y * width * 4;
      for (int x = 0; x < width; x++) {
        final i = rowStart + x * 4;
        if (pixels[i] < whiteThreshold ||
            pixels[i + 1] < whiteThreshold ||
            pixels[i + 2] < whiteThreshold) {
          return y;
        }
      }
    }
    return height - 1;
  }

  /// Decodes each rasterized PDF page into a ui.Image, trims the blank
  /// space below the content on the last page (where the fixed A4 page
  /// height otherwise leaves a large empty gap under the signature row),
  /// and draws every page's content onto one composite canvas - stacked
  /// vertically if there's more than one page.
  static Future<Uint8List> _composePng(List<PdfRaster> rasterPages) async {
    Future<ui.Image> decode(PdfRaster raster) {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        raster.pixels,
        raster.width,
        raster.height,
        ui.PixelFormat.rgba8888,
        completer.complete,
      );
      return completer.future;
    }

    final images = <ui.Image>[];
    for (final raster in rasterPages) {
      images.add(await decode(raster));
    }

    // Only the LAST page needs bottom-trimming - earlier pages (if the
    // list spans multiple pages) are filled with table rows and don't
    // have trailing blank space.
    const bottomPadding = 24; // small breathing room below the content
    final lastRaster = rasterPages.last;
    final contentBottom = _findContentBottom(lastRaster);
    final trimmedLastHeight =
        (contentBottom + bottomPadding).clamp(1, images.last.height);

    final width =
        images.map((img) => img.width).reduce((a, b) => a > b ? a : b);
    int totalHeight = 0;
    for (var i = 0; i < images.length; i++) {
      totalHeight +=
          (i == images.length - 1) ? trimmedLastHeight : images[i].height;
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width.toDouble(), totalHeight.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );

    double yOffset = 0;
    for (var i = 0; i < images.length; i++) {
      final img = images[i];
      final isLast = i == images.length - 1;
      final drawHeight = isLast ? trimmedLastHeight : img.height;

      canvas.drawImageRect(
        img,
        ui.Rect.fromLTWH(0, 0, img.width.toDouble(), drawHeight.toDouble()),
        ui.Rect.fromLTWH(
            0, yOffset, img.width.toDouble(), drawHeight.toDouble()),
        ui.Paint(),
      );
      yOffset += drawHeight;
    }

    final picture = recorder.endRecording();
    final composite = await picture.toImage(width, totalHeight);
    final byteData = await composite.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ------------------------------------------------------------------
  // Excel export - same columns, one sheet per category
  // ------------------------------------------------------------------
  static Future<File> exportExcel({
    required String category,
    required String day,
    required String date,
    required List<ExportRow> rows,
  }) async {
    final workbook = xls.Excel.createExcel();
    final sheetName = category;
    final sheet = workbook[sheetName];
    workbook.setDefaultSheet(sheetName);
    if (workbook.sheets.containsKey('Sheet1') && sheetName != 'Sheet1') {
      workbook.delete('Sheet1');
    }

    // Custom header: first row, uppercase, merged across the 4 table
    // columns (A-D) and centered.
    final headerText = (await loadHeader()).toUpperCase();
    if (headerText.isNotEmpty) {
      sheet.appendRow([xls.TextCellValue(headerText)]);
      sheet.merge(
        xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        xls.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
      );
      sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .cellStyle = xls.CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: xls.HorizontalAlign.Center,
      );
    }

    sheet.appendRow([
      xls.TextCellValue(
          'WEEKLY SATSANG ATTENDANCE CHART - ${category.toUpperCase()}')
    ]);
    sheet.appendRow([xls.TextCellValue('IIT SURYA NAGAR - UNIT NO. 1740')]);
    sheet.appendRow([
      xls.TextCellValue('DAY: $day'),
      xls.TextCellValue('DATE: $date'),
    ]);
    sheet.appendRow([]);

    sheet.appendRow([
      xls.TextCellValue('Sr.No'),
      xls.TextCellValue('Name'),
      xls.TextCellValue('Per.No'),
      xls.TextCellValue('PV/CV Time'),
    ]);

    for (final r in rows) {
      final rec = r.record;
      sheet.appendRow([
        xls.IntCellValue(r.member.srNo),
        xls.TextCellValue(r.member.name),
        xls.TextCellValue('${r.member.perNo} ${r.member.snsdNo}'.trim()),
        xls.TextCellValue(rec?.pvTime ?? ''),
      ]);
    }

    final dir = await exportsDir();
    final fileName = 'Hajari_${category}_${_fileSafeDate(date)}.xlsx';
    final file = File('${dir.path}/$fileName');
    final bytes = workbook.encode();
    await file.writeAsBytes(bytes!);
    return file;
  }

  static Future<void> shareFile(File file) async {
    await Share.shareXFiles([XFile(file.path)],
        text: 'Sewadal Hajari - ${file.path.split('/').last}');
  }

  static Future<List<File>> listSavedExports() async {
    final dir = await exportsDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.pdf') ||
            f.path.endsWith('.xlsx') ||
            f.path.endsWith('.png'))
        .toList();
    files
        .sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }
}