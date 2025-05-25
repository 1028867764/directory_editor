import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadPage extends StatefulWidget {
  final dynamic product;
  const UploadPage({super.key, required this.product});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final TextEditingController _markdownController = TextEditingController();
  bool _isUploading = false;

  Future<void> _uploadArticle() async {
    setState(() {
      _isUploading = true;
    });

    final slug = widget.product.id.toString();
    final title = widget.product.name[0].toString();
    final cosKey = '${slug}_markdown_1';
    final markdownContent = _markdownController.text;

    final payload = {
      'slug': slug,
      'title': title,
      'cos_key': cosKey,
      'markdown_content': markdownContent,
    };

    try {
      final response = await http.post(
        Uri.parse('https://your-api.com/upload'), // 你自己的后端API地址
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('上传成功')));
        Navigator.pop(context);
      } else {
        throw Exception('上传失败: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('错误: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final slug = widget.product.id.toString();
    final title = widget.product.name[0].toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('上传页', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
        centerTitle: true,
        leadingWidth: 100,
        leading: Row(
          children: [
            const SizedBox(width: 10),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.arrow_back),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('slug: $slug'),
            Text('title: $title'),
            const SizedBox(height: 10),
            TextField(
              controller: _markdownController,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '请输入 Markdown 内容',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadArticle,
              child:
                  _isUploading
                      ? const CircularProgressIndicator()
                      : const Text('上传文章'),
            ),
          ],
        ),
      ),
    );
  }
}
