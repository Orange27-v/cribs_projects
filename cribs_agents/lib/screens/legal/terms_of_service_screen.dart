import 'package:cribs_agents/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:cribs_agents/services/legal_document_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  late Future<String> _termsOfServiceContent;
  final LegalDocumentService _legalDocumentService = LegalDocumentService();

  @override
  void initState() {
    super.initState();
    _termsOfServiceContent =
        _legalDocumentService.getLegalDocument('terms_of_service');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('Terms of Service'),
        elevation: 0.3,
      ),
      body: FutureBuilder<String>(
        future: _termsOfServiceContent,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CustomLoadingIndicator(color: kPrimaryColor),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (snapshot.data == null || snapshot.data!.trim().isEmpty) {
            return _buildEmptyState();
          }

          return _buildContent(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return NetworkErrorWidget(
      errorMessage: getErrorMessage(error),
      onRefresh: () {
        setState(() {
          _termsOfServiceContent =
              _legalDocumentService.getLegalDocument('terms_of_service');
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Content Available',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please ensure the backend server is running and serving the legal documents correctly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String data) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Markdown(
              data: data,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.roboto(
                  fontSize: 15,
                  height: 1.55,
                  color: Colors.grey.shade900,
                ),
                h1: GoogleFonts.roboto(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 2,
                  color: kPrimaryColor,
                ),
                h2: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 2,
                  color: Colors.grey.shade800,
                ),
                h3: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.8,
                  color: Colors.grey.shade800,
                ),
                listBullet: GoogleFonts.roboto(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
