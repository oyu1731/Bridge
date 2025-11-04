import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ユーザー一覧')),
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
        ],
      ),
    );
  }
}