#!/usr/bin/env python3
"""
Extract OR RSZ runtime from input file and prepend it to output file.
"""

import re
import sys
import os


def extract_rsz_runtime(input_file):
    """Extract the RSZ runtime value from the input file."""
    pattern = r'\[INFO\] OR RSZ runtime:\s+(\d+) second'
    
    with open(input_file, 'r') as f:
        for line in f:
            match = re.search(pattern, line)
            if match:
                return int(match.group(1))
    
    return None


def prepend_to_file(output_file, content):
    """Prepend content to the top of the output file."""
    if os.path.exists(output_file):
        with open(output_file, 'r') as f:
            existing_content = f.read()
    else:
        existing_content = ''
    
    with open(output_file, 'w') as f:
        f.write(content + '\n' + existing_content)


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input_file> <output_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    if not os.path.exists(input_file):
        print(f"Error: Input file '{input_file}' does not exist.")
        sys.exit(1)
    
    runtime = extract_rsz_runtime(input_file)
    
    if runtime is None:
        print("Error: Could not find '[INFO] OR RSZ runtime:   XXX second' in input file.")
        sys.exit(1)
    
    prepend_to_file(output_file, f"[INFO] OR RSZ runtime:   {runtime} second")
    print(f"Successfully prepended runtime ({runtime} seconds) to {output_file}")


if __name__ == '__main__':
    main()
