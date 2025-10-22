import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

class CantoPdfPage extends StatefulWidget {
  final String pdfPath;
  final int startPage;
  final int endPage;

  const CantoPdfPage({
    super.key,
    required this.pdfPath,
    required this.startPage,
    required this.endPage,
  });

  @override
  State<CantoPdfPage> createState() => _CantoPdfPageState();
}

class _CantoPdfPageState extends State<CantoPdfPage> {
  List<Image> _pages = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadPdfPages();
  }

  Future<void> _loadPdfPages() async {
  try {
    final bytes = await rootBundle.load(widget.pdfPath);
    final document = await PdfDocument.openData(bytes.buffer.asUint8List());

    List<Image> pages = [];
    const double scale = 3; // aumenta la risoluzione

    for (int i = widget.startPage; i <= widget.endPage; i++) {
      final page = await document.getPage(i);

      // dimensioni aumentate per alta risoluzione
      final pageImage = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: PdfPageImageFormat.png,
      );

      pages.add(
        Image.memory(
          pageImage!.bytes,
          fit: BoxFit.contain,
        ),
      );

      await page.close();
    }

    setState(() {
      _pages = pages;
      _isLoading = false;
    });

    await document.close();
  } catch (e) {
    setState(() {
      _hasError = true;
      _isLoading = false;
    });
  }
}



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _pages.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Errore nel caricamento PDF')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Pagina $_currentPage di ${_pages.length}'),
      ),
      body: PageView.builder(
        itemCount: _pages.length,
        onPageChanged: (index) => setState(() => _currentPage = index + 1),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            child: Center(child: _pages[index]),
          );
        },
      ),
    );
  }
}
