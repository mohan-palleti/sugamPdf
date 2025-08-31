import 'pdf_annotation_service.dart';
import 'pdf_service.dart';
import 'pdf_page_ops_service.dart';

/// Very light-weight service locator for core singletons.
class AppServices {
  AppServices._internal();
  static final AppServices _instance = AppServices._internal();
  factory AppServices() => _instance;

  final PdfAnnotationService annotationService = PdfAnnotationService();
  final PdfService pdfService = PdfService();
  final PdfPageOpsService pageOpsService = PdfPageOpsService();
}

AppServices get services => AppServices();
