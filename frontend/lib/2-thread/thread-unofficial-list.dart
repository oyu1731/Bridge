import 'package:flutter/material.dart';
import 'package:bridge/00_header.dart';
import 'thread-create.dart';

void main() {
  runApp(MaterialApp(
    home: ThreadUnofficialList(),
  ));
}

class ThreadUnofficialList extends StatefulWidget {
  @override
  _ThreadUnofficialListState createState() => _ThreadUnofficialListState();
}

class _ThreadUnofficialListState extends State<ThreadUnofficialList> {
  List<String> items = ['1', '2', '3'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'スレッド一覧',
                style: TextStyle(fontSize: 30),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ThreadCreate()),
                  );
                },
                child: Text('スレッド作成'),
              ),
            ],
          ),
          
          SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.only(left: 40),
                  title: Text(items[index])
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}