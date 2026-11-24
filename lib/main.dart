import 'package:material_ui/material_ui.dart';

import 'app/observatory_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AetherObservatoryApp());
}

class AetherObservatoryApp extends StatelessWidget {
  const AetherObservatoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aether Observatory — Flutter Scene 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05070D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF6C46D),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ObservatoryScreen(),
    );
  }
}
