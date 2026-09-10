	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.section	.text._Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,"axG",@progbits,_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,comdat
	.protected	_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs ; -- Begin function _Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
	.globl	_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
	.p2align	8
	.type	_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,@function
_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs: ; @_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
; %bb.0:
	s_load_dwordx8 s[4:11], s[0:1], 0x18
	s_load_dwordx4 s[16:19], s[0:1], 0x0
	s_load_dwordx2 s[20:21], s[0:1], 0x10
	s_load_dwordx2 s[22:23], s[0:1], 0x38
	s_load_dwordx4 s[12:15], s[0:1], 0x40
	s_waitcnt lgkmcnt(0)
	s_add_i32 s0, s4, 0xff
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 24
	s_add_i32 s0, s0, s1
	s_ashr_i32 s28, s0, 8
	s_add_i32 s0, s5, 0xff
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 24
	s_add_i32 s0, s0, s1
	s_ashr_i32 s0, s0, 8
	s_abs_i32 s1, s0
	v_cvt_f32_u32_e32 v1, s1
	s_sub_i32 s7, 0, s1
	s_addk_i32 s6, 0x7f
	s_ashr_i32 s4, s6, 31
	v_rcp_iflag_f32_e32 v1, v1
	s_abs_i32 s5, s2
	s_lshr_b32 s4, s4, 25
	s_add_i32 s4, s6, s4
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_ashr_i32 s29, s4, 7
	s_xor_b32 s4, s2, s0
	s_ashr_i32 s4, s4, 31
	v_readfirstlane_b32 s24, v1
	s_mul_i32 s7, s7, s24
	s_mul_hi_u32 s7, s24, s7
	s_add_i32 s24, s24, s7
	s_mul_hi_u32 s7, s5, s24
	s_mul_i32 s24, s7, s1
	s_sub_i32 s5, s5, s24
	s_add_i32 s24, s7, 1
	s_sub_i32 s25, s5, s1
	s_cmp_ge_u32 s5, s1
	s_cselect_b32 s7, s24, s7
	s_cselect_b32 s5, s25, s5
	s_add_i32 s24, s7, 1
	s_cmp_ge_u32 s5, s1
	s_cselect_b32 s1, s24, s7
	s_xor_b32 s1, s1, s4
	s_sub_i32 s1, s1, s4
	s_mul_i32 s0, s1, s0
	s_sub_i32 s0, s2, s0
	v_readfirstlane_b32 s27, v0
	s_lshl_b32 s31, s3, 21
	s_lshl_b32 s30, s1, 1
	s_lshl_b32 s2, s0, 8
	s_lshr_b32 s25, s27, 6
	s_bfe_u32 s7, s27, 0x20006
	s_lshr_b32 s24, s27, 8
	s_ashr_i32 s33, s31, 31
	s_lshl_b32 s34, s0, 16
	s_lshl_b32 s35, s1, 17
	s_cmp_eq_u32 s24, 0
	v_and_b32_e32 v3, 15, v0
	v_lshlrev_b32_e32 v2, 1, v0
	s_movk_i32 s0, 0x60
	v_and_or_b32 v2, v2, s0, v3
	s_cselect_b64 s[0:1], -1, 0
	s_and_b64 s[4:5], s[0:1], exec
	s_cselect_b32 s5, s13, s15
	s_cselect_b32 s12, s12, s14
	s_mov_b32 s13, 0x21000
	s_cselect_b32 s4, s35, s34
	s_cselect_b32 s58, s13, 0x22000
	s_add_u32 s12, s12, s31
	s_addc_u32 s5, s5, s33
	s_ashr_i32 s13, s4, 31
	s_add_u32 s4, s12, s4
	s_addc_u32 s5, s5, s13
	s_mul_i32 s11, s11, s3
	s_and_b32 s5, s5, 0xffff
	s_ashr_i32 s12, s11, 31
	s_add_u32 s11, s16, s11
	s_addc_u32 s31, s17, s12
	s_mul_i32 s12, s22, s3
	s_ashr_i32 s13, s12, 31
	s_mul_i32 s16, s2, s9
	s_add_u32 s12, s18, s12
	s_addc_u32 s13, s19, s13
	s_ashr_i32 s17, s16, 31
	s_add_u32 s16, s12, s16
	s_addc_u32 s12, s13, s17
	s_and_b32 s17, s12, 0xffff
	s_mul_i32 s12, s23, s3
	v_and_b32_e32 v1, 63, v0
	s_ashr_i32 s13, s12, 31
	s_movk_i32 s38, 0xc0
	v_lshlrev_b32_e32 v1, 2, v1
	s_lshl_b64 s[12:13], s[12:13], 2
	v_lshlrev_b32_e32 v4, 8, v2
	v_and_or_b32 v2, v1, s38, v3
	s_add_u32 s12, s20, s12
	v_bfe_u32 v5, v0, 3, 3
	v_lshlrev_b32_e32 v2, 8, v2
	s_addc_u32 s13, s21, s13
	s_ashr_i32 s3, s2, 31
	v_lshlrev_b32_e32 v6, 2, v5
	v_cndmask_b32_e64 v140, v4, v2, s[0:1]
	s_lshl_b64 s[2:3], s[2:3], 2
	v_lshlrev_b32_e32 v2, 4, v0
	v_lshl_or_b32 v6, s24, 5, v6
	s_add_u32 s33, s12, s2
	v_and_b32_e32 v2, 0x70, v2
	v_or_b32_e32 v6, s7, v6
	s_addc_u32 s34, s13, s3
	v_mad_u64_u32 v[136:137], s[2:3], v6, s8, v[2:3]
	s_mul_i32 s19, s7, s9
	s_bfe_u32 s2, s25, 0x10001
	s_lshl_b32 s3, s9, 5
	v_mul_lo_u32 v5, s9, v5
	v_add_u32_e32 v2, s19, v2
	s_mul_i32 s12, s2, 0x1080
	s_lshl_b32 s2, s27, 3
	s_mul_i32 s18, s24, s3
	v_lshl_add_u32 v141, v5, 2, v2
	v_and_b32_e32 v6, 3, v0
	v_lshlrev_b32_e32 v7, 5, v0
	s_and_b32 s13, s2, 0x200
	s_lshl_b32 s2, s9, 6
	v_add_u32_e32 v142, s18, v141
	v_add_u32_e32 v145, s3, v141
	v_mul_u32_u24_e32 v6, 0x420, v6
	v_and_b32_e32 v7, 0x180, v7
	v_and_b32_e32 v8, 48, v0
	v_add_u32_e32 v143, s2, v142
	v_add_u32_e32 v144, s2, v141
	v_add_u32_e32 v146, s2, v145
	s_lshl_b32 s2, s27, 8
	s_lshl_b32 s36, s25, 12
	v_add3_u32 v6, v7, v6, v8
	s_and_b32 s2, s2, 0x8000
	s_and_b32 s3, s36, 0x1000
	v_lshlrev_b32_e32 v7, 2, v0
	s_or_b32 s37, s2, s3
	v_and_or_b32 v7, v7, s38, v3
	s_mul_i32 s2, s24, 0x1080
	s_mul_i32 s38, s7, 0x420
	s_add_i32 s39, s38, s2
	s_add_i32 s41, s39, 0x10800
	s_add_i32 s42, s39, 0x12900
	s_lshl_b32 s18, s24, 9
	s_lshl_b32 s19, s7, 8
	s_and_b32 s20, s27, 0x100
	s_add_i32 s40, s39, 0x2100
	s_lshl_b32 s43, s8, 7
	s_add_i32 s44, s39, 0x4200
	s_add_i32 s45, s39, 0x6300
	s_lshl_b32 s46, s9, 7
	s_add_i32 s47, s41, 0x4200
	s_add_i32 s48, s42, 0x4200
	s_cmpk_gt_i32 s6, 0xff
	v_lshrrev_b32_e32 v5, 2, v0
	s_cselect_b64 s[2:3], -1, 0
	s_add_i32 s49, s41, 0x8400
	s_add_i32 s50, s42, 0x8400
	s_add_i32 s52, s46, 0x80
	s_add_i32 s53, s41, 0xc600
	s_add_i32 s54, s42, 0xc600
	s_add_i32 s55, s29, -3
	s_add_i32 s12, s12, s13
	s_add_i32 s18, s18, 0x10800
	v_lshlrev_b32_e32 v2, 4, v3
	v_and_b32_e32 v5, 12, v5
	v_bfe_u32 v8, v0, 5, 1
	s_cmp_eq_u32 s24, 1
	v_and_or_b32 v1, v1, 60, v8
	v_or3_b32 v8, v5, v2, s19
	v_or3_b32 v2, v2, s20, v5
	s_cselect_b64 s[20:21], -1, 0
	v_lshl_or_b32 v3, s7, 4, v3
	s_max_i32 s7, s29, 2
	s_lshl_b32 s56, s10, 9
	s_add_i32 s7, s7, -1
	v_lshlrev_b32_e32 v0, 6, v0
	s_add_i32 s57, s56, 0x200
	s_or_b32 s19, s19, s58
	s_and_b32 s58, s7, 3
	v_and_b32_e32 v0, 0x400, v0
	v_lshlrev_b32_e32 v1, 2, v1
	v_add_u32_e32 v149, s12, v6
	v_add_u32_e32 v150, s18, v6
	v_lshl_or_b32 v5, s24, 4, v5
	v_mul_lo_u32 v6, v3, s10
	v_or_b32_e32 v3, 64, v3
	s_cmpk_gt_i32 s6, 0x27f
	v_lshlrev_b32_e32 v7, 8, v7
	v_or_b32_e32 v147, 0x21000, v8
	v_add_u32_e32 v8, 32, v5
	v_add_u32_e32 v9, 64, v5
	v_add_u32_e32 v10, 0x60, v5
	v_mul_lo_u32 v3, v3, s10
	v_or3_b32 v160, s19, v0, v1
	s_cselect_b64 s[22:23], -1, 0
	s_add_i32 s64, s38, 0x10800
	v_mov_b32_e32 v128, 0
	s_mov_b32 s26, 0
	s_mov_b32 s15, 0x20000
	s_mov_b32 s14, -1
	v_lshl_add_u32 v137, s8, 6, v136
	s_movk_i32 s35, 0x200
	s_movk_i32 s51, 0x80
	v_or_b32_e32 v148, 0x22000, v2
	v_add_lshl_u32 v151, v6, v5, 2
	v_add_lshl_u32 v152, v6, v8, 2
	v_add_lshl_u32 v153, v6, v9, 2
	v_add_lshl_u32 v154, v6, v10, 2
	v_add_lshl_u32 v155, v3, v5, 2
	v_add_lshl_u32 v156, v3, v8, 2
	v_add_lshl_u32 v157, v3, v9, 2
	v_add_lshl_u32 v158, v3, v10, 2
	v_cndmask_b32_e64 v159, v4, v7, s[0:1]
	v_add_u32_e32 v161, 0x800, v160
	s_and_b32 s59, s7, -4
	s_add_i32 s60, s39, 0x8400
	s_add_i32 s61, s39, 0xa500
	s_add_i32 s62, s39, 0xc600
	s_add_i32 s63, s39, 0xe700
	s_add_i32 s65, s38, 0x12900
	s_add_i32 s66, s64, 0x1080
	s_add_i32 s67, s64, 0x3180
	s_add_i32 s68, s64, 0x4200
	s_add_i32 s69, s64, 0x6300
	s_add_i32 s70, s64, 0x5280
	s_add_i32 s71, s64, 0x7380
	v_or_b32_e32 v162, 0x22400, v2
	s_add_i32 s72, s64, 0x8400
	s_add_i32 s73, s64, 0xa500
	s_add_i32 s74, s64, 0x9480
	s_add_i32 s75, s64, 0xb580
	s_add_i32 s76, s64, 0xc600
	s_add_i32 s77, s64, 0xe700
	s_add_i32 s78, s64, 0xd680
	s_add_i32 s79, s64, 0xf780
	v_or_b32_e32 v163, 0x22800, v2
	v_or_b32_e32 v164, 0x22c00, v2
	v_mov_b32_e32 v129, v128
	v_mov_b32_e32 v130, v128
	v_mov_b32_e32 v131, v128
	s_mov_b64 s[24:25], -1
	s_mov_b32 s80, 0x6020400
	s_mov_b32 s81, 0x7030501
	s_mov_b32 s82, 0x7060302
	s_mov_b32 s83, 0x5040100
	s_branch .LBB0_4
.LBB0_1:                                ;   in Loop: Header=BB0_4 Depth=1
	s_lshl_b32 s18, s27, 10
.LBB0_2:                                ;   in Loop: Header=BB0_4 Depth=1
	v_add_u32_e32 v132, s18, v147
	ds_read_b32 v134, v132
	v_add_u32_e32 v132, s18, v148
	;;#ASMSTART
	ds_read2st64_b32 v[132:133], v132 offset0:0 offset1:2

	;;#ASMEND
	v_add_u32_e32 v135, s26, v149
	ds_read_b128 v[190:193], v135
	ds_read_b128 v[194:197], v135 offset:64
	ds_read_b128 v[182:185], v135 offset:8448
	ds_read_b128 v[186:189], v135 offset:8512
	ds_read_b128 v[174:177], v135 offset:16896
	ds_read_b128 v[178:181], v135 offset:16960
	ds_read_b128 v[166:169], v135 offset:25344
	ds_read_b128 v[170:173], v135 offset:25408
	v_add_u32_e32 v135, s26, v150
	ds_read_b128 v[222:225], v135
	ds_read_b128 v[226:229], v135 offset:64
	ds_read_b128 v[214:217], v135 offset:4224
	ds_read_b128 v[218:221], v135 offset:4288
	ds_read_b128 v[206:209], v135 offset:8448
	ds_read_b128 v[210:213], v135 offset:8512
	ds_read_b128 v[198:201], v135 offset:12672
	ds_read_b128 v[202:205], v135 offset:12736
	s_waitcnt lgkmcnt(6)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[112:115], v[222:229], v[190:197], v[112:115], v132, v134 op_sel_hi:[0,0,0]
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s12, s84, s10
	s_ashr_i32 s13, s12, 31
	s_xor_b64 s[6:7], s[24:25], -1
	s_lshl_b64 s[12:13], s[12:13], 2
	s_add_u32 s12, s33, s12
	s_addc_u32 s13, s34, s13
	v_mfma_scale_f32_16x16x128_f8f6f4 v[116:119], v[214:221], v[190:197], v[116:119], v132, v134 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_and_b32 s13, s13, 0xffff
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
	v_mfma_scale_f32_16x16x128_f8f6f4 v[120:123], v[206:213], v[190:197], v[120:123], v132, v134 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[124:127], v[198:205], v[190:197], v[124:127], v132, v134 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[48:51], v[222:229], v[182:189], v[48:51], v132, v134 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[52:55], v[214:221], v[182:189], v[52:55], v132, v134 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[56:59], v[206:213], v[182:189], v[56:59], v132, v134 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[60:63], v[198:205], v[182:189], v[60:63], v132, v134 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[80:83], v[222:229], v[174:181], v[80:83], v132, v134 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[84:87], v[214:221], v[174:181], v[84:87], v132, v134 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[88:91], v[206:213], v[174:181], v[88:91], v132, v134 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[92:95], v[198:205], v[174:181], v[92:95], v132, v134 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[16:19], v[222:229], v[166:173], v[16:19], v132, v134 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[20:23], v[214:221], v[166:173], v[20:23], v132, v134 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[24:27], v[206:213], v[166:173], v[24:27], v132, v134 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[28:31], v[198:205], v[166:173], v[28:31], v132, v134 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[222:225], v135 offset:16896
	ds_read_b128 v[226:229], v135 offset:16960
	ds_read_b128 v[214:217], v135 offset:21120
	ds_read_b128 v[218:221], v135 offset:21184
	ds_read_b128 v[206:209], v135 offset:25344
	ds_read_b128 v[210:213], v135 offset:25408
	ds_read_b128 v[198:201], v135 offset:29568
	ds_read_b128 v[202:205], v135 offset:29632
	s_waitcnt lgkmcnt(6)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[96:99], v[222:229], v[190:197], v[96:99], v133, v134 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[100:103], v[214:221], v[190:197], v[100:103], v133, v134 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[104:107], v[206:213], v[190:197], v[104:107], v133, v134 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[108:111], v[198:205], v[190:197], v[108:111], v133, v134 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[32:35], v[222:229], v[182:189], v[32:35], v133, v134 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[36:39], v[214:221], v[182:189], v[36:39], v133, v134 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[40:43], v[206:213], v[182:189], v[40:43], v133, v134 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[44:47], v[198:205], v[182:189], v[44:47], v133, v134 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	v_mfma_scale_f32_16x16x128_f8f6f4 v[64:67], v[222:229], v[174:181], v[64:67], v133, v134 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[68:71], v[214:221], v[174:181], v[68:71], v133, v134 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[72:75], v[206:213], v[174:181], v[72:75], v133, v134 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[76:79], v[198:205], v[174:181], v[76:79], v133, v134 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	v_mfma_scale_f32_16x16x128_f8f6f4 v[0:3], v[222:229], v[166:173], v[0:3], v133, v134 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[4:7], v[214:221], v[166:173], v[4:7], v133, v134 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[8:11], v[206:213], v[166:173], v[8:11], v133, v134 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[12:15], v[198:205], v[166:173], v[12:15], v133, v134 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	buffer_store_dwordx4 v[112:115], v151, s[12:15], 0 offen nt
	buffer_store_dwordx4 v[116:119], v152, s[12:15], 0 offen nt
	buffer_store_dwordx4 v[120:123], v153, s[12:15], 0 offen nt
	buffer_store_dwordx4 v[124:127], v154, s[12:15], 0 offen nt
	buffer_store_dwordx4 v[48:51], v155, s[12:15], 0 offen nt
	buffer_store_dwordx4 v[52:55], v156, s[12:15], 0 offen nt
	buffer_store_dwordx4 v[56:59], v157, s[12:15], 0 offen nt
	buffer_store_dwordx4 v[60:63], v158, s[12:15], 0 offen nt
	buffer_store_dwordx4 v[96:99], v151, s[12:15], s35 offen nt
	buffer_store_dwordx4 v[100:103], v152, s[12:15], s35 offen nt
	buffer_store_dwordx4 v[104:107], v153, s[12:15], s35 offen nt
	buffer_store_dwordx4 v[108:111], v154, s[12:15], s35 offen nt
	buffer_store_dwordx4 v[32:35], v155, s[12:15], s35 offen nt
	buffer_store_dwordx4 v[36:39], v156, s[12:15], s35 offen nt
	buffer_store_dwordx4 v[40:43], v157, s[12:15], s35 offen nt
	buffer_store_dwordx4 v[44:47], v158, s[12:15], s35 offen nt
	buffer_store_dwordx4 v[80:83], v151, s[12:15], s56 offen nt
	buffer_store_dwordx4 v[84:87], v152, s[12:15], s56 offen nt
	buffer_store_dwordx4 v[88:91], v153, s[12:15], s56 offen nt
	buffer_store_dwordx4 v[92:95], v154, s[12:15], s56 offen nt
	buffer_store_dwordx4 v[16:19], v155, s[12:15], s56 offen nt
	buffer_store_dwordx4 v[20:23], v156, s[12:15], s56 offen nt
	buffer_store_dwordx4 v[24:27], v157, s[12:15], s56 offen nt
	buffer_store_dwordx4 v[28:31], v158, s[12:15], s56 offen nt
	buffer_store_dwordx4 v[64:67], v151, s[12:15], s57 offen nt
	buffer_store_dwordx4 v[68:71], v152, s[12:15], s57 offen nt
	buffer_store_dwordx4 v[72:75], v153, s[12:15], s57 offen nt
	buffer_store_dwordx4 v[76:79], v154, s[12:15], s57 offen nt
	buffer_store_dwordx4 v[0:3], v155, s[12:15], s57 offen nt
	buffer_store_dwordx4 v[4:7], v156, s[12:15], s57 offen nt
	buffer_store_dwordx4 v[8:11], v157, s[12:15], s57 offen nt
	buffer_store_dwordx4 v[12:15], v158, s[12:15], s57 offen nt
.LBB0_3:                                ;   in Loop: Header=BB0_4 Depth=1
	s_mov_b32 s26, 1
	s_mov_b64 s[24:25], 0
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccnz .LBB0_50
.LBB0_4:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_10 Depth 2
                                        ;     Child Loop BB0_35 Depth 2
	s_or_b32 s12, s26, s30
	s_cmp_ge_i32 s12, s28
	s_mov_b64 s[6:7], -1
	s_cbranch_scc1 .LBB0_3
; %bb.5:                                ;   in Loop: Header=BB0_4 Depth=1
	s_lshl_b32 s84, s12, 8
	s_mul_i32 s6, s84, s8
	s_ashr_i32 s7, s6, 31
	s_add_u32 s12, s11, s6
	s_addc_u32 s6, s31, s7
	s_lshl_b32 s27, s26, 16
	s_and_b32 s13, s6, 0xffff
	s_or_b32 s18, s27, s36
	s_and_b64 s[6:7], s[0:1], exec
	s_cselect_b32 s18, s18, s37
	s_mov_b32 s6, s14
	s_mov_b32 s7, s15
	s_mov_b32 m0, s39
	buffer_load_dwordx4 v[132:135], v159, s[4:7], s18 offen
	s_mov_b32 s18, s14
	buffer_load_dwordx4 v136, s[12:15], 0 offen lds
	s_mov_b32 m0, s40
	s_mov_b32 s19, s15
	buffer_load_dwordx4 v137, s[12:15], 0 offen lds
	s_mov_b32 m0, s41
	s_mov_b32 s26, 0
	buffer_load_dwordx4 v142, s[16:19], 0 offen lds
	s_mov_b32 m0, s42
	s_waitcnt vmcnt(3)
	v_mov_b32_e32 v0, v132
	buffer_load_dwordx4 v143, s[16:19], 0 offen lds
	s_mov_b32 m0, s44
	v_mov_b32_e32 v1, v133
	buffer_load_dwordx4 v136, s[12:15], s43 offen lds
	s_mov_b32 m0, s45
	v_permlane16_swap_b32_e64 v0, v1 bound_ctrl:1
	buffer_load_dwordx4 v137, s[12:15], s43 offen lds
	s_mov_b32 m0, s47
	v_perm_b32 v2, v1, v0, s80
	buffer_load_dwordx4 v142, s[16:19], s46 offen lds
	s_mov_b32 m0, s48
	v_perm_b32 v0, v1, v0, s81
	buffer_load_dwordx4 v143, s[16:19], s46 offen lds
	s_nop 0
	v_permlane32_swap_b32_e64 v2, v0 bound_ctrl:1
	s_waitcnt vmcnt(0)
	v_perm_b32 v1, v0, v2, s82
	v_perm_b32 v0, v0, v2, s83
	;;#ASMSTART
	ds_write2_b32 v160, v0, v1 offset0:0 offset1:2

	;;#ASMEND
	s_waitcnt lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_andn2_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_29
; %bb.6:                                ;   in Loop: Header=BB0_4 Depth=1
	s_mov_b32 m0, s49
	s_nop 0
	buffer_load_dwordx4 v142, s[16:19], s51 offen lds
	s_mov_b32 m0, s50
	s_nop 0
	buffer_load_dwordx4 v143, s[16:19], s51 offen lds
	s_mov_b32 m0, s53
	s_nop 0
	buffer_load_dwordx4 v142, s[16:19], s52 offen lds
	s_mov_b32 m0, s54
	s_nop 0
	buffer_load_dwordx4 v143, s[16:19], s52 offen lds
	; sched_barrier mask(0x00000000)
	s_add_i32 s27, s27, s36
	s_and_b64 s[6:7], s[0:1], exec
	s_cselect_b32 s85, s27, s37
	s_andn2_b64 vcc, exec, s[22:23]
	s_mov_b32 s6, 1
	s_cbranch_vccnz .LBB0_30
; %bb.7:                                ;   in Loop: Header=BB0_4 Depth=1
	v_mov_b32_e32 v112, 0
	s_add_i32 s86, s85, 16
	s_mov_b32 s87, 0
	s_mov_b32 s88, 0
	v_mov_b32_e32 v113, v112
	v_mov_b32_e32 v114, v112
	v_mov_b32_e32 v115, v112
	v_mov_b32_e32 v116, v112
	v_mov_b32_e32 v117, v112
	v_mov_b32_e32 v118, v112
	v_mov_b32_e32 v119, v112
	v_mov_b32_e32 v120, v112
	v_mov_b32_e32 v121, v112
	v_mov_b32_e32 v122, v112
	v_mov_b32_e32 v123, v112
	v_mov_b32_e32 v124, v112
	v_mov_b32_e32 v125, v112
	v_mov_b32_e32 v126, v112
	v_mov_b32_e32 v127, v112
	v_mov_b32_e32 v48, v112
	v_mov_b32_e32 v49, v112
	v_mov_b32_e32 v50, v112
	v_mov_b32_e32 v51, v112
	v_mov_b32_e32 v52, v112
	v_mov_b32_e32 v53, v112
	v_mov_b32_e32 v54, v112
	v_mov_b32_e32 v55, v112
	v_mov_b32_e32 v56, v112
	v_mov_b32_e32 v57, v112
	v_mov_b32_e32 v58, v112
	v_mov_b32_e32 v59, v112
	v_mov_b32_e32 v60, v112
	v_mov_b32_e32 v61, v112
	v_mov_b32_e32 v62, v112
	v_mov_b32_e32 v63, v112
	v_mov_b32_e32 v96, v112
	v_mov_b32_e32 v97, v112
	v_mov_b32_e32 v98, v112
	v_mov_b32_e32 v99, v112
	v_mov_b32_e32 v100, v112
	v_mov_b32_e32 v101, v112
	v_mov_b32_e32 v102, v112
	v_mov_b32_e32 v103, v112
	v_mov_b32_e32 v104, v112
	v_mov_b32_e32 v105, v112
	v_mov_b32_e32 v106, v112
	v_mov_b32_e32 v107, v112
	v_mov_b32_e32 v108, v112
	v_mov_b32_e32 v109, v112
	v_mov_b32_e32 v110, v112
	v_mov_b32_e32 v111, v112
	v_mov_b32_e32 v32, v112
	v_mov_b32_e32 v33, v112
	v_mov_b32_e32 v34, v112
	v_mov_b32_e32 v35, v112
	v_mov_b32_e32 v36, v112
	v_mov_b32_e32 v37, v112
	v_mov_b32_e32 v38, v112
	v_mov_b32_e32 v39, v112
	v_mov_b32_e32 v40, v112
	v_mov_b32_e32 v41, v112
	v_mov_b32_e32 v42, v112
	v_mov_b32_e32 v43, v112
	v_mov_b32_e32 v44, v112
	v_mov_b32_e32 v45, v112
	v_mov_b32_e32 v46, v112
	v_mov_b32_e32 v47, v112
	v_mov_b32_e32 v80, v112
	v_mov_b32_e32 v81, v112
	v_mov_b32_e32 v82, v112
	v_mov_b32_e32 v83, v112
	v_mov_b32_e32 v84, v112
	v_mov_b32_e32 v85, v112
	v_mov_b32_e32 v86, v112
	v_mov_b32_e32 v87, v112
	v_mov_b32_e32 v88, v112
	v_mov_b32_e32 v89, v112
	v_mov_b32_e32 v90, v112
	v_mov_b32_e32 v91, v112
	v_mov_b32_e32 v92, v112
	v_mov_b32_e32 v93, v112
	v_mov_b32_e32 v94, v112
	v_mov_b32_e32 v95, v112
	v_mov_b32_e32 v16, v112
	v_mov_b32_e32 v17, v112
	v_mov_b32_e32 v18, v112
	v_mov_b32_e32 v19, v112
	v_mov_b32_e32 v20, v112
	v_mov_b32_e32 v21, v112
	v_mov_b32_e32 v22, v112
	v_mov_b32_e32 v23, v112
	v_mov_b32_e32 v24, v112
	v_mov_b32_e32 v25, v112
	v_mov_b32_e32 v26, v112
	v_mov_b32_e32 v27, v112
	v_mov_b32_e32 v28, v112
	v_mov_b32_e32 v29, v112
	v_mov_b32_e32 v30, v112
	v_mov_b32_e32 v31, v112
	v_mov_b32_e32 v64, v112
	v_mov_b32_e32 v65, v112
	v_mov_b32_e32 v66, v112
	v_mov_b32_e32 v67, v112
	v_mov_b32_e32 v68, v112
	v_mov_b32_e32 v69, v112
	v_mov_b32_e32 v70, v112
	v_mov_b32_e32 v71, v112
	v_mov_b32_e32 v72, v112
	v_mov_b32_e32 v73, v112
	v_mov_b32_e32 v74, v112
	v_mov_b32_e32 v75, v112
	v_mov_b32_e32 v76, v112
	v_mov_b32_e32 v77, v112
	v_mov_b32_e32 v78, v112
	v_mov_b32_e32 v79, v112
	v_mov_b32_e32 v0, v112
	v_mov_b32_e32 v1, v112
	v_mov_b32_e32 v2, v112
	v_mov_b32_e32 v3, v112
	v_mov_b32_e32 v4, v112
	v_mov_b32_e32 v5, v112
	v_mov_b32_e32 v6, v112
	v_mov_b32_e32 v7, v112
	v_mov_b32_e32 v8, v112
	v_mov_b32_e32 v9, v112
	v_mov_b32_e32 v10, v112
	v_mov_b32_e32 v11, v112
	v_mov_b32_e32 v12, v112
	v_mov_b32_e32 v13, v112
	v_mov_b32_e32 v14, v112
	v_mov_b32_e32 v15, v112
	s_branch .LBB0_10
	.p2align	5
.LBB0_8:                                ;   in Loop: Header=BB0_10 Depth=2
	; sched_barrier mask(0x00000000)
.LBB0_9:                                ;   in Loop: Header=BB0_10 Depth=2
	v_mfma_scale_f32_16x16x128_f8f6f4 v[32:35], v[174:181], v[190:197], v[32:35], v139, v165 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	s_add_i32 s86, s86, 16
	s_cmp_lg_u32 s59, s89
	s_mov_b32 s87, s6
	s_mov_b32 s88, s89
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[36:39], v[166:173], v[190:197], v[36:39], v139, v165 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[40:43], v[222:229], v[190:197], v[40:43], v139, v165 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[44:47], v[214:221], v[190:197], v[44:47], v139, v165 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[64:67], v[174:181], v[198:205], v[64:67], v139, v165 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[68:71], v[166:173], v[198:205], v[68:71], v139, v165 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[72:75], v[222:229], v[198:205], v[72:75], v139, v165 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[76:79], v[214:221], v[198:205], v[76:79], v139, v165 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[0:3], v[174:181], v[182:189], v[0:3], v139, v165 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[4:7], v[166:173], v[182:189], v[4:7], v139, v165 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[8:11], v[222:229], v[182:189], v[8:11], v139, v165 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[12:15], v[214:221], v[182:189], v[12:15], v139, v165 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_cbranch_scc0 .LBB0_31
.LBB0_10:                               ;   Parent Loop BB0_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ds_read_b32 v165, v147
	;;#ASMSTART
	ds_read2st64_b32 v[138:139], v148 offset0:0 offset1:2

	;;#ASMEND
	ds_read_b128 v[190:193], v149 offset:8448
	ds_read_b128 v[194:197], v149 offset:8512
	ds_read_b128 v[206:209], v149
	ds_read_b128 v[210:213], v149 offset:64
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[222:225], v150 offset:8448
	ds_read_b128 v[226:229], v150 offset:8512
	ds_read_b128 v[214:217], v150 offset:12672
	ds_read_b128 v[218:221], v150 offset:12736
	ds_read_b128 v[174:177], v150 offset:16896
	ds_read_b128 v[178:181], v150 offset:16960
	ds_read_b128 v[166:169], v150 offset:21120
	ds_read_b128 v[170:173], v150 offset:21184
	ds_read_b128 v[238:241], v150
	ds_read_b128 v[242:245], v150 offset:64
	ds_read_b128 v[230:233], v150 offset:4224
	ds_read_b128 v[234:237], v150 offset:4288
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s60
	s_add_i32 s6, s87, 0x80
	buffer_load_dwordx4 v136, s[12:15], s6 offen lds
	s_mov_b32 m0, s61
	s_add_i32 s90, s43, s87
	buffer_load_dwordx4 v137, s[12:15], s6 offen lds
	s_add_i32 s6, s90, 0x80
	s_mov_b32 m0, s62
	s_nop 0
	buffer_load_dwordx4 v136, s[12:15], s6 offen lds
	s_mov_b32 m0, s63
	s_nop 0
	buffer_load_dwordx4 v137, s[12:15], s6 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[112:115], v[238:245], v[206:213], v[112:115], v138, v165 op_sel_hi:[0,0,0]
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[116:119], v[230:237], v[206:213], v[116:119], v138, v165 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[198:201], v149 offset:16896
	ds_read_b128 v[202:205], v149 offset:16960
	ds_read_b128 v[182:185], v149 offset:25344
	ds_read_b128 v[186:189], v149 offset:25408
	s_waitcnt lgkmcnt(8)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[120:123], v[222:229], v[206:213], v[120:123], v138, v165 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[124:127], v[214:221], v[206:213], v[124:127], v138, v165 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[48:51], v[238:245], v[190:197], v[48:51], v138, v165 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[52:55], v[230:237], v[190:197], v[52:55], v138, v165 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[56:59], v[222:229], v[190:197], v[56:59], v138, v165 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[60:63], v[214:221], v[190:197], v[60:63], v138, v165 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[80:83], v[238:245], v[198:205], v[80:83], v138, v165 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[84:87], v[230:237], v[198:205], v[84:87], v138, v165 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[88:91], v[222:229], v[198:205], v[88:91], v138, v165 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[92:95], v[214:221], v[198:205], v[92:95], v138, v165 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[16:19], v[238:245], v[182:189], v[16:19], v138, v165 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[20:23], v[230:237], v[182:189], v[20:23], v138, v165 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[24:27], v[222:229], v[182:189], v[24:27], v138, v165 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[28:31], v[214:221], v[182:189], v[28:31], v138, v165 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[214:217], v150 offset:25344
	ds_read_b128 v[218:221], v150 offset:25408
	ds_read_b128 v[222:225], v150 offset:29568
	ds_read_b128 v[226:229], v150 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[96:99], v[174:181], v[206:213], v[96:99], v139, v165 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[100:103], v[166:173], v[206:213], v[100:103], v139, v165 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[104:107], v[214:221], v[206:213], v[104:107], v139, v165 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[108:111], v[222:229], v[206:213], v[108:111], v139, v165 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s6, s88, 2
	s_cmp_ge_i32 s6, s29
	s_cbranch_scc1 .LBB0_14
; %bb.11:                               ;   in Loop: Header=BB0_10 Depth=2
	s_andn2_b64 vcc, exec, s[20:21]
	s_cbranch_vccnz .LBB0_13
; %bb.12:                               ;   in Loop: Header=BB0_10 Depth=2
	s_mov_b32 m0, s64
	s_add_i32 s6, s87, 0x100
	s_mov_b32 s18, s14
	s_mov_b32 s19, s15
	buffer_load_dwordx4 v141, s[16:19], s6 offen lds
	s_mov_b32 m0, s65
	s_nop 0
	buffer_load_dwordx4 v144, s[16:19], s6 offen lds
	s_mov_b32 m0, s66
	s_nop 0
	buffer_load_dwordx4 v145, s[16:19], s6 offen lds
	s_mov_b32 m0, s67
	s_nop 0
	buffer_load_dwordx4 v146, s[16:19], s6 offen lds
	s_add_i32 s6, s6, s46
	s_mov_b32 m0, s68
	s_nop 0
	buffer_load_dwordx4 v141, s[16:19], s6 offen lds
	s_mov_b32 m0, s69
	s_nop 0
	buffer_load_dwordx4 v144, s[16:19], s6 offen lds
	s_mov_b32 m0, s70
	s_nop 0
	buffer_load_dwordx4 v145, s[16:19], s6 offen lds
	s_mov_b32 m0, s71
	s_nop 0
	buffer_load_dwordx4 v146, s[16:19], s6 offen lds
.LBB0_13:                               ;   in Loop: Header=BB0_10 Depth=2
	; sched_barrier mask(0x00000000)
.LBB0_14:                               ;   in Loop: Header=BB0_10 Depth=2
	v_mfma_scale_f32_16x16x128_f8f6f4 v[32:35], v[174:181], v[190:197], v[32:35], v139, v165 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[36:39], v[166:173], v[190:197], v[36:39], v139, v165 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[40:43], v[214:221], v[190:197], v[40:43], v139, v165 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[44:47], v[222:229], v[190:197], v[44:47], v139, v165 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[64:67], v[174:181], v[198:205], v[64:67], v139, v165 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[68:71], v[166:173], v[198:205], v[68:71], v139, v165 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[72:75], v[214:221], v[198:205], v[72:75], v139, v165 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[76:79], v[222:229], v[198:205], v[76:79], v139, v165 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[0:3], v[174:181], v[182:189], v[0:3], v139, v165 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[4:7], v[166:173], v[182:189], v[4:7], v139, v165 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[8:11], v[214:221], v[182:189], v[8:11], v139, v165 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[12:15], v[222:229], v[182:189], v[12:15], v139, v165 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b32 v165, v147 offset:1024
	;;#ASMSTART
	ds_read2st64_b32 v[138:139], v162 offset0:0 offset1:2

	;;#ASMEND
	ds_read_b128 v[206:209], v149 offset:33792
	ds_read_b128 v[210:213], v149 offset:33856
	ds_read_b128 v[182:185], v149 offset:42240
	ds_read_b128 v[186:189], v149 offset:42304
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[238:241], v150 offset:33792
	ds_read_b128 v[242:245], v150 offset:33856
	ds_read_b128 v[230:233], v150 offset:38016
	ds_read_b128 v[234:237], v150 offset:38080
	ds_read_b128 v[222:225], v150 offset:42240
	ds_read_b128 v[226:229], v150 offset:42304
	ds_read_b128 v[214:217], v150 offset:46464
	ds_read_b128 v[218:221], v150 offset:46528
	ds_read_b128 v[174:177], v150 offset:50688
	ds_read_b128 v[178:181], v150 offset:50752
	ds_read_b128 v[166:169], v150 offset:54912
	ds_read_b128 v[170:173], v150 offset:54976
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s39
	s_add_i32 s6, s87, 0x100
	buffer_load_dwordx4 v136, s[12:15], s6 offen lds
	s_mov_b32 m0, s40
	s_nop 0
	buffer_load_dwordx4 v137, s[12:15], s6 offen lds
	s_add_i32 s6, s90, 0x100
	s_mov_b32 m0, s44
	s_nop 0
	buffer_load_dwordx4 v136, s[12:15], s6 offen lds
	s_mov_b32 m0, s45
	s_nop 0
	buffer_load_dwordx4 v137, s[12:15], s6 offen lds
	; sched_barrier mask(0x00000000)
	s_add_i32 s89, s88, 4
	s_cmp_lt_i32 s89, s29
	s_waitcnt lgkmcnt(10)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[112:115], v[238:245], v[206:213], v[112:115], v138, v165 op_sel_hi:[0,0,0]
	s_cselect_b64 s[26:27], -1, 0
	s_cmp_ge_i32 s89, s29
	s_waitcnt lgkmcnt(8)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[116:119], v[230:237], v[206:213], v[116:119], v138, v165 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_cbranch_scc1 .LBB0_16
; %bb.15:                               ;   in Loop: Header=BB0_10 Depth=2
	s_mov_b32 s6, s14
	s_mov_b32 s7, s15
	buffer_load_dwordx4 v[128:131], v140, s[4:7], s86 offen
.LBB0_16:                               ;   in Loop: Header=BB0_10 Depth=2
	ds_read_b128 v[198:201], v149 offset:50688
	ds_read_b128 v[202:205], v149 offset:50752
	s_waitcnt lgkmcnt(8)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[120:123], v[222:229], v[206:213], v[120:123], v138, v165 op_sel_hi:[1,0,0]
	ds_read_b128 v[190:193], v149 offset:59136
	ds_read_b128 v[194:197], v149 offset:59200
	s_waitcnt lgkmcnt(8)
	s_add_i32 s6, s88, 1
	s_cmp_ge_i32 s6, s55
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[124:127], v[214:221], v[206:213], v[124:127], v138, v165 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[48:51], v[238:245], v[182:189], v[48:51], v138, v165 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[52:55], v[230:237], v[182:189], v[52:55], v138, v165 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[56:59], v[222:229], v[182:189], v[56:59], v138, v165 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[60:63], v[214:221], v[182:189], v[60:63], v138, v165 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[80:83], v[238:245], v[198:205], v[80:83], v138, v165 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[84:87], v[230:237], v[198:205], v[84:87], v138, v165 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[88:91], v[222:229], v[198:205], v[88:91], v138, v165 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[92:95], v[214:221], v[198:205], v[92:95], v138, v165 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[16:19], v[238:245], v[190:197], v[16:19], v138, v165 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[20:23], v[230:237], v[190:197], v[20:23], v138, v165 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[24:27], v[222:229], v[190:197], v[24:27], v138, v165 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[28:31], v[214:221], v[190:197], v[28:31], v138, v165 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[214:217], v150 offset:59136
	ds_read_b128 v[218:221], v150 offset:59200
	ds_read_b128 v[222:225], v150 offset:63360
	ds_read_b128 v[226:229], v150 offset:63424
	v_mov_b32_e32 v138, v134
	v_mfma_scale_f32_16x16x128_f8f6f4 v[96:99], v[174:181], v[206:213], v[96:99], v139, v165 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[100:103], v[166:173], v[206:213], v[100:103], v139, v165 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[104:107], v[214:221], v[206:213], v[104:107], v139, v165 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[108:111], v[222:229], v[206:213], v[108:111], v139, v165 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_mov_b32_e32 v206, v135
	s_nop 1
	v_permlane16_swap_b32_e64 v138, v206 bound_ctrl:1
	v_perm_b32 v207, v206, v138, s80
	v_perm_b32 v138, v206, v138, s81
	s_nop 1
	v_permlane32_swap_b32_e64 v207, v138 bound_ctrl:1
	;;#ASMSTART
	;;#ASMEND
	v_perm_b32 v206, v138, v207, s82
	v_perm_b32 v138, v138, v207, s83
	;;#ASMSTART
	ds_write2_b32 v161, v138, v206 offset0:0 offset1:2

	;;#ASMEND
	s_cbranch_scc1 .LBB0_18
; %bb.17:                               ;   in Loop: Header=BB0_10 Depth=2
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt vmcnt(0)
	v_mov_b64_e32 v[134:135], v[130:131]
	v_mov_b64_e32 v[132:133], v[128:129]
.LBB0_18:                               ;   in Loop: Header=BB0_10 Depth=2
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s6, s88, 3
	s_cmp_ge_i32 s6, s29
	s_cbranch_scc1 .LBB0_22
; %bb.19:                               ;   in Loop: Header=BB0_10 Depth=2
	s_andn2_b64 vcc, exec, s[20:21]
	s_cbranch_vccnz .LBB0_21
; %bb.20:                               ;   in Loop: Header=BB0_10 Depth=2
	s_mov_b32 m0, s72
	s_add_i32 s6, s87, 0x180
	s_mov_b32 s18, s14
	s_mov_b32 s19, s15
	buffer_load_dwordx4 v141, s[16:19], s6 offen lds
	s_mov_b32 m0, s73
	s_nop 0
	buffer_load_dwordx4 v144, s[16:19], s6 offen lds
	s_mov_b32 m0, s74
	s_nop 0
	buffer_load_dwordx4 v145, s[16:19], s6 offen lds
	s_mov_b32 m0, s75
	s_nop 0
	buffer_load_dwordx4 v146, s[16:19], s6 offen lds
	s_add_i32 s6, s6, s46
	s_mov_b32 m0, s76
	s_nop 0
	buffer_load_dwordx4 v141, s[16:19], s6 offen lds
	s_mov_b32 m0, s77
	s_nop 0
	buffer_load_dwordx4 v144, s[16:19], s6 offen lds
	s_mov_b32 m0, s78
	s_nop 0
	buffer_load_dwordx4 v145, s[16:19], s6 offen lds
	s_mov_b32 m0, s79
	s_nop 0
	buffer_load_dwordx4 v146, s[16:19], s6 offen lds
.LBB0_21:                               ;   in Loop: Header=BB0_10 Depth=2
	; sched_barrier mask(0x00000000)
.LBB0_22:                               ;   in Loop: Header=BB0_10 Depth=2
	v_mfma_scale_f32_16x16x128_f8f6f4 v[32:35], v[174:181], v[182:189], v[32:35], v139, v165 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[36:39], v[166:173], v[182:189], v[36:39], v139, v165 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[40:43], v[214:221], v[182:189], v[40:43], v139, v165 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[44:47], v[222:229], v[182:189], v[44:47], v139, v165 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[64:67], v[174:181], v[198:205], v[64:67], v139, v165 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[68:71], v[166:173], v[198:205], v[68:71], v139, v165 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[72:75], v[214:221], v[198:205], v[72:75], v139, v165 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[76:79], v[222:229], v[198:205], v[76:79], v139, v165 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[0:3], v[174:181], v[190:197], v[0:3], v139, v165 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[4:7], v[166:173], v[190:197], v[4:7], v139, v165 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[8:11], v[214:221], v[190:197], v[8:11], v139, v165 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[12:15], v[222:229], v[190:197], v[12:15], v139, v165 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b32 v165, v147 offset:2048
	;;#ASMSTART
	ds_read2st64_b32 v[138:139], v163 offset0:0 offset1:2

	;;#ASMEND
	ds_read_b128 v[182:185], v149 offset:8448
	ds_read_b128 v[186:189], v149 offset:8512
	ds_read_b128 v[206:209], v149
	ds_read_b128 v[210:213], v149 offset:64
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[222:225], v150 offset:8448
	ds_read_b128 v[226:229], v150 offset:8512
	ds_read_b128 v[214:217], v150 offset:12672
	ds_read_b128 v[218:221], v150 offset:12736
	ds_read_b128 v[174:177], v150 offset:16896
	ds_read_b128 v[178:181], v150 offset:16960
	ds_read_b128 v[166:169], v150 offset:21120
	ds_read_b128 v[170:173], v150 offset:21184
	ds_read_b128 v[238:241], v150
	ds_read_b128 v[242:245], v150 offset:64
	ds_read_b128 v[230:233], v150 offset:4224
	ds_read_b128 v[234:237], v150 offset:4288
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s60
	s_add_i32 s6, s87, 0x180
	buffer_load_dwordx4 v136, s[12:15], s6 offen lds
	s_mov_b32 m0, s61
	s_nop 0
	buffer_load_dwordx4 v137, s[12:15], s6 offen lds
	s_add_i32 s6, s90, 0x180
	s_mov_b32 m0, s62
	s_nop 0
	buffer_load_dwordx4 v136, s[12:15], s6 offen lds
	s_mov_b32 m0, s63
	s_nop 0
	buffer_load_dwordx4 v137, s[12:15], s6 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[112:115], v[238:245], v[206:213], v[112:115], v138, v165 op_sel_hi:[0,0,0]
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[116:119], v[230:237], v[206:213], v[116:119], v138, v165 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[198:201], v149 offset:16896
	ds_read_b128 v[202:205], v149 offset:16960
	ds_read_b128 v[190:193], v149 offset:25344
	ds_read_b128 v[194:197], v149 offset:25408
	s_waitcnt lgkmcnt(8)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[120:123], v[222:229], v[206:213], v[120:123], v138, v165 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[124:127], v[214:221], v[206:213], v[124:127], v138, v165 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[48:51], v[238:245], v[182:189], v[48:51], v138, v165 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[52:55], v[230:237], v[182:189], v[52:55], v138, v165 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[56:59], v[222:229], v[182:189], v[56:59], v138, v165 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[60:63], v[214:221], v[182:189], v[60:63], v138, v165 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[80:83], v[238:245], v[198:205], v[80:83], v138, v165 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[84:87], v[230:237], v[198:205], v[84:87], v138, v165 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[88:91], v[222:229], v[198:205], v[88:91], v138, v165 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[92:95], v[214:221], v[198:205], v[92:95], v138, v165 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[16:19], v[238:245], v[190:197], v[16:19], v138, v165 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[20:23], v[230:237], v[190:197], v[20:23], v138, v165 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[24:27], v[222:229], v[190:197], v[24:27], v138, v165 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[28:31], v[214:221], v[190:197], v[28:31], v138, v165 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[214:217], v150 offset:25344
	ds_read_b128 v[218:221], v150 offset:25408
	ds_read_b128 v[222:225], v150 offset:29568
	ds_read_b128 v[226:229], v150 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[96:99], v[174:181], v[206:213], v[96:99], v139, v165 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[100:103], v[166:173], v[206:213], v[100:103], v139, v165 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[104:107], v[214:221], v[206:213], v[104:107], v139, v165 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[108:111], v[222:229], v[206:213], v[108:111], v139, v165 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_andn2_b64 vcc, exec, s[26:27]
	s_cbranch_vccnz .LBB0_26
; %bb.23:                               ;   in Loop: Header=BB0_10 Depth=2
	s_andn2_b64 vcc, exec, s[20:21]
	s_cbranch_vccnz .LBB0_25
; %bb.24:                               ;   in Loop: Header=BB0_10 Depth=2
	s_mov_b32 m0, s64
	s_add_i32 s6, s87, 0x200
	s_mov_b32 s18, s14
	s_mov_b32 s19, s15
	buffer_load_dwordx4 v141, s[16:19], s6 offen lds
	s_mov_b32 m0, s65
	s_nop 0
	buffer_load_dwordx4 v144, s[16:19], s6 offen lds
	s_mov_b32 m0, s66
	s_nop 0
	buffer_load_dwordx4 v145, s[16:19], s6 offen lds
	s_mov_b32 m0, s67
	s_nop 0
	buffer_load_dwordx4 v146, s[16:19], s6 offen lds
	s_add_i32 s6, s6, s46
	s_mov_b32 m0, s68
	s_nop 0
	buffer_load_dwordx4 v141, s[16:19], s6 offen lds
	s_mov_b32 m0, s69
	s_nop 0
	buffer_load_dwordx4 v144, s[16:19], s6 offen lds
	s_mov_b32 m0, s70
	s_nop 0
	buffer_load_dwordx4 v145, s[16:19], s6 offen lds
	s_mov_b32 m0, s71
	s_nop 0
	buffer_load_dwordx4 v146, s[16:19], s6 offen lds
.LBB0_25:                               ;   in Loop: Header=BB0_10 Depth=2
	; sched_barrier mask(0x00000000)
.LBB0_26:                               ;   in Loop: Header=BB0_10 Depth=2
	v_mfma_scale_f32_16x16x128_f8f6f4 v[32:35], v[174:181], v[182:189], v[32:35], v139, v165 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[36:39], v[166:173], v[182:189], v[36:39], v139, v165 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[40:43], v[214:221], v[182:189], v[40:43], v139, v165 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[44:47], v[222:229], v[182:189], v[44:47], v139, v165 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[64:67], v[174:181], v[198:205], v[64:67], v139, v165 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[68:71], v[166:173], v[198:205], v[68:71], v139, v165 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[72:75], v[214:221], v[198:205], v[72:75], v139, v165 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[76:79], v[222:229], v[198:205], v[76:79], v139, v165 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[0:3], v[174:181], v[190:197], v[0:3], v139, v165 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[4:7], v[166:173], v[190:197], v[4:7], v139, v165 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[8:11], v[214:221], v[190:197], v[8:11], v139, v165 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[12:15], v[222:229], v[190:197], v[12:15], v139, v165 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b32 v165, v147 offset:3072
	;;#ASMSTART
	ds_read2st64_b32 v[138:139], v164 offset0:0 offset1:2

	;;#ASMEND
	ds_read_b128 v[190:193], v149 offset:42240
	ds_read_b128 v[194:197], v149 offset:42304
	ds_read_b128 v[206:209], v149 offset:33792
	ds_read_b128 v[210:213], v149 offset:33856
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[222:225], v150 offset:42240
	ds_read_b128 v[226:229], v150 offset:42304
	ds_read_b128 v[214:217], v150 offset:46464
	ds_read_b128 v[218:221], v150 offset:46528
	ds_read_b128 v[174:177], v150 offset:50688
	ds_read_b128 v[178:181], v150 offset:50752
	ds_read_b128 v[166:169], v150 offset:54912
	ds_read_b128 v[170:173], v150 offset:54976
	ds_read_b128 v[238:241], v150 offset:33792
	ds_read_b128 v[242:245], v150 offset:33856
	ds_read_b128 v[230:233], v150 offset:38016
	ds_read_b128 v[234:237], v150 offset:38080
	; sched_barrier mask(0x00000000)
	s_mov_b32 m0, s39
	s_add_i32 s6, s87, 0x200
	buffer_load_dwordx4 v136, s[12:15], s6 offen lds
	s_mov_b32 m0, s40
	s_addk_i32 s90, 0x200
	buffer_load_dwordx4 v137, s[12:15], s6 offen lds
	s_mov_b32 m0, s44
	s_nop 0
	buffer_load_dwordx4 v136, s[12:15], s90 offen lds
	s_mov_b32 m0, s45
	s_nop 0
	buffer_load_dwordx4 v137, s[12:15], s90 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[112:115], v[238:245], v[206:213], v[112:115], v138, v165 op_sel_hi:[0,0,0]
	s_waitcnt lgkmcnt(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[116:119], v[230:237], v[206:213], v[116:119], v138, v165 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[198:201], v149 offset:50688
	ds_read_b128 v[202:205], v149 offset:50752
	ds_read_b128 v[182:185], v149 offset:59136
	ds_read_b128 v[186:189], v149 offset:59200
	s_waitcnt lgkmcnt(8)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[120:123], v[222:229], v[206:213], v[120:123], v138, v165 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[124:127], v[214:221], v[206:213], v[124:127], v138, v165 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[48:51], v[238:245], v[190:197], v[48:51], v138, v165 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[52:55], v[230:237], v[190:197], v[52:55], v138, v165 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[56:59], v[222:229], v[190:197], v[56:59], v138, v165 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[60:63], v[214:221], v[190:197], v[60:63], v138, v165 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[80:83], v[238:245], v[198:205], v[80:83], v138, v165 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[84:87], v[230:237], v[198:205], v[84:87], v138, v165 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[88:91], v[222:229], v[198:205], v[88:91], v138, v165 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[92:95], v[214:221], v[198:205], v[92:95], v138, v165 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[16:19], v[238:245], v[182:189], v[16:19], v138, v165 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[20:23], v[230:237], v[182:189], v[20:23], v138, v165 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[24:27], v[222:229], v[182:189], v[24:27], v138, v165 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[28:31], v[214:221], v[182:189], v[28:31], v138, v165 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[222:225], v150 offset:59136
	ds_read_b128 v[226:229], v150 offset:59200
	ds_read_b128 v[214:217], v150 offset:63360
	ds_read_b128 v[218:221], v150 offset:63424
	v_mov_b32_e32 v138, v132
	v_mfma_scale_f32_16x16x128_f8f6f4 v[96:99], v[174:181], v[206:213], v[96:99], v139, v165 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[100:103], v[166:173], v[206:213], v[100:103], v139, v165 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[104:107], v[222:229], v[206:213], v[104:107], v139, v165 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[108:111], v[214:221], v[206:213], v[108:111], v139, v165 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_mov_b32_e32 v206, v133
	s_nop 1
	v_permlane16_swap_b32_e64 v138, v206 bound_ctrl:1
	v_perm_b32 v207, v206, v138, s80
	v_perm_b32 v138, v206, v138, s81
	s_nop 1
	v_permlane32_swap_b32_e64 v207, v138 bound_ctrl:1
	;;#ASMSTART
	;;#ASMEND
	v_perm_b32 v206, v138, v207, s82
	v_perm_b32 v138, v138, v207, s83
	;;#ASMSTART
	ds_write2_b32 v160, v138, v206 offset0:0 offset1:2

	;;#ASMEND
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s7, s88, 5
	s_cmp_ge_i32 s7, s29
	s_cbranch_scc1 .LBB0_9
; %bb.27:                               ;   in Loop: Header=BB0_10 Depth=2
	s_andn2_b64 vcc, exec, s[20:21]
	s_cbranch_vccnz .LBB0_8
; %bb.28:                               ;   in Loop: Header=BB0_10 Depth=2
	s_mov_b32 m0, s72
	s_add_i32 s7, s87, 0x280
	s_mov_b32 s18, s14
	s_mov_b32 s19, s15
	buffer_load_dwordx4 v141, s[16:19], s7 offen lds
	s_mov_b32 m0, s73
	s_nop 0
	buffer_load_dwordx4 v144, s[16:19], s7 offen lds
	s_mov_b32 m0, s74
	s_nop 0
	buffer_load_dwordx4 v145, s[16:19], s7 offen lds
	s_mov_b32 m0, s75
	s_nop 0
	buffer_load_dwordx4 v146, s[16:19], s7 offen lds
	s_add_i32 s7, s7, s46
	s_mov_b32 m0, s76
	s_nop 0
	buffer_load_dwordx4 v141, s[16:19], s7 offen lds
	s_mov_b32 m0, s77
	s_nop 0
	buffer_load_dwordx4 v144, s[16:19], s7 offen lds
	s_mov_b32 m0, s78
	s_nop 0
	buffer_load_dwordx4 v145, s[16:19], s7 offen lds
	s_mov_b32 m0, s79
	s_nop 0
	buffer_load_dwordx4 v146, s[16:19], s7 offen lds
	s_branch .LBB0_8
.LBB0_29:                               ;   in Loop: Header=BB0_4 Depth=1
	v_mov_b32_e32 v63, 0
	v_mov_b32_e32 v62, v63
	v_mov_b32_e32 v61, v63
	v_mov_b32_e32 v60, v63
	v_mov_b32_e32 v59, v63
	v_mov_b32_e32 v58, v63
	v_mov_b32_e32 v57, v63
	v_mov_b32_e32 v56, v63
	v_mov_b32_e32 v55, v63
	v_mov_b32_e32 v54, v63
	v_mov_b32_e32 v53, v63
	v_mov_b32_e32 v52, v63
	v_mov_b32_e32 v51, v63
	v_mov_b32_e32 v50, v63
	v_mov_b32_e32 v49, v63
	v_mov_b32_e32 v48, v63
	v_mov_b32_e32 v127, v63
	v_mov_b32_e32 v126, v63
	v_mov_b32_e32 v125, v63
	v_mov_b32_e32 v124, v63
	v_mov_b32_e32 v123, v63
	v_mov_b32_e32 v122, v63
	v_mov_b32_e32 v121, v63
	v_mov_b32_e32 v120, v63
	v_mov_b32_e32 v119, v63
	v_mov_b32_e32 v118, v63
	v_mov_b32_e32 v117, v63
	v_mov_b32_e32 v116, v63
	v_mov_b32_e32 v115, v63
	v_mov_b32_e32 v114, v63
	v_mov_b32_e32 v113, v63
	v_mov_b32_e32 v112, v63
	v_mov_b32_e32 v47, v63
	v_mov_b32_e32 v46, v63
	v_mov_b32_e32 v45, v63
	v_mov_b32_e32 v44, v63
	v_mov_b32_e32 v43, v63
	v_mov_b32_e32 v42, v63
	v_mov_b32_e32 v41, v63
	v_mov_b32_e32 v40, v63
	v_mov_b32_e32 v39, v63
	v_mov_b32_e32 v38, v63
	v_mov_b32_e32 v37, v63
	v_mov_b32_e32 v36, v63
	v_mov_b32_e32 v35, v63
	v_mov_b32_e32 v34, v63
	v_mov_b32_e32 v33, v63
	v_mov_b32_e32 v32, v63
	v_mov_b32_e32 v111, v63
	v_mov_b32_e32 v110, v63
	v_mov_b32_e32 v109, v63
	v_mov_b32_e32 v108, v63
	v_mov_b32_e32 v107, v63
	v_mov_b32_e32 v106, v63
	v_mov_b32_e32 v105, v63
	v_mov_b32_e32 v104, v63
	v_mov_b32_e32 v103, v63
	v_mov_b32_e32 v102, v63
	v_mov_b32_e32 v101, v63
	v_mov_b32_e32 v100, v63
	v_mov_b32_e32 v99, v63
	v_mov_b32_e32 v98, v63
	v_mov_b32_e32 v97, v63
	v_mov_b32_e32 v96, v63
	v_mov_b32_e32 v31, v63
	v_mov_b32_e32 v30, v63
	v_mov_b32_e32 v29, v63
	v_mov_b32_e32 v28, v63
	v_mov_b32_e32 v27, v63
	v_mov_b32_e32 v26, v63
	v_mov_b32_e32 v25, v63
	v_mov_b32_e32 v24, v63
	v_mov_b32_e32 v23, v63
	v_mov_b32_e32 v22, v63
	v_mov_b32_e32 v21, v63
	v_mov_b32_e32 v20, v63
	v_mov_b32_e32 v19, v63
	v_mov_b32_e32 v18, v63
	v_mov_b32_e32 v17, v63
	v_mov_b32_e32 v16, v63
	v_mov_b32_e32 v95, v63
	v_mov_b32_e32 v94, v63
	v_mov_b32_e32 v93, v63
	v_mov_b32_e32 v92, v63
	v_mov_b32_e32 v91, v63
	v_mov_b32_e32 v90, v63
	v_mov_b32_e32 v89, v63
	v_mov_b32_e32 v88, v63
	v_mov_b32_e32 v87, v63
	v_mov_b32_e32 v86, v63
	v_mov_b32_e32 v85, v63
	v_mov_b32_e32 v84, v63
	v_mov_b32_e32 v83, v63
	v_mov_b32_e32 v82, v63
	v_mov_b32_e32 v81, v63
	v_mov_b32_e32 v80, v63
	v_mov_b32_e32 v15, v63
	v_mov_b32_e32 v14, v63
	v_mov_b32_e32 v13, v63
	v_mov_b32_e32 v12, v63
	v_mov_b32_e32 v11, v63
	v_mov_b32_e32 v10, v63
	v_mov_b32_e32 v9, v63
	v_mov_b32_e32 v8, v63
	v_mov_b32_e32 v7, v63
	v_mov_b32_e32 v6, v63
	v_mov_b32_e32 v5, v63
	v_mov_b32_e32 v4, v63
	v_mov_b32_e32 v3, v63
	v_mov_b32_e32 v2, v63
	v_mov_b32_e32 v1, v63
	v_mov_b32_e32 v0, v63
	v_mov_b32_e32 v79, v63
	v_mov_b32_e32 v78, v63
	v_mov_b32_e32 v77, v63
	v_mov_b32_e32 v76, v63
	v_mov_b32_e32 v75, v63
	v_mov_b32_e32 v74, v63
	v_mov_b32_e32 v73, v63
	v_mov_b32_e32 v72, v63
	v_mov_b32_e32 v71, v63
	v_mov_b32_e32 v70, v63
	v_mov_b32_e32 v69, v63
	v_mov_b32_e32 v68, v63
	v_mov_b32_e32 v67, v63
	v_mov_b32_e32 v66, v63
	v_mov_b32_e32 v65, v63
	v_mov_b32_e32 v64, v63
	s_mov_b32 s18, 0
	s_branch .LBB0_2
.LBB0_30:                               ;   in Loop: Header=BB0_4 Depth=1
	v_mov_b32_e32 v15, 0
	s_mov_b32 s18, 0
	v_mov_b32_e32 v14, v15
	v_mov_b32_e32 v13, v15
	v_mov_b32_e32 v12, v15
	v_mov_b32_e32 v11, v15
	v_mov_b32_e32 v10, v15
	v_mov_b32_e32 v9, v15
	v_mov_b32_e32 v8, v15
	v_mov_b32_e32 v7, v15
	v_mov_b32_e32 v6, v15
	v_mov_b32_e32 v5, v15
	v_mov_b32_e32 v4, v15
	v_mov_b32_e32 v3, v15
	v_mov_b32_e32 v2, v15
	v_mov_b32_e32 v1, v15
	v_mov_b32_e32 v0, v15
	v_mov_b32_e32 v79, v15
	v_mov_b32_e32 v78, v15
	v_mov_b32_e32 v77, v15
	v_mov_b32_e32 v76, v15
	v_mov_b32_e32 v75, v15
	v_mov_b32_e32 v74, v15
	v_mov_b32_e32 v73, v15
	v_mov_b32_e32 v72, v15
	v_mov_b32_e32 v71, v15
	v_mov_b32_e32 v70, v15
	v_mov_b32_e32 v69, v15
	v_mov_b32_e32 v68, v15
	v_mov_b32_e32 v67, v15
	v_mov_b32_e32 v66, v15
	v_mov_b32_e32 v65, v15
	v_mov_b32_e32 v64, v15
	v_mov_b32_e32 v31, v15
	v_mov_b32_e32 v30, v15
	v_mov_b32_e32 v29, v15
	v_mov_b32_e32 v28, v15
	v_mov_b32_e32 v27, v15
	v_mov_b32_e32 v26, v15
	v_mov_b32_e32 v25, v15
	v_mov_b32_e32 v24, v15
	v_mov_b32_e32 v23, v15
	v_mov_b32_e32 v22, v15
	v_mov_b32_e32 v21, v15
	v_mov_b32_e32 v20, v15
	v_mov_b32_e32 v19, v15
	v_mov_b32_e32 v18, v15
	v_mov_b32_e32 v17, v15
	v_mov_b32_e32 v16, v15
	v_mov_b32_e32 v95, v15
	v_mov_b32_e32 v94, v15
	v_mov_b32_e32 v93, v15
	v_mov_b32_e32 v92, v15
	v_mov_b32_e32 v91, v15
	v_mov_b32_e32 v90, v15
	v_mov_b32_e32 v89, v15
	v_mov_b32_e32 v88, v15
	v_mov_b32_e32 v87, v15
	v_mov_b32_e32 v86, v15
	v_mov_b32_e32 v85, v15
	v_mov_b32_e32 v84, v15
	v_mov_b32_e32 v83, v15
	v_mov_b32_e32 v82, v15
	v_mov_b32_e32 v81, v15
	v_mov_b32_e32 v80, v15
	v_mov_b32_e32 v47, v15
	v_mov_b32_e32 v46, v15
	v_mov_b32_e32 v45, v15
	v_mov_b32_e32 v44, v15
	v_mov_b32_e32 v43, v15
	v_mov_b32_e32 v42, v15
	v_mov_b32_e32 v41, v15
	v_mov_b32_e32 v40, v15
	v_mov_b32_e32 v39, v15
	v_mov_b32_e32 v38, v15
	v_mov_b32_e32 v37, v15
	v_mov_b32_e32 v36, v15
	v_mov_b32_e32 v35, v15
	v_mov_b32_e32 v34, v15
	v_mov_b32_e32 v33, v15
	v_mov_b32_e32 v32, v15
	v_mov_b32_e32 v111, v15
	v_mov_b32_e32 v110, v15
	v_mov_b32_e32 v109, v15
	v_mov_b32_e32 v108, v15
	v_mov_b32_e32 v107, v15
	v_mov_b32_e32 v106, v15
	v_mov_b32_e32 v105, v15
	v_mov_b32_e32 v104, v15
	v_mov_b32_e32 v103, v15
	v_mov_b32_e32 v102, v15
	v_mov_b32_e32 v101, v15
	v_mov_b32_e32 v100, v15
	v_mov_b32_e32 v99, v15
	v_mov_b32_e32 v98, v15
	v_mov_b32_e32 v97, v15
	v_mov_b32_e32 v96, v15
	v_mov_b32_e32 v63, v15
	v_mov_b32_e32 v62, v15
	v_mov_b32_e32 v61, v15
	v_mov_b32_e32 v60, v15
	v_mov_b32_e32 v59, v15
	v_mov_b32_e32 v58, v15
	v_mov_b32_e32 v57, v15
	v_mov_b32_e32 v56, v15
	v_mov_b32_e32 v55, v15
	v_mov_b32_e32 v54, v15
	v_mov_b32_e32 v53, v15
	v_mov_b32_e32 v52, v15
	v_mov_b32_e32 v51, v15
	v_mov_b32_e32 v50, v15
	v_mov_b32_e32 v49, v15
	v_mov_b32_e32 v48, v15
	v_mov_b32_e32 v127, v15
	v_mov_b32_e32 v126, v15
	v_mov_b32_e32 v125, v15
	v_mov_b32_e32 v124, v15
	v_mov_b32_e32 v123, v15
	v_mov_b32_e32 v122, v15
	v_mov_b32_e32 v121, v15
	v_mov_b32_e32 v120, v15
	v_mov_b32_e32 v119, v15
	v_mov_b32_e32 v118, v15
	v_mov_b32_e32 v117, v15
	v_mov_b32_e32 v116, v15
	v_mov_b32_e32 v115, v15
	v_mov_b32_e32 v114, v15
	v_mov_b32_e32 v113, v15
	v_mov_b32_e32 v112, v15
	s_branch .LBB0_32
.LBB0_31:                               ;   in Loop: Header=BB0_4 Depth=1
	s_add_i32 s6, s89, 1
	s_mov_b32 s18, s59
.LBB0_32:                               ;   in Loop: Header=BB0_4 Depth=1
	s_mov_b32 s87, 0
	s_mov_b32 s27, 0
	s_mov_b32 s86, 0
	s_branch .LBB0_35
.LBB0_33:                               ;   in Loop: Header=BB0_35 Depth=2
	; sched_barrier mask(0x00000000)
.LBB0_34:                               ;   in Loop: Header=BB0_35 Depth=2
	v_mfma_scale_f32_16x16x128_f8f6f4 v[32:35], v[176:183], v[184:191], v[32:35], v139, v165 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	s_add_i32 s6, s27, 1
	s_and_b32 s27, s6, 3
	s_add_i32 s6, s88, 1
	s_add_i32 s86, s86, 1
	v_mov_b64_e32 v[132:133], v[208:209]
	s_cmp_lg_u32 s86, s58
	s_mov_b32 s18, s88
	v_mfma_scale_f32_16x16x128_f8f6f4 v[36:39], v[168:175], v[184:191], v[36:39], v139, v165 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	v_mov_b64_e32 v[134:135], v[210:211]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[40:43], v[216:223], v[184:191], v[40:43], v139, v165 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[44:47], v[224:231], v[184:191], v[44:47], v139, v165 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[64:67], v[176:183], v[200:207], v[64:67], v139, v165 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[68:71], v[168:175], v[200:207], v[68:71], v139, v165 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[72:75], v[216:223], v[200:207], v[72:75], v139, v165 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[76:79], v[224:231], v[200:207], v[76:79], v139, v165 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[0:3], v[176:183], v[192:199], v[0:3], v139, v165 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[4:7], v[168:175], v[192:199], v[4:7], v139, v165 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[8:11], v[216:223], v[192:199], v[8:11], v139, v165 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[12:15], v[224:231], v[192:199], v[12:15], v139, v165 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_cbranch_scc0 .LBB0_1
.LBB0_35:                               ;   Parent Loop BB0_4 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_lshl_b32 s7, s27, 10
	v_add_u32_e32 v138, s7, v147
	ds_read_b32 v165, v138
	v_add_u32_e32 v138, s7, v148
	s_mul_i32 s19, s87, 0x8400
	;;#ASMSTART
	ds_read2st64_b32 v[138:139], v138 offset0:0 offset1:2

	;;#ASMEND
	v_add_u32_e32 v167, s19, v149
	ds_read_b128 v[208:211], v167
	ds_read_b128 v[212:215], v167 offset:64
	ds_read_b128 v[184:187], v167 offset:8448
	ds_read_b128 v[188:191], v167 offset:8512
	s_mov_b32 s88, s6
	s_xor_b32 s87, s87, 1
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v166, s19, v150
	ds_read_b128 v[240:243], v166
	ds_read_b128 v[244:247], v166 offset:64
	ds_read_b128 v[232:235], v166 offset:4224
	ds_read_b128 v[236:239], v166 offset:4288
	ds_read_b128 v[224:227], v166 offset:8448
	ds_read_b128 v[228:231], v166 offset:8512
	ds_read_b128 v[216:219], v166 offset:12672
	ds_read_b128 v[220:223], v166 offset:12736
	ds_read_b128 v[176:179], v166 offset:16896
	ds_read_b128 v[180:183], v166 offset:16960
	ds_read_b128 v[168:171], v166 offset:21120
	ds_read_b128 v[172:175], v166 offset:21184
	; sched_barrier mask(0x00000000)
	s_mul_i32 s26, s87, 0x8400
	s_add_i32 s7, s39, s26
	s_lshl_b32 s6, s6, 7
	s_mov_b32 m0, s7
	s_nop 0
	buffer_load_dwordx4 v136, s[12:15], s6 offen lds
	s_add_i32 m0, s7, 0x2100
	s_nop 0
	buffer_load_dwordx4 v137, s[12:15], s6 offen lds
	s_add_i32 s6, s88, s8
	s_lshl_b32 s6, s6, 7
	s_add_i32 m0, s7, 0x4200
	s_nop 0
	buffer_load_dwordx4 v136, s[12:15], s6 offen lds
	s_add_i32 m0, s7, 0x6300
	s_nop 0
	buffer_load_dwordx4 v137, s[12:15], s6 offen lds
	; sched_barrier mask(0x00000000)
	s_and_b32 s6, s18, 3
	s_waitcnt lgkmcnt(10)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[112:115], v[240:247], v[208:215], v[112:115], v138, v165 op_sel_hi:[0,0,0]
	s_cmp_lg_u32 s6, 1
	s_waitcnt lgkmcnt(8)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[116:119], v[232:239], v[208:215], v[116:119], v138, v165 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_cbranch_scc1 .LBB0_38
; %bb.36:                               ;   in Loop: Header=BB0_35 Depth=2
	s_add_i32 s6, s18, 3
	s_cmp_ge_i32 s6, s29
	s_cbranch_scc1 .LBB0_38
; %bb.37:                               ;   in Loop: Header=BB0_35 Depth=2
	s_lshl2_add_u32 s89, s6, s85
	s_mov_b32 s6, s14
	s_mov_b32 s7, s15
	buffer_load_dwordx4 v[128:131], v140, s[4:7], s89 offen
.LBB0_38:                               ;   in Loop: Header=BB0_35 Depth=2
	ds_read_b128 v[200:203], v167 offset:16896
	ds_read_b128 v[204:207], v167 offset:16960
	s_waitcnt lgkmcnt(8)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[120:123], v[224:231], v[208:215], v[120:123], v138, v165 op_sel_hi:[1,0,0]
	ds_read_b128 v[192:195], v167 offset:25344
	ds_read_b128 v[196:199], v167 offset:25408
	s_waitcnt lgkmcnt(8)
	s_and_b32 s89, s88, 3
	s_cmp_lt_i32 s89, 2
	s_mov_b64 s[6:7], -1
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[124:127], v[216:223], v[208:215], v[124:127], v138, v165 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[48:51], v[240:247], v[184:191], v[48:51], v138, v165 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[52:55], v[232:239], v[184:191], v[52:55], v138, v165 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[56:59], v[224:231], v[184:191], v[56:59], v138, v165 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[60:63], v[216:223], v[184:191], v[60:63], v138, v165 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[80:83], v[240:247], v[200:207], v[80:83], v138, v165 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[84:87], v[232:239], v[200:207], v[84:87], v138, v165 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[88:91], v[224:231], v[200:207], v[88:91], v138, v165 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[92:95], v[216:223], v[200:207], v[92:95], v138, v165 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[16:19], v[240:247], v[192:199], v[16:19], v138, v165 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[20:23], v[232:239], v[192:199], v[20:23], v138, v165 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[24:27], v[224:231], v[192:199], v[24:27], v138, v165 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[28:31], v[216:223], v[192:199], v[28:31], v138, v165 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[216:219], v166 offset:25344
	ds_read_b128 v[220:223], v166 offset:25408
	ds_read_b128 v[224:227], v166 offset:29568
	ds_read_b128 v[228:231], v166 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[96:99], v[176:183], v[208:215], v[96:99], v139, v165 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[100:103], v[168:175], v[208:215], v[100:103], v139, v165 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[104:107], v[216:223], v[208:215], v[104:107], v139, v165 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[108:111], v[224:231], v[208:215], v[108:111], v139, v165 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
                                        ; implicit-def: $vgpr208_vgpr209_vgpr210_vgpr211
	s_cbranch_scc1 .LBB0_43
; %bb.39:                               ;   in Loop: Header=BB0_35 Depth=2
	v_mov_b64_e32 v[210:211], v[134:135]
	s_cmp_eq_u32 s89, 2
	v_mov_b64_e32 v[208:209], v[132:133]
	s_cbranch_scc0 .LBB0_42
; %bb.40:                               ;   in Loop: Header=BB0_35 Depth=2
	v_mov_b32_e32 v138, v134
	v_mov_b32_e32 v166, v135
	s_nop 1
	v_permlane16_swap_b32_e64 v138, v166 bound_ctrl:1
	s_cmp_ge_i32 s18, s55
	v_perm_b32 v167, v166, v138, s80
	v_perm_b32 v138, v166, v138, s81
	s_nop 1
	v_permlane32_swap_b32_e64 v167, v138 bound_ctrl:1
	v_perm_b32 v166, v138, v167, s82
	v_perm_b32 v138, v138, v167, s83
	;;#ASMSTART
	ds_write2_b32 v161, v138, v166 offset0:0 offset1:2

	;;#ASMEND
	v_mov_b64_e32 v[210:211], v[134:135]
	v_mov_b64_e32 v[208:209], v[132:133]
	s_cbranch_scc1 .LBB0_42
; %bb.41:                               ;   in Loop: Header=BB0_35 Depth=2
	v_mov_b64_e32 v[210:211], v[134:135]
	v_mov_b64_e32 v[208:209], v[132:133]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt vmcnt(0)
	v_mov_b64_e32 v[210:211], v[130:131]
	v_mov_b64_e32 v[208:209], v[128:129]
.LBB0_42:                               ;   in Loop: Header=BB0_35 Depth=2
	s_mov_b64 s[6:7], 0
.LBB0_43:                               ;   in Loop: Header=BB0_35 Depth=2
	s_andn2_b64 vcc, exec, s[6:7]
	s_cbranch_vccnz .LBB0_47
; %bb.44:                               ;   in Loop: Header=BB0_35 Depth=2
	s_cmp_eq_u32 s89, 0
	s_cbranch_scc0 .LBB0_46
; %bb.45:                               ;   in Loop: Header=BB0_35 Depth=2
	v_mov_b32_e32 v138, v132
	v_mov_b32_e32 v166, v133
	s_nop 1
	v_permlane16_swap_b32_e64 v138, v166 bound_ctrl:1
	v_perm_b32 v167, v166, v138, s80
	v_perm_b32 v138, v166, v138, s81
	s_nop 1
	v_permlane32_swap_b32_e64 v167, v138 bound_ctrl:1
	v_perm_b32 v166, v138, v167, s82
	v_perm_b32 v138, v138, v167, s83
	;;#ASMSTART
	ds_write2_b32 v160, v138, v166 offset0:0 offset1:2

	;;#ASMEND
.LBB0_46:                               ;   in Loop: Header=BB0_35 Depth=2
	v_mov_b64_e32 v[210:211], v[134:135]
	v_mov_b64_e32 v[208:209], v[132:133]
.LBB0_47:                               ;   in Loop: Header=BB0_35 Depth=2
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s6, s18, 2
	s_cmp_ge_i32 s6, s29
	s_cbranch_scc1 .LBB0_34
; %bb.48:                               ;   in Loop: Header=BB0_35 Depth=2
	s_andn2_b64 vcc, exec, s[20:21]
	s_cbranch_vccnz .LBB0_33
; %bb.49:                               ;   in Loop: Header=BB0_35 Depth=2
	s_add_i32 s18, s19, s38
	s_add_i32 s89, s18, 0x10800
	s_lshl_b32 s7, s6, 7
	s_mov_b32 s18, s14
	s_mov_b32 s19, s15
	s_mov_b32 m0, s89
	s_add_i32 s6, s6, s9
	buffer_load_dwordx4 v141, s[16:19], s7 offen lds
	s_add_i32 m0, s89, 0x2100
	s_lshl_b32 s6, s6, 7
	buffer_load_dwordx4 v144, s[16:19], s7 offen lds
	s_add_i32 m0, s89, 0x1080
	s_nop 0
	buffer_load_dwordx4 v145, s[16:19], s7 offen lds
	s_add_i32 m0, s89, 0x3180
	s_nop 0
	buffer_load_dwordx4 v146, s[16:19], s7 offen lds
	s_add_i32 m0, s89, 0x4200
	s_nop 0
	buffer_load_dwordx4 v141, s[16:19], s6 offen lds
	s_add_i32 m0, s89, 0x6300
	s_nop 0
	buffer_load_dwordx4 v144, s[16:19], s6 offen lds
	s_add_i32 m0, s89, 0x5280
	s_nop 0
	buffer_load_dwordx4 v145, s[16:19], s6 offen lds
	s_add_i32 m0, s89, 0x7380
	s_nop 0
	buffer_load_dwordx4 v146, s[16:19], s6 offen lds
	s_branch .LBB0_33
.LBB0_50:
	s_endpgm
.Lfunc_end0:
	.size	_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs, .Lfunc_end0-_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
		.amdhsa_group_segment_fixed_size 143360
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
		.amdhsa_next_free_vgpr 248
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 248
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
	.section	.text._Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,"axG",@progbits,_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,comdat
                                        ; -- End function
	.set .L_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_vgpr, 248
	.set .L_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_agpr, 0
	.set .L_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.numbered_sgpr, 91
	.set .L_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_named_barrier, 0
	.set .L_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.private_seg_size, 0
	.set .L_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_vcc, 1
	.set .L_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_flat_scratch, 0
	.set .L_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_dyn_sized_stack, 0
	.set .L_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_recursion, 0
	.set .L_Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 10304
; TotalNumSgprs: 97
; NumVgprs: 248
; NumAgprs: 0
; TotalNumVgprs: 248
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 143360 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 30
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 248
; AccumOffset: 248
; Occupancy: 2
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 61
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.section	.AMDGPU.csdata,"",@progbits
	.type	__hip_cuid_c8f666a35ee4ad17,@object ; @__hip_cuid_c8f666a35ee4ad17
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_c8f666a35ee4ad17
__hip_cuid_c8f666a35ee4ad17:
	.byte	0                               ; 0x0
	.size	__hip_cuid_c8f666a35ee4ad17, 1

	.ident	"clang version 23.0.0git (https://github.com/ROCm/llvm-project.git 46fcb339fb61119b337f973c7ca9e710a319fdd0)"
	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.0 26014 7b800a19466229b8479a78de19143dc33c3ab9b5)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_c8f666a35ee4ad17
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .offset:         0
        .size:           96
        .value_kind:     by_value
    .gfx1250_revision: B0
    .group_segment_fixed_size: 143360
    .kernarg_segment_align: 8
    .kernarg_segment_size: 96
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           _Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
    .private_segment_fixed_size: 0
    .sgpr_count:     97
    .sgpr_spill_count: 0
    .symbol:         _Z63gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_unified_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     248
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
