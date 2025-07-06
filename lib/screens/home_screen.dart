import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Utility Home')),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          _FeatureTile(title: 'PDF Merge', icon: Icons.merge_type, route: '/pdf-merge'),
          _FeatureTile(title: 'Image to PDF', icon: Icons.image, route: '/image-to-pdf'),
          _FeatureTile(title: 'Camera to PDF', icon: Icons.camera_alt, route: '/camera-to-pdf'),
          _FeatureTile(title: 'PDF Viewer', icon: Icons.picture_as_pdf, route: '/pdf-viewer'),
          _FeatureTile(title: 'File Manager', icon: Icons.folder, route: '/file-manager'),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;
  const _FeatureTile({required this.title, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.deepPurple),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
