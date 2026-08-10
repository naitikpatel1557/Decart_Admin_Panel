import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final Color brandBlue = const Color(0xFF1F3BB3);

  String _chartViewMode = 'Weekly';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String emailName = user?.email?.split('@')[0] ?? 'Admin';

    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('orders').snapshots(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orderDocs = orderSnapshot.data?.docs ?? [];

          double totalRevenue = 0;
          int deliveredCount = 0;
          int activeCount = 0;

          Map<int, double> ordersChartData = {};
          double maxOrdersCount = 5;
          double chartMinX = 0;
          double chartMaxX = 6;

          if (_chartViewMode == 'Weekly') {
            for (int i = 0; i <= 6; i++) ordersChartData[i] = 0;
            chartMinX = 0; chartMaxX = 6;
          } else if (_chartViewMode == 'Monthly') {
            int daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
            for (int i = 1; i <= daysInMonth; i++) ordersChartData[i] = 0;
            chartMinX = 1; chartMaxX = daysInMonth.toDouble();
          } else if (_chartViewMode == 'Annual') {
            for (int i = 1; i <= 12; i++) ordersChartData[i] = 0;
            chartMinX = 1; chartMaxX = 12;
          }

          for (var doc in orderDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final double amount = (data['totalAmount'] ?? 0.0).toDouble();
            final String status = (data['status'] ?? '').toString().toLowerCase();
            final Timestamp? dateStamp = data['orderDate'] ?? data['createdAt'];

            if (status != 'cancelled') totalRevenue += amount;
            if (status == 'delivered') {
              deliveredCount++;
            } else if (status != 'cancelled') {
              activeCount++;
            }

            if (dateStamp != null) {
              DateTime dt = dateStamp.toDate();

              if (_chartViewMode == 'Weekly') {
                if (DateTime.now().difference(dt).inDays <= 7) {
                  int dayIndex = dt.weekday == 7 ? 0 : dt.weekday;
                  ordersChartData[dayIndex] = (ordersChartData[dayIndex] ?? 0) + 1;
                  if (ordersChartData[dayIndex]! > maxOrdersCount) maxOrdersCount = ordersChartData[dayIndex]!;
                }
              } else if (_chartViewMode == 'Monthly') {
                if (dt.year == _selectedYear && dt.month == _selectedMonth) {
                  ordersChartData[dt.day] = (ordersChartData[dt.day] ?? 0) + 1;
                  if (ordersChartData[dt.day]! > maxOrdersCount) maxOrdersCount = ordersChartData[dt.day]!;
                }
              } else if (_chartViewMode == 'Annual') {
                if (dt.year == _selectedYear) {
                  ordersChartData[dt.month] = (ordersChartData[dt.month] ?? 0) + 1;
                  if (ordersChartData[dt.month]! > maxOrdersCount) maxOrdersCount = ordersChartData[dt.month]!;
                }
              }
            }
          }

          List<FlSpot> chartSpots = [];
          ordersChartData.forEach((key, value) {
            chartSpots.add(FlSpot(key.toDouble(), value));
          });
          chartSpots.sort((a, b) => a.x.compareTo(b.x));

          double fulfillmentRate = orderDocs.isEmpty ? 0 : (deliveredCount / orderDocs.length) * 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good Morning, $emailName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Your live performance summary', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 24),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatCard('Total Revenue', '₹${totalRevenue.toStringAsFixed(0)}', 'Active', true),
                      _buildStatCard('Total Orders', '${orderDocs.length}', 'Lifetime', true),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').snapshots(),
                        builder: (c, snap) => _buildStatCard('Total Users', '${snap.data?.docs.length ?? 0}', 'Registered', true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  height: 400,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Orders Chart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Total orders: $_chartViewMode', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                height: 30,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _chartViewMode,
                                    isDense: true,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                                    items: ['Weekly', 'Monthly', 'Annual'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                    onChanged: (val) => setState(() => _chartViewMode = val!),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_chartViewMode == 'Monthly')
                                Row(
                                  children: [
                                    Container(
                                      height: 30,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: _selectedMonth,
                                          isDense: true,
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                          items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(_months[index]))),
                                          onChanged: (val) => setState(() => _selectedMonth = val!),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      height: 30,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          value: _selectedYear,
                                          isDense: true,
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                          items: List.generate(5, (index) => DropdownMenuItem(value: DateTime.now().year - index, child: Text('${DateTime.now().year - index}'))),
                                          onChanged: (val) => setState(() => _selectedYear = val!),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (_chartViewMode == 'Annual')
                                Container(
                                  height: 30,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedYear,
                                      isDense: true,
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                      items: List.generate(5, (index) => DropdownMenuItem(value: DateTime.now().year - index, child: Text('${DateTime.now().year - index}'))),
                                      onChanged: (val) => setState(() => _selectedYear = val!),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxOrdersCount + 2,
                            minX: chartMinX,
                            maxX: chartMaxX,
                            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                            titlesData: FlTitlesData(
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: _chartViewMode == 'Monthly' ? 5 : 1,
                                  getTitlesWidget: (value, meta) {
                                    int intVal = value.toInt();
                                    if (_chartViewMode == 'Weekly') {
                                      const days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
                                      if (intVal >= 0 && intVal < days.length) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(days[intVal], style: const TextStyle(color: Colors.grey, fontSize: 10)));
                                    }
                                    else if (_chartViewMode == 'Monthly') {
                                      if (intVal == 1 || intVal % 5 == 0) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('$intVal', style: const TextStyle(color: Colors.grey, fontSize: 10)));
                                    }
                                    else if (_chartViewMode == 'Annual') {
                                      if (intVal >= 1 && intVal <= 12) return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_months[intVal - 1], style: const TextStyle(color: Colors.grey, fontSize: 10)));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: chartSpots,
                                isCurved: true, color: brandBlue, barWidth: 3, dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: brandBlue.withOpacity(0.1)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF0C82EE), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Fulfillment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 24),
                      const Text('Active / Processing Orders', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('$activeCount', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, thickness: 2),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _circularStat('Fulfillment Rate', '${fulfillmentRate.toStringAsFixed(1)}%', fulfillmentRate / 100),
                      _circularStat('Total Delivered', '$deliveredCount', deliveredCount / (orderDocs.isEmpty ? 1 : orderDocs.length)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
    );
  }

  Widget _buildStatCard(String title, String value, String subtext, bool isPositive) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(isPositive ? Icons.check_circle : Icons.warning, color: isPositive ? Colors.green : Colors.orange, size: 12),
              const SizedBox(width: 4),
              Text(subtext, style: TextStyle(color: isPositive ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _circularStat(String title, String value, double progress) {
    return Column(
      children: [
        SizedBox(
          width: 50, height: 50,
          child: CircularProgressIndicator(value: progress.clamp(0.0, 1.0), strokeWidth: 6, backgroundColor: Colors.grey.shade200, color: brandBlue),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}