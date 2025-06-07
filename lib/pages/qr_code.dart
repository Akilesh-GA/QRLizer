import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IPQS {
  final String key = 'LjH2MelpvFFWTYdfj8Tc7LXvLtLM5GrQ';
  final String apiUrl = 'https://www.ipqualityscore.com/api/json/url/%s/%s';

  Future<Map<String, dynamic>> getAnalysis(String url, {int strictness = 0}) async {
    final queryParams = {'strictness': strictness.toString()};
    final encodedUrl = Uri.encodeQueryComponent(url);
    final fullUrl = Uri.parse(sprintf(apiUrl, [key, encodedUrl])).replace(queryParameters: queryParams);

    try {
      final response = await http.get(fullUrl);

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        return result;
      } else {
        print("IPQS HTTP Error during API request: Status code ${response.statusCode}");
        return {'error': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      print("IPQS Exception during API request: ${e.toString()}");
      return {'error': 'Exception: ${e.toString()}'};
    }
  }

  Future<bool> isMalicious(String url, {int strictness = 0}) async {
    final analysis = await getAnalysis(url, strictness: strictness);
    if (analysis.containsKey('success') && analysis['success'] == true) {
      return (analysis.containsKey('malware') && analysis['malware'] == true) ||
          (analysis.containsKey('phishing') && analysis['phishing'] == true) ||
          (analysis.containsKey('suspicious') && analysis['suspicious'] == true &&
              (analysis['risk_score'] is num ? (analysis['risk_score'] as num).toInt() > 75 : false));
    } else {
      print("IPQS Error during isMalicious check: ${analysis.toString()}");
      return false;
    }
  }
}

String sprintf(String format, List<dynamic> args) {
  String result = format;
  for (var arg in args) {
    result = result.replaceFirst('%s', arg.toString());
  }
  return result;
}

class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  String? scannedURL;
  String? analysisResult;
  final ipqsChecker = IPQS();
  MobileScannerController? controller;
  bool isScanning = true;
  bool isMaliciousUrl = false;
  Map<String, dynamic>? fullAnalysis;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) async {
    if (!isScanning) return; // Ignore scans if not in scanning mode

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null && rawValue != scannedURL) {
        setState(() {
          scannedURL = rawValue;
          analysisResult = 'Analyzing...';
          isMaliciousUrl = false; // Reset malicious status for the new scan
          fullAnalysis = null; // Reset full analysis
        });
        Uri? parsedUri = Uri.tryParse(scannedURL!);
        if (parsedUri != null) {
          String urlToAnalyze = scannedURL!;
          if (parsedUri.scheme.isEmpty) {
            urlToAnalyze = 'http://$scannedURL';
          }
          final analysis = await ipqsChecker.getAnalysis(urlToAnalyze);
          final bool isMalicious = await ipqsChecker.isMalicious(urlToAnalyze);
          setState(() {
            isMaliciousUrl = isMalicious;
            fullAnalysis = analysis;
            int riskScore = analysis.containsKey('risk_score') && analysis['risk_score'] is num
                ? (analysis['risk_score'] as num).toInt()
                : 0;
            analysisResult = isMalicious
                ? "'$scannedURL' is likely Malicious (Risk: $riskScore%)."
                : "'$scannedURL' is not likely Malicious (Risk: $riskScore%).";
            isScanning = false; // Stop scanning after processing one code
            controller?.stop(); // Optionally stop the camera

            if (isMalicious && fullAnalysis != null) {
              _showMaliciousAnalysisDialog(fullAnalysis!);
            }
          });
        } else {
          setState(() {
            analysisResult = 'Not a valid URL format.';
            isScanning = false; // Stop scanning after processing one code
            controller?.stop(); // Optionally stop the camera
          });
        }
      }
    }
  }

  void _scanNext() {
    setState(() {
      scannedURL = null;
      analysisResult = null;
      isScanning = true;
      isMaliciousUrl = false;
      fullAnalysis = null;
    });
    controller?.start(); // Restart the camera
  }

  void _showMaliciousAnalysisDialog(Map<String, dynamic> analysis) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Malicious URL Analysis'),
          content: SingleChildScrollView(
            child: Text(JsonEncoder.withIndent('  ').convert(analysis)),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR code'),
        leading: null, // To remove the back button if it exists
        automaticallyImplyLeading: false, // Ensure no automatic leading widget
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/'); // Navigate back to the home page
            },
            icon: const Icon(
              Icons.home, // Home icon
            ),
          ),
          // IconButton( // Keep the QR code generate button if you have it
          //   onPressed: () {
          //     // Navigator.popAndPushNamed(context, '/generate');
          //   },
          //   icon: const Icon(
          //     Icons.qr_code,
          //   ),
          // )
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: MobileScanner(
              controller: controller,
              onDetect: _handleScan,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (scannedURL != null)
                    Text(
                      'Scanned URL: $scannedURL',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 8),
                  if (analysisResult != null)
                    Text(
                      'Analysis Result: $analysisResult',
                      style: TextStyle(
                        color: isMaliciousUrl ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (scannedURL != null &&
                      (Uri.tryParse(scannedURL!) != null) &&
                      !isMaliciousUrl)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: InkWell(
                        child: Text(
                          'Open URL',
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        onTap: () async {
                          String urlToLaunch = scannedURL!;
                          final uri = Uri.tryParse(urlToLaunch);
                          if (uri != null && uri.scheme.isEmpty) {
                            urlToLaunch = 'http://$urlToLaunch';
                          }

                          final Uri launchUri = Uri.parse(urlToLaunch);
                          if (await canLaunchUrl(launchUri)) {
                            await launchUrl(launchUri);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Could not launch URL: $launchUri')),
                            );
                          }
                        },
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _scanNext,
                    child: const Text('Scan Next QR Code'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}