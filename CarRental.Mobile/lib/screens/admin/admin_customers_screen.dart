import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/profile.dart';
import 'package:go_router/go_router.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  List<Profile> _profiles = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await ApiService.getProfiles();
      if (mounted) {
        setState(() {
          _profiles = profiles;
        });
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profiles: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProfiles = _profiles.where((p) {
      final query = _searchQuery.toLowerCase();
      final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
      return fullName.contains(query) || (p.email?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          'Customer Management',
          style: GoogleFonts.inter(
              color: const Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFF2563EB)),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfiles,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProfiles.isEmpty
                    ? Center(
                        child: Text(
                          'No customers found',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF6B7280), fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProfiles,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProfiles.length,
                          itemBuilder: (context, index) {
                            final profile = filteredProfiles[index];
                            return _buildCustomerCard(profile);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Profile profile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () async {
          final result = await context.push('/admin/customer-detail', extra: profile);
          if (result == true || result == null) {
            _loadProfiles();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFDBEAFE),
                backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                child: profile.avatarUrl == null
                    ? Text(
                        profile.firstName.isNotEmpty ? profile.firstName[0].toUpperCase() : 'U',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF1D4ED8),
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${profile.firstName} ${profile.lastName}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        if (profile.isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ADMIN',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    if (profile.email != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 14, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(
                            profile.email!,
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5563)),
                          ),
                        ],
                      ),
                    ],
                    if (profile.phoneNumber != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(
                            profile.phoneNumber!,
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5563)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

