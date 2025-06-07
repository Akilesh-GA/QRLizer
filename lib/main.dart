import 'package:flutter/material.dart';
import 'package:qr_reader_3/pages/qr_code.dart';
import 'package:qr_reader_3/pages/analyse_url.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRLizer',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        hintColor: Colors.grey[600],
        scaffoldBackgroundColor: Colors.grey[200],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
            shadowColor: Colors.deepPurple.shade200,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.deepPurple),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF512DA8),
            letterSpacing: 0.8,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)
            .copyWith(secondary: Colors.amber),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const WelcomePage(),
        '/scan_qr': (context) => const ScanCodePage(),
        '/analyse_url': (context) => const URLAnalysisPage(),
        '/features': (context) => const FeaturesPage(), // Define the new route
      },
      initialRoute: '/',
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late Animation<double> _logoScaleAnimation;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Logo Animation
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.easeInOut),
    );

    // Button Animation
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Shorter animation
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _animateButtonTap(AnimationController controller) async {
    await controller.forward();
    await controller.reverse();
  }

  void _navigateToFeaturesPage() {
    Navigator.pushNamed(context, '/features');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRLizer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline), // Changed icon to info
            onPressed: _navigateToFeaturesPage,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ScaleTransition(
                scale: _logoScaleAnimation,
                child: const Icon(
                  Icons.security,
                  size: 100,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'QRLizer',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Protecting Against Quishing and URL Threats.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge!.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 30),

              // Security Status Indicator
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Status', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text('Real-time Protection : Turned On ', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text('URL Guard : Active ', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, color: Colors.deepPurple, size: 20),
                          const SizedBox(width: 8),
                          Text('Smart Analysis : Enabled ', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Action Buttons
              GestureDetector(
                onTap: () async {
                  await _animateButtonTap(_buttonAnimationController);
                },
                child: ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/scan_qr');
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR Code'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  await _animateButtonTap(_buttonAnimationController);
                },
                child: ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/analyse_url');
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('Analyze URL'),
                  ),
                ),
              ),

              const SizedBox(height: 45),

              Text(
                'QRLizer™ © 2025 - Your Digital Shield',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall!.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Key Features'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Explore the powerful features of QRLizer:', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.lightBlue, size: 30),
              title: Text('Instant QR Code Scanning & Analysis', style: theme.textTheme.headlineSmall),
              subtitle: Text('Quickly scan and analyze QR codes for malicious content.', style: theme.textTheme.bodyMedium),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.white,
              dense: false,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.blueGrey, size: 30),
              title: Text('Detailed URL Risk Assessment', style: theme.textTheme.headlineSmall),
              subtitle: Text('Analyze URLs for potential phishing, malware, and other threats.', style: theme.textTheme.bodyMedium),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.white,
              dense: false,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
              title: Text('Quishing and Phishing Detection', style: theme.textTheme.headlineSmall),
              subtitle: Text('Advanced detection of QR code and URL based phishing attempts.', style: theme.textTheme.bodyMedium),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: Colors.white,
              dense: false,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}