import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
 runApp(MaterialApp(
   home: Home(),
 ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //pegar o text
  final _toDoController = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovdPos;

//quando reinicia a tela
  void initState(){
    super.initState();

    _readData().then((data){
     setState(() {
       _toDoList = json.decode(data);
     });
    });
  }

  void _addToDo(){
    //atualizar na tela
    setState(() {
      Map<String, dynamic> newToDo = Map();
      //o title da tarefa
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);

      _saveData();
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });

      _saveData();
    });
    return null;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    //pegar o texto do textFild
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index){
    return Dismissible(
      //qual elemento vc quer deslizar
      //o elemento que ele clicou na hora
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white,),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text( _toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        //icone
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ?
          Icons.check : Icons.error),),
        //quando clicar no icone
        onChanged: (c){
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction){
       setState(() {
         _lastRemoved = Map.from(_toDoList[index]);
         _lastRemovdPos = index;
         _toDoList.removeAt(index);

         _saveData();
        //SnackBar é utilizado para mostrar uma mensagem para o usuario
         final snack = SnackBar(
           content: Text("Tarefa ${_lastRemoved["title"]}\" removida!"),
          action: SnackBarAction(label: "Desfazer",
            onPressed: (){
              setState(() {
                _toDoList.insert(_lastRemovdPos, _lastRemoved);
                _saveData();
              });
            },
          ),
           duration: Duration(seconds: 2),
         );
         Scaffold.of(context).removeCurrentSnackBar();
         Scaffold.of(context).showSnackBar(snack);
       });
      },
    );
  }


  //pegar o arquivo e salvar os dados
  Future<File> _getFile() async{
    //diretorio onde armazena os documentos do meu app
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }
  //Pegando a todoList colocando em um json e armazenando na string data
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    //esperar o arquivo
    final file = await _getFile();
    return file.writeAsString(data);
  }
 //ler os dados
  Future<String> _readData() async{
    try{
      final file = await _getFile();
      //ler os dados como string
      return file.readAsString();
    } catch (e){
      return null;
    }
  }
}
