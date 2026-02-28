import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen in-app viewer for certificate images and PDFs.
/// Uses Firebase Storage SDK (authenticated) to download files,
/// bypassing expired token / permission issues with raw URLs.
class CertificateViewerScreen extends StatefulWidget {
  final String url;
  final String fileName;
  final String? type;

  const CertificateViewerScreen({
    super.key,
    required this.url,
    required this.fileName,
    this.type,
  });

  @override
  State<CertificateViewerScreen> createState() =>
      _CertificateViewerScreenState();
}

class _CertificateViewerScreenState extends State<CertificateViewerScreen> {
  Uint8List? _imageBytes;
  bool _loading = true;
  String? _error;
  String? _freshDownloadUrl;

  String get _resolvedType {
    if (widget.type != null && widget.type!.isNotEmpty) {
      return widget.type!.toLowerCase();
    }
    final ext = widget.fileName.split('.').last.toLowerCase();
    return ext;
  }

  bool get _isImage {
    final t = _resolvedType;
    return t == 'jpg' || t == 'jpeg' || t == 'png' || t == 'gif' || t == 'webp';
  }

  bool get _isPdf {
    return _resolvedType == 'pdf';
  }

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  /// Tries to download the file using Firebase Storage SDK.
  /// Falls back to a fresh download URL if direct getData fails.
  Future<void> _loadFile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Get a reference from the stored URL
      final ref = FirebaseStorage.instance.refFromURL(widget.url);

      if (_isImage) {
        // Download image bytes directly via SDK (authenticated)
        final bytes = await ref.getData(10 * 1024 * 1024); // 10 MB max
        if (bytes != null) {
          setState(() {
            _imageBytes = bytes;
            _loading = false;
          });
          return;
        }
      }

      // For PDFs and other files, or if getData returned null,
      // get a fresh download URL with a new token
      final freshUrl = await ref.getDownloadURL();
      setState(() {
        _freshDownloadUrl = freshUrl;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Firebase Storage error: $e');
      // Last resort: keep the original URL
      setState(() {
        _freshDownloadUrl = widget.url;
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openInBrowser() async {
    final urlToOpen = _freshDownloadUrl ?? widget.url;
    try {
      final uri = Uri.parse(urlToOpen);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.fileName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            tooltip: 'Open in Browser',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _isImage
              ? _buildImageViewer(context)
              : _isPdf
                  ? _buildPdfPlaceholder(context)
                  : _buildGenericFile(context),
    );
  }

  Widget _buildImageViewer(BuildContext context) {
    if (_imageBytes != null) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Fallback: error state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Failed to load image',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadFile,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Open in Browser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'PDF Document',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open PDF in Browser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericFile(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.file_present, color: Colors.white54, size: 80),
            const SizedBox(height: 24),
            Text(
              widget.fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open in Browser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
