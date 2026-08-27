	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.section	.text._Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,"axG",@progbits,_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,comdat
	.protected	_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs ; -- Begin function _Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
	.globl	_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
	.p2align	8
	.type	_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,@function
_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs: ; @_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
; %bb.0:
	s_load_dwordx2 s[16:17], s[0:1], 0x1c
	s_abs_i32 s20, s2
	s_ashr_i32 s19, s2, 31
	v_readfirstlane_b32 s33, v0
	s_waitcnt lgkmcnt(0)
	s_add_i32 s4, s16, 0xff
	s_ashr_i32 s5, s4, 31
	s_lshr_b32 s5, s5, 24
	s_add_i32 s4, s4, s5
	s_ashr_i32 s16, s4, 8
	s_abs_i32 s18, s16
	v_cvt_f32_u32_e32 v1, s18
	s_sub_i32 s4, 0, s18
	s_ashr_i32 s21, s16, 31
	v_rcp_iflag_f32_e32 v1, v1
	s_nop 0
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_nop 0
	v_readfirstlane_b32 s5, v1
	s_mul_i32 s4, s4, s5
	s_mul_hi_u32 s4, s5, s4
	s_add_i32 s5, s5, s4
	s_mul_hi_u32 s22, s20, s5
	s_load_dwordx4 s[36:39], s[0:1], 0x0
	s_load_dwordx2 s[34:35], s[0:1], 0x10
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_load_dwordx2 s[40:41], s[0:1], 0x38
	s_load_dwordx8 s[4:11], s[0:1], 0x40
	s_mul_i32 s1, s22, s18
	s_sub_i32 s1, s20, s1
	s_xor_b32 s0, s19, s21
	s_add_i32 s19, s22, 1
	s_sub_i32 s20, s1, s18
	s_cmp_ge_u32 s1, s18
	s_cselect_b32 s19, s19, s22
	s_cselect_b32 s1, s20, s1
	s_add_i32 s20, s19, 1
	s_cmp_ge_u32 s1, s18
	s_cselect_b32 s1, s20, s19
	s_xor_b32 s1, s1, s0
	s_sub_i32 s24, s1, s0
	s_mul_i32 s0, s24, s16
	s_add_i32 s16, s17, 0x7f
	s_sub_i32 s25, s2, s0
	s_ashr_i32 s0, s16, 31
	s_lshr_b32 s0, s0, 25
	s_add_i32 s0, s16, s0
	s_ashr_i32 s2, s0, 7
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s0, s10, s3
	s_lshr_b32 s42, s33, 6
	s_ashr_i32 s1, s0, 31
	s_add_u32 s0, s4, s0
	s_mul_i32 s4, s8, s2
	s_mul_i32 s4, s4, s24
	s_addc_u32 s1, s5, s1
	s_ashr_i32 s5, s4, 31
	s_add_u32 s20, s0, s4
	s_addc_u32 s0, s1, s5
	s_and_b32 s21, s0, 0xffff
	s_mul_i32 s0, s11, s3
	s_ashr_i32 s1, s0, 31
	s_mul_i32 s4, s9, s2
	s_add_u32 s0, s6, s0
	s_mul_i32 s4, s4, s25
	s_addc_u32 s1, s7, s1
	s_ashr_i32 s5, s4, 31
	s_add_u32 s28, s0, s4
	s_addc_u32 s0, s1, s5
	v_and_b32_e32 v1, 63, v0
	s_and_b32 s29, s0, 0xffff
	s_mov_b32 s19, 0x20000
	s_mov_b32 s18, -1
	v_lshlrev_b32_e32 v73, 4, v1
	s_cmp_lt_i32 s42, 1
	s_mov_b64 s[0:1], -1
	s_cbranch_scc1 .LBB0_4
; %bb.1:                                ; %LeafBlock
	s_cmp_eq_u32 s42, 1
	s_cbranch_scc0 .LBB0_3
; %bb.2:
	s_mov_b32 s30, s18
	s_mov_b32 s31, s19
	s_mov_b32 m0, 0x21800
	s_nop 0
	buffer_load_dwordx4 v73, s[28:31], 0 offen lds
.LBB0_3:                                ; %Flow2421
	s_mov_b64 s[0:1], 0
.LBB0_4:                                ; %Flow2422
	s_andn2_b64 vcc, exec, s[0:1]
	s_cbranch_vccnz .LBB0_6
; %bb.5:
	s_mov_b32 s22, s18
	s_mov_b32 s23, s19
	s_mov_b32 m0, 0x21000
	s_nop 0
	buffer_load_dwordx4 v73, s[20:23], 0 offen lds
.LBB0_6:
	s_mul_i32 s4, s15, s3
	s_lshl_b32 s1, s24, 8
	s_lshl_b32 s0, s25, 8
	s_ashr_i32 s5, s4, 31
	s_add_u32 s4, s36, s4
	s_mul_i32 s6, s1, s12
	s_addc_u32 s5, s37, s5
	s_ashr_i32 s7, s6, 31
	s_add_u32 s24, s4, s6
	s_addc_u32 s4, s5, s7
	s_and_b32 s25, s4, 0xffff
	s_mul_i32 s4, s40, s3
	s_ashr_i32 s5, s4, 31
	s_add_u32 s4, s38, s4
	s_mul_i32 s10, s0, s13
	s_addc_u32 s5, s39, s5
	s_ashr_i32 s11, s10, 31
	s_add_u32 s4, s4, s10
	s_addc_u32 s5, s5, s11
	s_lshr_b32 s30, s33, 9
	v_and_b32_e32 v4, 56, v0
	s_and_b32 s15, s42, 7
	v_and_b32_e32 v3, 7, v0
	v_lshl_or_b32 v4, s30, 6, v4
	v_lshlrev_b32_e32 v2, 4, v3
	v_or_b32_e32 v4, s15, v4
	v_mad_u64_u32 v[68:69], s[10:11], v4, s12, v[2:3]
	v_mad_u64_u32 v[66:67], s[10:11], v4, s13, v[2:3]
	s_mul_i32 s10, s30, 0x2100
	s_mul_i32 s37, s15, 0x420
	s_mov_b32 s7, 0x20000
	s_mov_b32 s6, -1
	s_add_i32 s37, s37, s10
	s_mov_b32 s26, s6
	s_mov_b32 s27, s7
	s_mov_b32 m0, s37
	s_add_i32 s31, s37, 0x10800
	s_and_b32 s5, s5, 0xffff
	buffer_load_dwordx4 v68, s[24:27], 0 offen lds
	s_mov_b32 m0, s31
	s_add_i32 s36, s37, 0x4200
	s_lshl_b32 s23, s12, 7
	buffer_load_dwordx4 v66, s[4:7], 0 offen lds
	s_mov_b32 m0, s36
	s_lshl_b32 s39, s13, 7
	buffer_load_dwordx4 v68, s[24:27], s23 offen lds
	s_add_i32 m0, s31, 0x4200
	s_bfe_u32 s10, s42, 0x20001
	buffer_load_dwordx4 v66, s[4:7], s39 offen lds
	s_mul_i32 s26, s10, 0x2100
	s_lshl_b32 s10, s42, 8
	v_lshlrev_b32_e32 v2, 4, v0
	v_lshrrev_b32_e32 v4, 4, v1
	v_mul_u32_u24_e32 v1, 0x420, v3
	s_and_b32 s10, s10, 0x100
	v_and_b32_e32 v2, 0x80, v2
	v_and_b32_e32 v3, 48, v0
	v_and_b32_e32 v65, 15, v0
	v_add3_u32 v1, v1, v3, v2
	s_add_i32 s26, s26, s10
	s_lshl_b32 s17, s30, 8
	s_lshl_b32 s27, s15, 7
	v_lshlrev_b32_e32 v2, 3, v65
	v_lshlrev_b32_e32 v3, 1, v4
	v_lshlrev_b32_e32 v0, 4, v65
	v_lshlrev_b32_e32 v64, 2, v4
	s_mov_b32 s22, 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_cmpk_gt_i32 s16, 0xff
	v_add3_u32 v67, s17, v0, v64
	s_cbranch_scc1 .LBB0_8
; %bb.7:                                ; %.._crit_edge_crit_edge
	s_mov_b64 s[10:11], 0
	s_branch .LBB0_9
.LBB0_8:
	s_mov_b64 s[10:11], -1
.LBB0_9:                                ; %Flow2420
	v_add_u32_e32 v70, s26, v1
	v_add_u32_e32 v69, s17, v1
	v_or3_b32 v71, s27, v2, v3
	s_andn2_b64 vcc, exec, s[10:11]
	v_or3_b32 v72, v64, v0, s17
	s_cbranch_vccnz .LBB0_31
; %bb.10:                               ; %.lr.ph
	s_add_i32 s40, s37, 0x18c00
	s_movk_i32 s10, 0x80
	s_mov_b32 m0, s40
	s_nop 0
	buffer_load_dwordx4 v66, s[4:7], s10 offen lds
	s_add_i32 s10, s39, 0x80
	s_add_i32 m0, s37, 0x1ce00
	s_nop 0
	buffer_load_dwordx4 v66, s[4:7], s10 offen lds
	; sched_barrier mask(0x00000000)
	s_add_i32 s33, s37, 0x14a00
	v_add_u32_e32 v74, 0x10800, v69
	s_cmpk_lt_i32 s16, 0x180
	s_cbranch_scc1 .LBB0_32
; %bb.11:                               ; %.lr.ph.new
	s_max_i32 s43, s2, 2
	s_add_i32 s43, s43, -1
	v_mov_b32_e32 v60, 0
	s_and_b32 s38, s43, -2
	s_add_i32 s44, s37, 0x8400
	s_add_i32 s45, s36, 0x8400
	s_add_i32 s46, s33, 0x8400
	s_mov_b32 s10, 0
	s_mov_b32 s26, s6
	s_mov_b32 s27, s7
	s_mov_b32 s47, 0
	v_mov_b32_e32 v61, v60
	v_mov_b32_e32 v62, v60
	v_mov_b32_e32 v63, v60
	v_mov_b32_e32 v56, v60
	v_mov_b32_e32 v57, v60
	v_mov_b32_e32 v58, v60
	v_mov_b32_e32 v59, v60
	v_mov_b32_e32 v52, v60
	v_mov_b32_e32 v53, v60
	v_mov_b32_e32 v54, v60
	v_mov_b32_e32 v55, v60
	v_mov_b32_e32 v48, v60
	v_mov_b32_e32 v49, v60
	v_mov_b32_e32 v50, v60
	v_mov_b32_e32 v51, v60
	v_mov_b32_e32 v4, v60
	v_mov_b32_e32 v5, v60
	v_mov_b32_e32 v6, v60
	v_mov_b32_e32 v7, v60
	v_mov_b32_e32 v44, v60
	v_mov_b32_e32 v45, v60
	v_mov_b32_e32 v46, v60
	v_mov_b32_e32 v47, v60
	v_mov_b32_e32 v40, v60
	v_mov_b32_e32 v41, v60
	v_mov_b32_e32 v42, v60
	v_mov_b32_e32 v43, v60
	v_mov_b32_e32 v36, v60
	v_mov_b32_e32 v37, v60
	v_mov_b32_e32 v38, v60
	v_mov_b32_e32 v39, v60
	v_mov_b32_e32 v32, v60
	v_mov_b32_e32 v33, v60
	v_mov_b32_e32 v34, v60
	v_mov_b32_e32 v35, v60
	v_mov_b32_e32 v28, v60
	v_mov_b32_e32 v29, v60
	v_mov_b32_e32 v30, v60
	v_mov_b32_e32 v31, v60
	v_mov_b32_e32 v20, v60
	v_mov_b32_e32 v21, v60
	v_mov_b32_e32 v22, v60
	v_mov_b32_e32 v23, v60
	v_mov_b32_e32 v24, v60
	v_mov_b32_e32 v25, v60
	v_mov_b32_e32 v26, v60
	v_mov_b32_e32 v27, v60
	v_mov_b32_e32 v16, v60
	v_mov_b32_e32 v17, v60
	v_mov_b32_e32 v18, v60
	v_mov_b32_e32 v19, v60
	v_mov_b32_e32 v12, v60
	v_mov_b32_e32 v13, v60
	v_mov_b32_e32 v14, v60
	v_mov_b32_e32 v15, v60
	v_mov_b32_e32 v8, v60
	v_mov_b32_e32 v9, v60
	v_mov_b32_e32 v10, v60
	v_mov_b32_e32 v11, v60
	v_mov_b32_e32 v0, v60
	v_mov_b32_e32 v1, v60
	v_mov_b32_e32 v2, v60
	v_mov_b32_e32 v3, v60
	s_branch .LBB0_13
.LBB0_12:                               ;   in Loop: Header=BB0_13 Depth=1
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[40:43], v[118:125], v[78:85], v[40:43], v75, v76 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[36:39], v[110:117], v[78:85], v[36:39], v75, v76 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[16:19], v[94:101], v[86:93], v[16:19], v75, v76 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[12:15], v[102:109], v[86:93], v[12:15], v75, v76 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[8:11], v[118:125], v[86:93], v[8:11], v75, v76 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[0:3], v[110:117], v[86:93], v[0:3], v75, v76 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_setprio 0
	s_cmp_lg_u32 s38, s47
	s_cbranch_scc0 .LBB0_33
.LBB0_13:                               ; %NodeBlock2362
                                        ; =>This Inner Loop Header: Depth=1
	s_mov_b32 s49, s47
	s_mov_b32 s48, s10
	s_mov_b32 s47, 0x21000
	s_mov_b64 s[10:11], -1
	s_cmp_lt_i32 s42, 1
	s_mov_b32 s50, s8
	s_mov_b64 s[16:17], s[20:21]
	s_cbranch_scc1 .LBB0_18
; %bb.14:                               ; %LeafBlock2360
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_cmp_eq_u32 s42, 1
	s_cbranch_scc0 .LBB0_16
; %bb.15:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s47, 0x21800
	s_branch .LBB0_17
.LBB0_16:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b64 s[10:11], 0
.LBB0_17:                               ; %Flow2415
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s50, s9
	s_mov_b64 s[16:17], s[28:29]
.LBB0_18:                               ; %Flow2414
                                        ;   in Loop: Header=BB0_13 Depth=1
	v_or_b32_e32 v75, 0x21000, v71
	v_add_u32_e32 v77, 0x21800, v72
	v_add_u32_e32 v78, 0x21a00, v67
	ds_read_u16 v76, v75
	ds_read_b32 v77, v77
	ds_read_b32 v75, v78
	ds_read_b128 v[78:81], v70
	ds_read_b128 v[82:85], v70 offset:64
	ds_read_b128 v[118:121], v74
	ds_read_b128 v[122:125], v74 offset:64
	ds_read_b128 v[110:113], v74 offset:8448
	ds_read_b128 v[114:117], v74 offset:8512
	ds_read_b128 v[94:97], v74 offset:16896
	ds_read_b128 v[98:101], v74 offset:16960
	ds_read_b128 v[102:105], v74 offset:25344
	ds_read_b128 v[106:109], v74 offset:25408
	s_and_b64 vcc, exec, s[10:11]
	s_cbranch_vccz .LBB0_20
; %bb.19:                               ; %.sink.split.i
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_add_i32 s10, s49, 1
	s_cmp_lg_u32 s47, -1
	s_cselect_b32 s11, s47, 0
	s_mul_i32 s10, s50, s10
	s_add_i32 m0, s11, 0x400
	s_nop 0
	buffer_load_dwordx4 v73, s[16:19], s10 offen lds
.LBB0_20:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s44
	s_add_i32 s10, s48, 0x80
	s_add_i32 s50, s23, s48
	buffer_load_dwordx4 v68, s[24:27], s10 offen lds
	s_add_i32 s10, s50, 0x80
	s_mov_b32 m0, s45
	s_waitcnt lgkmcnt(12)
	v_and_b32_e32 v76, 0xffff, v76
	buffer_load_dwordx4 v68, s[24:27], s10 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(0)
	s_setprio 1
	ds_read_b128 v[86:89], v70 offset:16896
	ds_read_b128 v[90:93], v70 offset:16960
	v_mfma_scale_f32_16x16x128_f8f6f4 v[60:63], v[118:125], v[78:85], v[60:63], v77, v76 op_sel_hi:[0,0,0]
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[56:59], v[110:117], v[78:85], v[56:59], v77, v76 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[52:55], v[94:101], v[78:85], v[52:55], v77, v76 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[48:51], v[102:109], v[78:85], v[48:51], v77, v76 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[32:35], v[118:125], v[86:93], v[32:35], v77, v76 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[118:121], v74 offset:33792
	ds_read_b128 v[122:125], v74 offset:33856
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[28:31], v[110:117], v[86:93], v[28:31], v77, v76 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[110:113], v74 offset:42240
	ds_read_b128 v[114:117], v74 offset:42304
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[20:23], v[94:101], v[86:93], v[20:23], v77, v76 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	ds_read_b128 v[94:97], v74 offset:25344
	ds_read_b128 v[98:101], v74 offset:25408
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[24:27], v[102:109], v[86:93], v[24:27], v77, v76 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	ds_read_b128 v[102:105], v74 offset:16896
	ds_read_b128 v[106:109], v74 offset:16960
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[4:7], v[102:109], v[78:85], v[4:7], v75, v76 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[44:47], v[94:101], v[78:85], v[44:47], v75, v76 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s47, s49, 2
	s_cmp_ge_i32 s47, s2
	s_cbranch_scc1 .LBB0_22
; %bb.21:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s31
	s_add_i32 s10, s48, 0x100
	buffer_load_dwordx4 v66, s[4:7], s10 offen lds
	s_add_i32 s10, s10, s39
	s_mov_b32 m0, s33
	s_nop 0
	buffer_load_dwordx4 v66, s[4:7], s10 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_22:                               ;   in Loop: Header=BB0_13 Depth=1
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[40:43], v[118:125], v[78:85], v[40:43], v75, v76 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[36:39], v[110:117], v[78:85], v[36:39], v75, v76 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[16:19], v[102:109], v[86:93], v[16:19], v75, v76 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[12:15], v[94:101], v[86:93], v[12:15], v75, v76 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[8:11], v[118:125], v[86:93], v[8:11], v75, v76 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[0:3], v[110:117], v[86:93], v[0:3], v75, v76 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_setprio 0
	v_or_b32_e32 v75, 0x21400, v71
	v_add_u32_e32 v77, 0x21c00, v72
	v_add_u32_e32 v78, 0x21e00, v67
	ds_read_u16 v76, v75
	ds_read_b32 v77, v77
	ds_read_b32 v75, v78
	ds_read_b128 v[78:81], v70 offset:33792
	ds_read_b128 v[82:85], v70 offset:33856
	ds_read_b128 v[94:97], v74 offset:33792
	ds_read_b128 v[98:101], v74 offset:33856
	ds_read_b128 v[102:105], v74 offset:42240
	ds_read_b128 v[106:109], v74 offset:42304
	ds_read_b128 v[110:113], v74 offset:50688
	ds_read_b128 v[114:117], v74 offset:50752
	ds_read_b128 v[118:121], v74 offset:59136
	ds_read_b128 v[122:125], v74 offset:59200
	s_cmp_lt_i32 s42, 1
	s_cbranch_scc1 .LBB0_25
; %bb.23:                               ; %LeafBlock2364
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_cmp_eq_u32 s42, 1
	s_cbranch_scc0 .LBB0_26
; %bb.24:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b64 s[10:11], -1
	s_mov_b32 s51, 0x21800
	s_branch .LBB0_27
.LBB0_25:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s51, 0x21000
	s_mov_b32 s52, s8
	s_mov_b64 s[16:17], s[20:21]
	s_cbranch_execnz .LBB0_28
	s_branch .LBB0_29
.LBB0_26:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b64 s[10:11], 0
	s_mov_b32 s51, 0x21000
.LBB0_27:                               ; %Flow2413
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s52, s9
	s_mov_b64 s[16:17], s[28:29]
	s_and_b64 vcc, exec, s[10:11]
	s_cbranch_vccz .LBB0_29
.LBB0_28:                               ; %.sink.split.i.1
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_cmp_lg_u32 s51, -1
	s_mul_i32 s10, s52, s47
	s_cselect_b32 m0, s51, 0
	s_nop 0
	buffer_load_dwordx4 v73, s[16:19], s10 offen lds
.LBB0_29:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.1
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s37
	s_add_i32 s10, s48, 0x100
	buffer_load_dwordx4 v68, s[24:27], s10 offen lds
	s_addk_i32 s50, 0x100
	s_mov_b32 m0, s36
	s_waitcnt lgkmcnt(12)
	v_and_b32_e32 v76, 0xffff, v76
	buffer_load_dwordx4 v68, s[24:27], s50 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(0)
	s_setprio 1
	ds_read_b128 v[86:89], v70 offset:50688
	ds_read_b128 v[90:93], v70 offset:50752
	v_mfma_scale_f32_16x16x128_f8f6f4 v[60:63], v[94:101], v[78:85], v[60:63], v77, v76 op_sel_hi:[0,0,0]
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[56:59], v[102:109], v[78:85], v[56:59], v77, v76 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[52:55], v[110:117], v[78:85], v[52:55], v77, v76 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[48:51], v[118:125], v[78:85], v[48:51], v77, v76 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[32:35], v[94:101], v[86:93], v[32:35], v77, v76 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[94:97], v74 offset:50688
	ds_read_b128 v[98:101], v74 offset:50752
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[28:31], v[102:109], v[86:93], v[28:31], v77, v76 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[102:105], v74 offset:59136
	ds_read_b128 v[106:109], v74 offset:59200
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[20:23], v[110:117], v[86:93], v[20:23], v77, v76 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[24:27], v[118:125], v[86:93], v[24:27], v77, v76 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[4:7], v[94:101], v[78:85], v[4:7], v75, v76 op_sel_hi:[0,0,0]
	v_add_u32_e32 v77, 0x4200, v74
	ds_read_b128 v[118:121], v77 offset:50688
	v_add_u32_e32 v77, 0x4240, v74
	ds_read_b128 v[122:125], v77 offset:50688
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[44:47], v[102:109], v[78:85], v[44:47], v75, v76 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	v_add_u32_e32 v77, 0x6300, v74
	ds_read_b128 v[110:113], v77 offset:50688
	v_add_u32_e32 v77, 0x6340, v74
	ds_read_b128 v[114:117], v77 offset:50688
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s49, s49, 3
	s_cmp_ge_i32 s49, s2
	s_cbranch_scc1 .LBB0_12
; %bb.30:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s40
	s_add_i32 s11, s48, 0x180
	buffer_load_dwordx4 v66, s[4:7], s11 offen lds
	s_add_i32 s11, s11, s39
	s_mov_b32 m0, s46
	s_nop 0
	buffer_load_dwordx4 v66, s[4:7], s11 offen lds
	; sched_barrier mask(0x00000000)
	s_branch .LBB0_12
.LBB0_31:
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v17, v16
	v_mov_b32_e32 v18, v16
	v_mov_b32_e32 v19, v16
	v_mov_b32_e32 v12, v16
	v_mov_b32_e32 v13, v16
	v_mov_b32_e32 v14, v16
	v_mov_b32_e32 v15, v16
	v_mov_b32_e32 v8, v16
	v_mov_b32_e32 v9, v16
	v_mov_b32_e32 v10, v16
	v_mov_b32_e32 v11, v16
	v_mov_b32_e32 v0, v16
	v_mov_b32_e32 v1, v16
	v_mov_b32_e32 v2, v16
	v_mov_b32_e32 v3, v16
	v_mov_b32_e32 v32, v16
	v_mov_b32_e32 v33, v16
	v_mov_b32_e32 v34, v16
	v_mov_b32_e32 v35, v16
	v_mov_b32_e32 v28, v16
	v_mov_b32_e32 v29, v16
	v_mov_b32_e32 v30, v16
	v_mov_b32_e32 v31, v16
	v_mov_b32_e32 v20, v16
	v_mov_b32_e32 v21, v16
	v_mov_b32_e32 v22, v16
	v_mov_b32_e32 v23, v16
	v_mov_b32_e32 v24, v16
	v_mov_b32_e32 v25, v16
	v_mov_b32_e32 v26, v16
	v_mov_b32_e32 v27, v16
	v_mov_b32_e32 v4, v16
	v_mov_b32_e32 v5, v16
	v_mov_b32_e32 v6, v16
	v_mov_b32_e32 v7, v16
	v_mov_b32_e32 v44, v16
	v_mov_b32_e32 v45, v16
	v_mov_b32_e32 v46, v16
	v_mov_b32_e32 v47, v16
	v_mov_b32_e32 v40, v16
	v_mov_b32_e32 v41, v16
	v_mov_b32_e32 v42, v16
	v_mov_b32_e32 v43, v16
	v_mov_b32_e32 v36, v16
	v_mov_b32_e32 v37, v16
	v_mov_b32_e32 v38, v16
	v_mov_b32_e32 v39, v16
	v_mov_b32_e32 v60, v16
	v_mov_b32_e32 v61, v16
	v_mov_b32_e32 v62, v16
	v_mov_b32_e32 v63, v16
	v_mov_b32_e32 v56, v16
	v_mov_b32_e32 v57, v16
	v_mov_b32_e32 v58, v16
	v_mov_b32_e32 v59, v16
	v_mov_b32_e32 v52, v16
	v_mov_b32_e32 v53, v16
	v_mov_b32_e32 v54, v16
	v_mov_b32_e32 v55, v16
	v_mov_b32_e32 v48, v16
	v_mov_b32_e32 v49, v16
	v_mov_b32_e32 v50, v16
	v_mov_b32_e32 v51, v16
	s_branch .LBB0_44
.LBB0_32:
	v_mov_b32_e32 v3, 0
	s_mov_b32 s16, 1
	v_mov_b32_e32 v2, v3
	v_mov_b32_e32 v1, v3
	v_mov_b32_e32 v0, v3
	v_mov_b32_e32 v11, v3
	v_mov_b32_e32 v10, v3
	v_mov_b32_e32 v9, v3
	v_mov_b32_e32 v8, v3
	v_mov_b32_e32 v15, v3
	v_mov_b32_e32 v14, v3
	v_mov_b32_e32 v13, v3
	v_mov_b32_e32 v12, v3
	v_mov_b32_e32 v19, v3
	v_mov_b32_e32 v18, v3
	v_mov_b32_e32 v17, v3
	v_mov_b32_e32 v16, v3
	v_mov_b32_e32 v27, v3
	v_mov_b32_e32 v26, v3
	v_mov_b32_e32 v25, v3
	v_mov_b32_e32 v24, v3
	v_mov_b32_e32 v23, v3
	v_mov_b32_e32 v22, v3
	v_mov_b32_e32 v21, v3
	v_mov_b32_e32 v20, v3
	v_mov_b32_e32 v31, v3
	v_mov_b32_e32 v30, v3
	v_mov_b32_e32 v29, v3
	v_mov_b32_e32 v28, v3
	v_mov_b32_e32 v35, v3
	v_mov_b32_e32 v34, v3
	v_mov_b32_e32 v33, v3
	v_mov_b32_e32 v32, v3
	v_mov_b32_e32 v39, v3
	v_mov_b32_e32 v38, v3
	v_mov_b32_e32 v37, v3
	v_mov_b32_e32 v36, v3
	v_mov_b32_e32 v43, v3
	v_mov_b32_e32 v42, v3
	v_mov_b32_e32 v41, v3
	v_mov_b32_e32 v40, v3
	v_mov_b32_e32 v47, v3
	v_mov_b32_e32 v46, v3
	v_mov_b32_e32 v45, v3
	v_mov_b32_e32 v44, v3
	v_mov_b32_e32 v7, v3
	v_mov_b32_e32 v6, v3
	v_mov_b32_e32 v5, v3
	v_mov_b32_e32 v4, v3
	v_mov_b32_e32 v51, v3
	v_mov_b32_e32 v50, v3
	v_mov_b32_e32 v49, v3
	v_mov_b32_e32 v48, v3
	v_mov_b32_e32 v55, v3
	v_mov_b32_e32 v54, v3
	v_mov_b32_e32 v53, v3
	v_mov_b32_e32 v52, v3
	v_mov_b32_e32 v59, v3
	v_mov_b32_e32 v58, v3
	v_mov_b32_e32 v57, v3
	v_mov_b32_e32 v56, v3
	v_mov_b32_e32 v63, v3
	v_mov_b32_e32 v62, v3
	v_mov_b32_e32 v61, v3
	v_mov_b32_e32 v60, v3
	s_mov_b32 s38, 0
	s_cbranch_execnz .LBB0_34
	s_branch .LBB0_44
.LBB0_33:                               ; %._crit_edge.loopexit.unr-lcssa
	s_add_i32 s16, s47, 1
	s_bitcmp1_b32 s43, 0
	s_cselect_b64 s[10:11], -1, 0
	s_and_b64 vcc, exec, s[10:11]
	s_cbranch_vccz .LBB0_44
.LBB0_34:                               ; %NodeBlock2370
	s_mov_b32 s17, 0x21000
	v_or_b32_e32 v75, 0x21000, v71
	v_add_u32_e32 v76, 0x21800, v72
	v_add_u32_e32 v78, 0x21a00, v67
	s_cmp_lt_i32 s42, 1
	s_mov_b64 s[10:11], -1
	s_cbranch_scc1 .LBB0_39
; %bb.35:                               ; %LeafBlock2368
	s_cmp_eq_u32 s42, 1
	s_cbranch_scc0 .LBB0_37
; %bb.36:
	s_mov_b32 s17, 0x21800
	s_branch .LBB0_38
.LBB0_37:
	s_mov_b64 s[10:11], 0
.LBB0_38:                               ; %Flow2417
	s_mov_b32 s8, s9
	s_mov_b64 s[20:21], s[28:29]
.LBB0_39:                               ; %Flow2416
	ds_read_u16 v77, v75
	ds_read_b32 v76, v76
	ds_read_b32 v75, v78
	ds_read_b128 v[78:81], v70
	ds_read_b128 v[82:85], v70 offset:64
	ds_read_b128 v[118:121], v74
	ds_read_b128 v[122:125], v74 offset:64
	ds_read_b128 v[110:113], v74 offset:8448
	ds_read_b128 v[114:117], v74 offset:8512
	ds_read_b128 v[94:97], v74 offset:16896
	ds_read_b128 v[98:101], v74 offset:16960
	ds_read_b128 v[102:105], v74 offset:25344
	ds_read_b128 v[106:109], v74 offset:25408
	s_and_b64 vcc, exec, s[10:11]
	s_cbranch_vccz .LBB0_41
; %bb.40:                               ; %.sink.split.i.epil
	s_cmp_lg_u32 s17, -1
	s_cselect_b32 s9, s17, 0
	s_mul_i32 s8, s8, s16
	s_add_i32 m0, s9, 0x400
	s_mov_b32 s22, s18
	s_mov_b32 s23, s19
	buffer_load_dwordx4 v73, s[20:23], s8 offen lds
.LBB0_41:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.epil
	s_lshl_b32 s8, s16, 7
	s_add_i32 m0, s37, 0x8400
	s_mov_b32 s26, s6
	s_mov_b32 s27, s7
	buffer_load_dwordx4 v68, s[24:27], s8 offen lds
	s_add_i32 s8, s16, s12
	s_lshl_b32 s8, s8, 7
	s_add_i32 m0, s36, 0x8400
	s_nop 0
	buffer_load_dwordx4 v68, s[24:27], s8 offen lds
	s_waitcnt lgkmcnt(12)
	v_and_b32_e32 v68, 0xffff, v77
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(0)
	s_setprio 1
	ds_read_b128 v[86:89], v70 offset:16896
	ds_read_b128 v[90:93], v70 offset:16960
	v_mfma_scale_f32_16x16x128_f8f6f4 v[60:63], v[118:125], v[78:85], v[60:63], v76, v68 op_sel_hi:[0,0,0]
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[56:59], v[110:117], v[78:85], v[56:59], v76, v68 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[52:55], v[94:101], v[78:85], v[52:55], v76, v68 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[48:51], v[102:109], v[78:85], v[48:51], v76, v68 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[32:35], v[118:125], v[86:93], v[32:35], v76, v68 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[118:121], v74 offset:33792
	ds_read_b128 v[122:125], v74 offset:33856
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[28:31], v[110:117], v[86:93], v[28:31], v76, v68 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[110:113], v74 offset:42240
	ds_read_b128 v[114:117], v74 offset:42304
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[20:23], v[94:101], v[86:93], v[20:23], v76, v68 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	ds_read_b128 v[94:97], v74 offset:25344
	ds_read_b128 v[98:101], v74 offset:25408
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[24:27], v[102:109], v[86:93], v[24:27], v76, v68 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	ds_read_b128 v[102:105], v74 offset:16896
	ds_read_b128 v[106:109], v74 offset:16960
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[4:7], v[102:109], v[78:85], v[4:7], v75, v68 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[44:47], v[94:101], v[78:85], v[44:47], v75, v68 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s8, s38, 2
	s_cmp_ge_i32 s8, s2
	s_cbranch_scc1 .LBB0_43
; %bb.42:
	s_mov_b32 m0, s31
	s_lshl_b32 s2, s8, 7
	s_add_i32 s8, s8, s13
	buffer_load_dwordx4 v66, s[4:7], s2 offen lds
	s_lshl_b32 s2, s8, 7
	s_mov_b32 m0, s33
	s_nop 0
	buffer_load_dwordx4 v66, s[4:7], s2 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_43:                               ; %._crit_edge.loopexit.epilog-lcssa
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[40:43], v[118:125], v[78:85], v[40:43], v75, v68 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[36:39], v[110:117], v[78:85], v[36:39], v75, v68 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[16:19], v[102:109], v[86:93], v[16:19], v75, v68 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[12:15], v[94:101], v[86:93], v[12:15], v75, v68 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[8:11], v[118:125], v[86:93], v[8:11], v75, v68 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[0:3], v[110:117], v[86:93], v[0:3], v75, v68 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_setprio 0
	s_mov_b32 s22, 1
.LBB0_44:                               ; %._crit_edge
	s_mul_i32 s2, s41, s3
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[2:3], s[2:3], 2
	s_add_u32 s4, s34, s2
	s_mul_i32 s2, s1, s14
	s_addc_u32 s5, s35, s3
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[2:3], s[2:3], 2
	s_add_u32 s2, s4, s2
	s_addc_u32 s3, s5, s3
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s2, s0
	s_addc_u32 s1, s3, s1
	s_lshl_b32 s2, s22, 10
	v_or_b32_e32 v66, s2, v71
	s_or_b32 s2, s2, 0x21800
	v_add_u32_e32 v68, s2, v72
	v_add_u32_e32 v67, s2, v67
	s_mul_i32 s2, s22, 0x8400
	v_add_u32_e32 v69, s2, v69
	v_or_b32_e32 v66, 0x21000, v66
	v_add_u32_e32 v74, s2, v70
	v_add_u32_e32 v69, 0x10800, v69
	ds_read_u16 v66, v66
	ds_read_b32 v68, v68
	ds_read_b32 v67, v67 offset:512
	ds_read_b128 v[78:81], v74
	ds_read_b128 v[82:85], v74 offset:64
	ds_read_b128 v[70:73], v74 offset:16896
	ds_read_b128 v[74:77], v74 offset:16960
	ds_read_b128 v[86:89], v69
	ds_read_b128 v[90:93], v69 offset:64
	ds_read_b128 v[94:97], v69 offset:8448
	ds_read_b128 v[98:101], v69 offset:8512
	ds_read_b128 v[102:105], v69 offset:16896
	ds_read_b128 v[106:109], v69 offset:16960
	ds_read_b128 v[110:113], v69 offset:25344
	ds_read_b128 v[114:117], v69 offset:25408
	s_and_b32 s1, s1, 0xffff
	s_mov_b32 s3, 0x20000
	s_mov_b32 s2, -1
	s_waitcnt lgkmcnt(0)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[60:63], v[86:93], v[78:85], v[60:63], v68, v66 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[56:59], v[94:101], v[78:85], v[56:59], v68, v66 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[52:55], v[102:109], v[78:85], v[52:55], v68, v66 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[48:51], v[110:117], v[78:85], v[48:51], v68, v66 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[32:35], v[86:93], v[70:77], v[32:35], v68, v66 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[86:89], v69 offset:16896
	ds_read_b128 v[90:93], v69 offset:16960
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[28:31], v[94:101], v[70:77], v[28:31], v68, v66 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[94:97], v69 offset:25344
	ds_read_b128 v[98:101], v69 offset:25408
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[20:23], v[102:109], v[70:77], v[20:23], v68, v66 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	ds_read_b128 v[102:105], v69 offset:33792
	ds_read_b128 v[106:109], v69 offset:33856
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[24:27], v[110:117], v[70:77], v[24:27], v68, v66 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	ds_read_b128 v[110:113], v69 offset:42240
	ds_read_b128 v[114:117], v69 offset:42304
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[4:7], v[86:93], v[78:85], v[4:7], v67, v66 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[44:47], v[94:101], v[78:85], v[44:47], v67, v66 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[40:43], v[102:109], v[78:85], v[40:43], v67, v66 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[36:39], v[110:117], v[78:85], v[36:39], v67, v66 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[16:19], v[86:93], v[70:77], v[16:19], v67, v66 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[12:15], v[94:101], v[70:77], v[12:15], v67, v66 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[8:11], v[102:109], v[70:77], v[8:11], v67, v66 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[0:3], v[110:117], v[70:77], v[0:3], v67, v66 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_setprio 0
	s_mul_i32 s4, s15, s14
	s_add_i32 s7, s4, s30
	v_mad_u64_u32 v[64:65], s[4:5], s14, v65, v[64:65]
	s_lshl_b32 s4, s7, 6
	s_lshl_b32 s6, s14, 9
	v_lshl_add_u32 v64, v64, 2, s4
	s_movk_i32 s4, 0x200
	buffer_store_dwordx4 v[60:63], v64, s[0:3], 0 offen nt
	buffer_store_dwordx4 v[56:59], v64, s[0:3], 0 offen offset:128 nt
	buffer_store_dwordx4 v[52:55], v64, s[0:3], 0 offen offset:256 nt
	buffer_store_dwordx4 v[48:51], v64, s[0:3], 0 offen offset:384 nt
	buffer_store_dwordx4 v[4:7], v64, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[44:47], v64, s[0:3], s4 offen offset:128 nt
	buffer_store_dwordx4 v[40:43], v64, s[0:3], s4 offen offset:256 nt
	buffer_store_dwordx4 v[36:39], v64, s[0:3], s4 offen offset:384 nt
	buffer_store_dwordx4 v[32:35], v64, s[0:3], s6 offen nt
	buffer_store_dwordx4 v[28:31], v64, s[0:3], s6 offen offset:128 nt
	buffer_store_dwordx4 v[20:23], v64, s[0:3], s6 offen offset:256 nt
	buffer_store_dwordx4 v[24:27], v64, s[0:3], s6 offen offset:384 nt
	s_addk_i32 s6, 0x200
	buffer_store_dwordx4 v[16:19], v64, s[0:3], s6 offen nt
	buffer_store_dwordx4 v[12:15], v64, s[0:3], s6 offen offset:128 nt
	buffer_store_dwordx4 v[8:11], v64, s[0:3], s6 offen offset:256 nt
	buffer_store_dwordx4 v[0:3], v64, s[0:3], s6 offen offset:384 nt
	s_endpgm
.Lfunc_end0:
	.size	_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs, .Lfunc_end0-_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
		.amdhsa_group_segment_fixed_size 139264
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 96
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 126
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 128
		.amdhsa_reserve_vcc 1
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_tg_split 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.section	.text._Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,"axG",@progbits,_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,comdat
                                        ; -- End function
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_vgpr, 126
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_agpr, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.numbered_sgpr, 53
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_named_barrier, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.private_seg_size, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_vcc, 1
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_flat_scratch, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_dyn_sized_stack, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_recursion, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 4760
; TotalNumSgprs: 59
; NumVgprs: 126
; NumAgprs: 0
; TotalNumVgprs: 126
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 139264 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 15
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 126
; AccumOffset: 128
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 31
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.section	.AMDGPU.csdata,"",@progbits
	.type	__hip_cuid_1a0edf958066cf5d,@object ; @__hip_cuid_1a0edf958066cf5d
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_1a0edf958066cf5d
__hip_cuid_1a0edf958066cf5d:
	.byte	0                               ; 0x0
	.size	__hip_cuid_1a0edf958066cf5d, 1

	.ident	"AMD clang version 23.0.0git (https://github.com/ROCm/llvm-project.git 46fcb339fb61119b337f973c7ca9e710a319fdd0+PATCHED:440716f8b87be9d8e20ed910e10e5b6d14d57cf6)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_1a0edf958066cf5d
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .offset:         0
        .size:           96
        .value_kind:     by_value
    .gfx1250_revision: B0
    .group_segment_fixed_size: 139264
    .kernarg_segment_align: 8
    .kernarg_segment_size: 96
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
    .private_segment_fixed_size: 0
    .sgpr_count:     59
    .sgpr_spill_count: 0
    .symbol:         _Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     126
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
