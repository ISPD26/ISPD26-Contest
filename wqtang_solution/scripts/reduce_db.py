#!/usr/bin/env python3

import os
import sys
import shutil
from pathlib import Path

def parse_ppad_out(file_path):
    """Parse PPAD.out file and extract metrics."""
    try:
        with open(file_path, 'r') as f:
            lines = f.readlines()
        
        metrics = {}
        for line in lines:
            line = line.strip()
            if line.startswith('TNS:'):
                metrics['TNS'] = float(line.split(':')[1].strip())
            elif line.startswith('Power:'):
                metrics['Power'] = float(line.split(':')[1].strip())
            elif line.startswith('HPWL:'):
                metrics['HPWL'] = float(line.split(':')[1].strip())
            elif line.startswith('Displacement:'):
                metrics['Displacement'] = float(line.split(':')[1].strip())
        
        return metrics
    except Exception as e:
        print(f"Error parsing {file_path}: {e}")
        return None

def is_better_solution(metrics1, metrics2):
    """Check if metrics1 solution is better than metrics2 solution."""
    if not metrics1 or not metrics2:
        return False
    
    # Better if: TNS_1 >= TNS_2 AND Power_1 <= Power_2 AND HPWL_1 <= HPWL_2 AND Displacement_1 <= Displacement_2
    return (metrics1['TNS'] >= metrics2['TNS'] and
            metrics1['Power'] <= metrics2['Power'] and
            metrics1['HPWL'] <= metrics2['HPWL'] and
            metrics1['Displacement'] <= metrics2['Displacement'])

def main():
    if len(sys.argv) != 2:
        print("Usage: ./scripts/reduce_db.py <path>")
        print("Example: ./scripts/reduce_db.py ./database/aes/")
        sys.exit(1)
    
    path = sys.argv[1]
    
    if not os.path.exists(path):
        print(f"Error: Path {path} does not exist")
        sys.exit(1)
    
    # Get all folders in the path
    folders = [f for f in os.listdir(path) 
               if os.path.isdir(os.path.join(path, f)) and f != 'original']
    
    print(f"Found {len(folders)} folders to compare (excluding 'original')")
    
    # Parse metrics for all folders
    folder_metrics = {}
    for folder in folders:
        ppad_file = os.path.join(path, folder, 'PPAD.out')
        if os.path.exists(ppad_file):
            metrics = parse_ppad_out(ppad_file)
            if metrics:
                folder_metrics[folder] = metrics
            else:
                print(f"Warning: Could not parse metrics for {folder}")
        else:
            print(f"Warning: PPAD.out not found in {folder}")
    
    print(f"Successfully parsed metrics for {len(folder_metrics)} folders")
    
    # Compare all pairs and identify dominated solutions
    folders_to_remove = set()
    folder_list = list(folder_metrics.keys())
    
    for i, folder1 in enumerate(folder_list):
        for j, folder2 in enumerate(folder_list):
            if i != j and folder1 not in folders_to_remove and folder2 not in folders_to_remove:
                metrics1 = folder_metrics[folder1]
                metrics2 = folder_metrics[folder2]
                
                if is_better_solution(metrics1, metrics2):
                    folders_to_remove.add(folder2)
                    print(f"{folder1} dominates {folder2}")
                elif is_better_solution(metrics2, metrics1):
                    folders_to_remove.add(folder1)
                    print(f"{folder2} dominates {folder1}")
    
    # Remove dominated folders
    removed_count = 0
    for folder in folders_to_remove:
        folder_path = os.path.join(path, folder)
        try:
            shutil.rmtree(folder_path)
            print(f"Removed dominated solution: {folder}")
            removed_count += 1
        except Exception as e:
            print(f"Error removing {folder}: {e}")
    
    remaining_count = len(folder_metrics) - removed_count
    print(f"\nSummary:")
    print(f"- Original folders found: {len(folders)}")
    print(f"- Folders with valid metrics: {len(folder_metrics)}")
    print(f"- Dominated folders removed: {removed_count}")
    print(f"- Non-dominated folders remaining: {remaining_count}")

if __name__ == '__main__':
    main()