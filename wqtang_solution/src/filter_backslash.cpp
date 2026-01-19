#include <iostream>
#include <fstream>
#include <string>
#include <cctype>

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <input file> <output file>\n";
        return 1;
    }
    
    std::ifstream input(argv[1], std::ios::binary);
    if (!input) {
        std::cerr << "Error: Cannot open input file " << argv[1] << "\n";
        return 1;
    }
    
    std::ofstream output(argv[2], std::ios::binary);
    if (!output) {
        std::cerr << "Error: Cannot create output file " << argv[2] << "\n";
        return 1;
    }
    
    std::string buffer;
    buffer.reserve(8192); // Pre-allocate buffer
    
    char ch;
    while (input.get(ch)) {
        if (ch == '\\') {
            char next;
            if (input.get(next)) {
                if (std::isspace(next)) {
                    // Keep backslash and following space character
                    buffer += ch;
                    buffer += next;
                } else {
                    // Remove backslash, keep following character
                    buffer += next;
                }
            } else {
                // Backslash at end of file, remove it
                break;
            }
        } else {
            buffer += ch;
        }
        
        // Batch write for efficiency
        if (buffer.size() >= 8192) {
            output.write(buffer.data(), buffer.size());
            buffer.clear();
        }
    }
    
    // Write remaining content
    if (!buffer.empty()) {
        output.write(buffer.data(), buffer.size());
    }
    
    return 0;
}