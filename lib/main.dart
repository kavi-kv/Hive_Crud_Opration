import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('shoping_list_box');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'elek',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quentityController = TextEditingController();

  List<Map<String, dynamic>> _items = [];

  final _shopingBox = Hive.box('shoping_list_box');

  @override
  void initState() {
    super.initState();
    _refreshItem();
  }

  void _refreshItem() {
    final data = _shopingBox.keys.map((key) {
      final item = _shopingBox.get(key);
      return {
        "key": key,
        "name": item["name"].toString(),
        "quantity": item["quantity"].toString()
      };
    }).toList();

    setState(() {
      _items = data.reversed.toList();
    });
  }

  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _shopingBox.add(newItem);
    _refreshItem();
  }
  Future<void> _updateItem(int itemKey,Map<String,dynamic> item) async 
  {
    await _shopingBox.put(itemKey, item);
    _refreshItem();
  }
  
  Future<void> _deleteItem(int itemKey) async
  {
    await _shopingBox.delete(itemKey);
    _refreshItem();

    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('An Item has been deleted'))
    );
  }


  void _showForm(BuildContext ctx, int? itemKey) {
    if (itemKey != null) {
      final existingItems =
          _items.firstWhere((element) => element['key'] == itemKey);
          _nameController.text = existingItems['name'];
          _quentityController.text = existingItems['quantity'];
    }

    showModalBottomSheet(
        context: ctx,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  top: 15,
                  left: 15,
                  right: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  TextField(
                    controller: _quentityController,
                    decoration: const InputDecoration(hintText: 'Quentity'),
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  ElevatedButton(
                      onPressed: () async {
                        //?:-> store the item to hive database
                       if(itemKey == null)
                       {
                         _createItem({
                          "name": _nameController.text,
                          "quantity": _quentityController.text
                        });
                       }
                       if(itemKey != null)
                       {
                        _updateItem(itemKey, {
                          'name':_nameController.text.trim(),
                          'quantity':_quentityController.text.trim()
                        });
                       }

                        //?:-> Clear the textField
                        _nameController.text = '';
                        _quentityController.text = '';

                        Navigator.of(context).pop();
                      },
                      child:  Text( itemKey == null ? 'Create New' : 'Update')) 
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hive'),
      ),
      body: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final currentItem = _items[index];
            return Card(
              color: Colors.orange[400],
              margin: const EdgeInsets.all(10.0),
              elevation: 3,
              child: ListTile(
                title: Text(currentItem['name']),
                subtitle: Text(currentItem['quantity'].toString()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //*:-> Edit Icon(button)
                    IconButton(
                        onPressed: () => _showForm(context, currentItem['key']),
                        icon: const Icon(Icons.edit)),
                    IconButton(
                        onPressed: () => _deleteItem(currentItem['key']), icon: const Icon(Icons.delete))
                  ],
                ),
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
