#include <bits/stdc++.h>
using namespace std;

// Use pair to store cell placement coordinates (x, y)
using Point = pair<int64_t, int64_t>;

// Parse COMPONENTS section from DEF file
// Returns: map<instance_name, Point>
unordered_map<string, Point> parseComponents(const string& filename) {
    ifstream in(filename);
    unordered_map<string, Point> placements;
    
    if (!in) {
        cerr << "Error opening file: " << filename << endl;
        return placements;
    }

    string line, entry;
    bool inComps = false;
    
    while (getline(in, line)) {
        if (line.find("COMPONENTS") != string::npos && line.find("END COMPONENTS") == string::npos) {
            inComps = true;
            continue;
        }
        if (line.find("END COMPONENTS") != string::npos) {
            inComps = false;
            break;
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
            if (nameEnd == string::npos) continue;
            
            string instance_name = entry.substr(nameStart, nameEnd - nameStart);
            
            // Remove escaped brackets from instance name
            size_t pos = 0;
            while ((pos = instance_name.find("\\]", pos)) != string::npos) {
                instance_name.replace(pos, 2, "]");
                pos += 1;
            }
            pos = 0;
            while ((pos = instance_name.find("\\[", pos)) != string::npos) {
                instance_name.replace(pos, 2, "[");
                pos += 1;
            }
            
            // Extract coordinates from PLACED ( x y )
            size_t placedPos = entry.find("PLACED ( ");
            if (placedPos != string::npos) {
                placedPos += 9; // length of "PLACED ( "
                size_t spacePos = entry.find(' ', placedPos);
                size_t endPos = entry.find(' ', spacePos + 1);
                
                if (spacePos != string::npos && endPos != string::npos) {
                    string x_str = entry.substr(placedPos, spacePos - placedPos);
                    string y_str = entry.substr(spacePos + 1, endPos - spacePos - 1);
                    
                    Point placement = {stoll(x_str), stoll(y_str)};
                    
                    placements[instance_name] = placement;
                }
            }
        }
    }
    
    return placements;
}

// Calculate Manhattan distance between two placements
uint64_t calculateManhattanDistance(const Point& p1, const Point& p2) {
    // Use absolute value to ensure non-negative result
    uint64_t dx = abs(p1.first - p2.first);
    uint64_t dy = abs(p1.second - p2.second);
    return dx + dy;
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
        cerr << "Usage: " << argv[0] << " <original def> <optimized def>" << endl;
        return 1;
    }

    ios_base::sync_with_stdio(false);
    cin.tie(nullptr);

    string original_def = argv[1];
    string optimized_def = argv[2];

    // Parse components from both DEF files
    auto original_placements = parseComponents(original_def);
    auto optimized_placements = parseComponents(optimized_def);

    cout << "Original design has " << original_placements.size() << " components" << endl;
    cout << "Optimized design has " << optimized_placements.size() << " components" << endl;

    // Calculate displacement and check for missing cells in one pass
    uint64_t total_displacement = 0;
    uint64_t cell_count = 0;
    uint64_t moved_cells = 0;
    vector<string> missing_cells;
    
    for (const auto& [instance_name, orig_placement] : original_placements) {
        auto opt_it = optimized_placements.find(instance_name);
        
        if (opt_it != optimized_placements.end()) {
            // Cell exists in both designs - calculate displacement
            uint64_t displacement = calculateManhattanDistance(orig_placement, opt_it->second);
            total_displacement += displacement;
            cell_count++;
            
            // Count cells that were moved (displacement > 0)
            if (displacement > 0) {
                moved_cells++;
            }
            
            // Optional: print individual cell displacement for debugging
            // cout << "Cell " << instance_name << " displaced by " << displacement << endl;
        } else {
            // Cell missing in optimized design
            missing_cells.push_back(instance_name);
        }
    }

    // Report error if any cells are missing
    if (!missing_cells.empty()) {
        cerr << "\nERROR: " << missing_cells.size() << " cells from original design are missing in optimized design:" << endl;
        for (const string& cell_name : missing_cells) {
            cerr << "  - " << cell_name << endl;
        }
        return 1; // Exit with error code
    }

    // Calculate average displacement
    double average_displacement = 0.0;
    if (cell_count > 0) {
        average_displacement = static_cast<double>(total_displacement) / cell_count;
    }

    // Calculate movement statistics
    double moved_percentage = 0.0;
    if (cell_count > 0) {
        moved_percentage = (static_cast<double>(moved_cells) / cell_count) * 100.0;
    }

    cout << "Displacement Statistics:" << endl;
    cout << "- Cells analyzed: " << cell_count << endl;
    cout << "- Total displacement: " << total_displacement << endl;
    cout << "- Average displacement per cell: " << fixed << setprecision(6) << average_displacement << endl;
    cout << "- Cells moved: " << moved_cells << " out of " << cell_count 
         << " (" << fixed << setprecision(2) << moved_percentage << "%)" << endl;

    // Count new cells in optimized design (for information only)
    uint64_t new_cells = 0;
    for (const auto& [instance_name, opt_placement] : optimized_placements) {
        if (original_placements.find(instance_name) == original_placements.end()) {
            new_cells++;
        }
    }
    cout << "- New cells in optimized design (ignored): " << new_cells << endl;

    return 0;
}