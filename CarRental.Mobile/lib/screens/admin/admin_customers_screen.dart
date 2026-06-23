import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/profile.dart';
import '../../theme.dart';
import 'package:go_router/go_router.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  List<Profile> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await ApiService.getProfiles();
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      appBar: AppBar(
        title: const Text('Customer Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text1,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Auth (Cleanup Orphans)',
            onPressed: () async {
              try {
                await ApiService.cleanupOrphans();
                _loadProfiles();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auth synced successfully')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : RefreshIndicator(
              onRefresh: _loadProfiles,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _profiles.length,
                itemBuilder: (context, index) {
                  final profile = _profiles[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.blue.withOpacity(0.1),
                          backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                          child: profile.avatarUrl == null
                              ? Text(profile.firstName.isNotEmpty ? profile.firstName[0] : 'U', style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${profile.firstName} ${profile.lastName}', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text1)),
                              if (profile.email != null) ...[
                                const SizedBox(height: 4),
                                Text(profile.email!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text2)),
                              ],
                              if (profile.phoneNumber != null) ...[
                                const SizedBox(height: 4),
                                Text(profile.phoneNumber!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
                              ],
                            ],
                          ),
                        ),
                          if (profile.isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text('ADMIN', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.gold)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () async {
                              final result = await context.push('/admin/customer-detail', extra: profile);
                              if (result == true || result == null) {
                                // If they deleted the profile or made changes, reload
                                _loadProfiles();
                              }
                            },
                          )
                        ],
                      ),
                    );
                },
              ),
            ),
    );
  }
}
