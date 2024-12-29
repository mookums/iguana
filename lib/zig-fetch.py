import os
import sys
import json
import re
import subprocess

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

def fetch_dependency(dep, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    print(f"Fetching {dep['url']} using zig fetch")

    if 'url' in dep:
        fetch_cmd = ['zig', 'fetch', '--global-cache-dir', output_dir, dep['url']]
    elif 'path' in dep:
        fetch_cmd = ['zig', 'fetch', '--global-cache-dir', output_dir, dep['path']]
    else:
        raise ValueError("Either 'url' or 'path' must be provided for the dependency.")

    try:
        result = subprocess.run(fetch_cmd, capture_output=True, text=True, check=True)
        fetched_hash = result.stdout.strip()

        print(f"Successfully fetched {dep['url']}")
        dep_path = os.path.join(output_dir, "p", fetched_hash)
        build_zig_zon_path = os.path.join(dep_path, 'build.zig.zon')

        if os.path.exists(build_zig_zon_path):
            print(f"Found build.zig.zon in {dep['url']}, parsing and fetching recursive dependencies.")
            with open(build_zig_zon_path, 'r') as f:
                zon_content = f.read()
                recursive_deps = parse_zon_dependencies(zon_content)
                
                for recursive_dep in recursive_deps:
                    fetch_dependency(recursive_dep, output_dir)
        else:
            print(f"Did not find another build.zig.zon in {dep['url']}.")


    except subprocess.CalledProcessError as e:
        print(f"Failed to fetch dependency: {dep.get('url', dep.get('path', 'Unknown'))}. Error: {e}")
    except Exception as e:
        print(f"Unexpected error occured while fetching {dep['url']}: {e}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: zig-fetch.py <zon_file_path> <output dir>", file=sys.stderr)
        sys.exit(1)
        
    with open(sys.argv[1], 'r') as f:
        zon_content = f.read()

    output_dir = sys.argv[2];
    deps = parse_zon_dependencies(zon_content)
    
    for dep in deps:
        fetch_dependency(dep, output_dir)

    print(f"All dependencies have been processed and stored in {output_dir}")
