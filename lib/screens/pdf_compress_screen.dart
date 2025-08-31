import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/page_ops/page_ops_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../blocs/page_ops/page_ops_event.dart';
import '../blocs/page_ops/page_ops_state.dart';

class PdfCompressScreen extends StatefulWidget {
  final String pdfPath;
  const PdfCompressScreen({super.key, required this.pdfPath});
  @override
  State<PdfCompressScreen> createState() => _PdfCompressScreenState();
}

class _PdfCompressScreenState extends State<PdfCompressScreen> {
  double _scale = 0.7;
  int _quality = 70;
  bool _started = false;
  bool _loadingPrefs = true;
  static const _kScaleKey = 'compress_last_scale';
  static const _kQualityKey = 'compress_last_quality';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _scale = prefs.getDouble(_kScaleKey) ?? _scale;
        _quality = prefs.getInt(_kQualityKey) ?? _quality;
        _loadingPrefs = false;
      });
    } catch (_) {
      setState(()=> _loadingPrefs = false);
    }
  }

  Future<void> _persistPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kScaleKey, _scale);
    await prefs.setInt(_kQualityKey, _quality);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageOpsBloc()..add(LoadPageThumbnails(widget.pdfPath)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Compress PDF')),
        body: BlocConsumer<PageOpsBloc, PageOpsState>(
          listener: (context, state) {
            if (state is PageOpsResult) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compression complete')));
            }
            if (state is PageOpsError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is PageOpsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PageOpsProgress) {
              return _ProgressView(progress: state.progress, stage: state.stage, onCancel: () {
                context.read<PageOpsBloc>().add(CancelOpsEvent());
                Navigator.pop(context);
              });
            }
            if (_loadingPrefs) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PageOpsLoaded) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Original pages: ${state.workingOrder.length}'),
                    const SizedBox(height: 16),
                    Text('Scale (${_scale.toStringAsFixed(2)})'),
                    Slider(
                      value: _scale,
                      min: 0.3,
                      max: 1.0,
                      divisions: 7,
                      label: _scale.toStringAsFixed(2),
                      onChanged: (v) async {
                        setState(()=> _scale = v);
                        await _persistPrefs();
                      },
                    ),
                    const SizedBox(height: 8),
                    Text('Quality ($_quality)'),
                    Slider(
                      value: _quality.toDouble(),
                      min: 40,
                      max: 100,
                      divisions: 12,
                      label: _quality.toString(),
                      onChanged: (v) async {
                        setState(()=> _quality = v.toInt());
                        await _persistPrefs();
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.compress),
                        label: const Text('Start Compression'),
                        onPressed: _started ? null : () {
                          setState(()=> _started = true);
                          final output = widget.pdfPath.replaceAll('.pdf', '_compressed.pdf');
                          context.read<PageOpsBloc>().add(CompressPdfEvent(scale: _scale, quality: _quality, outputPath: output));
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is PageOpsResult) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Output file:'),
                  const SizedBox(height: 12),
                  for (final p in state.outputPaths) ListTile(title: Text(p.split('/').last), subtitle: Text(p)),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ProgressView extends StatelessWidget {
  final double progress; final String stage; final VoidCallback? onCancel;
  const _ProgressView({required this.progress, required this.stage, this.onCancel});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: progress == 0 || progress == 1 ? null : progress),
            const SizedBox(height: 16),
            Text(stage),
            const SizedBox(height: 24),
            if (onCancel != null)
              OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
              ),
          ],
        ),
      ),
    );
  }
}
