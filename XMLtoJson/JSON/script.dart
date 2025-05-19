import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File(
    'C:/Users/dell/directory_editor/XMLtoJson/JSON/必修250519.json',
  ); // 替换为你的 JSON 文件路径
  final jsonStr = await file.readAsString();
  final data = jsonDecode(jsonStr);

  int count = countTitleLeaves(data);
  print('叶子节点中包含 title 的数量: $count');
  int minor = 7418 - count;
  print('非叶子节点的数量: $minor');
}

int countTitleLeaves(dynamic node) {
  if (node is Map<String, dynamic>) {
    final children = node['children'];
    if (children == null || children.isEmpty) {
      return node.containsKey('title') ? 1 : 0;
    } else {
      return children.fold(0, (sum, child) => sum + countTitleLeaves(child));
    }
  } else if (node is List) {
    return node.fold(0, (sum, item) => sum + countTitleLeaves(item));
  }
  return 0;
}
