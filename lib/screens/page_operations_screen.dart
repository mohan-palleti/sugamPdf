import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/page_ops/page_ops_bloc.dart';
import '../blocs/page_ops/page_ops_event.dart';
import '../blocs/page_ops/page_ops_state.dart';

class PageOperationsScreen extends StatelessWidget {
  final String pdfPath;
  const PageOperationsScreen({super.key, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageOpsBloc()..add(LoadPageThumbnails(pdfPath)),
      child: const _PageOpsView(),
    );
  }
}

class _PageOpsView extends StatefulWidget {
  const _PageOpsView();
  @override
  State<_PageOpsView> createState() => _PageOpsViewState();
}

class _PageOpsViewState extends State<_PageOpsView> {
  final _scrollController = ScrollController();
  final _selected = <int>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Operations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              if (_selected.isNotEmpty) {
                context.read<PageOpsBloc>().add(DeletePagesEvent(_selected.toList()));
                _selected.clear();
                setState((){});
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_ccw),
            onPressed: () {
              final rot = { for (final p in _selected) p: 90 };
              context.read<PageOpsBloc>().add(RotatePagesEvent(rot));
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final state = context.read<PageOpsBloc>().state;
              if (state is PageOpsLoaded) {
                final output = state.pdfPath.replaceAll('.pdf', '_edited.pdf');
                context.read<PageOpsBloc>().add(ApplyPageOps(output));
              }
            },
          )
        ],
      ),
      body: BlocConsumer<PageOpsBloc, PageOpsState>(
        listener: (context, state) {
          if (state is PageOpsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is PageOpsResult) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operation complete')));
          }
        },
        builder: (context, state) {
          if (state is PageOpsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PageOpsProgress) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: state.progress),
                  const SizedBox(height: 12),
                  Text(state.stage),
                ],
              ),
            );
          }
          if (state is PageOpsLoaded) {
            return ReorderableListView(
              scrollController: _scrollController,
              onReorder: (oldIndex,newIndex){
                final order = List<int>.from(state.workingOrder);
                if (newIndex > oldIndex) newIndex -=1;
                final moved = order.removeAt(oldIndex);
                order.insert(newIndex, moved);
                context.read<PageOpsBloc>().add(ReorderPagesEvent(order));
              },
              children: [
                for (int i=0;i<state.workingOrder.length;i++) _PageTile(
                  key: ValueKey('pg_${state.workingOrder[i]}'),
                  thumb: state.thumbs.firstWhere((t)=> t.pageNumber == state.workingOrder[i], orElse: ()=> PageThumb(state.workingOrder[i], Uint8List(0))),
                  pageNum: state.workingOrder[i],
                  selected: _selected.contains(state.workingOrder[i]),
                  rotation: state.rotations[state.workingOrder[i]] ?? 0,
                  onTap: () {
                    setState(() {
                      if (_selected.contains(state.workingOrder[i])) _selected.remove(state.workingOrder[i]); else _selected.add(state.workingOrder[i]);
                    });
                  },
                )
              ],
            );
          }
          if (state is PageOpsResult) {
            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Generated files:'),
                ),
                for (final p in state.outputPaths) ListTile(title: Text(p.split('/').last), subtitle: Text(p)),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  final PageThumb thumb;
  final int pageNum;
  final bool selected;
  final int rotation;
  final VoidCallback onTap;
  const _PageTile({super.key, required this.thumb, required this.pageNum, required this.selected, required this.rotation, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: thumb.bytes.isEmpty ? const SizedBox(width:50,height:70) : Image.memory(thumb.bytes, width:50, fit: BoxFit.cover),
        title: Text('Page $pageNum'),
        subtitle: rotation !=0 ? Text('Rot: $rotation°') : null,
        trailing: selected ? const Icon(Icons.check_circle) : null,
        onTap: onTap,
      ),
    );
  }
}
