import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../services/api_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isLoading = true;
  bool _saving = false;
  
  List<String> _heroImages = [];
  String _heroVideoUrl = '';
  final TextEditingController _videoUrlCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getHeroImages(),
        ApiService.getHeroVideo(),
      ]);
      if (mounted) {
        setState(() {
          _heroImages = List<String>.from(results[0] as List);
          _heroVideoUrl = (results[1] as Map)['url'] ?? '';
          _videoUrlCtrl.text = _heroVideoUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _saving = true);
    try {
      final bytes = await image.readAsBytes();
      final mimeType = lookupMimeType(image.name) ?? 'image/jpeg';
      final fileName = 'hero-${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      
      final url = await ApiService.uploadDamageImage(bytes.toList(), fileName, mimeType); // reuse damage upload for fleet-images bucket equivalent
      setState(() {
        _heroImages.add(url);
      });
      await ApiService.updateHeroImages(_heroImages);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image added successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() => _saving = true);
    try {
      final updated = List<String>.from(_heroImages)..removeAt(index);
      await ApiService.updateHeroImages(updated);
      setState(() => _heroImages = updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image removed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveVideoUrl() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateHeroVideo(_videoUrlCtrl.text.trim());
      setState(() => _heroVideoUrl = _videoUrlCtrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video URL saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save video: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeVideo() async {
    setState(() => _saving = true);
    try {
      await ApiService.deleteHeroVideo();
      setState(() {
        _heroVideoUrl = '';
        _videoUrlCtrl.clear();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video removed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove video: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Site Settings',
          style: GoogleFonts.inter(color: const Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hero Images',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage the images that appear on the homepage slider.',
              style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._heroImages.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      Container(
                        width: 120, height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          image: DecorationImage(image: NetworkImage(entry.value), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 4, top: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(entry.key),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                GestureDetector(
                  onTap: _saving ? null : _pickAndUploadImage,
                  child: Container(
                    width: 120, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _saving 
                        ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate, color: Color(0xFF2563EB)),
                              const SizedBox(height: 4),
                              Text(
                                'Upload',
                                style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            Text(
              'Hero Video',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            Text(
              'Provide an MP4 URL to autoplay in the background. Leave blank to use images instead.',
              style: GoogleFonts.inter(color: const Color(0xFF6B7280), fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_heroVideoUrl.isNotEmpty) ...[
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 48)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _videoUrlCtrl,
                          decoration: InputDecoration(
                            labelText: 'Video URL (MP4)',
                            hintText: 'https://...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _saveVideoUrl,
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Save URL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_heroVideoUrl.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _removeVideo,
                          icon: const Icon(Icons.delete, size: 16, color: Color(0xFFDC2626)),
                          label: const Text('Remove Video', style: TextStyle(color: Color(0xFFDC2626))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

