import 'dart:typed_data';
import 'dart:ui' as ui;

/// A pixel-art sprite defined as a 2D color array.
/// 0 = transparent. Non-zero values are 0xAARRGGBB colors.
class PixelSprite {
  const PixelSprite({
    required this.pixels,
    required this.width,
    required this.height,
  });

  final List<List<int>> pixels;
  final int width;
  final int height;

  /// Rasterize to a [ui.Image] at [scale] pixels per sprite pixel.
  Future<ui.Image> toImage(int scale) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();

    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final color = pixels[row][col];
        if (color == 0) {
          continue;
        }
        paint.color = ui.Color(color);
        canvas.drawRect(
          ui.Rect.fromLTWH(
            col * scale.toDouble(),
            row * scale.toDouble(),
            scale.toDouble(),
            scale.toDouble(),
          ),
          paint,
        );
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(width * scale, height * scale);
  }
}

/// A sequence of [PixelSprite] frames played at [frameDuration] seconds/frame.
class PixelAnimation {
  const PixelAnimation({required this.frames, required this.frameDuration});

  final List<PixelSprite> frames;
  final double frameDuration;

  int frameCount() => frames.length;

  PixelSprite frameAt(double elapsedSeconds) {
    if (frames.isEmpty) {
      throw RangeError('PixelSprite.frames is empty');
    }
    final totalDuration = frameDuration * frames.length;
    final looped = elapsedSeconds % totalDuration;
    final idx = (looped / frameDuration).floor().clamp(0, frames.length - 1);
    return frames[idx];
  }
}

/// Encodes a raw RGBA byte list into a [ui.Image].
Future<ui.Image> bytesToImage(Uint8List bytes, int width, int height) {
  final completer = ui.ImmutableBuffer.fromUint8List(bytes);
  return completer.then((buf) async {
    final descriptor = ui.ImageDescriptor.raw(
      buf,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    return frame.image;
  });
}
