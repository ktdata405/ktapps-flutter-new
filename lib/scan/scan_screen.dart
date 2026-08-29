import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ktppsflutter/core_constants.dart';
import 'scan_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;
  bool _isCameraReady = false;
  
  final List<XFile> _capturedImages = [];
  final ScanService _service = ScanService();
  
  late AnimationController _scanController;
  String _mode = 'Document';
  bool _isAuto = true;
  bool _showGrid = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![_selectedCameraIndex], ResolutionPreset.high, enableAudio: false);
      try {
        await _controller!.initialize();
        if (!mounted) return;
        setState(() => _isCameraReady = true);
      } catch (e) {
        debugPrint('Camera initialization error: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (!_isCameraReady || _controller!.value.isTakingPicture) return;

    try {
      final XFile image = await _controller!.takePicture();
      setState(() {
        _capturedImages.add(image);
      });
      // Visual feedback: simple flash effect or toast
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Captured (${_capturedImages.length})'), duration: const Duration(milliseconds: 500)));
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  void _finishScan() {
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No images captured yet.')));
      return;
    }
    _showUploadDialog();
  }

  void _showUploadDialog() {
    final folderController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Save Scan', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a folder name to organize these scans.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: folderController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Folder Name (e.g., Invoices)', hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.pop(context); _upload(folderController.text); }, child: const Text('Upload')),
        ],
      ),
    );
  }

  Future<void> _upload(String folderName) async {
    setState(() => _loading = true);
    final files = _capturedImages.map((x) => File(x.path)).toList();
    final ok = await _service.uploadFiles(files, folderName);
    setState(() => _loading = false);
    if (ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scans uploaded successfully!')));
      setState(() => _capturedImages.clear());
      Navigator.pushNamed(context, '/report/scan');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(child: CameraPreview(_controller!)),
          
          // Overlay Gradients
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.5)])))),

          // Grid Lines
          if (_showGrid) Positioned.fill(child: _buildGridLines()),

          // Viewfinder
          Center(child: _buildViewfinder()),

          // Header Controls
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

          // Mode Selector
          Positioned(bottom: 140, left: 0, right: 0, child: _buildModeSelector()),

          // Camera Actions
          Positioned(bottom: 40, left: 0, right: 0, child: _buildCameraActions()),

          if (_loading) Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderIcon(icon: Icons.flash_on, onTap: () {}),
                  const SizedBox(width: 16),
                  _HeaderIcon(text: _isAuto ? 'AUTO' : 'MANUAL', color: _isAuto ? Colors.indigoAccent : Colors.amber, onTap: () => setState(() => _isAuto = !_isAuto)),
                  const SizedBox(width: 16),
                  _HeaderIcon(icon: Icons.grid_4x4, onTap: () => setState(() => _showGrid = !_showGrid)),
                ],
              ),
            ),
            const SizedBox(width: 48), // Spacer
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    return AspectRatio(
      aspectRatio: 1 / 1.414,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(border: Border.all(color: Colors.white24, width: 1), borderRadius: BorderRadius.circular(12)),
        child: Stack(
        children: [
          // Scanning Line
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              return Positioned(
                top: _scanController.value * (MediaQuery.of(context).size.width * 0.8 * 1.414),
                left: 0, right: 0,
                child: Container(height: 2, decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.indigoAccent.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)], color: Colors.indigoAccent)),
              );
            },
          ),
          // Corners
          Positioned(top: 0, left: 0, child: _Corner(top: true, left: true)),
          Positioned(top: 0, right: 0, child: _Corner(top: true, left: false)),
          Positioned(bottom: 0, left: 0, child: _Corner(top: false, left: true)),
          Positioned(bottom: 0, right: 0, child: _Corner(top: false, left: false)),
        ],
      ),
    ),
    );
  }

  Widget _buildModeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ['Translate', 'Document', 'ID Card'].map((m) {
          final isSelected = _mode == m;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () => setState(() => _mode = m),
              child: Column(
                children: [
                  Text(m.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  if (isSelected) Container(margin: const EdgeInsets.only(top: 8), width: 4, height: 4, decoration: const BoxDecoration(color: Colors.indigoAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.indigoAccent, blurRadius: 4)])),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCameraActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gallery / Last captured
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/report/scan'),
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24), image: _capturedImages.isNotEmpty ? DecorationImage(image: FileImage(File(_capturedImages.last.path)), fit: BoxFit.cover) : null),
              child: _capturedImages.isEmpty ? const Icon(Icons.photo_library_outlined, color: Colors.white70) : null,
            ),
          ),
          // Capture Button
          InkWell(
            onTap: _capture,
            child: Container(
              width: 80, height: 80,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white38, width: 4)),
              child: Container(decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            ),
          ),
          // Finish Button
          InkWell(
            onTap: _finishScan,
            child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle, border: Border.all(color: Colors.white10)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.check, color: Colors.white, size: 28),
                  if (_capturedImages.isNotEmpty)
                    Positioned(top: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.indigoAccent, shape: BoxShape.circle), child: Text('${_capturedImages.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLines() {
    return GridView.count(crossAxisCount: 3, children: List.generate(9, (i) => Container(decoration: BoxDecoration(border: Border.all(color: Colors.white10, width: 0.5)))));
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData? icon; final String? text; final Color? color; final VoidCallback onTap;
  const _HeaderIcon({this.icon, this.text, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: icon != null ? Icon(icon, color: color ?? Colors.white70, size: 20) : Text(text!, style: TextStyle(color: color ?? Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)));
  }
}

class _Corner extends StatelessWidget {
  final bool top, left;
  const _Corner({required this.top, required this.left});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          left: left ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          right: !left ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
        ),
      ),
    );
  }
}
