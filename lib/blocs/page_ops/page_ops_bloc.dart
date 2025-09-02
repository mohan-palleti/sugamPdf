import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import '../../services/pdf_page_ops_service.dart';
import '../../services/app_services.dart';
import 'page_ops_event.dart';
import 'page_ops_state.dart';

class PageOpsBloc extends Bloc<PageOpsEvent, PageOpsState> {
  final PdfPageOpsService _svc;
  bool _cancelRequested = false;
  PageOpsBloc({PdfPageOpsService? service}) : _svc = service ?? services.pageOpsService, super(PageOpsInitial()) {
    on<LoadPageThumbnails>(_onLoadThumbs);
    on<ReorderPagesEvent>(_onReorder);
    on<DeletePagesEvent>(_onDeleteMark);
    on<RotatePagesEvent>(_onRotate);
    on<ApplyPageOps>(_onApply);
    on<SplitPdfEvent>(_onSplit);
    on<CompressPdfEvent>(_onCompress);
  on<_InternalProgress>(_onInternalProgress);
    on<CancelOpsEvent>(_onCancel);
  }

  Future<void> _onLoadThumbs(LoadPageThumbnails e, Emitter<PageOpsState> emit) async {
    emit(PageOpsLoading());
    try {
      final doc = await pdfx.PdfDocument.openFile(e.pdfPath);
      final pages = doc.pagesCount;
      final thumbs = <PageThumb>[];
      for (int i=1;i<=pages;i++) {
        final page = await doc.getPage(i);
        final img = await page.render(width: 120, height: (120 * page.height / page.width));
        if (img != null) {
          thumbs.add(PageThumb(i, img.bytes));
        }
        page.close();
      }
      doc.close();
      emit(PageOpsLoaded(
        pdfPath: e.pdfPath,
        thumbs: thumbs,
        workingOrder: [for (int i=1;i<=pages;i++) i],
        rotations: const {},
        deletions: const {},
      ));
    } catch (err) {
      emit(PageOpsError('Failed to load thumbnails: $err'));
    }
  }

  void _onReorder(ReorderPagesEvent e, Emitter<PageOpsState> emit) {
    final st = state;
    if (st is PageOpsLoaded) {
      emit(st.copyWith(workingOrder: e.newOrder));
    }
  }

  void _onDeleteMark(DeletePagesEvent e, Emitter<PageOpsState> emit) {
    final st = state;
    if (st is PageOpsLoaded) {
      final newDel = Set<int>.from(st.deletions)..addAll(e.pages);
      emit(st.copyWith(deletions: newDel));
    }
  }

  void _onRotate(RotatePagesEvent e, Emitter<PageOpsState> emit) {
    final st = state;
    if (st is PageOpsLoaded) {
      final r = Map<int,int>.from(st.rotations);
      e.rotations.forEach((k,v){ r[k] = v;});
      emit(st.copyWith(rotations: r));
    }
  }

  Future<void> _onApply(ApplyPageOps e, Emitter<PageOpsState> emit) async {
    final st = state;
    if (st is! PageOpsLoaded) return;
    emit(const PageOpsProgress(0, 'start'));
    try {
      // build final sequence excluding deletions
      final sequence = st.workingOrder.where((p) => !st.deletions.contains(p)).toList();
      _cancelRequested = false;
      final file = await _svc.rebuildFromPageList(
        pdfPath: st.pdfPath,
        pageSequence: sequence,
        rotations: st.rotations,
        scale: 1.0,
        jpegQuality: 85,
        outputPath: e.outputPath,
        onProgress: (p,s)=> add(_InternalProgress(p,s)),
        isCancelled: () => _cancelRequested,
      );
      emit(PageOpsResult([file.path]));
    } catch (err) {
      emit(PageOpsError('Failed to apply operations: $err'));
    }
  }

  Future<void> _onSplit(SplitPdfEvent e, Emitter<PageOpsState> emit) async {
    final st = state;
    if (st is! PageOpsLoaded) return;
    emit(const PageOpsProgress(0, 'split start'));
    try {
      final ranges = e.ranges.map((r)=> PageRange(r[0], r[1])).toList();
      _cancelRequested = false;
      final files = await _svc.splitPdf(
        pdfPath: st.pdfPath,
        ranges: ranges,
        onProgress: (p,s)=> add(_InternalProgress(p,s)),
      );
      emit(PageOpsResult(files.map((f)=> f.path).toList()));
    } catch (err) {
      emit(PageOpsError('Failed to split PDF: $err'));
    }
  }

  Future<void> _onCompress(CompressPdfEvent e, Emitter<PageOpsState> emit) async {
    final st = state;
    if (st is! PageOpsLoaded) return;
    emit(const PageOpsProgress(0, 'compress start'));
    try {
      _cancelRequested = false;
      final file = await _svc.compressPdf(
        pdfPath: st.pdfPath,
        scale: e.scale,
        jpegQuality: e.quality,
        outputPath: e.outputPath,
        onProgress: (p,s)=> add(_InternalProgress(p,s)),
      );
      emit(PageOpsResult([file.path]));
    } catch (err) {
      emit(PageOpsError('Failed to compress PDF: $err'));
    }
  }

  // Internal progress event bridging
  void _onInternalProgress(_InternalProgress e, Emitter<PageOpsState> emit) {
    emit(PageOpsProgress(e.progress, e.stage));
  }

  void _onCancel(CancelOpsEvent e, Emitter<PageOpsState> emit) {
    _cancelRequested = true;
  }
}

class _InternalProgress extends PageOpsEvent {
  final double progress; final String stage; const _InternalProgress(this.progress,this.stage);
  @override
  List<Object?> get props => [progress, stage];
}

class CancelOpsEvent extends PageOpsEvent {}
