import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiKey = 'e311704811aa87c73bb08a025e3d5a01';

void main() => runApp(const WeatherApp());

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Forecast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? currentWeather;
  List<dynamic> forecast = [];
  bool loading = false;
  String? error;

  Future<void> fetchWeather(String city) async {
    if (city.trim().isEmpty) {
      setState(() {
        error = 'Please enter a city.';
        return;
      });
    }

    setState(() {
      loading = true;
      error = null;
      currentWeather = null;
      forecast = [];
    });

    final weatherUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
    final forecastUrl =
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric';

    try {
      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (weatherResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        setState(() {
          currentWeather = json.decode(weatherResponse.body);
          forecast = json.decode(forecastResponse.body)['list'];
          loading = false;
        });
      } else {
        setState(() {
          error = 'City not found or API error.';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Something went wrong.';
        loading = false;
      });
    }
  }

  Widget buildWeatherCard(Map<String, dynamic> weather) {
    final temp = weather['main']['temp'];
    final desc = weather['weather'][0]['description'];
    final icon = weather['weather'][0]['icon'];
    final city = weather['name'];
    final country = weather['sys']['country'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Colors.white10, Colors.white24],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        children: [
          Text(
            '$city, $country',
            style: const TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Image.network('https://openweathermap.org/img/wn/$icon@2x.png'),
          Text(
            '${temp.toStringAsFixed(1)} °C',
            style: const TextStyle(fontSize: 40, color: Colors.white),
          ),
          Text(
            desc.toUpperCase(),
            style: const TextStyle(
                fontSize: 16, letterSpacing: 1, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget buildForecastList() {
    final items = forecast.where((item) {
      final date = DateTime.parse(item['dt_txt']);
      return date.hour == 12;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '5-Day Forecast',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        ...items.map((item) {
          final date = item['dt_txt'].split(' ')[0];
          final temp = item['main']['temp'];
          final desc = item['weather'][0]['description'];
          final icon = item['weather'][0]['icon'];
          return Card(
            color: Colors.white10,
            elevation: 2,
            child: ListTile(
              leading: Image.network(
                  'https://openweathermap.org/img/wn/$icon@2x.png'),
              title: Text(date, style: const TextStyle(color: Colors.white)),
              subtitle: Text('$desc - ${temp.toStringAsFixed(1)} °C',
                  style: const TextStyle(color: Colors.white70)),
            ),
          );
        })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Weather App'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onSubmitted: fetchWeather,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white12,
                hintText: 'Enter city',
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : () => fetchWeather(_controller.text),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Get Weather'),
            ),
            const SizedBox(height: 20),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.redAccent)),
            if (currentWeather != null) buildWeatherCard(currentWeather!),
            const SizedBox(height: 20),
            if (forecast.isNotEmpty) buildForecastList(),
          ],
        ),
      ),
    );
  }
}
