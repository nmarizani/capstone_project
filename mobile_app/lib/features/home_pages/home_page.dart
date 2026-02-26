import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../auth/auth_service.dart';
import '../prediction/active_scan_page.dart';
import 'notification_page.dart';
import '../settings_privacy/settings_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userProfile;
  final _authService = AuthService();

  // Demo patient data
  final Map<String, dynamic> _patient = {
    'name': 'Tinevimbo Muyayagwa',
    'id': 'PT-2026-0847',
    'status': 'Postpartum: 30 minutes',
    'age': '28 years',
    'heartrate': '190 bpm',
    'hemoglobin': '11.2 g/dL',
    'bloodPressure': '120/80 mmHg',
    'gestationalAge': '39 weeks',
    'diabetes': 'No',
    'bloodType': 'O+',
    'hypertension': 'Yes',
    'avatarUrl': null,
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getUserProfile();
    if (mounted) setState(() => _userProfile = profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: SafeArea(
        child: _currentIndex == 0
            ? _buildDashboard()
            : _currentIndex == 1
                ? const ActiveScanScreen()
                : const NotificationsScreen(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPatientDashboardCard(),
          const SizedBox(height: 16),
          _buildPatientInfoCard(),
          const SizedBox(height: 16),
          _buildVitalsRow(),
          const SizedBox(height: 16),
          _buildMoreDetails(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final displayName = _userProfile?['fullName'] ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Midwife';

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.secondary,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $displayName',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Patient Dashboard',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          onPressed: () => setState(() => _currentIndex = 2),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientDashboardCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, Color(0xFFE0EAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.dashboard_outlined, color: AppColors.primary, size: 22),
          SizedBox(width: 10),
          Text(
            'Patient Dashboard',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Information',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.secondary.withOpacity(0.3),
                child: const Icon(Icons.person, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _patient['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'ID: ${_patient['id']}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _patient['status'],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsRow() {
    return Row(
      children: [
        Expanded(child: _buildVitalCard('Age', _patient['age'], Icons.person_outline)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildVitalCard('Heart Rate', _patient['heartrate'], Icons.favorite_outline, color: AppColors.danger)),
        const SizedBox(width: 12),
        Expanded(child: _buildVitalCard('Hemoglobin', _patient['hemoglobin'], Icons.favorite_outline, color: AppColors.danger)),
        const SizedBox(width: 12),
        Expanded(child: _buildVitalCard('Blood Pressure', _patient['bloodPressure'], Icons.favorite_outline, color: AppColors.danger)),
      ],
    );
  }

  Widget _buildVitalCard(String label, String value, IconData icon, {Color color = AppColors.primary}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.scanner_outlined),
            activeIcon: Icon(Icons.scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}