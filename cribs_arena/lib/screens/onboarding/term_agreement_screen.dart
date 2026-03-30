import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cribs_arena/screens/onboarding/welcome_screen.dart';
import '../../constants.dart';
import '../../widgets/widgets.dart';
import 'package:cribs_arena/services/legal_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Using flutter_markdown

class TermAgreementScreen extends StatefulWidget {
  const TermAgreementScreen({super.key});

  @override
  State<TermAgreementScreen> createState() => _TermAgreementScreenState();
}

class _TermAgreementScreenState extends State<TermAgreementScreen>
    with TickerProviderStateMixin {
  bool _agreed = false;
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = false;
  bool _showScrollButton = false;
  late AnimationController _buttonAnimationController;
  static const double _buttonHeight = kSizedBoxH48;

  final LegalService _legalService = LegalService();
  late Future<Map<String, String>> _legalDocumentsFuture;
  String _termsContent = '';
  String _privacyContent = '';
  String _termsVersion = '';
  bool _isLoadingContent = true;

  @override
  void initState() {
    super.initState();
    _legalDocumentsFuture = _loadLegalDocuments();
    _scrollController.addListener(_handleScroll);

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showScrollButton = true;
        });
      }
    });
  }

  Future<Map<String, String>> _loadLegalDocuments() async {
    try {
      final termsResponse =
          await _legalService.fetchLegalDocument('terms_of_service');
      final privacyResponse =
          await _legalService.fetchLegalDocument('privacy_policy');

      if (mounted) {
        setState(() {
          _termsContent = termsResponse['data']['content']!;
          _termsVersion = termsResponse['data']['version']!;
          _privacyContent = privacyResponse['data']['content']!;
          _isLoadingContent = false;
        });
      }
      return {'termsContent': _termsContent, 'privacyContent': _privacyContent};
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
        SnackbarHelper.showError(context, 'Failed to load legal documents: $e',
            position: FlashPosition.bottom);
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final atBottom = (maxScroll - currentScroll).abs() < 50.0;

    if (_isAtBottom != atBottom) {
      setState(() {
        _isAtBottom = atBottom;
      });

      if (atBottom) {
        _buttonAnimationController.forward();
      } else {
        _buttonAnimationController.reverse();
      }
    }
  }

  Future<void> _onContinue() async {
    // Add haptic feedback
    // HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() {
      _isLoadingContent = true; // Use _isLoadingContent to indicate saving
    });
    try {
      await _legalService.agreeToTerms(_termsVersion);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to record agreement: $e',
            position: FlashPosition.bottom);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _toggleAgreement() {
    setState(() {
      _agreed = !_agreed;
    });
  }

  void _showDocumentInDialog(
      BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => CustomAlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Markdown(
            data: content,
            shrinkWrap: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: _buttonHeight,
            child: ElevatedButton(
              onPressed: (_agreed && !_isLoadingContent) ? _onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_agreed && !_isLoadingContent)
                    ? kPrimaryColor
                    : Colors.grey.shade400,
                padding: EdgeInsets.zero,
                minimumSize: const Size(double.infinity, _buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: (_agreed && !_isLoadingContent) ? 2 : 0,
              ),
              child: _isLoadingContent
                  ? const CustomLoadingIndicator(
                      color: kWhite,
                      backgroundColor: Colors.transparent,
                      size: 24,
                      strokeWidth: 2.5)
                  : const Text(
                      'Accept & Continue',
                      style: TextStyle(
                        fontSize: kFontSize14,
                        fontWeight: FontWeight.w500,
                        color: kWhite,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showScrollButton ? _buttonHeight : 0,
            child: SizedBox(
              width: double.infinity,
              height: _buttonHeight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isAtBottom
                    ? OutlinedButton(
                        key: const ValueKey('scroll_to_top'),
                        onPressed: _scrollToTop,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side:
                              const BorderSide(color: Colors.black, width: 1.5),
                          minimumSize:
                              const Size(double.infinity, _buttonHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.keyboard_arrow_up, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Scroll to top',
                              style: TextStyle(
                                fontSize: kFontSize14,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : OutlinedButton(
                        key: const ValueKey('scroll_to_bottom'),
                        onPressed: _scrollToBottom,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side:
                              const BorderSide(color: Colors.black, width: 1.5),
                          minimumSize:
                              const Size(double.infinity, _buttonHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.keyboard_arrow_down,
                                color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Scroll to bottom',
                              style: TextStyle(
                                fontSize: kFontSize14,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: FutureBuilder<Map<String, String>>(
          future: _legalDocumentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CustomLoadingIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error loading legal documents: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            } else {
              return Column(
                children: [
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 8),
                            const CircleImageContainer(
                              imagePath: 'assets/images/note_taking.png',
                              size: 80,
                            ),
                            const SizedBox(height: 24),
                            const _Title(),
                            const SizedBox(height: 18),
                            const _Description(),
                            const SizedBox(height: 8),
                            _LegalContentSection(content: _termsContent),
                            const SizedBox(height: 24),
                            _CheckboxSection(
                              agreed: _agreed,
                              onTap: _toggleAgreement,
                              onTermsTap: () => _showDocumentInDialog(
                                  context, 'Terms of Service', _termsContent),
                              onPrivacyTap: () => _showDocumentInDialog(
                                  context, 'Privacy Policy', _privacyContent),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottomButtons(),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'TERMS & POLICY',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Welcome! Before you continue, please take a moment to read through our Terms of Service and Privacy Policy.\n',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 15, color: Colors.black87),
    );
  }
}

class _LegalContentSection extends StatelessWidget {
  final String content;

  const _LegalContentSection({required this.content});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: MarkdownBody(
        data: content,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          listBullet:
              const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ),
      ),
    );
  }
}

class _CheckboxSection extends StatelessWidget {
  final bool agreed;
  final VoidCallback onTap;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const _CheckboxSection({
    required this.agreed,
    required this.onTap,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: agreed ? kPrimaryColor : Colors.transparent,
                border: Border.all(
                  color: agreed ? kPrimaryColor : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: agreed
                  ? const Icon(
                      Icons.check,
                      color: kWhite,
                      size: 16,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'I have read and agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: const TextStyle(
                        color: Color(0xFF0066CC),
                        fontWeight: FontWeight.w500,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = onTermsTap,
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: Color(0xFF0066CC),
                        fontWeight: FontWeight.w500,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = onPrivacyTap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
