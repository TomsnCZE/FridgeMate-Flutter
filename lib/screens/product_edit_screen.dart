import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  final List<String> _units = ['ks', 'g', 'kg', 'ml', 'l'];
  final List<String> _categories = ['Lednice', 'Mrazák', 'Spíž'];
  final List<String> _types = ['Jídlo', 'Pití', 'Ostatní'];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product.name;
    _brandController.text = widget.product.brand ?? '';
    _quantityController.text = widget.product.quantity.toString();
    _unit = widget.product.extra?['unit'] ?? 'ks';
    _category = widget.product.category;
    _type = widget.product.extra?['type'] ?? 'Jídlo';
    _expirationDate = widget.product.expirationDate;

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
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
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
        'localImagePath': _savedImagePath ?? _originalImagePath,
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
          'Upravit produkt',
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
                decoration: const InputDecoration(
                  labelText: 'Název produktu *',
                  border: OutlineInputBorder(),
                  filled: false,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Zadej název' : null,
              ),
              const SizedBox(height: 16),

              // ZNAČKA
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Značka (nepovinné)',
                  border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Množství *',
                        border: OutlineInputBorder(),
                        filled: false,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Zadej množství';
                        final num = double.tryParse(v);
                        if (num == null || num <= 0) return 'Neplatné množství';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Jednotka',
                        border: OutlineInputBorder(),
                        filled: false,
                      ),
                      items: _units
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
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
                decoration: const InputDecoration(
                  labelText: 'Umístění',
                  border: OutlineInputBorder(),
                  filled: false,
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'Lednice'),
              ),
              const SizedBox(height: 16),

              // TYP PRODUKTU
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Typ produktu',
                  border: OutlineInputBorder(),
                  filled: false,
                ),
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'Jídlo'),
              ),
              const SizedBox(height: 16),

              // DATUM SPOTŘEBY
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Datum spotřeby',
                    border: OutlineInputBorder(),
                    filled: false,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expirationDate != null
                            ? '${_expirationDate!.day}.${_expirationDate!.month}.${_expirationDate!.year}'
                            : 'Vyber datum',
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
                      child: const Text('Zrušit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Uložit'),
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
        const Text(
          'Fotka produktu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                  label: const Text('Galerie'),
                  onPressed: _pickFromGallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Fotoaparát'),
                  onPressed: _takePhoto,
                ),
              ),
            ],
          ),

        if (_originalImagePath != null && _selectedImage == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Použije se původní fotka',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
