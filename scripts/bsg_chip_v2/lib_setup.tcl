set libdir "${top_proj_dir}/Platform/ASAP7/lib"
set lefdir "${top_proj_dir}/Platform/ASAP7/lef"



set libworst "
  ${libdir}/asap7sc7p5t_AO_LVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_AO_RVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_AO_SLVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_INVBUF_LVT_TT_nldm_220122.lib \
  ${libdir}/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib \
  ${libdir}/asap7sc7p5t_INVBUF_SLVT_TT_nldm_220122.lib \
  ${libdir}/asap7sc7p5t_OA_LVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_OA_RVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_OA_SLVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_SEQ_LVT_TT_nldm_220123.lib \
  ${libdir}/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib \
  ${libdir}/asap7sc7p5t_SEQ_SLVT_TT_nldm_220123.lib \
  ${libdir}/asap7sc7p5t_SIMPLE_LVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_SIMPLE_SLVT_TT_nldm_211120.lib \
  ${libdir}/sram_asap7_16x256_1rw.lib \
  ${libdir}/sram_asap7_32x256_1rw.lib \
  ${libdir}/sram_asap7_64x256_1rw.lib \
  ${libdir}/sram_asap7_64x64_1rw.lib \
  ${libdir}/sram_asap7_32x32_1rw.lib \
  ${libdir}/sram_asap7_116x128_1rw.lib \
  ${libdir}/sram_asap7_48x256_1rw.lib \
  ${libdir}/sram_asap7_62x64_1rw.lib \
  ${libdir}/sram_asap7_124x64_1rw.lib \
  ${libdir}/sram_asap7_64x512_1rw.lib \
  "

set libbest "
  ${libdir}/asap7sc7p5t_AO_LVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_AO_RVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_AO_SLVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_INVBUF_LVT_TT_nldm_220122.lib \
  ${libdir}/asap7sc7p5t_INVBUF_RVT_TT_nldm_220122.lib \
  ${libdir}/asap7sc7p5t_INVBUF_SLVT_TT_nldm_220122.lib \
  ${libdir}/asap7sc7p5t_OA_LVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_OA_RVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_OA_SLVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_SEQ_LVT_TT_nldm_220123.lib \
  ${libdir}/asap7sc7p5t_SEQ_RVT_TT_nldm_220123.lib \
  ${libdir}/asap7sc7p5t_SEQ_SLVT_TT_nldm_220123.lib \
  ${libdir}/asap7sc7p5t_SIMPLE_LVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_SIMPLE_RVT_TT_nldm_211120.lib \
  ${libdir}/asap7sc7p5t_SIMPLE_SLVT_TT_nldm_211120.lib \
  ${libdir}/sram_asap7_16x256_1rw.lib \
  ${libdir}/sram_asap7_32x256_1rw.lib \
  ${libdir}/sram_asap7_64x256_1rw.lib \
  ${libdir}/sram_asap7_64x64_1rw.lib \
  ${libdir}/sram_asap7_32x32_1rw.lib \
  ${libdir}/sram_asap7_116x128_1rw.lib \
  ${libdir}/sram_asap7_48x256_1rw.lib \
  ${libdir}/sram_asap7_62x64_1rw.lib \
  ${libdir}/sram_asap7_124x64_1rw.lib \
  ${libdir}/sram_asap7_64x512_1rw.lib \
  "

set lefs "
  ${lefdir}/asap7_tech_1x_201209.lef \
  ${lefdir}/asap7sc7p5t_28_L_1x_220121a.lef \
  ${lefdir}/asap7sc7p5t_28_R_1x_220121a.lef \
  ${lefdir}/asap7sc7p5t_28_SL_1x_220121a.lef \
  ${lefdir}/sram_asap7_16x256_1rw.lef \
  ${lefdir}/sram_asap7_32x256_1rw.lef \
  ${lefdir}/sram_asap7_64x256_1rw.lef \
  ${lefdir}/sram_asap7_64x64_1rw.lef \
  ${lefdir}/sram_asap7_32x32_1rw.lef \
  ${lefdir}/sram_asap7_116x128_1rw.lef \
  ${lefdir}/sram_asap7_48x256_1rw.lef \
  ${lefdir}/sram_asap7_62x64_1rw.lef \
  ${lefdir}/sram_asap7_124x64_1rw.lef \
  ${lefdir}/sram_asap7_64x512_1rw.lef \
  "

set rc_file "${top_proj_dir}/Platform/ASAP7/util/setRC.tcl"



