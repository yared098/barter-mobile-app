import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/categories_provider.dart';
import '../../providers/requests_provider.dart';
import '../../theme.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  final _specs = <({String key, String value})>[];

  String? _categoryId;
  String _type = 'BUY';
  bool _saving = false;
  bool _fetchingLocation = false;
  double? _capturedLat;
  double? _capturedLng;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  AppLocalizations get _t => AppLocalizations.of(context)!;

  Future<void> _useCurrentLocation() async {
    if (_fetchingLocation) return;
    setState(() => _fetchingLocation = true);
    final t = _t;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack(t.turnOnLocation);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _snack(t.locationPermissionDenied);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _snack(t.locationPermissionBlocked);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );

      String address = 'Current location';
      try {
        final places = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (places.isNotEmpty) {
          final p = places.first;
          final parts = <String>[
            if (p.subLocality != null && p.subLocality!.isNotEmpty)
              p.subLocality!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.administrativeArea != null &&
                p.administrativeArea!.isNotEmpty)
              p.administrativeArea!,
          ];
          if (parts.isNotEmpty) address = parts.join(', ');
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _capturedLat = pos.latitude;
        _capturedLng = pos.longitude;
        _locationCtrl.text = address;
      });
      _snack(t.locationCaptured);
    } on LocationServiceDisabledException {
      _snack(t.locationServicesDisabled);
    } on TimeoutException {
      _snack(t.locationTimeout);
    } on PermissionDeniedException {
      _snack(t.locationDeniedByUser);
    } catch (e) {
      _snack(t.locationError(e.toString().replaceFirst('Exception: ', '')));
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  void _clearLocation() {
    setState(() {
      _capturedLat = null;
      _capturedLng = null;
      _locationCtrl.clear();
    });
  }

  Future<void> _submit() async {
    final t = _t;
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (title.length < 3) {
      _snack(t.titleTooShort);
      return;
    }
    if (desc.isEmpty) {
      _snack(t.addDescriptionPrompt);
      return;
    }
    if (_categoryId == null) {
      _snack(t.pickCategoryPrompt);
      return;
    }

    final min = double.tryParse(_budgetMinCtrl.text.trim());
    final max = double.tryParse(_budgetMaxCtrl.text.trim());
    if (min != null && max != null && min > max) {
      _snack(t.budgetRangeInvalid);
      return;
    }

    final specsMap = <String, String>{};
    for (final s in _specs) {
      if (s.key.trim().isNotEmpty && s.value.trim().isNotEmpty) {
        specsMap[s.key.trim()] = s.value.trim();
      }
    }

    setState(() => _saving = true);
    try {
      await ref.read(requestsServiceProvider).create({
        'title': title,
        'description': desc,
        'categoryId': _categoryId,
        'type': _type,
        if (specsMap.isNotEmpty) 'specifications': specsMap,
        if (min != null) 'budgetMin': min,
        if (max != null) 'budgetMax': max,
        if (_locationCtrl.text.trim().isNotEmpty)
          'location': _locationCtrl.text.trim(),
        if (_capturedLat != null) 'latitude': _capturedLat,
        if (_capturedLng != null) 'longitude': _capturedLng,
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
      _snack(t.requestPostedSuccess);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          t.postARequest,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16.5,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _sectionLabel(t.whatDoYouNeed),
          _field(controller: _titleCtrl, hint: t.requestTitleHint),
          const SizedBox(height: 10),
          _sectionLabel(t.details),
          _field(
            controller: _descCtrl,
            hint: t.requestDescriptionHint,
            maxLines: 4,
          ),
          const SizedBox(height: 14),

          _sectionLabel(t.category),
          categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (_, __) => Text(t.couldNotLoadCategories),
            data: (cats) {
              final items = (cats as List).cast<Map<String, dynamic>>();
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((c) {
                  final id = c['id'] as String;
                  final name = c['name'] as String? ?? '—';
                  final icon = c['icon'] as String?;
                  final selected = _categoryId == id;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '${icon ?? ''} $name'.trim(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 14),

          _sectionLabel(t.howWillYouPay),
          Row(
            children: [
              _typeChip('BUY', t.cash),
              const SizedBox(width: 8),
              _typeChip('BARTER', t.barter),
              const SizedBox(width: 8),
              _typeChip('EITHER', t.either),
            ],
          ),
          const SizedBox(height: 14),

          _sectionLabel(t.budgetEthOptional),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _budgetMinCtrl,
                  hint: t.min,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  controller: _budgetMaxCtrl,
                  hint: t.max,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _sectionLabel(t.specificationsOptional)),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _specs.add((key: '', value: ''))),
                icon: const Icon(Icons.add, size: 16),
                label: Text(t.add, style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          ..._specs.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _specField(
                      initial: s.key,
                      hint: t.specKeyHint,
                      onChanged: (v) => setState(() {
                        _specs[i] = (key: v, value: _specs[i].value);
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _specField(
                      initial: s.value,
                      hint: t.specValueHint,
                      onChanged: (v) => setState(() {
                        _specs[i] = (key: _specs[i].key, value: v);
                      }),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _specs.removeAt(i)),
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),

          _sectionLabel(t.pickupLocationOptional),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _fetchingLocation ? null : _useCurrentLocation,
              icon: _fetchingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.my_location_rounded,
                      size: 18, color: AppColors.primary),
              label: Text(
                _fetchingLocation
                    ? t.gettingYourLocation
                    : (_capturedLat != null
                        ? t.updateMyLocation
                        : t.useMyCurrentLocation),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                backgroundColor:
                    AppColors.primaryLight.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          if (_capturedLat != null && _capturedLng != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.gps_fixed_rounded,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.gpsCaptured(
                        _capturedLat!.toStringAsFixed(4),
                        _capturedLng!.toStringAsFixed(4),
                      ),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearLocation,
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),

          _field(controller: _locationCtrl, hint: t.locationNameHint),
          const SizedBox(height: 6),
          Text(
            _capturedLat != null ? t.locationEditHint : t.locationAttachHint,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    t.postRequest,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
        filled: true,
        fillColor: AppColors.primaryLight.withValues(alpha: 0.4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.10),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _specField({
    required String initial,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initial,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.primaryLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.15),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}