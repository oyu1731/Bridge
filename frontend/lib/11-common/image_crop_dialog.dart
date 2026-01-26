import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class ImageCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  
  const ImageCropDialog({super.key, required this.imageBytes});

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  double _cropSize = 120.0; // クロップ円のサイズ（可変）
  Offset _cropPosition = Offset.zero; // クロップ円の位置（Canvas中央からの相対位置）
  img.Image? _decodedImage;
  ui.Image? _uiImage;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    // 画像をデコード
    _decodedImage = img.decodeImage(widget.imageBytes);
    
    // UI用の画像を作成
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    _uiImage = frame.image;
    
    setState(() {});
  }


  Future<Uint8List> _getCroppedImage() async {
    if (_decodedImage == null || _canvasSize.width == 0) {
      return widget.imageBytes;
    }

    // 元画像とCanvasのアスペクト比
    final imgW = _decodedImage!.width.toDouble();
    final imgH = _decodedImage!.height.toDouble();
    final canvasW = _canvasSize.width;
    final canvasH = _canvasSize.height;
    final imgAspect = imgW / imgH;
    final canvasAspect = canvasW / canvasH;

    // BoxFit.containで画像がCanvasに収まる表示サイズと余白
    double displayW, displayH, offsetX, offsetY;
    if (imgAspect > canvasAspect) {
      displayW = canvasW;
      displayH = canvasW / imgAspect;
      offsetX = 0;
      offsetY = (canvasH - displayH) / 2;
    } else {
      displayH = canvasH;
      displayW = canvasH * imgAspect;
      offsetX = (canvasW - displayW) / 2;
      offsetY = 0;
    }

    // 枠の中心座標（Canvas基準）
    final cropCenterX = canvasW / 2 + _cropPosition.dx;
    final cropCenterY = canvasH / 2 + _cropPosition.dy;
    final cropRadius = _cropSize / 2;

    // 枠の左上座標（Canvas基準）
    final cropLeft = cropCenterX - cropRadius;
    final cropTop = cropCenterY - cropRadius;

    // 枠内の画像部分の座標（画像表示領域基準）
    final imgCropLeft = ((cropLeft - offsetX) * (imgW / displayW)).clamp(0, imgW - 1).round();
    final imgCropTop = ((cropTop - offsetY) * (imgH / displayH)).clamp(0, imgH - 1).round();
    final imgCropSize = (_cropSize * (imgW / displayW)).clamp(1, imgW - imgCropLeft).clamp(1, imgH - imgCropTop).round();

    // 枠が画像サイズより大きい場合は中央正方形クロップ
    if (imgCropSize > imgW || imgCropSize > imgH) {
      final minSide = imgW < imgH ? imgW : imgH;
      final cropX = ((imgW - minSide) / 2).round();
      final cropY = ((imgH - minSide) / 2).round();
      final cropped = img.copyCrop(
        _decodedImage!,
        x: cropX,
        y: cropY,
        width: minSide.round(),
        height: minSide.round(),
      );
      final finalImg = img.copyResize(cropped, width: 256, height: 256);
      return Uint8List.fromList(img.encodeJpg(finalImg, quality: 95));
    } else {
      final cropped = img.copyCrop(
        _decodedImage!,
        x: imgCropLeft,
        y: imgCropTop,
        width: imgCropSize,
        height: imgCropSize,
      );
      final finalImg = img.copyResize(cropped, width: 256, height: 256);
      return Uint8List.fromList(img.encodeJpg(finalImg, quality: 95));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uiImage == null) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('画像を読み込んでいます...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.crop_free, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'アイコンの範囲を選択',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // プレビュー領域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _canvasSize = constraints.biggest;
                    final maxOffsetX = (_canvasSize.width - _cropSize) / 2;
                    final maxOffsetY = (_canvasSize.height - _cropSize) / 2;
                    return GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _cropPosition += details.delta;
                          _cropPosition = Offset(
                            _cropPosition.dx.clamp(-maxOffsetX, maxOffsetX),
                            _cropPosition.dy.clamp(-maxOffsetY, maxOffsetY),
                          );
                        });
                      },
                      child: CustomPaint(
                        size: _canvasSize,
                        painter: _UnifiedCropPainter(
                          image: _uiImage!,
                          cropPosition: _cropPosition,
                          cropSize: _cropSize,
                        ),
                        child: Stack(
                          children: [
                            // ドラッグアイコン
                            Positioned(
                              left: _canvasSize.width / 2 + _cropPosition.dx - 24,
                              top: _canvasSize.height / 2 + _cropPosition.dy - 24,
                              child: IgnorePointer(
                                child: Icon(
                                  Icons.open_with,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 48,
                                  shadows: const [
                                    Shadow(color: Colors.black54, blurRadius: 8),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // コントロール
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '画面をドラッグして位置を調整、スライダーでサイズを調整',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // サイズ調整スライダー
                  Row(
                    children: [
                      const Icon(Icons.zoom_out, size: 20, color: Colors.grey),
                      Expanded(
                        child: Slider(
                          value: _cropSize,
                          min: 80.0,
                          max: 400.0,
                          divisions: 64,
                          label: '${_cropSize.round()}px',
                          onChanged: (value) {
                            setState(() {
                              _cropSize = value;
                              final maxOffsetX = (_canvasSize.width - _cropSize) / 2;
                              final maxOffsetY = (_canvasSize.height - _cropSize) / 2;
                              _cropPosition = Offset(
                                _cropPosition.dx.clamp(-maxOffsetX, maxOffsetX),
                                _cropPosition.dy.clamp(-maxOffsetY, maxOffsetY),
                              );
                            });
                          },
                        ),
                      ),
                      const Icon(Icons.zoom_in, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${_cropSize.round()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ボタン
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _cropPosition = Offset.zero;
                            _cropSize = 120.0;
                          });
                        },
                        child: const Text('リセット'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final croppedBytes = await _getCroppedImage();
                          if (context.mounted) {
                            Navigator.of(context).pop(croppedBytes);
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('決定'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnifiedCropPainter extends CustomPainter {
  final ui.Image image;
  final Offset cropPosition;
  final double cropSize;

  _UnifiedCropPainter({
    required this.image,
    required this.cropPosition,
    required this.cropSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 画像をCanvas全体に描画
    final paint = Paint();
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // クロップ円の中心座標
    final centerX = size.width / 2 + cropPosition.dx;
    final centerY = size.height / 2 + cropPosition.dy;
    final cropRadius = cropSize / 2;

    // 暗いオーバーレイ（円形の外側）
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(
        center: Offset(centerX, centerY),
        radius: cropRadius,
      ))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    // 円形の枠線（白）
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(
      Offset(centerX, centerY),
      cropRadius,
      borderPaint,
    );

    // 内側のガイド円（薄い白）
    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(
      Offset(centerX, centerY),
      cropRadius * 0.7,
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(_UnifiedCropPainter oldDelegate) {
    return oldDelegate.cropPosition != cropPosition ||
           oldDelegate.cropSize != cropSize ||
           oldDelegate.image != image;
  }
}
