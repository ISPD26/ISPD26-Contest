# Check if all arguments are provided
DESIGNS="NV_NVDLA_partition_c ac97_top aes aes_cipher_top ariane des des3 fpu mc_top mempool_tile_wrap netcard_fast pci_bridge32 tv80s"

#DESIGNS="ac97_top aes aes_cipher_top ariane des pci_bridge32"

if [ $# -ne 2 ]; then
    echo "Usage: $0 <result path> <database path>"
    exit 1
fi

RES_PATH=$1
DB_PATH=$2
for case in $DESIGNS; do
    echo "============${case} start==============="
    ./scripts/update_db.py "${RES_PATH}/${case}/" "${DB_PATH}/${case}/"
    echo "============${case} end==============="
    echo ""
done

./check_db.sh "${DB_PATH}"