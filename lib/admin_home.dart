import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:parkpro_admin/motorcycle_area_page.dart';
import 'package:parkpro_admin/reports_admin.dart';
import 'package:parkpro_admin/task_management.dart';
import 'package:parkpro_admin/user_list.dart';
import 'package:parkpro_admin/vehicle_area_page.dart';

import 'enforcer_list.dart'; // Import your enforcer_list.dart file

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String _selectedPage = "Dashboard"; // Tracks the currently selected page

  /// Fetch the count of documents in a Firestore collection
  Future<int> getCount(String collection) async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection(collection).get();
    return querySnapshot.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: Text(
          'Admin - $_selectedPage',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.amberAccent[400],
      ),
      body: Row(
        children: [
          SingleChildScrollView(child: _buildSidebar(context)), // Sidebar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: _buildPageContent(context), // Dynamic content area
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the sidebar
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.amberAccent[400],
      child: Column(
        children: [
          DrawerHeader(
            decoration:
                const BoxDecoration(color: Color.fromARGB(181, 246, 250, 253)),
            child: Center(
              child: Image.asset(
                'assets/loginlogo.png', // Adjust the logo path as necessary
                fit: BoxFit.contain,
                width: 150,
              ),
            ),
          ),
          _buildDrawerItem(
            title: 'Dashboard',
            icon: Icons.dashboard,
            onTap: () => _updateSelectedPage("Dashboard"),
          ),
          _buildDrawerItem(
            title: 'Manage Enforcer',
            icon: Icons.person,
            onTap: () => _updateSelectedPage("Manage Enforcer"),
          ),
          _buildDrawerItem(
            title: 'Manage User',
            icon: Icons.group,
            onTap: () => _updateSelectedPage("Manage User"),
          ),
          _buildDrawerItem(
            title: 'Vehicle Parking Area',
            icon: Icons.directions_car,
            onTap: () => _updateSelectedPage("Vehicle Parking Area"),
          ),
          _buildDrawerItem(
            title: 'Motorcycle Parking Area',
            icon: Icons.motorcycle,
            onTap: () => _updateSelectedPage("Motorcycle Parking Area"),
          ),
          _buildDrawerItem(
            title: 'Task Management',
            icon: Icons.task,
            onTap: () => _updateSelectedPage("Task Management"),
          ),
          _buildDrawerItem(
            title: 'Reports',
            icon: Icons.task,
            onTap: () => _updateSelectedPage("Reports"),
          ),
        ],
      ),
    );
  }

  /// Updates the selected page
  void _updateSelectedPage(String page) {
    setState(() {
      _selectedPage = page;
    });
  }

  /// Builds a single drawer item
  Widget _buildDrawerItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(color: Colors.black)),
      onTap: onTap,
    );
  }

  /// Builds the dynamic content for each selected page
  Widget _buildPageContent(BuildContext context) {
    if (_selectedPage == "Dashboard") {
      return _buildDashboard(context);
    } else if (_selectedPage == "Manage Enforcer") {
      return const EnforcerListPage(); // Display the EnforcerList widget
    } else if (_selectedPage == "Manage User") {
      return const UserList(); // Display the ManageUser widget
    } else if (_selectedPage == "Vehicle Parking Area") {
      return const VehicleAreaPage(); // Display Vehicle Parking Area
    } else if (_selectedPage == "Motorcycle Parking Area") {
      return const MotorcycleAreaPage();
    } else if (_selectedPage == "Task Management") {
      return const TaskManagementAdmin(); // Display Motorcycle Parking Area
    } else if (_selectedPage == "Reports") {
      return const ReportsAdmin();
    } else {
      return Center(
        child: Text(
          '$_selectedPage Page Content',
          style: const TextStyle(fontSize: 18),
        ),
      );
    }
  }

  /// Builds the Dashboard page content
  Widget _buildDashboard(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        getCount('enforcer_account'),
        getCount('user'),
        getCount('motorcycle_area'),
        getCount('vehicle_area'),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final counts = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDashboardTile(
                    title: 'Enforcers',
                    count: counts[0],
                    imagePath: 'assets/enforcer.JPG',
                  ),
                  _buildDashboardTile(
                    title: 'Users',
                    count: counts[1],
                    imagePath: 'assets/user.JPG',
                  ),
                  _buildDashboardTile(
                    title: 'Motorcycle Areas',
                    count: counts[2],
                    imagePath: 'assets/motor_area.JPG',
                  ),
                  _buildDashboardTile(
                    title: 'Vehicle Areas',
                    count: counts[3],
                    imagePath: 'assets/vehicle_area.JPG',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildAnalyticsChart(counts),
            ],
          ),
        );
      },
    );
  }

  /// Creates a dashboard tile with an image, title, and count
  Widget _buildDashboardTile({
    required String title,
    required int count,
    required String imagePath,
  }) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.asset(
            imagePath,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ],
    );
  }

  /// Builds an analytics bar chart
  Widget _buildAnalyticsChart(List<int> counts) {
    return AspectRatio(
      aspectRatio: 2.10,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: counts[0].toDouble(),
                      color: Colors.blue,
                      width: 25,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                  showingTooltipIndicators: [0],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: counts[1].toDouble(),
                      color: Colors.green,
                      width: 25,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                  showingTooltipIndicators: [0],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: counts[2].toDouble(),
                      color: Colors.orange,
                      width: 25,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                  showingTooltipIndicators: [0],
                ),
                BarChartGroupData(
                  x: 3,
                  barRods: [
                    BarChartRodData(
                      toY: counts[3].toDouble(),
                      color: Colors.red,
                      width: 25,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                  showingTooltipIndicators: [0],
                ),
              ],
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBorder: BorderSide(color: Colors.grey[700]!),
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String label;
                    switch (group.x) {
                      case 0:
                        label = 'Enforcers';
                        break;
                      case 1:
                        label = 'Users';
                        break;
                      case 2:
                        label = 'Motorcycle Areas';
                        break;
                      case 3:
                        label = 'Vehicle Areas';
                        break;
                      default:
                        label = '';
                        break;
                    }
                    return BarTooltipItem(
                      '$label\nCount: ${rod.toY.toInt()}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('Enforcers');
                        case 1:
                          return const Text('Users');
                        case 2:
                          return const Text('Motorcycle Areas');
                        case 3:
                          return const Text('Vehicle Areas');
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
