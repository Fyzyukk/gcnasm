	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.section	.text._Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,"axG",@progbits,_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,comdat
	.protected	_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs ; -- Begin function _Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
	.globl	_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
	.p2align	8
	.type	_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,@function
_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs: ; @_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
; %bb.0:
	s_load_dwordx8 s[4:11], s[0:1], 0x18
	s_load_dwordx4 s[20:23], s[0:1], 0x0
	s_load_dwordx2 s[24:25], s[0:1], 0x10
	s_load_dwordx2 s[26:27], s[0:1], 0x38
	s_load_dwordx8 s[12:19], s[0:1], 0x40
	s_waitcnt lgkmcnt(0)
	s_add_i32 s0, s4, 0xff
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 24
	s_add_i32 s0, s0, s1
	s_ashr_i32 s33, s0, 8
	s_add_i32 s0, s5, 0xff
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 24
	s_add_i32 s0, s0, s1
	s_ashr_i32 s34, s0, 8
	s_add_i32 s0, s34, 1
	s_lshr_b32 s1, s0, 31
	s_add_i32 s0, s0, s1
	s_ashr_i32 s0, s0, 1
	s_abs_i32 s1, s0
	v_cvt_f32_u32_e32 v1, s1
	s_sub_i32 s7, 0, s1
	s_add_i32 s4, s6, 0x7f
	s_ashr_i32 s5, s4, 31
	v_rcp_iflag_f32_e32 v1, v1
	s_abs_i32 s6, s2
	s_lshr_b32 s5, s5, 25
	s_add_i32 s5, s4, s5
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_ashr_i32 s35, s5, 7
	s_xor_b32 s5, s2, s0
	s_ashr_i32 s5, s5, 31
	v_readfirstlane_b32 s28, v1
	s_mul_i32 s7, s7, s28
	s_mul_hi_u32 s7, s28, s7
	s_add_i32 s28, s28, s7
	s_mul_hi_u32 s7, s6, s28
	s_mul_i32 s28, s7, s1
	s_sub_i32 s6, s6, s28
	s_add_i32 s28, s7, 1
	s_sub_i32 s29, s6, s1
	s_cmp_ge_u32 s6, s1
	s_cselect_b32 s7, s28, s7
	s_cselect_b32 s6, s29, s6
	s_add_i32 s28, s7, 1
	s_cmp_ge_u32 s6, s1
	s_cselect_b32 s1, s28, s7
	s_xor_b32 s1, s1, s5
	s_sub_i32 s1, s1, s5
	s_lshl_b32 s37, s1, 1
	s_mul_i32 s1, s1, s0
	s_sub_i32 s0, s2, s1
	s_lshl_b32 s38, s0, 1
	s_mul_i32 s0, s11, s3
	s_ashr_i32 s1, s0, 31
	s_add_u32 s11, s20, s0
	s_mul_i32 s0, s26, s3
	s_addc_u32 s39, s21, s1
	s_ashr_i32 s1, s0, 31
	s_add_u32 s40, s22, s0
	s_mul_i32 s0, s27, s3
	s_addc_u32 s41, s23, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s42, s24, s0
	s_mul_i32 s0, s18, s3
	s_addc_u32 s43, s25, s1
	s_ashr_i32 s1, s0, 31
	s_add_u32 s44, s12, s0
	s_mul_i32 s0, s19, s3
	s_addc_u32 s45, s13, s1
	s_ashr_i32 s1, s0, 31
	s_add_u32 s47, s14, s0
	s_addc_u32 s48, s15, s1
	s_lshl_b32 s50, s8, 7
	v_lshlrev_b32_e32 v3, 4, v0
	s_lshl_b32 s51, s9, 7
	v_and_b32_e32 v66, 0x70, v3
	v_and_b32_e32 v3, 3, v0
	s_movk_i32 s0, 0x420
	s_cmpk_lt_i32 s4, 0x100
	v_mad_u32_u24 v72, v3, s0, 64
	s_cselect_b64 s[18:19], -1, 0
	s_lshl_b32 s54, s10, 9
	s_max_i32 s0, s35, 2
	s_add_i32 s53, s51, 0x80
	s_add_i32 s56, s54, 0x200
	s_add_i32 s0, s0, -1
	s_cmpk_gt_i32 s4, 0x17f
	v_and_b32_e32 v2, 63, v0
	v_lshlrev_b32_e32 v5, 5, v0
	v_and_b32_e32 v75, 15, v0
	s_cselect_b64 s[28:29], -1, 0
	s_and_b32 s57, s0, -2
	v_lshrrev_b32_e32 v1, 1, v0
	v_bfe_u32 v4, v0, 4, 2
	v_mul_u32_u24_e32 v67, 0x420, v3
	v_and_b32_e32 v5, 0x180, v5
	v_and_b32_e32 v6, 48, v0
	v_lshlrev_b32_e32 v74, 4, v2
	v_lshlrev_b32_e32 v2, 3, v75
	s_bitcmp1_b32 s0, 0
	s_mov_b32 s36, 0
	s_mul_i32 s46, s16, s35
	s_mul_i32 s49, s17, s35
	v_and_b32_e32 v1, 28, v1
	v_add3_u32 v73, v67, v6, v5
	v_lshlrev_b32_e32 v76, 2, v4
	v_lshl_or_b32 v77, v4, 1, v2
	s_movk_i32 s52, 0x80
	s_movk_i32 s55, 0x200
	s_mov_b32 s2, -1
	v_or_b32_e32 v78, v6, v5
	s_cselect_b64 s[30:31], -1, 0
	s_mov_b32 s3, 0x20000
	s_branch .LBB0_2
.LBB0_1:                                ;   in Loop: Header=BB0_2 Depth=1
	s_add_i32 s36, s36, 1
	s_cmp_eq_u32 s36, 4
	s_cbranch_scc1 .LBB0_48
.LBB0_2:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_15 Depth 2
	s_lshr_b32 s4, s36, 1
	s_and_b32 s0, s36, 1
	s_add_i32 s4, s4, s37
	s_or_b32 s5, s0, s38
	s_cmp_lt_i32 s4, s33
	s_cselect_b64 s[0:1], -1, 0
	s_cmp_lt_i32 s5, s34
	s_cselect_b64 s[6:7], -1, 0
	s_and_b64 s[0:1], s[0:1], s[6:7]
	s_andn2_b64 vcc, exec, s[0:1]
	s_cbranch_vccnz .LBB0_1
; %bb.3:                                ;   in Loop: Header=BB0_2 Depth=1
	v_readfirstlane_b32 s59, v0
	s_mul_i32 s0, s46, s4
	s_lshr_b32 s62, s59, 6
	s_ashr_i32 s1, s0, 31
	s_add_u32 s20, s44, s0
	s_mul_i32 s0, s49, s5
	s_addc_u32 s6, s45, s1
	s_ashr_i32 s1, s0, 31
	s_add_u32 s24, s47, s0
	s_addc_u32 s0, s48, s1
	s_and_b32 s25, s0, 0xffff
	s_cmp_lt_i32 s62, 1
	s_mov_b64 s[0:1], -1
	s_cbranch_scc1 .LBB0_7
; %bb.4:                                ; %LeafBlock
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_cmp_eq_u32 s62, 1
	s_cbranch_scc0 .LBB0_6
; %bb.5:                                ;   in Loop: Header=BB0_2 Depth=1
	s_mov_b32 s26, s2
	s_mov_b32 s27, s3
	s_mov_b32 m0, 0x21800
	s_nop 0
	buffer_load_dwordx4 v74, s[24:27], 0 offen lds
.LBB0_6:                                ; %Flow2711
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_mov_b64 s[0:1], 0
.LBB0_7:                                ; %Flow2712
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_andn2_b64 vcc, exec, s[0:1]
	s_and_b32 s21, s6, 0xffff
	s_cbranch_vccnz .LBB0_9
; %bb.8:                                ;   in Loop: Header=BB0_2 Depth=1
	s_mov_b32 s22, s2
	s_mov_b32 s23, s3
	s_mov_b32 m0, 0x21000
	s_nop 0
	buffer_load_dwordx4 v74, s[20:23], 0 offen lds
.LBB0_9:                                ;   in Loop: Header=BB0_2 Depth=1
	s_lshl_b32 s27, s4, 8
	s_mul_i32 s0, s27, s8
	s_lshl_b32 s26, s5, 8
	s_ashr_i32 s1, s0, 31
	s_add_u32 s4, s11, s0
	s_addc_u32 s0, s39, s1
	s_and_b32 s5, s0, 0xffff
	s_mul_i32 s0, s26, s9
	s_ashr_i32 s1, s0, 31
	s_add_u32 s12, s40, s0
	s_addc_u32 s0, s41, s1
	s_lshr_b32 s59, s59, 8
	s_and_b32 s58, s62, 3
	v_lshl_or_b32 v2, s59, 5, v1
	v_or_b32_e32 v2, s58, v2
	s_and_b32 s13, s0, 0xffff
	v_mad_u64_u32 v[70:71], s[0:1], v2, s8, v[66:67]
	v_mad_u64_u32 v[68:69], s[0:1], v2, s9, v[66:67]
	s_mul_i32 s0, s59, 0x1080
	s_mul_i32 s64, s58, 0x420
	s_add_i32 s64, s64, s0
	s_mov_b32 s6, s2
	s_mov_b32 s7, s3
	s_mov_b32 m0, s64
	s_add_i32 s60, s64, 0x10800
	s_mov_b32 s14, s2
	s_mov_b32 s15, s3
	buffer_load_dwordx4 v70, s[4:7], 0 offen lds
	s_mov_b32 m0, s60
	s_add_i32 s63, s64, 0x4200
	buffer_load_dwordx4 v68, s[12:15], 0 offen lds
	s_mov_b32 m0, s63
	s_nop 0
	buffer_load_dwordx4 v70, s[4:7], s50 offen lds
	s_add_i32 m0, s60, 0x4200
	s_lshl_b32 s6, s59, 7
	buffer_load_dwordx4 v68, s[12:15], s51 offen lds
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b64 s[0:1], -1
	s_andn2_b64 vcc, exec, s[18:19]
	v_add_u32_e32 v69, s6, v77
	s_cbranch_vccnz .LBB0_11
; %bb.10:                               ; %.._crit_edge_crit_edge
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_mov_b64 s[0:1], 0
.LBB0_11:                               ; %Flow2710
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_lshl_or_b32 v2, s58, 9, v78
	v_lshl_or_b32 v3, v75, 4, v76
	v_add_u32_e32 v79, v2, v67
	v_lshl_add_u32 v71, s59, 9, v73
	v_lshl_or_b32 v80, s58, 8, v3
	s_andn2_b64 vcc, exec, s[0:1]
	v_or_b32_e32 v81, s6, v77
	s_cbranch_vccnz .LBB0_33
; %bb.12:                               ; %.lr.ph
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_add_i32 s23, s64, 0x18c00
	s_mov_b32 s14, s2
	s_mov_b32 s15, s3
	s_mov_b32 m0, s23
	s_mov_b32 s6, s2
	buffer_load_dwordx4 v68, s[12:15], s52 offen lds
	s_add_i32 m0, s64, 0x1ce00
	s_mov_b32 s7, s3
	buffer_load_dwordx4 v68, s[12:15], s53 offen lds
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v83, v2, v72
	s_add_i32 s61, s64, 0x14a00
	s_mov_b32 s15, 1
	s_mov_b32 s22, 0
	s_andn2_b64 vcc, exec, s[28:29]
	v_add_u32_e32 v84, 0x21800, v81
	v_add_u32_e32 v85, 0x21a00, v69
	v_add_u32_e32 v82, 0x10800, v71
	s_cbranch_vccnz .LBB0_34
; %bb.13:                               ; %.lr.ph.new
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_mov_b32_e32 v62, 0
	s_add_i32 s65, s64, 0x8400
	s_add_i32 s66, s63, 0x8400
	s_add_i32 s67, s61, 0x8400
	s_mov_b32 s0, 0
	v_add_u32_e32 v86, 0x21e00, v69
	s_mov_b32 s70, 0
	v_mov_b32_e32 v63, v62
	v_mov_b32_e32 v64, v62
	v_mov_b32_e32 v65, v62
	v_mov_b32_e32 v58, v62
	v_mov_b32_e32 v59, v62
	v_mov_b32_e32 v60, v62
	v_mov_b32_e32 v61, v62
	v_mov_b32_e32 v54, v62
	v_mov_b32_e32 v55, v62
	v_mov_b32_e32 v56, v62
	v_mov_b32_e32 v57, v62
	v_mov_b32_e32 v50, v62
	v_mov_b32_e32 v51, v62
	v_mov_b32_e32 v52, v62
	v_mov_b32_e32 v53, v62
	v_mov_b32_e32 v46, v62
	v_mov_b32_e32 v47, v62
	v_mov_b32_e32 v48, v62
	v_mov_b32_e32 v49, v62
	v_mov_b32_e32 v42, v62
	v_mov_b32_e32 v43, v62
	v_mov_b32_e32 v44, v62
	v_mov_b32_e32 v45, v62
	v_mov_b32_e32 v38, v62
	v_mov_b32_e32 v39, v62
	v_mov_b32_e32 v40, v62
	v_mov_b32_e32 v41, v62
	v_mov_b32_e32 v34, v62
	v_mov_b32_e32 v35, v62
	v_mov_b32_e32 v36, v62
	v_mov_b32_e32 v37, v62
	v_mov_b32_e32 v30, v62
	v_mov_b32_e32 v31, v62
	v_mov_b32_e32 v32, v62
	v_mov_b32_e32 v33, v62
	v_mov_b32_e32 v26, v62
	v_mov_b32_e32 v27, v62
	v_mov_b32_e32 v28, v62
	v_mov_b32_e32 v29, v62
	v_mov_b32_e32 v22, v62
	v_mov_b32_e32 v23, v62
	v_mov_b32_e32 v24, v62
	v_mov_b32_e32 v25, v62
	v_mov_b32_e32 v18, v62
	v_mov_b32_e32 v19, v62
	v_mov_b32_e32 v20, v62
	v_mov_b32_e32 v21, v62
	v_mov_b32_e32 v14, v62
	v_mov_b32_e32 v15, v62
	v_mov_b32_e32 v16, v62
	v_mov_b32_e32 v17, v62
	v_mov_b32_e32 v10, v62
	v_mov_b32_e32 v11, v62
	v_mov_b32_e32 v12, v62
	v_mov_b32_e32 v13, v62
	v_mov_b32_e32 v6, v62
	v_mov_b32_e32 v7, v62
	v_mov_b32_e32 v8, v62
	v_mov_b32_e32 v9, v62
	v_mov_b32_e32 v2, v62
	v_mov_b32_e32 v3, v62
	v_mov_b32_e32 v4, v62
	v_mov_b32_e32 v5, v62
	s_branch .LBB0_15
.LBB0_14:                               ;   in Loop: Header=BB0_15 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[114:121], v[98:105], v[14:17], v88, v87 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[106:113], v[98:105], v[10:13], v88, v87 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[114:121], v[90:97], v[6:9], v88, v87 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[106:113], v[90:97], v[2:5], v88, v87 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_setprio 0
	s_cmp_lg_u32 s57, s70
	s_cbranch_scc0 .LBB0_35
.LBB0_15:                               ; %NodeBlock2657
                                        ;   Parent Loop BB0_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_mov_b32 s69, s70
	s_mov_b32 s68, s0
	s_mov_b32 s70, 0x21000
	s_mov_b64 s[14:15], -1
	s_cmp_lt_i32 s62, 1
	s_mov_b32 s71, s16
	s_mov_b64 s[0:1], s[20:21]
	s_cbranch_scc1 .LBB0_20
; %bb.16:                               ; %LeafBlock2655
                                        ;   in Loop: Header=BB0_15 Depth=2
	s_cmp_eq_u32 s62, 1
	s_cbranch_scc0 .LBB0_18
; %bb.17:                               ;   in Loop: Header=BB0_15 Depth=2
	s_mov_b32 s70, 0x21800
	s_branch .LBB0_19
.LBB0_18:                               ;   in Loop: Header=BB0_15 Depth=2
	s_mov_b64 s[14:15], 0
.LBB0_19:                               ; %Flow2705
                                        ;   in Loop: Header=BB0_15 Depth=2
	s_mov_b32 s71, s17
	s_mov_b64 s[0:1], s[24:25]
.LBB0_20:                               ; %Flow2704
                                        ;   in Loop: Header=BB0_15 Depth=2
	v_or_b32_e32 v87, 0x21000, v80
	ds_read_b128 v[100:103], v79
	ds_read_b128 v[104:107], v79 offset:64
	ds_read_b128 v[92:95], v79 offset:4224
	ds_read_b128 v[96:99], v83 offset:4224
	ds_read_b32 v87, v87
	ds_read_u16 v88, v84
	ds_read_u16 v90, v85
	ds_read_b128 v[116:119], v82
	ds_read_b128 v[120:123], v82 offset:64
	ds_read_b128 v[108:111], v82 offset:4224
	ds_read_b128 v[112:115], v82 offset:4288
	s_and_b64 vcc, exec, s[14:15]
	s_cbranch_vccz .LBB0_22
; %bb.21:                               ; %.sink.split.i
                                        ;   in Loop: Header=BB0_15 Depth=2
	s_add_i32 s14, s69, 1
	s_cmp_lg_u32 s70, -1
	s_cselect_b32 s15, s70, 0
	s_mul_i32 s14, s71, s14
	s_add_i32 m0, s15, 0x400
	s_nop 0
	buffer_load_dwordx4 v74, s[0:3], s14 offen lds
.LBB0_22:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit
                                        ;   in Loop: Header=BB0_15 Depth=2
	s_mov_b32 m0, s65
	s_add_i32 s0, s68, 0x80
	s_add_i32 s71, s50, s68
	buffer_load_dwordx4 v70, s[4:7], s0 offen lds
	s_add_i32 s0, s71, 0x80
	s_mov_b32 m0, s66
	s_waitcnt lgkmcnt(5)
	v_and_b32_e32 v89, 0xffff, v88
	buffer_load_dwordx4 v70, s[4:7], s0 offen lds
	s_waitcnt lgkmcnt(4)
	v_and_b32_e32 v88, 0xffff, v90
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(0)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[116:123], v[100:107], v[62:65], v89, v87 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[108:115], v[100:107], v[58:61], v89, v87 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[116:123], v[92:99], v[54:57], v89, v87 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[116:119], v82 offset:21120
	ds_read_b128 v[120:123], v82 offset:21184
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[108:115], v[92:99], v[50:53], v89, v87 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[108:111], v82 offset:16896
	ds_read_b128 v[112:115], v82 offset:16960
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[108:115], v[100:107], v[46:49], v88, v87 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[116:123], v[100:107], v[42:45], v88, v87 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[102:105], v79 offset:16960
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[108:115], v[92:99], v[38:41], v88, v87 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[106:109], v82 offset:4224
	ds_read_b128 v[110:113], v82 offset:4288
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[116:123], v[92:99], v[34:37], v88, v87 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[114:117], v82
	ds_read_b128 v[118:121], v82 offset:64
	ds_read_b128 v[98:101], v79 offset:16896
	ds_read_b128 v[90:93], v79 offset:21120
	ds_read_b128 v[94:97], v83 offset:21120
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[114:121], v[98:105], v[30:33], v89, v87 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[106:113], v[98:105], v[26:29], v89, v87 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[114:121], v[90:97], v[22:25], v89, v87 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	ds_read_b128 v[114:117], v82 offset:16896
	ds_read_b128 v[118:121], v82 offset:16960
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[106:113], v[90:97], v[18:21], v89, v87 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	ds_read_b128 v[106:109], v82 offset:21120
	ds_read_b128 v[110:113], v82 offset:21184
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	s_setprio 0
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s70, s69, 2
	s_cmp_ge_i32 s70, s35
	s_cbranch_scc1 .LBB0_24
; %bb.23:                               ;   in Loop: Header=BB0_15 Depth=2
	s_mov_b32 m0, s60
	s_add_i32 s0, s68, 0x100
	s_mov_b32 s14, s6
	s_mov_b32 s15, s7
	buffer_load_dwordx4 v68, s[12:15], s0 offen lds
	s_add_i32 s0, s0, s51
	s_mov_b32 m0, s61
	s_nop 0
	buffer_load_dwordx4 v68, s[12:15], s0 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_24:                               ;   in Loop: Header=BB0_15 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[114:121], v[98:105], v[14:17], v88, v87 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[106:113], v[98:105], v[10:13], v88, v87 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[114:121], v[90:97], v[6:9], v88, v87 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[106:113], v[90:97], v[2:5], v88, v87 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_setprio 0
	v_or_b32_e32 v87, 0x21400, v80
	v_add_u32_e32 v89, 0x21c00, v81
	ds_read_b128 v[98:101], v79 offset:33792
	ds_read_b128 v[102:105], v79 offset:33856
	ds_read_b128 v[90:93], v79 offset:38016
	ds_read_b128 v[94:97], v83 offset:38016
	ds_read_u16 v88, v86
	ds_read_b128 v[114:117], v82 offset:33792
	ds_read_b128 v[118:121], v82 offset:33856
	ds_read_b128 v[106:109], v82 offset:38016
	ds_read_b32 v87, v87
	ds_read_u16 v89, v89
	ds_read_b128 v[110:113], v82 offset:38080
	s_cmp_lt_i32 s62, 1
	s_cbranch_scc1 .LBB0_27
; %bb.25:                               ; %LeafBlock2659
                                        ;   in Loop: Header=BB0_15 Depth=2
	s_cmp_eq_u32 s62, 1
	s_cbranch_scc0 .LBB0_28
; %bb.26:                               ;   in Loop: Header=BB0_15 Depth=2
	s_mov_b64 s[14:15], -1
	s_mov_b32 s72, 0x21800
	s_branch .LBB0_29
.LBB0_27:                               ;   in Loop: Header=BB0_15 Depth=2
	s_mov_b32 s72, 0x21000
	s_mov_b32 s73, s16
	s_mov_b64 s[0:1], s[20:21]
	s_cbranch_execnz .LBB0_30
	s_branch .LBB0_31
.LBB0_28:                               ;   in Loop: Header=BB0_15 Depth=2
	s_mov_b64 s[14:15], 0
	s_mov_b32 s72, 0x21000
.LBB0_29:                               ; %Flow2703
                                        ;   in Loop: Header=BB0_15 Depth=2
	s_mov_b32 s73, s17
	s_mov_b64 s[0:1], s[24:25]
	s_and_b64 vcc, exec, s[14:15]
	s_cbranch_vccz .LBB0_31
.LBB0_30:                               ; %.sink.split.i.1
                                        ;   in Loop: Header=BB0_15 Depth=2
	s_cmp_lg_u32 s72, -1
	s_mul_i32 s14, s73, s70
	s_cselect_b32 m0, s72, 0
	s_nop 0
	buffer_load_dwordx4 v74, s[0:3], s14 offen lds
.LBB0_31:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.1
                                        ;   in Loop: Header=BB0_15 Depth=2
	s_mov_b32 m0, s64
	s_add_i32 s0, s68, 0x100
	buffer_load_dwordx4 v70, s[4:7], s0 offen lds
	s_addk_i32 s71, 0x100
	s_mov_b32 m0, s63
	s_waitcnt lgkmcnt(6)
	v_and_b32_e32 v88, 0xffff, v88
	buffer_load_dwordx4 v70, s[4:7], s71 offen lds
	s_waitcnt lgkmcnt(1)
	v_and_b32_e32 v89, 0xffff, v89
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(0)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[114:121], v[98:105], v[62:65], v89, v87 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[106:113], v[98:105], v[58:61], v89, v87 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[114:121], v[90:97], v[54:57], v89, v87 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[114:117], v82 offset:54912
	ds_read_b128 v[118:121], v82 offset:54976
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[106:113], v[90:97], v[50:53], v89, v87 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[106:109], v82 offset:50688
	ds_read_b128 v[110:113], v82 offset:50752
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[106:113], v[98:105], v[46:49], v88, v87 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[114:121], v[98:105], v[42:45], v88, v87 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[98:101], v79 offset:50688
	ds_read_b128 v[102:105], v79 offset:50752
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[106:113], v[90:97], v[38:41], v88, v87 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[106:109], v82 offset:38016
	ds_read_b128 v[110:113], v82 offset:38080
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[114:121], v[90:97], v[34:37], v88, v87 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[114:117], v82 offset:33792
	ds_read_b128 v[118:121], v82 offset:33856
	ds_read_b128 v[90:93], v79 offset:54912
	ds_read_b128 v[94:97], v83 offset:54912
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[114:121], v[98:105], v[30:33], v89, v87 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[106:113], v[98:105], v[26:29], v89, v87 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[114:121], v[90:97], v[22:25], v89, v87 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	ds_read_b128 v[114:117], v82 offset:50688
	ds_read_b128 v[118:121], v82 offset:50752
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[106:113], v[90:97], v[18:21], v89, v87 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	ds_read_b128 v[106:109], v82 offset:54912
	ds_read_b128 v[110:113], v82 offset:54976
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	s_setprio 0
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s69, s69, 3
	s_cmp_ge_i32 s69, s35
	s_cbranch_scc1 .LBB0_14
; %bb.32:                               ;   in Loop: Header=BB0_15 Depth=2
	s_mov_b32 m0, s23
	s_add_i32 s1, s68, 0x180
	s_mov_b32 s14, s6
	s_mov_b32 s15, s7
	buffer_load_dwordx4 v68, s[12:15], s1 offen lds
	s_add_i32 s1, s1, s51
	s_mov_b32 m0, s67
	s_nop 0
	buffer_load_dwordx4 v68, s[12:15], s1 offen lds
	; sched_barrier mask(0x00000000)
	s_branch .LBB0_14
.LBB0_33:                               ;   in Loop: Header=BB0_2 Depth=1
	v_mov_b32_e32 v14, 0
	s_mov_b32 s22, 0
	v_mov_b32_e32 v15, v14
	v_mov_b32_e32 v16, v14
	v_mov_b32_e32 v17, v14
	v_mov_b32_e32 v10, v14
	v_mov_b32_e32 v11, v14
	v_mov_b32_e32 v12, v14
	v_mov_b32_e32 v13, v14
	v_mov_b32_e32 v6, v14
	v_mov_b32_e32 v7, v14
	v_mov_b32_e32 v8, v14
	v_mov_b32_e32 v9, v14
	v_mov_b32_e32 v2, v14
	v_mov_b32_e32 v3, v14
	v_mov_b32_e32 v4, v14
	v_mov_b32_e32 v5, v14
	v_mov_b32_e32 v30, v14
	v_mov_b32_e32 v31, v14
	v_mov_b32_e32 v32, v14
	v_mov_b32_e32 v33, v14
	v_mov_b32_e32 v26, v14
	v_mov_b32_e32 v27, v14
	v_mov_b32_e32 v28, v14
	v_mov_b32_e32 v29, v14
	v_mov_b32_e32 v22, v14
	v_mov_b32_e32 v23, v14
	v_mov_b32_e32 v24, v14
	v_mov_b32_e32 v25, v14
	v_mov_b32_e32 v18, v14
	v_mov_b32_e32 v19, v14
	v_mov_b32_e32 v20, v14
	v_mov_b32_e32 v21, v14
	v_mov_b32_e32 v46, v14
	v_mov_b32_e32 v47, v14
	v_mov_b32_e32 v48, v14
	v_mov_b32_e32 v49, v14
	v_mov_b32_e32 v42, v14
	v_mov_b32_e32 v43, v14
	v_mov_b32_e32 v44, v14
	v_mov_b32_e32 v45, v14
	v_mov_b32_e32 v38, v14
	v_mov_b32_e32 v39, v14
	v_mov_b32_e32 v40, v14
	v_mov_b32_e32 v41, v14
	v_mov_b32_e32 v34, v14
	v_mov_b32_e32 v35, v14
	v_mov_b32_e32 v36, v14
	v_mov_b32_e32 v37, v14
	v_mov_b32_e32 v62, v14
	v_mov_b32_e32 v63, v14
	v_mov_b32_e32 v64, v14
	v_mov_b32_e32 v65, v14
	v_mov_b32_e32 v58, v14
	v_mov_b32_e32 v59, v14
	v_mov_b32_e32 v60, v14
	v_mov_b32_e32 v61, v14
	v_mov_b32_e32 v54, v14
	v_mov_b32_e32 v55, v14
	v_mov_b32_e32 v56, v14
	v_mov_b32_e32 v57, v14
	v_mov_b32_e32 v50, v14
	v_mov_b32_e32 v51, v14
	v_mov_b32_e32 v52, v14
	v_mov_b32_e32 v53, v14
	s_branch .LBB0_46
.LBB0_34:                               ;   in Loop: Header=BB0_2 Depth=1
	v_mov_b32_e32 v5, 0
	v_mov_b32_e32 v4, v5
	v_mov_b32_e32 v3, v5
	v_mov_b32_e32 v2, v5
	v_mov_b32_e32 v9, v5
	v_mov_b32_e32 v8, v5
	v_mov_b32_e32 v7, v5
	v_mov_b32_e32 v6, v5
	v_mov_b32_e32 v13, v5
	v_mov_b32_e32 v12, v5
	v_mov_b32_e32 v11, v5
	v_mov_b32_e32 v10, v5
	v_mov_b32_e32 v17, v5
	v_mov_b32_e32 v16, v5
	v_mov_b32_e32 v15, v5
	v_mov_b32_e32 v14, v5
	v_mov_b32_e32 v21, v5
	v_mov_b32_e32 v20, v5
	v_mov_b32_e32 v19, v5
	v_mov_b32_e32 v18, v5
	v_mov_b32_e32 v25, v5
	v_mov_b32_e32 v24, v5
	v_mov_b32_e32 v23, v5
	v_mov_b32_e32 v22, v5
	v_mov_b32_e32 v29, v5
	v_mov_b32_e32 v28, v5
	v_mov_b32_e32 v27, v5
	v_mov_b32_e32 v26, v5
	v_mov_b32_e32 v33, v5
	v_mov_b32_e32 v32, v5
	v_mov_b32_e32 v31, v5
	v_mov_b32_e32 v30, v5
	v_mov_b32_e32 v37, v5
	v_mov_b32_e32 v36, v5
	v_mov_b32_e32 v35, v5
	v_mov_b32_e32 v34, v5
	v_mov_b32_e32 v41, v5
	v_mov_b32_e32 v40, v5
	v_mov_b32_e32 v39, v5
	v_mov_b32_e32 v38, v5
	v_mov_b32_e32 v45, v5
	v_mov_b32_e32 v44, v5
	v_mov_b32_e32 v43, v5
	v_mov_b32_e32 v42, v5
	v_mov_b32_e32 v49, v5
	v_mov_b32_e32 v48, v5
	v_mov_b32_e32 v47, v5
	v_mov_b32_e32 v46, v5
	v_mov_b32_e32 v53, v5
	v_mov_b32_e32 v52, v5
	v_mov_b32_e32 v51, v5
	v_mov_b32_e32 v50, v5
	v_mov_b32_e32 v57, v5
	v_mov_b32_e32 v56, v5
	v_mov_b32_e32 v55, v5
	v_mov_b32_e32 v54, v5
	v_mov_b32_e32 v61, v5
	v_mov_b32_e32 v60, v5
	v_mov_b32_e32 v59, v5
	v_mov_b32_e32 v58, v5
	v_mov_b32_e32 v65, v5
	v_mov_b32_e32 v64, v5
	v_mov_b32_e32 v63, v5
	v_mov_b32_e32 v62, v5
	s_mov_b32 s14, 0
	s_cbranch_execnz .LBB0_36
	s_branch .LBB0_46
.LBB0_35:                               ; %._crit_edge.loopexit.unr-lcssa
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_add_i32 s15, s70, 1
	s_mov_b32 s14, s57
	s_mov_b64 s[0:1], s[30:31]
	s_and_b64 vcc, exec, s[0:1]
	s_cbranch_vccz .LBB0_46
.LBB0_36:                               ; %NodeBlock2665
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_mov_b32 s22, 0x21000
	s_mov_b64 s[0:1], -1
	s_cmp_lt_i32 s62, 1
	s_mov_b32 s23, s16
	s_cbranch_scc1 .LBB0_41
; %bb.37:                               ; %LeafBlock2663
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_cmp_eq_u32 s62, 1
	s_cbranch_scc0 .LBB0_39
; %bb.38:                               ;   in Loop: Header=BB0_2 Depth=1
	s_mov_b32 s22, 0x21800
	s_branch .LBB0_40
.LBB0_39:                               ;   in Loop: Header=BB0_2 Depth=1
	s_mov_b64 s[0:1], 0
.LBB0_40:                               ; %Flow2707
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_mov_b32 s23, s17
	s_mov_b64 s[20:21], s[24:25]
.LBB0_41:                               ; %Flow2706
                                        ;   in Loop: Header=BB0_2 Depth=1
	v_or_b32_e32 v86, 0x21000, v80
	ds_read_b128 v[96:99], v79
	ds_read_b128 v[100:103], v79 offset:64
	ds_read_b128 v[88:91], v79 offset:4224
	ds_read_b128 v[92:95], v83 offset:4224
	ds_read_b32 v86, v86
	ds_read_u16 v84, v84
	ds_read_u16 v85, v85
	ds_read_b128 v[112:115], v82
	ds_read_b128 v[116:119], v82 offset:64
	ds_read_b128 v[104:107], v82 offset:4224
	ds_read_b128 v[108:111], v82 offset:4288
	s_and_b64 vcc, exec, s[0:1]
	s_cbranch_vccz .LBB0_43
; %bb.42:                               ; %.sink.split.i.epil
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_cmp_lg_u32 s22, -1
	s_cselect_b32 s1, s22, 0
	s_mul_i32 s0, s23, s15
	s_add_i32 m0, s1, 0x400
	s_mov_b32 s22, s2
	s_mov_b32 s23, s3
	buffer_load_dwordx4 v74, s[20:23], s0 offen lds
.LBB0_43:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.epil
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_lshl_b32 s0, s15, 7
	s_add_i32 m0, s64, 0x8400
	s_waitcnt lgkmcnt(5)
	v_and_b32_e32 v84, 0xffff, v84
	buffer_load_dwordx4 v70, s[4:7], s0 offen lds
	s_add_i32 s0, s15, s8
	s_lshl_b32 s0, s0, 7
	s_add_i32 m0, s63, 0x8400
	s_nop 0
	buffer_load_dwordx4 v70, s[4:7], s0 offen lds
	s_waitcnt lgkmcnt(4)
	v_and_b32_e32 v70, 0xffff, v85
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(0)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[112:119], v[96:103], v[62:65], v84, v86 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[104:111], v[96:103], v[58:61], v84, v86 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[112:119], v[88:95], v[54:57], v84, v86 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[112:115], v82 offset:21120
	ds_read_b128 v[116:119], v82 offset:21184
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[104:111], v[88:95], v[50:53], v84, v86 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[104:107], v82 offset:16896
	ds_read_b128 v[108:111], v82 offset:16960
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[104:111], v[96:103], v[46:49], v70, v86 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[112:119], v[96:103], v[42:45], v70, v86 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[96:99], v79 offset:16896
	ds_read_b128 v[100:103], v79 offset:16960
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[104:111], v[88:95], v[38:41], v70, v86 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[104:107], v82 offset:4224
	ds_read_b128 v[108:111], v82 offset:4288
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[112:119], v[88:95], v[34:37], v70, v86 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[112:115], v82
	ds_read_b128 v[116:119], v82 offset:64
	ds_read_b128 v[88:91], v79 offset:21120
	ds_read_b128 v[92:95], v83 offset:21120
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[112:119], v[96:103], v[30:33], v84, v86 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[104:111], v[96:103], v[26:29], v84, v86 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[112:119], v[88:95], v[22:25], v84, v86 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	ds_read_b128 v[112:115], v82 offset:16896
	ds_read_b128 v[116:119], v82 offset:16960
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[104:111], v[88:95], v[18:21], v84, v86 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	ds_read_b128 v[104:107], v82 offset:21120
	ds_read_b128 v[108:111], v82 offset:21184
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	s_setprio 0
	s_waitcnt vmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s0, s14, 2
	s_cmp_ge_i32 s0, s35
	s_cbranch_scc1 .LBB0_45
; %bb.44:                               ;   in Loop: Header=BB0_2 Depth=1
	s_mov_b32 m0, s60
	s_lshl_b32 s1, s0, 7
	s_mov_b32 s14, s6
	s_mov_b32 s15, s7
	s_add_i32 s0, s0, s9
	buffer_load_dwordx4 v68, s[12:15], s1 offen lds
	s_lshl_b32 s0, s0, 7
	s_mov_b32 m0, s61
	s_nop 0
	buffer_load_dwordx4 v68, s[12:15], s0 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_45:                               ; %._crit_edge.loopexit.epilog-lcssa
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[112:119], v[96:103], v[14:17], v70, v86 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[104:111], v[96:103], v[10:13], v70, v86 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[112:119], v[88:95], v[6:9], v70, v86 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[104:111], v[88:95], v[2:5], v70, v86 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_setprio 0
	s_mov_b32 s22, 1
.LBB0_46:                               ; %._crit_edge
                                        ;   in Loop: Header=BB0_2 Depth=1
	s_mul_i32 s0, s27, s10
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s4, s42, s0
	s_addc_u32 s5, s43, s1
	s_ashr_i32 s27, s26, 31
	s_lshl_b64 s[0:1], s[26:27], 2
	s_add_u32 s0, s4, s0
	s_addc_u32 s1, s5, s1
	s_lshl_b32 s4, s22, 10
	v_or_b32_e32 v68, s4, v80
	s_or_b32 s4, s4, 0x21800
	v_add_u32_e32 v70, s4, v81
	v_add_u32_e32 v69, s4, v69
	s_mul_i32 s4, s22, 0x8400
	v_add_u32_e32 v71, s4, v71
	v_or_b32_e32 v68, 0x21000, v68
	v_add_u32_e32 v79, s4, v79
	v_add_u32_e32 v71, 0x10800, v71
	ds_read_b32 v68, v68
	ds_read_u16 v70, v70
	ds_read_u16 v69, v69 offset:512
	ds_read_b128 v[88:91], v79
	ds_read_b128 v[92:95], v79 offset:64
	ds_read_b128 v[80:83], v79 offset:4224
	ds_read_b128 v[84:87], v79 offset:4288
	ds_read_b128 v[96:99], v71
	ds_read_b128 v[100:103], v71 offset:64
	ds_read_b128 v[104:107], v71 offset:4224
	ds_read_b128 v[108:111], v71 offset:4288
	s_and_b32 s1, s1, 0xffff
	s_waitcnt lgkmcnt(0)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[96:103], v[88:95], v[62:65], v70, v68 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[104:111], v[88:95], v[58:61], v70, v68 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[96:103], v[80:87], v[54:57], v70, v68 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[96:99], v71 offset:16896
	ds_read_b128 v[100:103], v71 offset:16960
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[104:111], v[80:87], v[50:53], v70, v68 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[104:107], v71 offset:21120
	ds_read_b128 v[108:111], v71 offset:21184
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[96:103], v[88:95], v[46:49], v69, v68 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[104:111], v[88:95], v[42:45], v69, v68 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[88:91], v71
	ds_read_b128 v[92:95], v71 offset:64
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[96:103], v[80:87], v[38:41], v69, v68 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[96:99], v79 offset:16896
	ds_read_b128 v[100:103], v79 offset:16960
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[104:111], v[80:87], v[34:37], v69, v68 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	ds_read_b128 v[104:107], v71 offset:4224
	ds_read_b128 v[108:111], v71 offset:4288
	ds_read_b128 v[80:83], v79 offset:21120
	ds_read_b128 v[84:87], v79 offset:21184
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[88:95], v[96:103], v[30:33], v70, v68 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[104:111], v[96:103], v[26:29], v70, v68 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[88:95], v[80:87], v[22:25], v70, v68 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	ds_read_b128 v[88:91], v71 offset:16896
	ds_read_b128 v[92:95], v71 offset:16960
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[104:111], v[80:87], v[18:21], v70, v68 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	ds_read_b128 v[104:107], v71 offset:21120
	ds_read_b128 v[108:111], v71 offset:21184
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[88:95], v[96:103], v[14:17], v69, v68 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[104:111], v[96:103], v[10:13], v69, v68 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[88:95], v[80:87], v[6:9], v69, v68 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[104:111], v[80:87], v[2:5], v69, v68 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_setprio 0
	v_lshl_or_b32 v69, s58, 4, v75
	v_lshl_or_b32 v68, s59, 4, v76
	v_mul_lo_u32 v70, v69, s10
	v_add_u32_e32 v71, 64, v68
	v_or_b32_e32 v69, 64, v69
	v_add_lshl_u32 v79, v70, v68, 2
	v_mul_lo_u32 v69, v69, s10
	buffer_store_dwordx4 v[62:65], v79, s[0:3], 0 offen nt
	s_cmp_eq_u32 s36, 3
	s_nop 0
	v_add_lshl_u32 v62, v70, v71, 2
	buffer_store_dwordx4 v[58:61], v62, s[0:3], 0 offen nt
	s_nop 1
	v_add_lshl_u32 v58, v69, v68, 2
	buffer_store_dwordx4 v[54:57], v58, s[0:3], 0 offen nt
	s_nop 1
	v_add_lshl_u32 v54, v69, v71, 2
	buffer_store_dwordx4 v[50:53], v54, s[0:3], 0 offen nt
	buffer_store_dwordx4 v[46:49], v79, s[0:3], s55 offen nt
	buffer_store_dwordx4 v[42:45], v62, s[0:3], s55 offen nt
	buffer_store_dwordx4 v[38:41], v58, s[0:3], s55 offen nt
	buffer_store_dwordx4 v[34:37], v54, s[0:3], s55 offen nt
	buffer_store_dwordx4 v[30:33], v79, s[0:3], s54 offen nt
	buffer_store_dwordx4 v[26:29], v62, s[0:3], s54 offen nt
	buffer_store_dwordx4 v[22:25], v58, s[0:3], s54 offen nt
	buffer_store_dwordx4 v[18:21], v54, s[0:3], s54 offen nt
	buffer_store_dwordx4 v[14:17], v79, s[0:3], s56 offen nt
	buffer_store_dwordx4 v[10:13], v62, s[0:3], s56 offen nt
	buffer_store_dwordx4 v[6:9], v58, s[0:3], s56 offen nt
	buffer_store_dwordx4 v[2:5], v54, s[0:3], s56 offen nt
	s_cbranch_scc1 .LBB0_1
; %bb.47:                               ;   in Loop: Header=BB0_2 Depth=1
	s_barrier
	s_branch .LBB0_1
.LBB0_48:
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
		.amdhsa_next_free_vgpr 124
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 124
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
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_vgpr, 124
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_agpr, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.numbered_sgpr, 74
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_named_barrier, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.private_seg_size, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_vcc, 1
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_flat_scratch, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_dyn_sized_stack, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_recursion, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 5096
; TotalNumSgprs: 80
; NumVgprs: 124
; NumAgprs: 0
; TotalNumVgprs: 124
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 139264 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 15
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 124
; AccumOffset: 124
; Occupancy: 4
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 30
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.section	.AMDGPU.csdata,"",@progbits
	.type	__hip_cuid_ac43dc1b2c1cda27,@object ; @__hip_cuid_ac43dc1b2c1cda27
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_ac43dc1b2c1cda27
__hip_cuid_ac43dc1b2c1cda27:
	.byte	0                               ; 0x0
	.size	__hip_cuid_ac43dc1b2c1cda27, 1

	.ident	"AMD clang version 23.0.0git (https://github.com/ROCm/llvm-project.git 46fcb339fb61119b337f973c7ca9e710a319fdd0+PATCHED:440716f8b87be9d8e20ed910e10e5b6d14d57cf6)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_ac43dc1b2c1cda27
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
    .sgpr_count:     80
    .sgpr_spill_count: 0
    .symbol:         _Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     124
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
