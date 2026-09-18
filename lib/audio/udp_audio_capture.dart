import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'audio_capture.dart';

class UdpAudioCapture implements AudioCaptureService {
  static const port = 48123;

  RawDatagramSocket? _socket;
  final _controller = StreamController<Float32List>.broadcast();
  bool _capturing = false;

  @override
  bool get isCapturing => _capturing;

  @override
  Stream<Float32List> get audioStream => _controller.stream;

  @override
  Future<void> start(AudioSource source) async {
    _socket = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      port,
      reuseAddress: true,
    );
    _socket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = _socket!.receive();
      if (datagram == null) return;
      final bytes = datagram.data;
      final samples = Float32List(bytes.lengthInBytes ~/ 2);
      final pcm16 = Int16List.view(
        bytes.buffer,
        bytes.offsetInBytes,
        bytes.lengthInBytes ~/ 2,
      );
      for (var i = 0; i < samples.length; i++) {
        samples[i] = pcm16[i] / 32768.0;
      }
      _controller.add(samples);
    });
    _capturing = true;
  }

  @override
  Future<void> stop() async {
    _capturing = false;
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    _controller.close();
  }
}
