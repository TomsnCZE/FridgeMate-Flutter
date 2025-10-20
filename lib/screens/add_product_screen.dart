import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final String? initialName;
  final String? initialCategory;
  final String? initialBrand;

  const AddProductScreen({
    super.key,
    this.initialName,
    this.initialCategory,
    this.initialBrand,
  });

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

  final List<String> _units = ['ks', 'g', 'kg', 'ml', 'l'];
  final List<String> _categories = ['Lednice', 'Mrazák', 'Spíž'];
  final List<String> _types = ['Jídlo', 'Pití', 'Ostatní'];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName?.trim() ?? '';
    _brandController.text = widget.initialBrand?.trim() ?? '';
    _quantityController.text = '1';
    
    if (widget.initialCategory != null) {
      _type = widget.initialCategory!;
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );
      
      if (photo != null && mounted) {
        setState(() {
          _selectedImage = File(photo.path);
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
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('❌ Chyba při výběru z galerie: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() => _expirationDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    
    final product = Product(
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      category: _category,
      quantity: quantity,
      expirationDate: _expirationDate,
      extra: {
        'unit': _unit,
        'type': _type,
        'location': _category,
        'localImagePath': _selectedImage?.path,
      },
    );

    Navigator.of(context).pop(product);
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
        title: const Text('Přidat produkt'),
        backgroundColor: const Color.fromARGB(255, 254, 215, 97),
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
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Zadej název' : null,
              ),
              const SizedBox(height: 16),

              // ZNAČKA
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Značka (nepovinné)',
                  border: OutlineInputBorder(),
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
                      ),
                      items: _units
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
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
                    labelText: 'Datum spotřeby (nepovinné)',
                    border: OutlineInputBorder(),
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

              // TLAČÍTKO PRO PŘIDÁNÍ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC9B05),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _submit,
                  child: const Text(
                    'Přidat produkt',
                    style: TextStyle(fontSize: 16),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC9B05),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _takePhoto,
                ),
              ),
            ],
          ),
      ],
    );
  }
}