import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/page_ops/page_ops_bloc.dart';
import '../blocs/page_ops/page_ops_event.dart';
import '../blocs/page_ops/page_ops_state.dart';

class PdfSplitScreen extends StatefulWidget {
  final String pdfPath;
  const PdfSplitScreen({super.key, required this.pdfPath});
  @override
  State<PdfSplitScreen> createState() => _PdfSplitScreenState();
}

class _PdfSplitScreenState extends State<PdfSplitScreen> {
  final _rangesController = TextEditingController(text: '1-3,4-5');
  bool _started = false;

  @override
  void dispose() {
    _rangesController.dispose();
    super.dispose();
  }

  List<List<int>> _parseRanges(String input, int maxPage) {
    final cleaned = input.replaceAll(' ', '');
    final parts = cleaned.split(',');
    final ranges = <List<int>>[];
    final used = <int>{};
    for (final part in parts) {
      if (part.isEmpty) continue;
      if (part.contains('-')) {
        final segs = part.split('-');
        if (segs.length == 2) {
          final start = int.tryParse(segs[0]);
          final end = int.tryParse(segs[1]);
          if (start != null && end != null && start >=1 && end >= start && end <= maxPage) {
            bool overlap = false;
            for (int p = start; p <= end; p++) {
              if (used.contains(p)) { overlap = true; break; }
            }
            if (overlap) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Overlap detected in $part')));
              return [];
            }
            for (int p = start; p <= end; p++) { used.add(p); }
            ranges.add([start,end]);
          }
        }
      } else {
        final single = int.tryParse(part);
        if (single != null && single >=1 && single <= maxPage) {
          if (used.contains(single)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Overlap detected at $single')));
            return [];
          }
            used.add(single);
            ranges.add([single,single]);
        }
      }
    }
    return ranges;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageOpsBloc()..add(LoadPageThumbnails(widget.pdfPath)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Split PDF')),
        body: BlocConsumer<PageOpsBloc, PageOpsState>(
          listener: (context, state) {
            if (state is PageOpsResult) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Split complete')));
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
              return _ProgressView(
                progress: state.progress,
                stage: state.stage,
                onCancel: () {
                  context.read<PageOpsBloc>().add(CancelOpsEvent());
                  Navigator.pop(context);
                },
              );
            }
            if (state is PageOpsLoaded) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total pages: ${state.workingOrder.length}'),
                    const SizedBox(height: 12),
                    const Text('Enter ranges (e.g., 1-3,5,6-8)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rangesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Ranges',
                      ),
                      minLines: 1,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.call_split),
                      label: const Text('Split'),
                      onPressed: _started ? null : () {
                        final ranges = _parseRanges(_rangesController.text, state.workingOrder.length);
                        if (ranges.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid ranges.')));
                          return;
                        }
                        setState(()=> _started = true);
                        context.read<PageOpsBloc>().add(SplitPdfEvent(ranges));
                      },
                    ),
                  ],
                ),
              );
            }
            if (state is PageOpsResult) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Output files:'),
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
