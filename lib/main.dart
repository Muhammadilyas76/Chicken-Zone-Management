
import 'package:flutter/material.dart';

void main() {
  runApp(const ChickenZoneApp());
}

class ChickenZoneApp extends StatelessWidget {
  const ChickenZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chicken Zone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
      ),
      home: const Dashboard(),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        title: const Text(
          '🐔 Chicken Zone',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade900,
                    Colors.orange.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text(
                    'CHICKEN ZONE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Poultry Business Management',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.25,
              children: const [
                DashboardCard(
                  title: 'Total Mall',
                  subtitle: 'کل مال',
                  icon: Icons.inventory_2,
                  color: Colors.green,
                ),
                DashboardCard(
                  title: 'Mall Ki Qeemat',
                  subtitle: 'مال کی قیمت',
                  icon: Icons.payments,
                  color: Colors.orange,
                ),
                DashboardCard(
                  title: 'Mall Mein Kami',
                  subtitle: 'مال میں کمی',
                  icon: Icons.remove_circle,
                  color: Colors.blue,
                ),
                DashboardCard(
                  title: 'Gari Kharch',
                  subtitle: 'گاڑی خرچ',
                  icon: Icons.local_shipping,
                  color: Colors.red,
                ),
                DashboardCard(
                  title: 'Customers',
                  subtitle: 'کسٹمرز',
                  icon: Icons.people,
                  color: Colors.purple,
                ),
                DashboardCard(
                  title: 'Reports',
                  subtitle: 'رپورٹس',
                  icon: Icons.bar_chart,
                  color: Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
