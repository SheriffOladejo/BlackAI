import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:signalai/view/chart_analysis.dart';

class LoadingAnalysisScreen extends StatefulWidget {

  final String filepath;
  final Function callback;

  const LoadingAnalysisScreen({
    required this.filepath,
    required this.callback,
    Key? key,
  }) : super(key: key);

  @override
  _LoadingAnalysisScreenState createState() => _LoadingAnalysisScreenState();

}

class _LoadingAnalysisScreenState extends State<LoadingAnalysisScreen> {

  File? selectedImage;
  bool isAnalyzing = true;
  String analysisResult = '';
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      analyzeChart();
    });
  }

  Future<void> analyzeChart() async {
    try {
      setState(() {
        isAnalyzing = true;
        selectedImage = File(widget.filepath);
        analysisResult = '';
        errorMessage = '';
      });

      if (selectedImage == null) {
        throw Exception('No image selected');
      }

      final imageBytes = await selectedImage!.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      const apiKey = ''; // Replace with your actual API key
      const apiUrl = 'https://api.openai.com/v1/chat/completions';

      const systemMessage = '''
      You are an expert financial analyst specializing in technical analysis of candlestick charts.
      Analyze the provided chart image and respond with:
      1. Market Trend: (Bullish/Neutral/Bearish)
      2. Recommendation with explanation of why: (Strong Buy, Buy, Hold, Sell, Strong Sell)
      3. Detailed technical analysis: Include patterns, support/resistance levels in your explanation
      4. Specific buy triggers and confidence 
      5. Specific sell triggers and confidence level
      6. Respond only with valid JSON
      7. Do NOT include any introductory text, explanations, or the word "json" before the output
      Use professional but concise language.
      
      return json in this structure
      {
        "Market Trend": "String result",
        "Recommendation": "String result",
        "Technical Analysis": "String result",
        "Buy Trigger": "String result",
        "Sell Trigger": "String result",
        "Support Level": "\$Value",
        "Resistance Level": "\$Value"
      }
      
      Return the data in form of json specifying the points above.
      Return just concise json data alone, no extra explanations or text at the beginning, just structure whatever you have to say in json, because it will be parsed as-is
      ''';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-4-turbo",
          "messages": [
            {
              "role": "system",
              "content": systemMessage,
            },
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": "Analyze this candlestick chart and provide a detailed technical analysis with recommendations."
                },
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:image/jpeg;base64,$base64Image"
                  }
                }
              ],
            }
          ],
          "max_tokens": 1000,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final analysis = jsonResponse['choices'][0]['message']['content'];
        setState(() {
          analysisResult = analysis;
          isAnalyzing = false;
        });

        widget.callback();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChartAnalysisScreen(
                analysis: analysisResult,
                imagePath: widget.filepath,
              ),
            ),
          );
        }

      } else {
        throw Exception('Failed to analyze image: ${response.body}');
      }
    } catch (e) {
      setState(() {
        errorMessage = "Analysis failed: ${e.toString()}";
        isAnalyzing = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Analysis Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset("asset/image/chart.png",
              fit: BoxFit.fill,
              width: 24,
              height: 24,
            ),
            Container(width: 5),
            const Text(
              "Analyzing Market Trends",
              style: TextStyle(
                  fontFamily: 'inter-bold',
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("asset/image/analysis_loading.png"),
            Container(height: 25,),
            const Text('"Patience is the key to unlocking market potential"', style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              fontFamily: 'inter-medium'
            ), textAlign: TextAlign.center,)
          ],
        ),
      ),
      bottomSheet: Container(
        height: 100,
        alignment: Alignment.topCenter,
        width: MediaQuery.of(context).size.width,
        child: isAnalyzing
            ? const CircularProgressIndicator(color: Colors.grey)
            : errorMessage.isNotEmpty
            ? Text(errorMessage, style: TextStyle(color: Colors.red))
            : SizedBox.shrink(),
      ),
    );
  }
}
