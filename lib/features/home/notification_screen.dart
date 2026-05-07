import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Data notifikasi mock
  final List<Map<String, dynamic>> _todayNotifications = [
    {
      'title': 'Reminder!!',
      'time': '2m ago',
      'message': 'Jangan Lupa minum obat ya ariff!! kesehatan kamu itu berharga banget',
      'icon': Icons.alarm,
      'iconColor': Colors.orange,
      'type': 'reminder',
    },
    {
      'title': 'Kamu hebat',
      'time': '4m ago',
      'message': 'Kamu tidak pernah lupa untuk menjaga kesehatan kamu dengan terus rutin ariff!!',
      'icon': Icons.emoji_events,
      'iconColor': Colors.amber,
      'type': 'achievement',
    },
    {
      'title': 'Security Alert',
      'time': '7h ago',
      'message': 'Perangkat baru saja login di sekitar Surabaya',
      'icon': Icons.security,
      'iconColor': Colors.red,
      'type': 'security',
    },
  ];

  final List<Map<String, dynamic>> _earlierNotifications = [
    {
      'title': 'Security Alert',
      'time': '7h ago',
      'message': 'Perangkat baru saja login di sekitar Surabaya',
      'icon': Icons.security,
      'iconColor': Colors.red,
      'type': 'security',
    },
    {
      'title': 'Reminder',
      'time': '8h ago',
      'message': 'Mari kita melangkah untuk hari selanjutnya',
      'icon': Icons.alarm,
      'iconColor': Colors.orange,
      'type': 'reminder',
    },
    {
      'title': 'Security Alert',
      'time': '11h ago',
      'message': 'Perangkat baru saja login di sekitar Surabaya',
      'icon': Icons.security,
      'iconColor': Colors.red,
      'type': 'security',
    },
    {
      'title': 'Security Alert',
      'time': '12h ago',
      'message': 'Perangkat baru saja login di sekitar Surabaya',
      'icon': Icons.security,
      'iconColor': Colors.red,
      'type': 'security',
    },
  ];

  final List<Map<String, dynamic>> _thisWeekNotifications = [
    {
      'title': 'Security Alert',
      'time': '2 days ago',
      'message': 'Perangkat baru saja login di sekitar Surabaya',
      'icon': Icons.security,
      'iconColor': Colors.red,
      'type': 'security',
    },
    {
      'title': 'Reminder',
      'time': '3 days ago',
      'message': 'Jangan lupa minum obat ya!',
      'icon': Icons.alarm,
      'iconColor': Colors.orange,
      'type': 'reminder',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan icon lonceng dan jumlah notifikasi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B92F5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Color(0xFF5B92F5),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifikasi',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${_todayNotifications.length + _earlierNotifications.length + _thisWeekNotifications.length} notifikasi baru',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section TODAY
            _buildSectionHeader('TODAY'),
            ..._todayNotifications.map((notif) => _buildNotificationCard(notif)),

            // Section TODAY (kedua - sesuai gambar)
            _buildSectionHeader('TODAY'),
            ..._earlierNotifications.map((notif) => _buildNotificationCard(notif)),

            // Section THIS WEEK
            _buildSectionHeader('THIS WEEK'),
            ..._thisWeekNotifications.map((notif) => _buildNotificationCard(notif)),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4A89F3),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: notif['iconColor'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              notif['icon'],
              color: notif['iconColor'],
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notif['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      notif['time'],
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notif['message'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}