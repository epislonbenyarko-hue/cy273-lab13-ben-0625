import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(const ReleaseApp());

class Product {
  const Product(this.name, this.priceGhs);

  final String name;
  final double priceGhs;
}

// 2,000 items to test scrolling performance.
final List<Product> products = List.generate(
  2000,
  (i) => Product('Campus item ${i + 1}', 5 + (i % 50) * 1.5),
);

/// Exercise 3: favourites live in a ChangeNotifier so the AppBar counter can
/// use `context.select` and rebuild only when the count actually changes.
class Favourites with ChangeNotifier {
  final Set<int> _indices = <int>{};

  int get count => _indices.length;

  bool contains(int index) => _indices.contains(index);

  void toggle(int index) {
    if (!_indices.remove(index)) {
      _indices.add(index);
    }
    notifyListeners();
  }
}

class ReleaseApp extends StatelessWidget {
  const ReleaseApp({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => Favourites(),
        child: MaterialApp(
          title: 'UMaT Market',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorSchemeSeed: const Color(0xFF0B6E4F)),
          home: const ProductListPage(),
        ),
      );
}

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('UMaT Market'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: FavouriteCount()),
            ),
          ],
        ),
        // The search field and list are a separate subtree, so typing never
        // rebuilds the AppBar (exercise 2).
        body: const ProductBrowser(),
      );
}

/// Exercise 3: only this widget watches the favourite *count*.
class FavouriteCount extends StatelessWidget {
  const FavouriteCount({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<Favourites, int>((f) => f.count);
    return Text('♥ $count');
  }
}

/// Exercise 2: owns the query, so only this subtree rebuilds while typing.
class ProductBrowser extends StatefulWidget {
  const ProductBrowser({super.key});

  @override
  State<ProductBrowser> createState() => _ProductBrowserState();
}

class _ProductBrowserState extends State<ProductBrowser> {
  final _controller = TextEditingController();
  List<int> _visible = List<int>.generate(products.length, (i) => i);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String value) {
    final needle = value.trim().toLowerCase();
    final matches = <int>[];
    if (needle.isEmpty) {
      matches.addAll(List<int>.generate(products.length, (i) => i));
    } else {
      for (var i = 0; i < products.length; i++) {
        if (products[i].name.toLowerCase().contains(needle)) matches.add(i);
      }
    }
    setState(() => _visible = matches);
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              decoration: InputDecoration(
                labelText: 'Search 2,000 campus items',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            // Exercise 1: keep `builder` — only visible rows are built.
            // A plain ListView would create all 2,000 ListTiles up front.
            child: _visible.isEmpty
                ? const Center(child: Text('No matching items'))
                : ListView.builder(
                    itemCount: _visible.length,
                    itemBuilder: (context, row) {
                      final index = _visible[row];
                      return ProductTile(index: index, product: products[index]);
                    },
                  ),
          ),
        ],
      );
}

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.index,
    required this.product,
  });

  final int index;
  final Product product;

  @override
  Widget build(BuildContext context) {
    // Rebuild only when *this* row's favourite flag changes.
    final isFavourite =
        context.select<Favourites, bool>((f) => f.contains(index));
    final price = product.priceGhs.toStringAsFixed(2);

    return RepaintBoundary(
      child: ListTile(
        key: ValueKey('product-$index'),
        leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
        title: Text(product.name),
        subtitle: Text('GHS $price'),
        trailing: IconButton(
          tooltip: isFavourite ? 'Remove favourite' : 'Add favourite',
          icon: Icon(isFavourite ? Icons.favorite : Icons.favorite_border),
          color: isFavourite ? Colors.red : null,
          onPressed: () => context.read<Favourites>().toggle(index),
        ),
      ),
    );
  }
}
