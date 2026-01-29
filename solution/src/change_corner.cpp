#include <bits/stdc++.h>
using namespace std;

// Function to check if a string is a valid corner name
bool isValidCorner(const string& corner) {
    return corner == "L" || corner == "R" || corner == "SL" || corner == "SRAM";
}

// Function to replace the corner suffix in a cell type name
string changeCorner(const string& cell_type, const string& new_corner) {
    // Don't change TAPCELL
    if (cell_type.find("TAPCELL") == 0) {
        return cell_type;
    }
    
    // Find the last underscore in the cell type name
    size_t last_underscore = cell_type.find_last_of('_');
    if (last_underscore != string::npos) {
        // Extract the current suffix after the last underscore
        string current_suffix = cell_type.substr(last_underscore + 1);
        
        // Only replace if the current suffix is a valid corner
        if (isValidCorner(current_suffix)) {
            return cell_type.substr(0, last_underscore + 1) + new_corner;
        }
    }
    
    // If no underscore found or current suffix is not a valid corner, return unchanged
    return cell_type;
}

// Parse and modify DEF file, changing cell type names in COMPONENTS section
void processDefFile(const string& input_file, const string& output_file, const string& corner_name) {
    ifstream in(input_file);
    ofstream out(output_file);
    
    if (!in) {
        cerr << "Error opening input file: " << input_file << endl;
        return;
    }
    
    if (!out) {
        cerr << "Error opening output file: " << output_file << endl;
        return;
    }

    string line, entry;
    bool inComps = false;
    int components_processed = 0;
    int components_changed = 0;
    
    while (getline(in, line)) {
        if (line.find("COMPONENTS") != string::npos && line.find("END COMPONENTS") == string::npos) {
            inComps = true;
            out << line << endl;
            continue;
        }
        if (line.find("END COMPONENTS") != string::npos) {
            inComps = false;
            out << line << endl;
            continue;
        }

        if (inComps && line.find("- ") != string::npos) {
            entry = line;
            // Read multi-line entries until we find semicolon
            while (entry.find(';') == string::npos) {
                if (!getline(in, line)) break;
                entry += " " + line;
            }

            // Extract instance name (after "- ")
            size_t nameStart = entry.find("- ") + 2;
            size_t nameEnd = entry.find(' ', nameStart);
            if (nameEnd == string::npos) {
                out << entry << endl;
                continue;
            }
            
            string instance_name = entry.substr(nameStart, nameEnd - nameStart);
            
            // Extract cell type name (next token after instance name)
            size_t typeStart = nameEnd + 1;
            size_t typeEnd = entry.find(' ', typeStart);
            if (typeEnd == string::npos) {
                typeEnd = entry.find(';', typeStart);
            }
            if (typeEnd == string::npos) {
                out << entry << endl;
                continue;
            }
            
            string original_cell_type = entry.substr(typeStart, typeEnd - typeStart);
            string new_cell_type = changeCorner(original_cell_type, corner_name);
            
            components_processed++;
            
            // Check if the cell type was actually changed
            if (new_cell_type != original_cell_type) {
                components_changed++;
                // Replace the cell type in the entry
                string modified_entry = entry.substr(0, typeStart) + new_cell_type + entry.substr(typeEnd);
                out << modified_entry << endl;
            } else {
                // Cell type unchanged, write original entry
                out << entry << endl;
            }
        } else {
            // Non-component line, write as-is
            out << line << endl;
        }
    }
    
    cout << "Successfully processed " << components_processed << " components" << endl;
    cout << "Changed " << components_changed << " components from valid corners to " << corner_name << endl;
    cout << "Skipped " << (components_processed - components_changed) << " components (no valid corner suffix)" << endl;
}

// Parse and modify Verilog file, changing cell type names
void processVerilogFile(const string& input_file, const string& output_file, const string& corner_name) {
    ifstream in(input_file);
    ofstream out(output_file);
    
    if (!in) {
        cerr << "Error opening input Verilog file: " << input_file << endl;
        return;
    }
    
    if (!out) {
        cerr << "Error opening output Verilog file: " << output_file << endl;
        return;
    }

    string line;
    int instances_changed = 0;
    
    while (getline(in, line)) {
        // Look for lines with cell instantiations
        // Pattern: whitespace + CELL_TYPE + whitespace + instance_name + whitespace + (
        // Example:  BUFx3_ASAP7_75t_L rebuffer18 (.A(net395),
        
        size_t pos = 0;
        string modified_line = line;
        
        // Skip leading whitespace
        while (pos < line.length() && isspace(line[pos])) pos++;
        
        if (pos < line.length() && (isalpha(line[pos]) || line[pos] == '_')) {
            // Extract potential cell type
            size_t cell_start = pos;
            while (pos < line.length() && (isalnum(line[pos]) || line[pos] == '_')) {
                pos++;
            }
            string cell_type = line.substr(cell_start, pos - cell_start);
            
            // Check if this is followed by whitespace and then an identifier (instance name)
            if (pos < line.length() && isspace(line[pos])) {
                size_t ws_start = pos;
                while (pos < line.length() && isspace(line[pos])) pos++;
                
                // Check for instance name
                if (pos < line.length() && (isalpha(line[pos]) || line[pos] == '_' || line[pos] == '\\')) {
                    size_t inst_start = pos;
                    while (pos < line.length() && (isalnum(line[pos]) || line[pos] == '_' || line[pos] == '/' || line[pos] == '\\')) {
                        pos++;
                    }
                    
                    // Skip whitespace after instance name
                    while (pos < line.length() && isspace(line[pos])) pos++;
                    
                    // Check if followed by '(' which indicates instantiation
                    if (pos < line.length() && line[pos] == '(') {
                        // This is a cell instantiation
                        string new_cell_type = changeCorner(cell_type, corner_name);
                        
                        if (new_cell_type != cell_type) {
                            modified_line = line.substr(0, cell_start) + new_cell_type + line.substr(cell_start + cell_type.length());
                            instances_changed++;
                        }
                    }
                }
            }
        }
        
        out << modified_line << endl;
    }
    
    cout << "Verilog: Changed " << instances_changed << " instances to " << corner_name << endl;
}

int main(int argc, char* argv[]) {
    if (argc != 6) {
        cerr << "Usage: " << argv[0] << " <input def> <output def> <input verilog> <output verilog> <corner name>" << endl;
        cerr << "Example: " << argv[0] << " testcases/aes_cipher_top/aes_cipher_top.def ./test_dir/aes_cipher_top.def testcases/aes_cipher_top/aes_cipher_top.v ./test_dir/aes_cipher_top.v SL" << endl;
        return 1;
    }

    ios_base::sync_with_stdio(false);
    cin.tie(nullptr);

    string input_def = argv[1];
    string output_def = argv[2];
    string input_verilog = argv[3];
    string output_verilog = argv[4];
    string corner_name = argv[5];

    cout << "Processing DEF file: " << input_def << endl;
    cout << "Output DEF file: " << output_def << endl;
    cout << "Processing Verilog file: " << input_verilog << endl;
    cout << "Output Verilog file: " << output_verilog << endl;
    cout << "Changing corner to: " << corner_name << endl;

    processDefFile(input_def, output_def, corner_name);
    processVerilogFile(input_verilog, output_verilog, corner_name);

    return 0;
}