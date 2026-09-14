import 'package:dio/dio.dart';

/// Weather data model
class WeatherData {
  final double temperature;
  final double humidity;
  final String condition;
  final double rainfall;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.rainfall,
  });

  Map<String, dynamic> toJson() => {
    'weatherTemperature': temperature,
    'weatherHumidity': humidity,
    'weatherCondition': condition,
    'weatherRainfall': rainfall,
  };
}

/// Weather Service using OpenWeatherMap API
class WeatherService {
  static final _dio = Dio();
  static const String _apiKey = '680b7e32cf5ab8c9107aac32c782396a';

  /// Fetch current weather data for given coordinates
  static Future<WeatherData?> getCurrentWeather(double lat, double lng) async {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$lat'
          '&lon=$lng'
          '&appid=$_apiKey'
          '&units=metric'; // Celsius

      final response = await _dio.get(url);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final main = data['main'];
        final weather = data['weather'][0];
        final rain = data['rain'];
        
        return WeatherData(
          temperature: (main['temp'] as num).toDouble(),
          humidity: (main['humidity'] as num).toDouble(),
          condition: weather['main'] as String, // e.g., "Rain", "Clear", "Clouds"
          rainfall: rain != null ? (rain['1h'] as num?)?.toDouble() ?? 0.0 : 0.0,
        );
      }
      return null;
    } catch (e) {
      print('Weather API error: $e');
      return null;
    }
  }
}
