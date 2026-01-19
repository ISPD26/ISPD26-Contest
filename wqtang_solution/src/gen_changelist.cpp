#include <bits/stdc++.h>
using namespace std;

// Parse COMPONENTS section from DEF file
// Returns: map<instance_name, cell_type>
unordered_map<string, string> parseComponents(const string& filename) {
    ifstream in(filename);
    unordered_map<string, string> components;
    
    if (!in) {
        cerr << "Error opening file: " << filename << endl;
        return components;
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
            
            // Extract cell type name (next token after instance name)
            size_t typeStart = nameEnd + 1;
            size_t typeEnd = entry.find(' ', typeStart);
            if (typeEnd == string::npos) {
                typeEnd = entry.find(';', typeStart);
            }
            if (typeEnd == string::npos) continue;
            
            string cell_type = entry.substr(typeStart, typeEnd - typeStart);
            
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
            
            components[instance_name] = cell_type;
        }
    }
    
    return components;
}

string trim(const string &s){
    string res;
    bool start=false;
    for(char c:s){
        if(!isspace(c))start=true;
        if(start)res.push_back(c);
    }
    while(res.size()&&isspace(res.back()))res.pop_back();
    return res;
}

struct Inserted_Buffer{
    vector<pair<string,string>> load_pins; // {cell, pin}
    string cell_name,cell_type,net_name;
};

void parseNets(const string& filename,ofstream &out,const unordered_map<string,string> &newBuf_cellType) {
    ifstream in(filename);
    if (!in) {
        cerr << "Error opening file: " << filename << endl;
    }

    string line;
    bool inNets = false;

    vector<pair<string,string>> pins;
    pair<string,string> newCell;
    string netName;
    bool inserted=false;
    bool startNetName=false;
    bool inPin=false;
    string pin_name;

    vector<Inserted_Buffer> buffers;

    while (getline(in, line)) {
        if (line.find("NETS") != string::npos && line.find("END NETS") == string::npos && line.find("SPECIALNETS") == string::npos) {
            inNets = true;
            continue;
        }
        if (line.find("END NETS") != string::npos) {
            inNets = false;
            break;
        }
        if (inNets) {
            for(char c:line){
                if(c==';'){
                    //cout<<pins.size()<<" "<<inserted<<endl;
                    if(inserted){
                        auto buffer=Inserted_Buffer();
                        for(const auto &[inst,pin]:pins){
                            buffer.load_pins.emplace_back(inst,pin);
                        }
                        buffer.cell_name=newCell.first;
                        buffer.cell_type=newCell.second;
                        buffer.net_name=netName;
                        buffers.emplace_back(buffer);
                    }
                    pins.clear();
                    inserted=false;
                    netName="";
                }
                if(c=='('){
                    if(startNetName){
                        netName=trim(netName);
                        startNetName=false;
                    }
                    inPin=true;
                }
                if(c==')'){
                    //cout<<pin_name<<endl;
                    pin_name=trim(pin_name);
                    //cout<<pin_name<<endl;
                    string inst,pin;
                    istringstream sin(pin_name);
                    sin>>inst>>pin;
                    auto iter=newBuf_cellType.find(inst);
                    if(iter!=newBuf_cellType.end()&&pin=="Y"){
                        inserted=true;
                        newCell=make_pair(iter->first,iter->second);
                    }
                    else pins.emplace_back(inst,pin);
                    pin_name="";
                    inPin=false;
                }
                if(startNetName){
                    netName.push_back(c);
                }
                if(c=='-'){
                    startNetName=true;
                }
                if(inPin){
                    if(c!='('&&c!=')'&&c!='\\')pin_name.push_back(c);
                }
            }
        }
    }

    //topological-sorted buffer insertion
    vector<vector<int>> graph;
    vector<int> indegrees(buffers.size()+5,0);
    graph.resize(buffers.size()+5);
    unordered_map<string,int> cell_idx;
    for(int i=0;i<buffers.size();++i){
        cell_idx[buffers[i].cell_name]=i;
    }
    for(int i=0;i<buffers.size();++i){
        for(const auto &[cell,pin]:buffers[i].load_pins){
            auto iter=cell_idx.find(cell);
            if(iter!=cell_idx.end()){
                graph[iter->second].push_back(i);
                ++indegrees[i];
            }
        }
    }
    queue<int> ique;
    for(int i=0;i<buffers.size();++i){
        if(indegrees[i]==0){
            ique.push(i);
        }
    }
    while(ique.size()){
        int u=ique.front();ique.pop();
        //insert_buffer { g214225/A } rebuffer84 HB1xp67_ASAP7_75t_L net84
        out<<"insert_buffer {";
        for(int i=0;i<buffers[u].load_pins.size();++i){
            if(i)out<<" ";
            out<<buffers[u].load_pins[i].first<<"/"<<buffers[u].load_pins[i].second;
        }
        out<<"} ";
        out<<buffers[u].cell_type<<" "<<buffers[u].cell_name<<" "<<buffers[u].net_name<<endl;
        for(auto v:graph[u]){
            --indegrees[v];
            if(indegrees[v]==0)ique.push(v);
        }
    }
}

int main(int argc, char* argv[]) {
    if (argc != 4) {
        cerr << "Usage: " << argv[0] << " <original def> <optimized def> <output changelist>" << endl;
        return 1;
    }

    ios_base::sync_with_stdio(false);
    cin.tie(nullptr);

    string original_def = argv[1];
    string optimized_def = argv[2];
    string output_file = argv[3];

    // Parse components from both DEF files
    auto original_components = parseComponents(original_def);
    auto optimized_components = parseComponents(optimized_def);
    //cout<<original_components.size()<<" "<<optimized_components.size()<<endl;
    

    ofstream out(output_file);
    if (!out) {
        cerr << "Error opening output file: " << output_file << endl;
        return 1;
    }

    // Statistics counters
    int buffer_count = 0;
    int resize_count = 0;
    unordered_map<string,string> newBuf_cellType;

    // Find cell sizing changes and buffer insertions
    for (const auto& [instance_name, opt_cell_type] : optimized_components) {
        
        auto orig_it = original_components.find(instance_name);
        
        if (orig_it != original_components.end()) {
            // Instance exists in both - check for cell type change
            const string& orig_cell_type = orig_it->second;
            
            if (orig_cell_type != opt_cell_type) {
                // Cell sizing detected
                out << "size_cell " << instance_name << " " << opt_cell_type << "\n";
                resize_count++;
            }
        }
        else {
            newBuf_cellType[instance_name]=opt_cell_type;
            buffer_count++;
        }
    }

    parseNets(optimized_def,out,newBuf_cellType);


    // Output statistics
    cout << "Changelist generation completed:" << endl;
    cout << "- Resized instances: " << resize_count << endl;
    cout << "- Inserted buffers: " << buffer_count << endl;


    out.close();
    return 0;
}