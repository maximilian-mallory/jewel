import 'package:flutter/material.dart';

class Screen1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Random Things')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Random Facts',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '1. Flutter is developed by Google.',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '2. Dart is the programming language used by Flutter.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Random Images',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.network(
                  'https://picsum.photos/100/100?random=1',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
                Image.network(
                  'https://picsum.photos/100/100?random=2',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
                Image.network(
                  'https://picsum.photos/100/100?random=3',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Placeholder for button action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Button pressed!')),
                );
              },
              child: Text('Press Me'),
            ),
            SizedBox(height: 20),
            Divider(),
            Text(
              'Random List:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Item ${index + 1}'),
                    leading: Icon(Icons.star),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  }
