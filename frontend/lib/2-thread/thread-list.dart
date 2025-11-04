import 'package:flutter/material.dart';
import 'thread-unofficial-list.dart';

void main() {
  runApp(MaterialApp(
    home: ThreadList(), // 起動時に表示する画面
  ));
}

class ThreadList extends StatefulWidget {
  @override
  _ThreadListState createState() => _ThreadListState();
}

class _ThreadListState extends State<ThreadList> {
  List<String> items = ['1', '2', '3'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ユーザー一覧')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '公式スレッド',
            style: TextStyle(fontSize: 30),
          ),
          Row(
            children: [
              Text(
                'HOTスレッド',
                style: TextStyle(fontSize: 30),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ThreadUnofficialList()),
                  );
                },
                child: Text(
                  'スレッド一覧',
                  style: TextStyle(fontSize: 20),
                ),
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