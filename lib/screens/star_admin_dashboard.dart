import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StarAdminDashboard extends StatefulWidget {
  const StarAdminDashboard({super.key});

  @override
  State<StarAdminDashboard> createState() => _StarAdminDashboardState();
}

class _StarAdminDashboardState extends State<StarAdminDashboard> {
  final Color brandBlue = const Color(0xFF1F3BB3);
  final Color backgroundLight = const Color(0xFFF4F5F7);
  final Color textDark = const Color(0xFF1F1F1F);
  final Color textGrey = const Color(0xFF8D8D8D);

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- LEFT SIDEBAR ---
          _buildSidebar(),

          // --- MAIN CONTENT AREA ---
          Expanded(
            child: Column(
              children: [
                // Top Header Navbar
                _buildTopNavbar(),

                // Scrollable Dashboard Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreetingSection(),
                        const SizedBox(height: 24),
                        _buildTabsAndActions(),
                        const SizedBox(height: 24),
                        _buildStatsRow(),
                        const SizedBox(height: 24),

                        // Charts and Side Widgets Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _buildMainChart()),
                            const SizedBox(width: 24),
                            Expanded(flex: 3, child: _buildRightSideWidgets()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // SIDEBAR WIDGET
  // ==============================================================
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const Icon(Icons.menu, color: Colors.black87),
                const SizedBox(width: 16),
                Text(
                  'DecartAdmin',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textDark),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _sidebarItem(Icons.grid_view, 'Dashboard', 0),

                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8, left: 16),
                  child: Text('UI ELEMENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                _sidebarItem(Icons.shopping_bag_outlined, 'Manage Orders', 1),
                _sidebarItem(Icons.add_box_outlined, 'Add Product', 2),

                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8, left: 16),
                  child: Text('FORMS AND DATAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                _sidebarItem(Icons.people_outline, 'Users Directory', 3),
                _sidebarItem(Icons.forum_outlined, 'Feedback & Support', 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? brandBlue.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? brandBlue : textGrey),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? brandBlue : textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // TOP NAVBAR WIDGET
  // ==============================================================
  Widget _buildTopNavbar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAEAEC))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black54), onPressed: () {}),
          IconButton(icon: const Icon(Icons.mail_outline, color: Colors.black54), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black54), onPressed: () {}),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=Admin&background=1F3BB3&color=fff'),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // MAIN DASHBOARD COMPONENTS
  // ==============================================================
  Widget _buildGreetingSection() {
    final user = FirebaseAuth.instance.currentUser;
    final String emailName = user?.email?.split('@')[0] ?? 'Admin';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Good Morning, ',
                style: TextStyle(fontSize: 24, color: textDark),
                children: [
                  TextSpan(text: emailName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Your performance summary this week', style: TextStyle(color: textGrey, fontSize: 14)),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
              child: const Row(children: [Text('Select Category'), SizedBox(width: 8), Icon(Icons.keyboard_arrow_down, size: 16)]),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
              child: const Row(children: [Icon(Icons.calendar_today, size: 16), SizedBox(width: 8), Text('11/02/2026')]),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTabsAndActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _tabText('Overview', true),
            _tabText('Audiences', false),
            _tabText('Demographics', false),
            _tabText('More', false),
          ],
        ),
        Row(
          children: [
            _actionButton(Icons.share, 'Share', Colors.white, Colors.black87),
            const SizedBox(width: 8),
            _actionButton(Icons.print, 'Print', Colors.white, Colors.black87),
            const SizedBox(width: 8),
            _actionButton(Icons.download, 'Export', brandBlue, Colors.white),
          ],
        )
      ],
    );
  }

  Widget _tabText(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? brandBlue : textDark)),
          const SizedBox(height: 4),
          if (isActive) Container(height: 2, width: 24, color: brandBlue) else const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: bgColor == Colors.white ? Border.all(color: Colors.grey.shade300) : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatItem(title: 'Bounce Rate', value: '32.53%', change: '-0.5%', isPositive: false),
        _StatItem(title: 'Page Views', value: '7,682', change: '+0.1%', isPositive: true),
        _StatItem(title: 'New Sessions', value: '68.8', change: '-68.8', isPositive: false),
        _StatItem(title: 'Avg. Time on Site', value: '2m:35s', change: '+0.8%', isPositive: true),
        _StatItem(title: 'Total Revenue', value: '₹42,500', change: '+12.4%', isPositive: true),
      ],
    );
  }

  // ==============================================================
  // CHARTS & WIDGETS
  // ==============================================================
  Widget _buildMainChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Performance Line Chart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Overview of orders and traffic over the week', style: TextStyle(color: textGrey, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  _legendDot('This week', brandBlue),
                  const SizedBox(width: 16),
                  _legendDot('Last week', Colors.lightBlueAccent),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(days[value.toInt()], style: TextStyle(color: textGrey, fontSize: 10)));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 50), FlSpot(1, 110), FlSpot(2, 60), FlSpot(3, 280), FlSpot(4, 130), FlSpot(5, 210), FlSpot(6, 200)],
                    isCurved: true,
                    color: brandBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: brandBlue.withOpacity(0.1)),
                  ),
                  LineChartBarData(
                    spots: const [FlSpot(0, 30), FlSpot(1, 170), FlSpot(2, 250), FlSpot(3, 150), FlSpot(4, 20), FlSpot(5, 40), FlSpot(6, 180)],
                    isCurved: true,
                    color: Colors.lightBlueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.lightBlueAccent.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: textGrey, fontSize: 12)),
      ],
    );
  }

  Widget _buildRightSideWidgets() {
    return Column(
      children: [
        // Blue Status Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0C82EE), // Bright Blue
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 24),
              Text('Closed Value', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('357', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              // Note: You can add a mini fl_chart here if desired, using a placeholder line for now
              Divider(color: Colors.white24, thickness: 2),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Circular Progress Widgets
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _circularStat('Total Visitors', '26.80%'),
              _circularStat('Visits per day', '9065'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circularStat(String title, String value) {
    return Column(
      children: [
        SizedBox(
          width: 50, height: 50,
          child: CircularProgressIndicator(value: 0.7, strokeWidth: 6, backgroundColor: Colors.grey.shade200, color: brandBlue),
        ),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(color: textGrey, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isPositive;

  const _StatItem({required this.title, required this.value, required this.change, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF8D8D8D), fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: isPositive ? Colors.green : Colors.red, size: 18),
            Text(change, style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }
}