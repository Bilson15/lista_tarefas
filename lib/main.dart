import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const Home(),
    theme: ThemeData(
        hintColor: Colors.indigo,
        primaryColor: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(
          disabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.indigo)),
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.indigo)),
          focusedBorder:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.indigo)),
          hintStyle: TextStyle(color: Colors.indigo),
        )),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List _toDoList = [];

  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    setState(() {
      _readData().then((data) => {_toDoList = json.decode(data)});
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = _toDoController.text;
      _toDoController.text = "";
      newTodo["ok"] = false;
      _toDoList.add(newTodo);
      _saveData();
    });
  }

  Future<void> _reflesh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Lista de Tarefas"),
          backgroundColor: Colors.indigo,
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(5.0, 10.00, 5.0, 10.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                          controller: _toDoController,
                          decoration: const InputDecoration(
                            labelText: "Nova Tarefa",
                            icon: Icon(
                              Icons.add_task,
                              color: Colors.indigo,
                            ),
                            labelStyle: TextStyle(
                              color: Colors.indigo,
                            ),
                          ),
                          validator: (texto) {
                            if (texto!.isEmpty) {
                              return "Insira alguma tarefa";
                            }
                          }),
                    ),
                    const Padding(padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0)),
                    ElevatedButton(
                        child: const Text("ADD"),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.indigo),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _addToDo();
                          }
                        }),
                  ],
                ),
              ),
              Expanded(
                  child: RefreshIndicator(
                child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10.0),
                    itemCount: _toDoList.length,
                    itemBuilder: builItem),
                onRefresh: _reflesh,
              )),
            ],
          ),
        ));
  }

  Widget builItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.indigo,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
          title: Text(_toDoList[index]["title"]),
          value: _toDoList[index]["ok"],
          secondary: CircleAvatar(
            child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.warning),
            backgroundColor: Colors.indigo,
          ),
          onChanged: (value) {
            setState(() {
              _toDoList[index]["ok"] = value;
              _saveData();
            });
          }),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();
          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: const Duration(seconds: 5),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = "${directory.path}/data.json";
    return File(file);
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return e.toString();
    }
  }
}
