import 'package:flutter/material.dart';
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
      return (analysis.containsKey('malware') &&
          analysis['malware'] == true) ||
          (analysis.containsKey('phishing') &&
              analysis['phishing'] == true) ||
          (analysis.containsKey('suspicious') &&
              analysis['suspicious'] == true &&
              (analysis['risk_score'] is num
                  ? (analysis['risk_score'] as num).toInt() > 75
                  : false));
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

class URLAnalysisPage extends StatefulWidget {
  const URLAnalysisPage({super.key});

  @override
  State<URLAnalysisPage> createState() => _URLAnalysisPageState();
}

class _URLAnalysisPageState extends State<URLAnalysisPage> {
  final TextEditingController _urlController = TextEditingController();
  String? analysisResult;
  Map<String, dynamic>? fullAnalysis;
  final ipqsChecker = IPQS();
  bool isAnalyzing = false;

  Future<void> _analyzeURL() async {
    setState(() {
      analysisResult = 'Analyzing...';
      fullAnalysis = null;
      isAnalyzing = true;
    });

    String urlToAnalyze = _urlController.text.trim();
    if (urlToAnalyze.isNotEmpty) {
      Uri? parsedUri = Uri.tryParse(urlToAnalyze);
      if (parsedUri != null) {
        if (parsedUri.scheme.isEmpty) {
          urlToAnalyze = 'http://$urlToAnalyze';
        }

        // Simulate a 5-second delay
        await Future.delayed(const Duration(seconds: 5));

        final analysis = await ipqsChecker.getAnalysis(urlToAnalyze);
        final bool isMalicious = await ipqsChecker.isMalicious(urlToAnalyze);

        setState(() {
          isAnalyzing = false;
          fullAnalysis = analysis;
          if (analysis.containsKey('error')) {
            analysisResult = 'Error: ${analysis['error']}';
          } else {
            analysisResult = isMalicious
                ? "'$urlToAnalyze' is likely Malicious (Risk: ${analysis['risk_score'] ?? 'N/A'}%).\n\nFull Analysis (JSON):\n${JsonEncoder.withIndent('  ').convert(analysis)}"
                : "'$urlToAnalyze' is likely Safe (Risk: ${analysis['risk_score'] ?? 'N/A'}%).\n\nFull Analysis (JSON):\n${JsonEncoder.withIndent('  ').convert(analysis)}";
          }
        });
      } else {
        setState(() {
          isAnalyzing = false;
          analysisResult = 'Invalid URL format.';
          fullAnalysis = null;
        });
      }
    } else {
      setState(() {
        isAnalyzing = false;
        analysisResult = 'Please enter a URL.';
        fullAnalysis = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('URL Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/'); // Navigate to the home page route
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Enter URL to Analyze',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isAnalyzing ? null : _analyzeURL,
              child: isAnalyzing
                  ? const CircularProgressIndicator()
                  : const Text('Analyze URL'),
            ),
            const SizedBox(height: 20),
            if (analysisResult != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analysis Result:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysisResult!,
                    style: TextStyle(
                      color: fullAnalysis != null
                          ? (fullAnalysis!.containsKey('malware') &&
                          fullAnalysis!['malware'] == true ||
                          fullAnalysis!.containsKey('phishing') &&
                              fullAnalysis!['phishing'] == true ||
                          fullAnalysis!.containsKey('suspicious') &&
                              fullAnalysis!['suspicious'] == true &&
                              (fullAnalysis!['risk_score'] is num
                                  ? (fullAnalysis!['risk_score'] as num)
                                  .toInt() >
                                  75
                                  : false))
                          ? Colors.red
                          : Colors.green
                          : Colors.black87,
                    ),
                  ),
                  if (fullAnalysis != null &&
                      !fullAnalysis!.containsKey('error') &&
                      !(fullAnalysis!.containsKey('malware') &&
                          fullAnalysis!['malware'] == true ||
                          fullAnalysis!.containsKey('phishing') &&
                              fullAnalysis!['phishing'] == true ||
                          fullAnalysis!.containsKey('suspicious') &&
                              fullAnalysis!['suspicious'] == true &&
                              (fullAnalysis!['risk_score'] is num
                                  ? (fullAnalysis!['risk_score'] as num)
                                  .toInt() >
                                  75
                                  : false)))
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: InkWell(
                        child: const Text(
                          'Open URL',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        onTap: () async {
                          String urlToLaunch = _urlController.text.trim();
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
                                  content: Text(
                                      'Could not launch URL: $launchUri')),
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}