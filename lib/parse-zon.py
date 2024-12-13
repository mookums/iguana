import sys
import json
import re

def parse_zon_dependencies(zon_str):
    deps_match = re.search(r'\.dependencies\s*=\s*\.\{((?:[^{}]|{[^{}]*})*)\}', zon_str, re.DOTALL)
    if not deps_match:
        return []
    
    deps_block = deps_match.group(1)
    
    dep_entries = []
    current_depth = 0
    current_entry = ""
    
    for char in deps_block:
        if char == '{':
            current_depth += 1
        elif char == '}':
            current_depth -= 1
        elif char == ',' and current_depth == 0:
            if current_entry.strip():
                dep_entries.append(current_entry.strip())
            current_entry = ""
            continue
            
        current_entry += char
    
    if current_entry.strip():
        dep_entries.append(current_entry.strip())
    
    dependencies = []
    for entry in dep_entries:
        dep = {}
        
        url_match = re.search(r'\.url\s*=\s*"([^"]*)"', entry)
        if url_match:
            dep['url'] = url_match.group(1)
        
        hash_match = re.search(r'\.hash\s*=\s*"([^"]*)"', entry)
        if hash_match:
            dep['hash'] = hash_match.group(1)
        
        path_match = re.search(r'\.path\s*=\s*"([^"]*)"', entry)
        if path_match:
            dep['path'] = path_match.group(1)
        
        lazy_match = re.search(r'\.lazy\s*=\s*(true|false)', entry)
        if lazy_match:
            dep['lazy'] = lazy_match.group(1) == 'true'
        else:
            dep['lazy'] = False
        
        if dep:
            dependencies.append(dep)
    
    return dependencies

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: script.py <zon_file_path>", file=sys.stderr)
        sys.exit(1)
        
    with open(sys.argv[1], 'r') as f:
        zon_content = f.read()
    
    deps = parse_zon_dependencies(zon_content)
    print(json.dumps(deps, indent=2))
