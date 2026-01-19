DESIGNS="NV_NVDLA_partition_c ac97_top aes aes_cipher_top ariane des des3 fpu mc_top mempool_tile_wrap netcard_fast pci_bridge32 tv80s"

#DESIGNS="ac97_top aes aes_cipher_top ariane des pci_bridge32"
for case in $DESIGNS; do
# for case in "des"; do
    echo "============${case} start==============="
    ./run.sh $case 1 1 1 &
    echo "============${case} end==============="
    echo ""
done

wait

./scripts/make_table_ppa.py

# Create tar archive of write_ans.log files from specific folders
# TIMESTAMP=$(date +%Y%m%d%H%M)
# TAR_NAME="log-${TIMESTAMP}.tar.gz"
# tar -czf "$TAR_NAME" ./output/results.xlsx ./output/ac97_top/write_ans.log ./output/aes/write_ans.log ./output/aes_cipher_top/write_ans.log ./output/ariane/write_ans.log ./output/des/write_ans.log ./output/pci_bridge32/write_ans.log 2>/dev/null
# echo "Created archive: $TAR_NAME"