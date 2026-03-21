import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ai_analysis_provider.dart';
import 'screens/home_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const BistRadarApp());

class BistRadarApp extends StatelessWidget {
  const BistRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AiAnalysisProvider()),
      ],
      child: MaterialApp(
      title: 'BIST Radar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4AA),
          surface: Color(0xFF1E1E2E),
        ),
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
      ),
      home: const SplashScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final List<Widget> _screens = [HomeScreen(), PortfolioScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF2A2A3E),
        selectedItemColor: const Color(0xFF00D4AA),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: 'Piyasa'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Portföy'),
        ],
      ),
    );
  }
}