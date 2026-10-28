import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../providers/api_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/matches_provider.dart';
import '../providers/products_provider.dart';
import '../theme.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';

class PostProductScreen extends ConsumerStatefulWidget {
  final bool isFirstProduct;
  const PostProductScreen({super.key, this.isFirstProduct = false});

  @override
  ConsumerState<PostProductScreen> createState() => _PostProductScreenState();
}

class _PostProductScreenState extends ConsumerState<PostProductScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _haveCategoryId;
  final List<String> _wantCategoryIds = [];
  String _condition = 'GOOD';
  File? _image;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_haveCategoryId == null) {
      setState(() => _error = t.selectCategoryError);
      return;
    }
    if (_wantCategoryIds.isEmpty) {
      setState(() => _error = t.selectWantedError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiProvider);
      final images = <String>[];
      if (_image != null) {
        final url = await api.uploadImage(_image!);
        images.add(url);
      }

      await api.createProduct({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'images': images,
        'condition': _condition,
        'estimatedValue': double.parse(_valueCtrl.text.trim()),
        'categoryId': _haveCategoryId,
        'wants': _wantCategoryIds.map((id) => {'categoryId': id}).toList(),
      });

      ref.invalidate(myProductsProvider);
      ref.invalidate(matchesProvider);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          widget.isFirstProduct
              ? t.postYourFirstProduct
              : t.postProductTitle,
        ),
        actions: [
          if (!widget.isFirstProduct)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${t.errorGeneric}\n$e',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(categoriesProvider),
                  child: Text(t.tryAgain),
                ),
              ],
            ),
          ),
        ),
        data: (categories) => _buildForm(categories, t),
      ),
    );
  }

  Widget _buildForm(List<dynamic> categories, AppLocalizations t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image picker ──
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  image: _image != null
                      ? DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _image == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.addPhoto,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // ── Title ──
            _label(t.title),
            TextFormField(
              controller: _titleCtrl,
              validator: (v) =>
                  (v ?? '').trim().length < 3 ? t.titleMinLength : null,
              decoration: InputDecoration(hintText: t.requestTitleHint),
            ),
            const SizedBox(height: 16),

            // ── Description ──
            _label(t.description),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              validator: (v) =>
                  (v ?? '').trim().length < 10 ? t.descriptionMinLength : null,
              decoration: InputDecoration(hintText: t.requestDescriptionHint),
            ),
            const SizedBox(height: 16),

            // ── Condition ──
            _label(t.condition),
            DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(),
              items: [
                DropdownMenuItem(value: 'NEW', child: Text(t.conditionNew)),
                DropdownMenuItem(
                  value: 'LIKE_NEW',
                  child: Text(t.conditionLikeNew),
                ),
                DropdownMenuItem(value: 'GOOD', child: Text(t.conditionGood)),
                DropdownMenuItem(value: 'FAIR', child: Text(t.conditionFair)),
              ],
              onChanged: (v) => setState(() => _condition = v ?? 'GOOD'),
            ),
            const SizedBox(height: 16),

            // ── Estimated value ──
            _label(t.estimatedValue),
            TextFormField(
              controller: _valueCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return t.invalidNumber;
                return null;
              },
              decoration: InputDecoration(hintText: t.estimatedValueHint),
            ),
            const SizedBox(height: 24),

            // ── Have category ──
            _label(t.categoryPrompt),
            DropdownButtonFormField<String>(
              value: _haveCategoryId,
              decoration: InputDecoration(hintText: t.selectCategory),
              items: categories
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c['id'] as String,
                      child: Text('${c['icon'] ?? ''} ${c['name']}'.trim()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _haveCategoryId = v),
            ),
            const SizedBox(height: 24),

            // ── Want categories ──
            _label(t.wantedPrompt),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((c) {
                final id = c['id'] as String;
                final selected = _wantCategoryIds.contains(id);
                return ChoiceChip(
                  label: Text('${c['icon'] ?? ''} ${c['name']}'.trim()),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.white : AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _wantCategoryIds.add(id);
                      } else {
                        _wantCategoryIds.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            // ── Error ──
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 32),
            PrimaryButton(
              label: t.postProduct,
              onPressed: _submit,
              loading: _loading,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      );
}