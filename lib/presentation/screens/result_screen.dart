import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:erase_it/presentation/provider/image_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/custom_button.dart';
import '../widgets/image_display.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _playEntryAnimation();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  void _playEntryAnimation() {
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          );
        },
      ),
      title: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Text(
              'Result',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
      centerTitle: true,
      actions: [
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: IconButton(
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.restart_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                onPressed: () => _resetAndGoHome(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF0A0A0A),
          ],
        ),
      ),
      child: SafeArea(
        child: Consumer<ImageHandleProvider>(
          builder: (context, provider, child) {
            final file = provider.processedImage;

            if (file == null) {
              return _buildErrorState();
            }

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildContent(file, provider),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No processed image found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please go back and try again',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Go Back',
            onPressed: () => Navigator.pop(context),
            icon: Icons.arrow_back,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(File file, ImageHandleProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildImageSection(file),
          const Spacer(),
          _buildActionButtons(file, provider),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green[300],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Background Removed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green[300],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 16),
        Text(
          'Your image is ready!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
        const SizedBox(height: 8),
        Text(
          'Save to gallery or share with friends',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white60,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
      ],
    );
  }

  Widget _buildImageSection(File file) {
    return ImageDisplay(
      file: file,
      showZoomIcon: true,
      onTap: () => _showFullScreenImage(file),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildActionButtons(File file, ImageHandleProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Save',
                icon: Icons.download,
                onPressed: _isLoading ? null : () => _saveToGallery(file),
                isLoading: provider.loadingType == LoadingType.savingToGallery,
                loadingText: 'Saving...',
              ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.3),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'Share',
                icon: Icons.share,
                onPressed: _isLoading ? null : () => _shareImage(file, provider),
                isLoading: provider.loadingType == LoadingType.sharing,
                loadingText: 'Sharing...',
              ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Create Another',
          icon: Icons.add_photo_alternate,
          onPressed: _resetAndGoHome,
          color: Colors.white.withOpacity(0.1),
        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
      ],
    );
  }

  Future<void> _saveToGallery(File file) async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      // Check and request permission
      PermissionStatus status;
      
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt <= 32) {
          status = await Permission.storage.request();
        } else {
          status = await Permission.photos.request();
        }
      } else {
        status = await Permission.photos.request();
      }

      if (!status.isGranted) {
        await _showPermissionDialog();
        return;
      }

      // Save the image
      await Gal.putImage(file.path, album: 'EraseIt');
      
      HapticFeedback.lightImpact();
      _showSuccessSnackBar('Image saved to gallery!');
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorSnackBar('Failed to save image: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareImage(File file, ImageHandleProvider provider) async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await provider.shareImage();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out my background removed image created with EraseIt! 🎨✨',
        subject: 'My EraseIt Creation',
      );
      HapticFeedback.lightImpact();
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorSnackBar('Failed to share image: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetAndGoHome() {
    HapticFeedback.lightImpact();
    final provider = Provider.of<ImageHandleProvider>(context, listen: false);
    provider.reset();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _showFullScreenImage(File file) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                child: Image.file(file),
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _showPermissionDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[300],
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Permission Required',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Storage permission is required to save images to your gallery. Please grant permission in settings.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green[300],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
