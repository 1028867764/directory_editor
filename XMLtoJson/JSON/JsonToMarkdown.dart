/*

import 'dart:convert';
import 'dart:io';
import 'package:docx/docx.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main(List<String> args) async {
  // 读取 JSON 文件
  String jsonString = await File('data.json').readAsString(encoding: utf8);
  List<dynamic> data = jsonDecode(jsonString);

  // 创建一个新的 Word 文档
  final doc = Document();

  // 处理 JSON 数据并添加到文档
  await processJson(data, doc, 0);

  // 保存文档到指定路径
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String outputPath = '${appDocDir.path}/output.docx';
  await doc.save(outputPath);

  print("Word 文档已成功生成：$outputPath");
}

Future<void> processJson(
  List<dynamic> data,
  Document doc,
  int currentLevel,
) async {
  for (var item in data) {
    if (item is Map && item.containsKey('title')) {
      String title = item['title'];
      int level = item.containsKey('level') ? item['level'] : 0;

      // 根据层级设置标题样式
      switch (level) {
        case 0:
          doc.addHeading(title, style: 'Title');
          break;
        case 1:
          doc.addHeading(title, style: 'Heading 1');
          break;
        case 2:
          doc.addHeading(title, style: 'Heading 2');
          break;
        case 3:
          doc.addHeading(title, style: 'Heading 3');
          break;
        default:
          // 对于更深层级，可以根据需要自定义样式
          doc.addParagraph(title, style: 'Normal');
          break;
      }
    }

    if (item is Map &&
        item.containsKey('children') &&
        item['children'] != null) {
      // 递归处理子项，层级加一
      await processJson(item['children'], doc, currentLevel + 1);
    }
  }
}

*/
