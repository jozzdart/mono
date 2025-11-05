import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';

/// Temperature units supported by the widget.
enum TemperatureUnit { celsius, fahrenheit }

/// A themed CLI widget that shows live weather using the Open‑Meteo API.
///
/// Aligns with ThemeDemo styling via [PromptTheme] and [FrameRenderer].
class WeatherWidget {
  final String? city;
  final double? latitude;
  final double? longitude;
  final TemperatureUnit unit;
  final PromptTheme theme;
  final String title;

  const WeatherWidget.city(
    this.city, {
    this.unit = TemperatureUnit.celsius,
    this.theme = const PromptTheme(),
    this.title = 'Weather',
  })  : latitude = null,
        longitude = null;

  const WeatherWidget.coords({
    required this.latitude,
    required this.longitude,
    this.unit = TemperatureUnit.celsius,
    this.theme = const PromptTheme(),
    this.title = 'Weather',
  }) : city = null;

  /// Fetches and renders the weather box.
  Future<void> show() async {
    final style = theme.style;

    try {
      final loc = await _resolveLocation();
      final weather = await _fetchWeather(loc);

      final unitSymbol = unit == TemperatureUnit.celsius ? '°C' : '°F';
      final iconDesc = _iconAndDescription(weather.weatherCode);

      final header = FrameRenderer.titleWithBorders(
        '$title – ${loc.displayName}',
        theme,
      );
      stdout.writeln('${theme.bold}$header${theme.reset}');

      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.info}Now${theme.reset}: ${iconDesc.icon} ${iconDesc.description}');
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.accent}${weather.temperature.toStringAsFixed(1)}$unitSymbol${theme.reset}  •  Wind ${weather.windSpeed.toStringAsFixed(0)} km/h ${_arrowForWind(weather.windDirection)}');
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}lat ${loc.latitude.toStringAsFixed(2)}, lon ${loc.longitude.toStringAsFixed(2)}${theme.reset}');

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine('$title – ${loc.displayName}', theme));
      }
    } catch (e) {
      final label = '$title – Error';
      final top = FrameRenderer.titleWithBordersColored(label, theme, theme.error);
      stdout.writeln('${theme.bold}$top${theme.reset}');
      stdout.writeln(
          '${theme.error}${style.borderVertical}${theme.reset} ${theme.error}Failed to load weather: $e${theme.reset}');
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLineColored(label, theme, theme.error));
      }
    }
  }

  Future<_ResolvedLocation> _resolveLocation() async {
    if (latitude != null && longitude != null) {
      return _ResolvedLocation(
        displayName: '(${latitude!.toStringAsFixed(2)}, ${longitude!.toStringAsFixed(2)})',
        latitude: latitude!,
        longitude: longitude!,
      );
    }

    final q = (city ?? '').trim();
    if (q.isEmpty) {
      throw ArgumentError('Provide either city or coordinates');
    }

    // Open‑Meteo Geocoding API
    final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeQueryComponent(q)}&count=1');
    final json = await _getJson(uri);
    if (json is! Map<String, dynamic> || json['results'] == null) {
      throw StateError('Unexpected geocoding response');
    }
    final results = json['results'] as List<dynamic>;
    if (results.isEmpty) {
      throw StateError('Location not found for "$q"');
    }
    final r = results.first as Map<String, dynamic>;
    final name = [r['name'], r['admin1'], r['country']]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    return _ResolvedLocation(
      displayName: name,
      latitude: (r['latitude'] as num).toDouble(),
      longitude: (r['longitude'] as num).toDouble(),
    );
  }

  Future<_CurrentWeather> _fetchWeather(_ResolvedLocation loc) async {
    final unitParam = unit == TemperatureUnit.celsius ? 'celsius' : 'fahrenheit';
    final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${loc.latitude}&longitude=${loc.longitude}&current_weather=true&temperature_unit=$unitParam');
    final json = await _getJson(uri);
    if (json is! Map<String, dynamic> || json['current_weather'] == null) {
      throw StateError('Unexpected weather response');
    }
    final w = json['current_weather'] as Map<String, dynamic>;
    return _CurrentWeather(
      temperature: (w['temperature'] as num).toDouble(),
      windSpeed: (w['windspeed'] as num).toDouble(),
      windDirection: (w['winddirection'] as num).toDouble(),
      weatherCode: (w['weathercode'] as num).toInt(),
    );
  }

  Future<dynamic> _getJson(Uri uri) async {
    final client = HttpClient();
    client.userAgent = 'terminice-weather-widget';
    try {
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 8));
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode} for ${uri.toString()}');
      }
      final body = await res.transform(utf8.decoder).join();
      return jsonDecode(body);
    } on TimeoutException {
      throw TimeoutException('Request timed out');
    } finally {
      client.close(force: true);
    }
  }

  _WindArrow _arrowForWind(double deg) {
    // 8-wind rose
    const arrows = ['↑','↗','→','↘','↓','↙','←','↖'];
    final idx = ((deg % 360) / 45).round() % 8;
    return _WindArrow(arrows[idx]);
  }

  _IconDesc _iconAndDescription(int code) {
    // Based on WMO weather interpretation codes
    if (code == 0) return _IconDesc('☀️', 'Clear sky');
    if (code == 1) return _IconDesc('🌤', 'Mainly clear');
    if (code == 2) return _IconDesc('⛅', 'Partly cloudy');
    if (code == 3) return _IconDesc('☁️', 'Overcast');
    if (code == 45 || code == 48) return _IconDesc('🌫', 'Fog');
    if (code >= 51 && code <= 57) return _IconDesc('🌦', 'Drizzle');
    if (code >= 61 && code <= 67) return _IconDesc('🌧', 'Rain');
    if (code >= 71 && code <= 77) return _IconDesc('❄️', 'Snow');
    if (code >= 80 && code <= 82) return _IconDesc('🌦', 'Rain showers');
    if (code >= 95) return _IconDesc('⛈', 'Thunderstorm');
    return _IconDesc('🌡', 'Weather');
  }
}

class _ResolvedLocation {
  final String displayName;
  final double latitude;
  final double longitude;
  _ResolvedLocation({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class _CurrentWeather {
  final double temperature;
  final double windSpeed;
  final double windDirection;
  final int weatherCode;
  _CurrentWeather({
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.weatherCode,
  });
}

class _IconDesc {
  final String icon;
  final String description;
  const _IconDesc(this.icon, this.description);
}

class _WindArrow {
  final String arrow;
  const _WindArrow(this.arrow);
  @override
  String toString() => arrow;
}


