import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:cleanclik/core/models/waste_models.dart';
import 'package:cleanclik/core/services/camera/qr_bin_service.dart';
import 'package:cleanclik/core/theme/category_visuals.dart';

/// In-app generator for waste bin QR codes.
///
/// Replaces the old scripts/generate_bin_qr_codes.py workflow: pick a
/// category, stamp the current GPS location, preview a Snapcode-style card,
/// and print it straight from the phone.
class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final GlobalKey _qrCardKey = GlobalKey();
  final TextEditingController _locationNameController = TextEditingController();

  WasteCategory _category = WasteCategory.recycle;
  late String _binId;
  double? _latitude;
  double? _longitude;
  bool _fetchingLocation = false;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _binId = QRBinService.generateBinId(_category);
    _fetchLocation();
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Location permission needed to stamp bin coordinates');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      _showMessage('Could not get location: $e');
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  void _selectCategory(WasteCategory category) {
    setState(() {
      _category = category;
      _binId = QRBinService.generateBinId(category);
    });
  }

  String? get _payload {
    final lat = _latitude;
    final lng = _longitude;
    if (lat == null || lng == null) return null;
    return QRBinService.createQRPayload(
      binId: _binId,
      category: _category,
      latitude: lat,
      longitude: lng,
      locationName: _locationNameController.text,
    );
  }

  Future<Uint8List?> _captureQrCard() async {
    final boundary = _qrCardKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _printQrCard() async {
    if (_payload == null || _printing) return;
    setState(() => _printing = true);
    try {
      final pngBytes = await _captureQrCard();
      if (pngBytes == null) {
        _showMessage('Failed to render QR card');
        return;
      }

      await Printing.layoutPdf(
        name: '$_binId.pdf',
        onLayout: (PdfPageFormat format) async {
          final doc = pw.Document();
          doc.addPage(
            pw.Page(
              pageFormat: format,
              build: (context) => pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(pw.MemoryImage(pngBytes), width: 340),
                    pw.SizedBox(height: 24),
                    pw.Text(
                      'Scan with CleanClik to dispose responsibly',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
          return doc.save();
        },
      );
    } catch (e) {
      _showMessage('Printing failed: $e');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payload = _payload;

    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Bin QR Generator'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCategorySelector(),
              const SizedBox(height: 20),
              Center(
                child: payload == null
                    ? _buildLocationPending()
                    : RepaintBoundary(
                        key: _qrCardKey,
                        child: _SnapQrCard(
                          payload: payload,
                          category: _category,
                          binId: _binId,
                          locationName: _locationNameController.text,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _locationNameController,
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Location name (optional)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  hintText: 'e.g. Central Park - North Gate',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildLocationRow(theme),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: payload == null || _printing ? null : _printQrCard,
                style: FilledButton.styleFrom(
                  backgroundColor: _category.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _printing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.print),
                label: Text(
                  _printing ? 'Preparing…' : 'Print QR Code',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: WasteCategory.values.map((category) {
        final selected = category == _category;
        return ChoiceChip(
          selected: selected,
          onSelected: (_) => _selectCategory(category),
          avatar: Icon(
            CategoryVisuals.iconOf(category),
            size: 18,
            color: selected ? Colors.white : category.color,
          ),
          label: Text(category.codeName),
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
          selectedColor: category.color,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? category.color : Colors.white24,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationPending() {
    return Container(
      width: 300,
      height: 300,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_fetchingLocation) ...[
            const CircularProgressIndicator(color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Getting location…',
              style: TextStyle(color: Colors.white54),
            ),
          ] else ...[
            const Icon(Icons.location_off, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Location needed to create a bin QR',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _fetchLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationRow(ThemeData theme) {
    final lat = _latitude;
    final lng = _longitude;
    return Row(
      children: [
        const Icon(Icons.my_location, color: Colors.white38, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            lat == null || lng == null
                ? 'No coordinates yet'
                : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        TextButton.icon(
          onPressed: _fetchingLocation ? null : _fetchLocation,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Update'),
        ),
      ],
    );
  }
}

/// Snapcode-style QR card: bold category-colored card with rounded corners,
/// circular QR modules, and the category icon in the center.
class _SnapQrCard extends StatelessWidget {
  final String payload;
  final WasteCategory category;
  final String binId;
  final String locationName;

  const _SnapQrCard({
    required this.payload,
    required this.category,
    required this.binId,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    const darkModule = Color(0xFF17171B);

    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: category.color,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: category.color.withValues(alpha: 0.45),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 232,
                  gapless: true,
                  // High error correction so the center icon badge never
                  // breaks scanning.
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: category.color,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: darkModule,
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Icon(
                    CategoryVisuals.iconOf(category),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            category.codeName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            binId,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          if (locationName.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              locationName.trim(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
