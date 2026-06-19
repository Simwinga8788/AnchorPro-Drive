import os
import re
import glob

dashboard_dir = r"c:\Users\simwi\Desktop\Car_Rental_Portal\CarRental.Web\src\pages\admin"
page_files = glob.glob(os.path.join(dashboard_dir, "**", "*.tsx"), recursive=True)
import_statement = "import ResponsiveTable from '../../components/ResponsiveTable';\n"

for file_path in page_files:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    if "data-table" not in content or "ResponsiveTable" in content:
        continue

    table_pattern = re.compile(r'(<table[^>]*className=["\'][^"\']*data-table[^"\']*["\'][^>]*>.*?</table\s*>)', re.DOTALL)
    
    def wrap_table(match):
        table_html = match.group(1)
        return f"<ResponsiveTable>\n{table_html}\n</ResponsiveTable>"

    new_content, count = table_pattern.subn(wrap_table, content)

    if count > 0:
        if import_statement not in new_content:
            last_import_idx = new_content.rfind("import ")
            if last_import_idx != -1:
                end_of_line = new_content.find("\n", last_import_idx)
                new_content = new_content[:end_of_line+1] + import_statement + new_content[end_of_line+1:]
            else:
                new_content = import_statement + new_content

        with open(file_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Updated {file_path} (wrapped {count} tables)")
