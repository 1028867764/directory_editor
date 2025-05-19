import xml.etree.ElementTree as ET
import json
from pathlib import Path


def parse_xml(element, parent_id=None, level=0, counter=[0], level_offset=-1):
    children = []
    for child in element:
        if child.tag == "ITEM":
            counter[0] += 1  # 使用计数器确保唯一ID
            current_id = (
                f"{parent_id}_{counter[0]}" if parent_id else f"root_{counter[0]}"
            )
            # 应用层级偏移
            adjusted_level = int(child.attrib.get("INDENT", 0)) + level_offset
            node = {
                "id": current_id,
                "title": child.attrib.get("NAME", "").strip(),
                "level": adjusted_level,
                "children": parse_xml(child, current_id, level, counter, level_offset),
            }
            children.append(node)
        else:
            # 如果不是ITEM元素，继续递归处理其子元素
            children.extend(parse_xml(child, parent_id, level, counter))
    return children


def save_json(data, file_path):
    file_path = Path(
        r"C:\Users\dell\directory_editor\XMLtoJson\JSON\output.json"
    )  # 确保是 Path 对象
    try:
        # 确保目录存在
        file_path.parent.mkdir(parents=True, exist_ok=True)
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
        print(f"JSON已保存至: {file_path}")
    except Exception as e:
        print(f"保存失败: {str(e)}")


# 主程序
xml_path = Path(r"C:\Users\dell\directory_editor\XMLtoJson\【书签】必修-250519.xml")
if not xml_path.exists():
    print(f"错误：文件 {xml_path} 不存在！")
else:
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()

        json_data = parse_xml(root)

        save_json(json_data, "output.json")
    except ET.ParseError as e:
        print(f"XML解析错误: {e}")
