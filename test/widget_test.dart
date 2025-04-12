import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(const DirectoryEditorApp());
}

class DirectoryItem {
  String id;
  String title;
  int level;
  bool isExpanded;
  List<DirectoryItem> children;

  DirectoryItem({
    required this.id,
    required this.title,
    this.level = 0,
    this.isExpanded = true,
    this.children = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'level': level,
      'isExpanded': isExpanded,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  factory DirectoryItem.fromJson(Map<String, dynamic> json) {
    return DirectoryItem(
      id: json['id'],
      title: json['title'],
      level: json['level'],
      isExpanded: json['isExpanded'] ?? true,
      children:
          (json['children'] as List?)
              ?.map((childJson) => DirectoryItem.fromJson(childJson))
              .toList() ??
          [],
    );
  }
}

class DirectoryEditorApp extends StatelessWidget {
  const DirectoryEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '目录编辑器',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DirectoryEditorScreen(),
    );
  }
}

class DirectoryEditorScreen extends StatefulWidget {
  const DirectoryEditorScreen({super.key});

  @override
  _DirectoryEditorScreenState createState() => _DirectoryEditorScreenState();
}

class _DirectoryEditorScreenState extends State<DirectoryEditorScreen> {
  List<DirectoryItem> directoryItems = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('目录编辑器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: _showImportExportMenu,
          ),
        ],
      ),
      body: _buildDirectoryList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRootItem,
        tooltip: '添加根目录项',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDirectoryList() {
    return ListView.builder(
      itemCount: directoryItems.length,
      itemBuilder: (context, index) {
        return _buildDirectoryItem(directoryItems[index]);
      },
    );
  }

  Widget _buildDirectoryItem(DirectoryItem item) {
    return Column(
      children: [
        Slidable(
          key: Key(item.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (context) => _editItem(item),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: '编辑',
              ),
              SlidableAction(
                onPressed: (context) => _deleteItem(item),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: '删除',
              ),
            ],
          ),
          child: LongPressDraggable(
            data: item,
            feedback: Material(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(item.title),
                  contentPadding: EdgeInsets.only(
                    left: 16.0 * (item.level + 1),
                  ),
                ),
              ),
            ),
            childWhenDragging: Container(),
            onDragCompleted: () {},
            child: DragTarget<DirectoryItem>(
              onAccept: (draggedItem) {
                _handleDrop(draggedItem, item);
              },
              builder: (context, candidateData, rejectedData) {
                return ListTile(
                  leading: IconButton(
                    icon: Icon(
                      item.isExpanded ? Icons.expand_more : Icons.chevron_right,
                    ),
                    onPressed: () => _toggleExpand(item),
                  ),
                  title: Text(item.title),
                  onTap: () => _editItem(item),
                  contentPadding: EdgeInsets.only(
                    left: 16.0 * (item.level + 1),
                  ),
                );
              },
            ),
          ),
        ),
        if (item.isExpanded && item.children.isNotEmpty)
          ...item.children.map(_buildDirectoryItem).toList(),
      ],
    );
  }

  void _addRootItem() {
    _addItem(null);
  }

  void _addItem(DirectoryItem? parent) {
    final newItem = DirectoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '新目录项',
      level: parent != null ? parent.level + 1 : 0,
    );

    setState(() {
      if (parent != null) {
        parent.children.add(newItem);
      } else {
        directoryItems.add(newItem);
      }
    });
  }

  void _editItem(DirectoryItem item) {
    TextEditingController controller = TextEditingController(text: item.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑目录项'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '输入目录项名称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  item.title = controller.text;
                });
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(DirectoryItem item) {
    setState(() {
      bool removed = false;
      for (var parent in directoryItems) {
        removed = _removeItemFromParent(parent, item);
        if (removed) break;
      }

      if (!removed) {
        directoryItems.remove(item);
      }
    });
  }

  bool _removeItemFromParent(DirectoryItem parent, DirectoryItem itemToRemove) {
    if (parent.children.contains(itemToRemove)) {
      parent.children.remove(itemToRemove);
      return true;
    }

    for (var child in parent.children) {
      if (_removeItemFromParent(child, itemToRemove)) {
        return true;
      }
    }

    return false;
  }

  void _toggleExpand(DirectoryItem item) {
    setState(() {
      item.isExpanded = !item.isExpanded;
    });
  }

  void _showImportExportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('导入目录'),
                onTap: () {
                  Navigator.pop(context);
                  _importDirectory();
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('导出目录'),
                onTap: () {
                  Navigator.pop(context);
                  _exportDirectory();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importDirectory() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(content);

        setState(() {
          directoryItems =
              jsonList.map((json) => DirectoryItem.fromJson(json)).toList();
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('目录导入成功')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
  }

  Future<void> _exportDirectory() async {
    try {
      String fileName =
          'directory_${DateTime.now().millisecondsSinceEpoch}.json';
      String content = jsonEncode(
        directoryItems.map((item) => item.toJson()).toList(),
      );

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '保存目录文件',
        fileName: fileName,
      );

      if (outputFile != null) {
        File file = File(outputFile);
        await file.writeAsString(content);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('目录导出成功')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }

  void _handleDrop(DirectoryItem draggedItem, DirectoryItem targetItem) {
    if (draggedItem.id == targetItem.id) return;

    _removeItemFromAnywhere(draggedItem);

    setState(() {
      targetItem.children.add(draggedItem);
      draggedItem.level = targetItem.level + 1;
    });
  }

  void _removeItemFromAnywhere(DirectoryItem item) {
    for (int i = 0; i < directoryItems.length; i++) {
      if (directoryItems[i].id == item.id) {
        setState(() {
          directoryItems.removeAt(i);
        });
        return;
      }
    }

    for (var rootItem in directoryItems) {
      if (_removeItemFromParent(rootItem, item)) {
        return;
      }
    }
  }
}
