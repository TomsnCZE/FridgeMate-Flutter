import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? existingProduct;

  const AddProductScreen({super.key, this.existingProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();

  String _unit = 'ks';
  String _category = 'Lednice';
  String _type = 'Jídlo';
  DateTime? _expirationDate;
  File? _selectedImage;
  String? _savedImagePath;

  final List<String> _units = ['ks', 'g', 'kg', 'ml', 'l'];
  final List<String> _categories = ['Lednice', 'Mrazák', 'Spíž'];
  final List<String> _types = ['Jídlo', 'Pití', 'Ostatní'];

  @override
  void initState() {
    super.initState();

    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _nameController.text = p.name;
      _brandController.text = p.brand ?? '';
      _quantityController.text = p.quantity.toString();
      _unit = p.extra?['unit'] ?? 'ks';
      _category = p.category;
      _type = p.extra?['type'] ?? 'Jídlo';
      _expirationDate = p.expirationDate;

      final imagePath = p.extra?['localImagePath'];
      if (imagePath != null && File(imagePath).existsSync()) {
        _selectedImage = File(imagePath);
        _savedImagePath = imagePath;
      }
    } else {
      _quantityController.text = '1';
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
    final XFile? photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (photo == null) return;

    final saved = await _saveImagePermanently(photo.path);

    setState(() {
      _selectedImage = saved;
      _savedImagePath = saved.path;
    });
  }

  Future<void> _pickFromGallery() async {
    final XFile? img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (img == null) return;

    final saved = await _saveImagePermanently(img.path);

    setState(() {
      _selectedImage = saved;
      _savedImagePath = saved.path;
    });
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final quantity = double.tryParse(_quantityController.text) ?? 1.0;

    final product = Product(
      id: widget.existingProduct?.id,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      category: _category,
      expirationDate: _expirationDate,
      quantity: quantity,
      extra: {
        'unit': _unit,
        'type': _type,
        'localImagePath': _savedImagePath,
      },
    );

    if (widget.existingProduct == null || widget.existingProduct!.id == null) {
      // INSERT
      final int newId = await DatabaseService.instance.insertProduct(
        product.toMap(),
      );

      final savedProduct = Product(
        id: newId,
        name: product.name,
        brand: product.brand,
        category: product.category,
        expirationDate: product.expirationDate,
        quantity: product.quantity,
        extra: product.extra,
      );
      Navigator.pop(context, savedProduct);
    } else {
      // UPDATE
      await DatabaseService.instance.updateProduct(
        widget.existingProduct!.id!,
        product.toMap(),
      );

      final updatedProduct = Product(
        id: widget.existingProduct!.id,
        name: product.name,
        brand: product.brand,
        category: product.category,
        expirationDate: product.expirationDate,
        quantity: product.quantity,
        extra: product.extra,
      );

      Navigator.pop(context, updatedProduct);
    }
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
        title: Text(
          widget.existingProduct == null ? 'Přidat produkt' : 'Upravit produkt',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImageSelector(),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Název *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Zadej název' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Značka',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Množství *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vyplň množství';
                        final n = double.tryParse(v);
                        if (n == null || n <= 0) return 'Neplatné číslo';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Jednotka',
                      ),
                      items: _units
                          .map(
                            (u) => DropdownMenuItem(value: u, child: Text(u)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _category,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Umístění',
                ),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _type,
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Typ produktu',
                ),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Datum spotřeby',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expirationDate == null
                            ? 'Vybrat datum'
                            : '${_expirationDate!.day}.${_expirationDate!.month}.${_expirationDate!.year}',
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _submit,
                  child: Text(
                    widget.existingProduct == null ? 'Přidat' : 'Uložit změny',
                  ),
                ),
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
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
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
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Galerie"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Foto"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
