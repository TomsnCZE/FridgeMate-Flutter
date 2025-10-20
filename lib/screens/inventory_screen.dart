import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_detail_bottom_sheet.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/add_product_screen.dart';
import '../screens/product_edit_screen.dart';
import '../routes/custom_routes.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> _products = [];
  String _search = '';
  String _filterCategory = 'Vše';

  void _addProduct(Product product) {
    setState(() {
      _products.add(product);
    });
  }

  void _editProduct(int index, Product product) {
    setState(() {
      _products[index] = product;
    });
  }

  void _deleteProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  void _showProductDetail(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ProductDetailBottomSheet(product: product),
    );
  }

  void _showEditScreen(int index) async {
    final result = await Navigator.push(
      context,
      SlideRightRoute(
        page: EditProductScreen(product: _products[index], index: index),
      ),
    );

    if (result != null) {
      if (result == 'delete') {
        _deleteProduct(index);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_products[index].name} byl smazán'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        _editProduct(index, result);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${result.name} byl upraven')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(
        _search.toLowerCase(),
      );
      final matchesCategory =
          _filterCategory == 'Vše' || p.category == _filterCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    final expiredCount = _products
        .where(
          (p) =>
              p.expirationDate != null &&
              p.expirationDate!.isBefore(DateTime.now()),
        )
        .length;

    final expiringSoonCount = _products
        .where(
          (p) =>
              p.expirationDate != null &&
              p.expirationDate!.isAfter(DateTime.now()) &&
              p.expirationDate!.difference(DateTime.now()).inDays <= 3,
        )
        .length;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Hledat produkt...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),

          if (expiredCount > 0 || expiringSoonCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      expiredCount > 0
                          ? '$expiredCount produktů prošlo expirací'
                          : '$expiringSoonCount produktů brzy expiruje',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Vše', 'Lednice', 'Spíž', 'Mrazák']
                    .map(
                      (cat) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: _filterCategory == cat,
                          onSelected: (selected) {
                            setState(() => _filterCategory = cat);
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(
                            0xFFEC9B05,
                          ).withOpacity(0.2),
                          checkmarkColor: const Color(0xFFEC9B05),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Žádné produkty',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Text(
                          'Přidej první produkt pomocí tlačítka +',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => ProductCard(
                      product: filtered[i],
                      index: _products.indexOf(filtered[i]),
                      onEdit: () =>
                          _showEditScreen(_products.indexOf(filtered[i])),
                      onDelete: () =>
                          _deleteProduct(_products.indexOf(filtered[i])),
                      onTap: () => _showProductDetail(filtered[i]),
                    ),
                  ),
          ),
        ],
      ),

      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: const Color(0xFFEC9B05),
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        spacing: 12,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Přidat ručně',
            onTap: () async {
              final newProduct = await Navigator.push<Product>(
                context,
                SlideLeftRoute(page: const AddProductScreen()),
              );

              if (newProduct != null) {
                _addProduct(newProduct);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${newProduct.name} byl přidán do skladu'),
                  ),
                );
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.qr_code_scanner),
            label: 'Skenovat QR',
            onTap: () async {
              final newProduct = await Navigator.push<Product>(
                context,
                MaterialPageRoute(builder: (_) => const QRScannerScreen()),
              );

              if (newProduct != null) {
                _addProduct(newProduct);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${newProduct.name} byl přidán do skladu'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}