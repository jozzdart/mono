import 'dart:io';
import 'dart:async';

import '../style/theme.dart';
import '../system/frame_renderer.dart';

class ServiceEndpoint {
  final String name;
  final Uri url;
  final String method; // GET | HEAD
  final Duration timeout;

  ServiceEndpoint(
    this.name,
    String url, {
    this.method = 'GET',
    this.timeout = const Duration(seconds: 5),
  }) : url = Uri.parse(url);
}

class ServiceMonitor {
  final List<ServiceEndpoint> endpoints;
  final PromptTheme theme;
  final String? title;
  final int concurrency;
  final int retries;

  const ServiceMonitor(
    this.endpoints, {
    this.theme = const PromptTheme(),
    this.title,
    this.concurrency = 6,
    this.retries = 1,
  });

  Future<void> run() async {
    final style = theme.style;
    final label = title ?? 'Service Monitor';

    final top = style.showBorder
        ? FrameRenderer.titleWithBorders(label, theme)
        : FrameRenderer.plainTitle(label, theme);
    stdout.writeln('${theme.bold}$top${theme.reset}');

    final results = await _runPings();

    // Column widths
    final nameW = _cap(_maxLen(endpoints.map((e) => e.name.length)), 8, 24);
    final urlW = _cap(
        _maxLen(endpoints.map((e) => e.url.toString().length)), 20, 48);

    // Header line
    final header = StringBuffer()
      ..write('${_pad('Name', nameW)}  ')
      ..write('${_pad('URL', urlW)}  ')
      ..write('${_pad('Code', 4)}  ')
      ..write('${_pad('Latency', 8)}');
    stdout.writeln(
        '${theme.gray}${style.borderVertical}${theme.reset} '
        '${theme.bold}${theme.gray}$header${theme.reset}');

    int okCount = 0, warnCount = 0, errCount = 0, timeoutCount = 0;
    for (final r in results) {
      final status = _statusOf(r);
      switch (status) {
        case _LineStatus.ok:
          okCount++;
          break;
        case _LineStatus.warn:
          warnCount++;
          break;
        case _LineStatus.error:
          errCount++;
          break;
        case _LineStatus.timeout:
          timeoutCount++;
          break;
      }

      final icon = _statusIcon(status);
      final name = _pad(r.endpoint.name, nameW);
      final urlStr = _truncate(r.endpoint.url.toString(), urlW);
      final code = r.code != null
          ? '${r.ok ? theme.info : (r.code! < 500 ? theme.warn : theme.error)}${_pad(r.code.toString(), 4)}${theme.reset}'
          : '${theme.warn}${_pad('—', 4)}${theme.reset}';
      final latency = r.elapsed != null
          ? '${theme.selection}${_pad('${r.elapsed!.inMilliseconds} ms', 8)}${theme.reset}'
          : '${theme.warn}${_pad('timeout', 8)}${theme.reset}';
      final note = r.errorMessage != null
          ? ' ${theme.gray}(${r.errorMessage})${theme.reset}'
          : '';

      stdout.writeln(
        '${theme.gray}${style.borderVertical}${theme.reset} '
        '$icon ${theme.bold}${theme.accent}$name${theme.reset}  '
        '${theme.gray}$urlStr${theme.reset}  '
        '$code  $latency$note',
      );
    }

    if (style.showBorder) {
      final summary = '${theme.bold}${theme.gray}Summary:${theme.reset} '
          '${theme.info}ok $okCount${theme.reset}  •  '
          '${theme.warn}warn $warnCount${theme.reset}  •  '
          '${theme.error}error $errCount${theme.reset}  •  '
          '${theme.warn}timeout $timeoutCount${theme.reset}';
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} $summary');
      stdout.writeln(FrameRenderer.bottomLine(label, theme));
    }
  }

  Future<List<_PingResult>> _runPings() async {
    final results = List<_PingResult?>.filled(endpoints.length, null);
    int nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final i = nextIndex;
        if (i >= endpoints.length) break;
        nextIndex = i + 1;
        results[i] = await _pingWithRetries(endpoints[i], retries);
      }
    }

    final workers = List.generate(concurrency, (_) => worker());
    await Future.wait(workers);
    return results.cast<_PingResult>();
  }

  Future<_PingResult> _pingWithRetries(ServiceEndpoint endpoint, int retries) async {
    _PingResult result = await _pingOnce(endpoint);
    int attempts = 0;
    while (result.code == null && attempts < retries) {
      attempts++;
      result = await _pingOnce(endpoint);
    }
    return result;
  }

  Future<_PingResult> _pingOnce(ServiceEndpoint endpoint) async {
    final client = HttpClient();
    client.connectionTimeout = endpoint.timeout;
    final watch = Stopwatch()..start();

    try {
      final req = await client.openUrl(endpoint.method, endpoint.url);
      req.followRedirects = true;
      final res = await req.close().timeout(endpoint.timeout);
      await res.drain<void>();
      watch.stop();
      final code = res.statusCode;
      if (endpoint.method == 'HEAD' && (code == 405 || code == 501)) {
        return await _fallbackGet(client, endpoint, watch);
      }
      return _PingResult(endpoint, elapsed: watch.elapsed, code: code);
    } on HandshakeException catch (e) {
      watch.stop();
      return _PingResult(endpoint,
          elapsed: null, code: null, errorMessage: 'TLS ${e.runtimeType}');
    } on SocketException catch (e) {
      watch.stop();
      return _PingResult(endpoint,
          elapsed: null,
          code: null,
          errorMessage: e.osError?.message ?? 'socket');
    } on HttpException catch (e) {
      watch.stop();
      return _PingResult(endpoint,
          elapsed: null, code: null, errorMessage: e.message);
    } on TlsException catch (e) {
      watch.stop();
      return _PingResult(endpoint,
          elapsed: null, code: null, errorMessage: 'TLS ${e.message}');
    } on TimeoutException {
      watch.stop();
      return _PingResult(endpoint,
          elapsed: null, code: null, errorMessage: 'timeout');
    } catch (e) {
      watch.stop();
      return _PingResult(endpoint,
          elapsed: null, code: null, errorMessage: e.toString());
    } finally {
      client.close(force: true);
    }
  }

  Future<_PingResult> _fallbackGet(
      HttpClient client, ServiceEndpoint endpoint, Stopwatch watch) async {
    try {
      watch.reset();
      watch.start();
      final req = await client.getUrl(endpoint.url);
      req.followRedirects = true;
      final res = await req.close().timeout(endpoint.timeout);
      await res.drain<void>();
      watch.stop();
      return _PingResult(endpoint, elapsed: watch.elapsed, code: res.statusCode);
    } catch (e) {
      watch.stop();
      return _PingResult(endpoint,
          elapsed: null, code: null, errorMessage: e.toString());
    }
  }

  String _pad(String text, int width) {
    if (text.length >= width) return text;
    return text + ' ' * (width - text.length);
  }

  String _truncate(String text, int width) {
    if (text.length <= width) return _pad(text, width);
    if (width <= 1) return text.substring(0, width);
    return text.substring(0, width - 1) + '…';
  }

  int _cap(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  int _maxLen(Iterable<int> lengths) {
    var max = 0;
    for (final l in lengths) {
      if (l > max) max = l;
    }
    return max;
  }

  _LineStatus _statusOf(_PingResult r) {
    if (r.code == null) return _LineStatus.timeout;
    if (r.code! >= 200 && r.code! < 400) return _LineStatus.ok;
    if (r.code! >= 400 && r.code! < 500) return _LineStatus.warn;
    return _LineStatus.error;
  }

  String _statusIcon(_LineStatus s) {
    switch (s) {
      case _LineStatus.ok:
        return '${theme.checkboxOn}✔${theme.reset}';
      case _LineStatus.warn:
        return '${theme.warn}▲${theme.reset}';
      case _LineStatus.error:
        return '${theme.error}✖${theme.reset}';
      case _LineStatus.timeout:
        return '${theme.warn}…${theme.reset}';
    }
  }
}

class _PingResult {
  final ServiceEndpoint endpoint;
  final Duration? elapsed;
  final int? code;
  final String? errorMessage;

  _PingResult(this.endpoint, {this.elapsed, this.code, this.errorMessage});

  bool get ok => code != null && code! >= 200 && code! < 400;
}

enum _LineStatus { ok, warn, error, timeout }
