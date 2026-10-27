import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
    if (!_formKey.currentState!.validate()) return;
    if (_haveCategoryId == null) {
      setState(() => _error = 'Select what category your item is');
      return;
    }
    if (_wantCategoryIds.isEmpty) {
      setState(() => _error = 'Pick at least one category you want');
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
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          widget.isFirstProduct ? 'Post your first product' : 'Post a product',
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
                  'Failed to load categories\n$e',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(categoriesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (categories) => _buildForm(categories),
      ),
    );
  }

  Widget _buildForm(List<dynamic> categories) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add a photo',
                            style: TextStyle(
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
            _label('Title'),
            TextFormField(
              controller: _titleCtrl,
              validator: (v) =>
                  (v ?? '').trim().length < 3 ? 'Min 3 characters' : null,
              decoration: const InputDecoration(hintText: 'iPhone 15 Pro'),
            ),
            const SizedBox(height: 16),
            _label('Description'),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              validator: (v) =>
                  (v ?? '').trim().length < 10 ? 'Min 10 characters' : null,
              decoration: const InputDecoration(
                hintText: 'Condition, age, extras...',
              ),
            ),
            const SizedBox(height: 16),
            _label('Condition'),
            DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(value: 'NEW', child: Text('New')),
                DropdownMenuItem(value: 'LIKE_NEW', child: Text('Like new')),
                DropdownMenuItem(value: 'GOOD', child: Text('Good')),
                DropdownMenuItem(value: 'FAIR', child: Text('Fair')),
              ],
              onChanged: (v) => setState(() => _condition = v ?? 'GOOD'),
            ),
            const SizedBox(height: 16),
            _label('Estimated value (ETB)'),
            TextFormField(
              controller: _valueCtrl,
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return 'Enter a number';
                return null;
              },
              decoration: const InputDecoration(hintText: '12000'),
            ),
            const SizedBox(height: 24),
            _label('What category is your item?'),
            DropdownButtonFormField<String>(
              value: _haveCategoryId,
              decoration: const InputDecoration(hintText: 'Select'),
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
            _label('What do you want in exchange?'),
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
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB00020), fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Post product',
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
