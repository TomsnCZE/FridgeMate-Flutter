import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();

  late String _unit;
  late String _category;
  late String _type;
  DateTime? _expirationDate;
  File? _selectedImage;
  String? _originalImagePath;
  String? _savedImagePath;
  bool _removeImageOnSave = false;

  final List<String> _units = ['ks', 'g', 'kg', 'ml', 'l'];
  final List<String> _categories = ['fridge', 'freezer', 'pantry'];
  final List<String> _types = ['food', 'beverage', 'other'];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product.name;
    _brandController.text = widget.product.brand ?? '';
    _quantityController.text = widget.product.quantity.toString();
    _unit = (widget.product.extra?['unit'] as String?) ?? 'ks';
    _category = _normalizeCategoryKey(widget.product.category);
    _type = _normalizeTypeKey(widget.product.extra?['type']);
    _expirationDate = widget.product.expirationDate;

    // Prevent DropdownButtonFormField assertion: value must be one of the items.
    if (!_units.contains(_unit)) {
      _unit = _units.first;
    }
    if (!_categories.contains(_category)) {
      _category = _categories.first;
    }
    if (!_types.contains(_type)) {
      _type = _types.first;
    }

    final originalPath = widget.product.extra?['localImagePath'];
    if (originalPath != null &&
        originalPath.isNotEmpty &&
        File(originalPath).existsSync()) {
      _originalImagePath = originalPath;
      _savedImagePath = originalPath;
      _selectedImage = File(originalPath);
    } else {
      _originalImagePath = null;
      _selectedImage = null;
    }
  }

  String _unitLabel(String unit) {
    if (unit == 'ks') return 'add_product.pieces'.tr();
    return unit;
  }

  String _categoryLabel(String key) {
    return 'add_product.$key'.tr();
  }

  String _typeLabel(String key) {
    return 'add_product.$key'.tr();
  }

  String _normalizeCategoryKey(dynamic raw) {
    final v = (raw ?? '').toString().trim();
    if (v == 'fridge' || v == 'freezer' || v == 'pantry') return v;
    if (v == 'Lednice') return 'fridge';
    if (v == 'Mrazák' || v == 'Mrazak') return 'freezer';
    if (v == 'Spíž' || v == 'Spiz') return 'pantry';
    return 'fridge';
  }

  String _normalizeTypeKey(dynamic raw) {
    final v = (raw ?? '').toString().trim();
    if (v == 'food' || v == 'beverage' || v == 'other') return v;
    if (v == 'Jídlo' || v == 'Jidlo') return 'food';
    if (v == 'Pití' || v == 'Piti' || v == 'Nápoj' || v == 'Napoj') return 'beverage';
    if (v == 'Ostatní' || v == 'Ostatni') return 'other';
    return 'food';
  }

  Future<File> _saveImagePermanently(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'product_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
    final newPath = p.join(dir.path, fileName);
    return File(sourcePath).copy(newPath);
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        final savedImage = await _saveImagePermanently(photo.path);
        setState(() {
          _selectedImage = savedImage;
          _savedImagePath = savedImage.path;
          _removeImageOnSave = false;
        });
      }
    } catch (e) {
      print('❌ Chyba při focení: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final savedImage = await _saveImagePermanently(image.path);
        setState(() {
          _selectedImage = savedImage;
          _savedImagePath = savedImage.path;
          _removeImageOnSave = false;
        });
      }
    } catch (e) {
      print('❌ Chyba při výběru z galerie: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _savedImagePath = null;
      _originalImagePath = null; // user explicitly removed
      _removeImageOnSave = true;
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null && mounted) {
      setState(() => _expirationDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.tryParse(_quantityController.text) ?? 1.0;

    final updatedProduct = Product(
      id: widget.product.id,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      category: _category,
      quantity: quantity,
      expirationDate: _expirationDate,
      extra: {
        'unit': _unit,
        'type': _type,
        'localImagePath': _removeImageOnSave ? null : (_savedImagePath ?? _originalImagePath),
      },
    );

    // UPDATE in DB
    if (widget.product.id != null) {
      await DatabaseService.instance.updateProduct(
        widget.product.id!,
        updatedProduct.toMap(),
      );
    }

    if (!mounted) return;
    Navigator.pop(context, updatedProduct); // return updated product
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'add_product.edit'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withOpacity(0.6),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FOTKA PRODUKTU
              _buildImageSelector(),
              const SizedBox(height: 24),
              // NÁZEV
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'add_product.name'.tr() + ' *',
                  border: const OutlineInputBorder(),
                  filled: false,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'add_product.name_required'.tr() : null,
              ),
              const SizedBox(height: 16),

              // ZNAČKA
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: 'add_product.brand'.tr(),
                  border: const OutlineInputBorder(),
                  filled: false,
                ),
              ),
              const SizedBox(height: 16),

              // MNOŽSTVÍ A JEDNOTKA
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'add_product.quantity'.tr() + ' *',
                        border: const OutlineInputBorder(),
                        filled: false,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'add_product.quantity_required'.tr();
                        final num = double.tryParse(v);
                        if (num == null || num <= 0) return 'add_product.quantity_invalid'.tr();
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: InputDecoration(
                        labelText: 'add_product.unit'.tr(),
                        border: const OutlineInputBorder(),
                        filled: false,
                      ),
                      items: _units
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(_unitLabel(u))),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v ?? 'ks'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // UMÍSTĚNÍ
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'add_product.location'.tr(),
                  border: const OutlineInputBorder(),
                  filled: false,
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(c))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'fridge'),
              ),
              const SizedBox(height: 16),

              // TYP PRODUKTU
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'add_product.product_type'.tr(),
                  border: const OutlineInputBorder(),
                  filled: false,
                ),
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t))))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'food'),
              ),
              const SizedBox(height: 16),

              // DATUM SPOTŘEBY
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'add_product.expiration_date'.tr(),
                    border: const OutlineInputBorder(),
                    filled: false,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expirationDate != null
                            ? '${_expirationDate!.day}.${_expirationDate!.month}.${_expirationDate!.year}'
                            : 'add_product.pick_date'.tr(),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // TLAČÍTKA
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('add_product.close'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text('add_product.save_changes'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'add_product.photo'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        if (_selectedImage != null)
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _removeImage,
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: Text('add_product.gallery'.tr()),
                  onPressed: _pickFromGallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: Text('add_product.photo'.tr()),
                  onPressed: _takePhoto,
                ),
              ),
            ],
          ),

      ],
    );
  }
}
