# Check if all arguments are provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <database path>"
    exit 1
fi

DB_PATH=$1
for case in "ac97_top" "aes" "aes_cipher_top" "ariane" "des" "pci_bridge32"; do
    echo "============${case} start==============="
    ./scripts/reduce_db.py "${DB_PATH}/${case}/"
    echo "============${case} end==============="
    echo ""
done