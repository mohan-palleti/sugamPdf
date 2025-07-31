import "dart:io";
import "package:flutter/material.dart";

class ImageEditorScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditorScreen({super.key, required this.imagePath});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  late File _imageFile;
  bool _isProcessing = false;
  int _rotationDegrees = 0;
  bool _isGrayscale = false;

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
  }

  Future<void> _cropImage() async {
    // Show dialog explaining that cropping is not available in this version
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Not Available'),
        content: const Text(
          'For this version, cropping is not available due to plugin compatibility issues. '
          'You can still rotate the image and apply filters.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _rotateLeft() {
    setState(() {
      _rotationDegrees = (_rotationDegrees - 90) % 360;
    });
  }
  
  void _rotateRight() {
    setState(() {
      _rotationDegrees = (_rotationDegrees + 90) % 360;
    });
  }
  
  void _toggleGrayscale() {
    setState(() {
      _isGrayscale = !_isGrayscale;
    });
  }

  Future<void> _saveAndExit() async {
    Navigator.of(context).pop(_imageFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Image"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAndExit,
            tooltip: "Save",
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: _isProcessing
                ? const CircularProgressIndicator()
                : ColorFiltered(
                    colorFilter: _isGrayscale
                        ? const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 1, 0,
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.srcOver,
                          ),
                    child: Transform.rotate(
                      angle: _rotationDegrees * 3.14159 / 180,
                      child: Image.file(
                        _imageFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.crop,
              label: "Crop",
              onPressed: _cropImage,
            ),
            _buildActionButton(
              icon: Icons.rotate_left,
              label: "Rotate L",
              onPressed: _rotateLeft,
            ),
            _buildActionButton(
              icon: Icons.rotate_right,
              label: "Rotate R",
              onPressed: _rotateRight,
            ),
            _buildActionButton(
              icon: _isGrayscale ? Icons.color_lens : Icons.monochrome_photos,
              label: _isGrayscale ? "Color" : "B&W",
              onPressed: _toggleGrayscale,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
