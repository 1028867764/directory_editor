import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // 导入分享插件
import 'package:intl/intl.dart';

void main() {
  runApp(const DirectoryEditorApp());
}

class DirectoryItem {
  String id;
  String title;
  int level;
  bool isExpanded;
  List<DirectoryItem> children;
  TextEditingController controller; // 新增控制器

  DirectoryItem({
    required this.id,
    required this.title,
    this.level = 0,
    this.isExpanded = false,
    this.children = const [],
  }) : controller = TextEditingController(text: title); // 初始化控制器

  DirectoryItem copyWith({
    String? id,
    String? title,
    int? level,
    bool? isExpanded,
    List<DirectoryItem>? children,
  }) {
    return DirectoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      level: level ?? this.level,
      isExpanded: isExpanded ?? this.isExpanded,
      children: children ?? this.children,
    )..controller.text = title ?? this.title; // ✅ 确保 controller 同步更新
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // 添加 id 字段
      'title': title,
      'level': level,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }

  factory DirectoryItem.fromJson(Map<String, dynamic> json) {
    return DirectoryItem(
      id:
          json['id'] ??
          DateTime.now().millisecondsSinceEpoch.toString(), // 优先使用原有ID
      title: json['title'],
      level: json['level'],
      isExpanded: false, // 默认不展开
      children:
          (json['children'] as List?)
              ?.map((childJson) => DirectoryItem.fromJson(childJson))
              .toList() ??
          [],
    );
  }
  // 在dispose时释放控制器（重要！）
  void dispose() {
    controller.dispose();
  }
}

class DirectoryEditorApp extends StatelessWidget {
  const DirectoryEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '多级目录编辑器',
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
  bool _isLoading = true; // 添加加载状态变量

  Future<void> _loadDirectoryItems() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/directory_data.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        setState(() {
          directoryItems =
              jsonList.map((json) => DirectoryItem.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        // 如果文件不存在，使用默认数据
        setState(() {
          directoryItems = [
            DirectoryItem(id: '1', title: '根目录1'),
            DirectoryItem(id: '2', title: '根目录2'),
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载数据失败: $e');
      setState(() {
        directoryItems = [
          DirectoryItem(id: '1', title: '根目录1'),
          DirectoryItem(id: '2', title: '根目录2'),
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDirectoryItems() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/directory_data.json');
      final content = jsonEncode(
        directoryItems.map((item) => item.toJson()).toList(),
      );
      await file.writeAsString(content);
    } catch (e) {
      print('保存数据失败: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDirectoryItems(); // 添加初始化加载数据
  }

  @override
  void dispose() {
    // 释放所有控制器
    for (var item in directoryItems) {
      _disposeItemControllers(item);
    }
    super.dispose();
  }

  void _disposeItemControllers(DirectoryItem item) {
    item.dispose();
    for (var child in item.children) {
      _disposeItemControllers(child);
    }
  }

  void _updateItem(DirectoryItem oldItem, DirectoryItem newItem) {
    setState(() {
      _updateItemInList(directoryItems, oldItem, newItem);
      _saveDirectoryItems(); // 添加这行以保存变更
    });
  }

  bool _updateItemInList(
    List<DirectoryItem> items,
    DirectoryItem oldItem,
    DirectoryItem newItem,
  ) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].id == oldItem.id) {
        items[i] = newItem;
        return true;
      }
      if (_updateItemInList(items[i].children, oldItem, newItem)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(25.0), // 自定义高度
        child: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.add, size: 15.0),
              onPressed: () => _addItem(null),
            ),
            IconButton(
              icon: const Icon(Icons.import_export, size: 15.0),
              onPressed: _showImportExportMenu,
            ),
          ],
        ),
      ),
      body: _buildDirectoryList(),
      floatingActionButton: Visibility(
        visible: false, // 隐藏按钮
        child: FloatingActionButton(
          backgroundColor: Colors.blue.withOpacity(0.3),
          onPressed: () => _addItem(null),
          tooltip: '添加根目录项',
          child: const Icon(Icons.add),
        ),
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
        ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 0.0),
          dense: true, // 添加这行使列表更紧凑
          leading: IconButton(
            icon: Icon(
              item.isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 12.0, // 调整图标大小
            ),
            onPressed: () => _toggleExpand(item),
          ),
          title: TextField(
            style: TextStyle(fontSize: 12.0), // 设置文本大小
            controller: item.controller, // 绑定控制器
            onChanged: (value) => _updateTitle(item, value),
            decoration: InputDecoration(
              hintText: '输入目录名称',
              hintStyle: TextStyle(fontSize: 12.0), // 提示文本大小
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(left: 0.0),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.add, size: 12.0), // 调整图标大小
                onPressed: () => _addItem(item),
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 12.0), // 调整图标大小
                onPressed: () => _deleteItem(item),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey[300]),
        if (item.isExpanded && item.children.isNotEmpty)
          ...item.children
              .map((child) => _buildDirectoryItem(child))
              .toList()
              .map(
                (childWidget) => Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: childWidget,
                ),
              ),
      ],
    );
  }

  void _addItem(DirectoryItem? parent) {
    final newItem = DirectoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '新目录项',
      level: parent != null ? parent.level + 1 : 0,
    );

    setState(() {
      if (parent != null) {
        _updateItem(
          parent,
          parent.copyWith(
            children: [...parent.children, newItem],
            isExpanded: true,
          ),
        );
      } else {
        directoryItems.add(newItem);
        _saveDirectoryItems(); // 添加这行以保存变更
      }
    });
  }

  void _deleteItem(DirectoryItem item) {
    setState(() {
      if (!_removeItemFromParent(directoryItems, item)) {
        // If item is a root item
        directoryItems.removeWhere((element) => element.id == item.id);
      }
      _saveDirectoryItems(); // 添加这行以保存变更
    });
  }

  bool _removeItemFromParent(
    List<DirectoryItem> items,
    DirectoryItem itemToRemove,
  ) {
    for (var item in items) {
      if (item.children.any((child) => child.id == itemToRemove.id)) {
        _updateItem(
          item,
          item.copyWith(
            children:
                item.children
                    .where((child) => child.id != itemToRemove.id)
                    .toList(),
          ),
        );
        return true;
      }
      if (_removeItemFromParent(item.children, itemToRemove)) {
        return true;
      }
    }
    return false;
  }

  void _toggleExpand(DirectoryItem item) {
    _updateItem(item, item.copyWith(isExpanded: !item.isExpanded));
  }

  void _updateTitle(DirectoryItem item, String newTitle) {
    // ✅ 只更新数据，不强制刷新 UI
    item.title = newTitle;
    _saveDirectoryItems(); // 异步保存，避免频繁 setState
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
                leading: const Icon(Icons.download),
                title: const Text('导出目录'),
                onTap: _exportDirectory,
              ),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('导入目录'),
                onTap: _importDirectory,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportDirectory() async {
    // 弹出对话框让用户输入文件名
    final fileNameController = TextEditingController(
      text:
          'directory_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}',
    );

    final fileName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('导出目录'),
            content: TextField(
              controller: fileNameController,
              decoration: const InputDecoration(
                labelText: '文件名',
                hintText: '输入导出文件的名称',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(context, fileNameController.text),
                child: const Text('确定'),
              ),
            ],
          ),
    );

    // 如果用户取消操作，fileName将为null
    if (fileName == null || fileName.isEmpty) return;

    try {
      // 1. 生成 JSON 数据
      String fileName =
          'directory_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.json';
      String content = jsonEncode(
        directoryItems.map((item) => item.toJson()).toList(),
      );

      // 2. 保存到临时文件（QQ分享需要文件路径）
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content);

      // 3. 使用 share_plus 分享文件
      await Share.shareXFiles(
        [XFile(file.path)], // 要分享的文件
        text: '这是导出的目录结构文件', // 可选：附加文本
        subject: '目录导出', // 可选：分享主题（邮件等场景）
      );

      // 4. 提示用户
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已导出并弹出分享选项')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }

  Future<void> _importDirectory() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);

        setState(() {
          directoryItems =
              jsonList.map((json) => DirectoryItem.fromJson(json)).toList();
          _saveDirectoryItems(); // 添加这行以保存变更
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
}
