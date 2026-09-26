import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/export_service.dart';

/// Separate page that lists every PDF/Excel/PNG that has been
/// generated and saved, with options to open/share/preview each.
class ExportsScreen extends StatefulWidget {
  const ExportsScreen({super.key});

  @override
  State<ExportsScreen> createState() => _ExportsScreenState();
}

class _ExportsScreenState extends State<ExportsScreen> {
  List<File> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final files = await ExportService.listSavedExports();
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  void _previewImage(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(file.path.split('/').last),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => ExportService.shareFile(file),
              ),
            ],
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image.file(file),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved PDF / Excel / Image Files'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(
                  child: Text(
                      'No exports yet. Generate a PDF/Excel/Image from the attendance tab.'))
              : ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, i) {
                    final file = _files[i];
                    final isPdf = file.path.endsWith('.pdf');
                    final isPng = file.path.endsWith('.png');

                    Widget leading;
                    if (isPng) {
                      leading = ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          file,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      );
                    } else {
                      leading = Icon(
                        isPdf ? Icons.picture_as_pdf : Icons.table_chart,
                        color: isPdf ? Colors.red : Colors.green,
                      );
                    }

                    return ListTile(
                      leading: leading,
                      title: Text(file.path.split('/').last),
                      subtitle: Text(file.statSync().modified.toString()),
                      onTap: isPng ? () => _previewImage(file) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPdf)
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => Printing.layoutPdf(
                                  onLayout: (_) => file.readAsBytes()),
                            ),
                          if (isPng)
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _previewImage(file),
                            ),
                          IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () => ExportService.shareFile(file),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
