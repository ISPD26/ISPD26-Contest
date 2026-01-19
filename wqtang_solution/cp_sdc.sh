DESIGNS="NV_NVDLA_partition_c ac97_top aes aes_cipher_top ariane des des3 fpu mc_top mempool_tile_wrap netcard_fast pci_bridge32 tv80s"
#DESIGNS="ac97_top aes aes_cipher_top ariane des pci_bridge32"

for case in $DESIGNS; do
    cp ./testcases/$case/$case.sdc ./database/$case/original/$case.sdc
done
