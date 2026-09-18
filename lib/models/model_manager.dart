import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';
import '../core/languages.dart';

enum PackStatus { notDownloaded, downloading, downloaded, error }

class PackProgress {
  final PackStatus status;
  final double progress;
  final String? error;
  const PackProgress(this.status, this.progress, [this.error]);
}

class ModelManager {
  final Dio _dio;

  ModelManager({Dio? dio}) : _dio = dio ?? Dio();

  Future<Directory> get modelsDir async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/models');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<String> coreModelPath(String fileName) async {
    final dir = await modelsDir;
    return '${dir.path}/core/$fileName';
  }

  Future<bool> coreModelsReady() async {
    final whisper = await coreModelPath(AppConstants.whisperModelFile);
    final translator = await coreModelPath(AppConstants.translatorModelFile);
    return File(whisper).existsSync() && File(translator).existsSync();
  }

  Future<bool> isLanguagePackDownloaded(Language lang) async {
    if (lang.isBaseLanguage) return true; // Español e Inglés vienen incluidos
    final dir = await modelsDir;
    final pack = File('${dir.path}/packs/${lang.code}/model.bin');
    return pack.existsSync();
  }

  Stream<PackProgress> downloadCoreModels() async* {
    final dir = await modelsDir;
    final coreDir = Directory('${dir.path}/core');
    if (!coreDir.existsSync()) coreDir.createSync(recursive: true);

    final files = {
      AppConstants.whisperModelFile: AppConstants.whisperModelUrl,
      AppConstants.translatorModelFile: AppConstants.translatorModelUrl,
    };

    var done = 0;
    for (final entry in files.entries) {
      final target = '${coreDir.path}/${entry.key}';
      if (File(target).existsSync()) {
        done++;
        yield PackProgress(PackStatus.downloading, done / files.length);
        continue;
      }
      yield* _download(
        entry.value,
        target,
        (p) => PackProgress(
          PackStatus.downloading,
          (done + p) / files.length,
        ),
      );
      await _verifySha256(target);
      done++;
    }
    yield const PackProgress(PackStatus.downloaded, 1.0);
  }

  Stream<PackProgress> downloadLanguagePack(Language lang) async* {
    if (lang.isBaseLanguage) {
      yield const PackProgress(PackStatus.downloaded, 1.0);
      return;
    }
    final dir = await modelsDir;
    final packDir = Directory('${dir.path}/packs/${lang.code}');
    if (!packDir.existsSync()) packDir.createSync(recursive: true);
    final target = '${packDir.path}/model.bin';

    if (File(target).existsSync()) {
      yield const PackProgress(PackStatus.downloaded, 1.0);
      return;
    }

    final downloadUrl = '${AppConstants.translationPacksBaseUrl}/opus-mt-es-${lang.code}/resolve/main/model.npz';

    yield* _download(
      downloadUrl,
      target,
      (p) => PackProgress(PackStatus.downloading, p),
    );
    await _verifySha256(target);
    yield const PackProgress(PackStatus.downloaded, 1.0);
  }

  Future<void> deleteLanguagePack(Language lang) async {
    if (lang.isBaseLanguage) return;
    final dir = await modelsDir;
    final packDir = Directory('${dir.path}/packs/${lang.code}');
    if (packDir.existsSync()) packDir.deleteSync(recursive: true);
  }

  Stream<PackProgress> _download(
    String url,
    String target,
    PackProgress Function(double) map,
  ) async* {
    final controller = StreamController<PackProgress>();
    _dio.download(
      url,
      target,
      onReceiveProgress: (received, total) {
        if (total > 0) controller.add(map(received / total));
      },
    ).then((_) {
      controller.close();
    }).catchError((e) {
      controller.add(PackProgress(PackStatus.error, 0, e.toString()));
      controller.close();
    });
    yield* controller.stream;
  }

  Future<void> _verifySha256(String path) async {
    final file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw ModelManagerException('Descarga incompleta: $path');
    }
    final digest = await sha256.bind(file.openRead()).first;
    final manifest = File('$path.sha256');
    if (manifest.existsSync()) {
      final expected = (await manifest.readAsString()).trim();
      if (digest.toString() != expected) {
        file.deleteSync();
        throw ModelManagerException('Checksum inválido en $path');
      }
    }
  }
}

class ModelManagerException implements Exception {
  final String message;
  ModelManagerException(this.message);
  @override
  String toString() => 'ModelManagerException: $message';
}
