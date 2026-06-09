import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _endpoint = 'https://api.deepseek.com/chat/completions';

  /// Sends sensor data to the DeepSeek API and retrieves analysis comments.
  static Future<String> analyzeGait({
    required String apiKey,
    required double fsr1Newtons,
    required double fsr2Newtons,
    required double temp,
    required double humidity,
    required double cop,
    required double cadence,
    required int stepCount,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('API Key is empty. Please enter your DeepSeek API key in Developer Settings.');
    }

    final Map<String, String> headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json; charset=utf-8',
    };

    final Map<String, dynamic> body = {
      'model': 'deepseek-chat',
      'messages': [
        {
          'role': 'system',
          'content': 'You are an automated informational assistant integrated into a smart Ankle-Foot Orthosis (AFO). Your job is to analyze real-time sensor data provided by the user and summarize it in plain, encouraging English.\n\n'
              'Strict Rules:\n'
              'Keep your response under 3 sentences.\n'
              'Do NOT diagnose any medical conditions or suggest changes to medical treatment.\n'
              'Do NOT tell the user to modify the physical structure of the AFO.\n'
              'If the temperature exceeds 32°C or humidity exceeds 70%, gently suggest taking a brief rest to let the skin breathe and prevent friction.\n'
              'If the force distribution is heavily skewed to one sensor, simply note the imbalance (e.g., "You are currently putting more weight on your heel").\n'
              'Mention their active step count and cadence as encouragement when walking.'
        },
        {
          'role': 'user',
          'content': 'Current sensor readings:\n'
              '- Anterior Force (FSR1): ${fsr1Newtons.toStringAsFixed(1)} N\n'
              '- Posterior Force (FSR2): ${fsr2Newtons.toStringAsFixed(1)} N\n'
              '- Under-foot Temperature: ${temp.toStringAsFixed(1)}°C\n'
              '- Under-foot Humidity: ${humidity.toStringAsFixed(1)}%\n'
              '- Center of Pressure (COP) Shift: ${cop.toStringAsFixed(2)}\n'
              '- Walking Cadence: ${cadence.toStringAsFixed(0)} Steps/Min\n'
              '- Cumulative Step Count: $stepCount'
        }
      ],
      'temperature': 0.7,
      'max_tokens': 150,
    };

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String content = data['choices'][0]['message']['content'] ?? '';
        return content.trim();
      } else {
        final errorMsg = _parseErrorResponse(response.body);
        throw Exception('Server returned error code: ${response.statusCode}. Details: $errorMsg');
      }
    } catch (e) {
      throw Exception('Failed to connect to DeepSeek API: $e');
    }
  }

  /// Parses error response from body if available
  static String _parseErrorResponse(String body) {
    try {
      final data = jsonDecode(body);
      if (data != null && data['error'] != null && data['error']['message'] != null) {
        return data['error']['message'];
      }
    } catch (_) {}
    return body.isNotEmpty ? body : 'Unknown network error';
  }

  /// Generates a realistic mock insight locally for demo purposes when no key is entered.
  static Future<String> simulateAnalysis({
    required double fsr1Newtons,
    required double fsr2Newtons,
    required double temp,
    required double humidity,
    required double cop,
    required double cadence,
    required int stepCount,
  }) async {
    // Artificial loading delay for realism
    await Future.delayed(const Duration(milliseconds: 1500));

    // Rule 1: Temperature > 32 or Humidity > 70
    if (temp > 32.0 || humidity > 70.0) {
      final String triggerFactor = temp > 32.0 ? 'temperature (${temp.toStringAsFixed(1)}°C)' : 'humidity (${humidity.toStringAsFixed(1)}%)';
      return 'I notice that your orthosis $triggerFactor is elevated. I gently suggest taking a brief rest to let your skin breathe and prevent friction. Otherwise, your step pattern is looking steady.';
    }

    // Rule 2: Force heavily skewed
    final double total = fsr1Newtons + fsr2Newtons;
    if (total > 5.0) {
      final double ratio1 = fsr1Newtons / total;
      final double ratio2 = fsr2Newtons / total;
      if (ratio1 > 0.75) {
        return 'You are currently putting significantly more weight on the front of your foot. Try to adjust your posture and shift some pressure back toward your heel. Keep going, you have reached $stepCount steps!';
      } else if (ratio2 > 0.75) {
        return 'You are currently putting more weight on your heel. Focus on stepping forward smoothly through your toes. Your walking cadence is steady at ${cadence.toStringAsFixed(0)} steps per minute!';
      }
    }

    // Default: Healthy balance and activity
    if (stepCount > 0) {
      return 'Your force distribution is well-balanced. Great job on taking $stepCount steps today at a cadence of ${cadence.toStringAsFixed(0)} steps per minute. Keep up this healthy, consistent stride!';
    }
    return 'Your force distribution is well-balanced and your foot microclimate is in the optimal comfort range. Keep up this healthy, consistent stride as you walk!';
  }
}
