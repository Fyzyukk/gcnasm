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
	s_ashr_i32 s30, s0, 8
	s_add_i32 s0, s5, 0xff
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 24
	s_add_i32 s0, s0, s1
	s_ashr_i32 s31, s0, 8
	s_add_i32 s0, s31, 1
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
	s_ashr_i32 s33, s5, 7
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
	s_lshl_b32 s35, s1, 1
	s_mul_i32 s1, s1, s0
	s_sub_i32 s0, s2, s1
	s_lshl_b32 s36, s0, 1
	s_mul_i32 s0, s11, s3
	s_ashr_i32 s1, s0, 31
	s_add_u32 s11, s20, s0
	s_mul_i32 s0, s26, s3
	s_addc_u32 s37, s21, s1
	s_ashr_i32 s1, s0, 31
	s_add_u32 s38, s22, s0
	s_mul_i32 s0, s27, s3
	s_addc_u32 s39, s23, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s40, s24, s0
	s_mul_i32 s0, s18, s3
	s_addc_u32 s41, s25, s1
	s_ashr_i32 s1, s0, 31
	s_add_u32 s42, s12, s0
	s_mul_i32 s0, s19, s3
	s_addc_u32 s43, s13, s1
	s_ashr_i32 s1, s0, 31
	v_and_b32_e32 v3, 3, v0
	v_lshlrev_b32_e32 v4, 5, v0
	s_add_u32 s45, s14, s0
	v_mul_u32_u24_e32 v3, 0x420, v3
	v_and_b32_e32 v4, 0x180, v4
	v_and_b32_e32 v5, 48, v0
	s_addc_u32 s46, s15, s1
	s_lshl_b32 s48, s8, 6
	v_add3_u32 v131, v3, v5, v4
	s_lshl_b32 s49, s9, 6
	v_lshrrev_b32_e32 v3, 2, v0
	s_lshl_b32 s50, s8, 7
	s_lshl_b32 s51, s9, 7
	v_lshlrev_b32_e32 v2, 4, v0
	v_and_b32_e32 v137, 12, v3
	s_movk_i32 s0, 0xf0
	s_cmpk_lt_i32 s4, 0x100
	v_and_or_b32 v138, v2, s0, v137
	s_cselect_b64 s[0:1], -1, 0
	s_max_i32 s2, s33, 2
	s_lshl_b32 s56, s10, 9
	s_add_i32 s2, s2, -1
	s_add_i32 s53, s51, 0x80
	s_lshl_b32 s54, s8, 8
	s_lshl_b32 s55, s9, 8
	s_add_i32 s58, s56, 0x200
	s_and_b32 s59, s2, 3
	s_cmpk_gt_i32 s4, 0x27f
	s_cselect_b64 s[18:19], -1, 0
	s_and_b32 s60, s2, -4
	v_lshrrev_b32_e32 v1, 1, v0
	s_cmp_lg_u32 s59, 0
	s_mov_b32 s34, 0
	s_mul_i32 s44, s16, s33
	s_mul_i32 s47, s17, s33
	v_and_b32_e32 v1, 28, v1
	v_and_b32_e32 v130, 0x70, v2
	v_and_b32_e32 v136, 0x3f0, v2
	s_movk_i32 s52, 0x80
	v_and_b32_e32 v139, 15, v0
	s_movk_i32 s57, 0x200
	s_mov_b32 s6, -1
	s_cselect_b64 s[24:25], -1, 0
	s_mov_b32 s7, 0x20000
	s_and_b64 s[0:1], exec, s[0:1]
	s_mov_b32 s65, 0
	s_branch .LBB0_3
.LBB0_1:                                ;   in Loop: Header=BB0_3 Depth=1
	s_mul_i32 s2, s27, s10
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[2:3], s[2:3], 2
	s_add_u32 s4, s40, s2
	s_addc_u32 s5, s41, s3
	s_ashr_i32 s27, s26, 31
	s_lshl_b64 s[2:3], s[26:27], 2
	s_add_u32 s4, s4, s2
	v_lshl_or_b32 v133, s61, 4, v139
	s_addc_u32 s2, s5, s3
	v_lshl_or_b32 v132, s62, 4, v137
	v_mul_lo_u32 v134, v133, s10
	s_and_b32 s5, s2, 0xffff
	v_add_u32_e32 v135, 32, v132
	v_or_b32_e32 v133, 64, v133
	v_add_lshl_u32 v142, v134, v132, 2
	v_add_u32_e32 v140, 64, v132
	v_add_u32_e32 v141, 0x60, v132
	v_mul_lo_u32 v133, v133, s10
	buffer_store_dwordx4 v[98:101], v142, s[4:7], 0 offen nt
	s_nop 1
	v_add_lshl_u32 v98, v134, v135, 2
	buffer_store_dwordx4 v[102:105], v98, s[4:7], 0 offen nt
	v_add_lshl_u32 v99, v134, v140, 2
	v_add_lshl_u32 v100, v134, v141, 2
	v_add_lshl_u32 v101, v133, v132, 2
	v_add_lshl_u32 v102, v133, v135, 2
	v_add_lshl_u32 v103, v133, v140, 2
	v_add_lshl_u32 v104, v133, v141, 2
	buffer_store_dwordx4 v[106:109], v99, s[4:7], 0 offen nt
	buffer_store_dwordx4 v[110:113], v100, s[4:7], 0 offen nt
	buffer_store_dwordx4 v[114:117], v101, s[4:7], 0 offen nt
	buffer_store_dwordx4 v[118:121], v102, s[4:7], 0 offen nt
	buffer_store_dwordx4 v[122:125], v103, s[4:7], 0 offen nt
	buffer_store_dwordx4 v[126:129], v104, s[4:7], 0 offen nt
	buffer_store_dwordx4 v[82:85], v142, s[4:7], s57 offen nt
	buffer_store_dwordx4 v[86:89], v98, s[4:7], s57 offen nt
	buffer_store_dwordx4 v[90:93], v99, s[4:7], s57 offen nt
	buffer_store_dwordx4 v[94:97], v100, s[4:7], s57 offen nt
	buffer_store_dwordx4 v[66:69], v101, s[4:7], s57 offen nt
	buffer_store_dwordx4 v[70:73], v102, s[4:7], s57 offen nt
	buffer_store_dwordx4 v[74:77], v103, s[4:7], s57 offen nt
	buffer_store_dwordx4 v[78:81], v104, s[4:7], s57 offen nt
	buffer_store_dwordx4 v[50:53], v142, s[4:7], s56 offen nt
	buffer_store_dwordx4 v[54:57], v98, s[4:7], s56 offen nt
	buffer_store_dwordx4 v[58:61], v99, s[4:7], s56 offen nt
	buffer_store_dwordx4 v[62:65], v100, s[4:7], s56 offen nt
	buffer_store_dwordx4 v[34:37], v101, s[4:7], s56 offen nt
	buffer_store_dwordx4 v[38:41], v102, s[4:7], s56 offen nt
	buffer_store_dwordx4 v[42:45], v103, s[4:7], s56 offen nt
	buffer_store_dwordx4 v[46:49], v104, s[4:7], s56 offen nt
	buffer_store_dwordx4 v[18:21], v142, s[4:7], s58 offen nt
	buffer_store_dwordx4 v[22:25], v98, s[4:7], s58 offen nt
	buffer_store_dwordx4 v[26:29], v99, s[4:7], s58 offen nt
	buffer_store_dwordx4 v[30:33], v100, s[4:7], s58 offen nt
	buffer_store_dwordx4 v[2:5], v101, s[4:7], s58 offen nt
	buffer_store_dwordx4 v[6:9], v102, s[4:7], s58 offen nt
	buffer_store_dwordx4 v[10:13], v103, s[4:7], s58 offen nt
	buffer_store_dwordx4 v[14:17], v104, s[4:7], s58 offen nt
.LBB0_2:                                ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_eq_u32 s12, 4
	s_mov_b32 s65, s12
	s_cbranch_scc1 .LBB0_82
.LBB0_3:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_22 Depth 2
                                        ;     Child Loop BB0_63 Depth 2
	s_lshr_b32 s5, s65, 1
	s_and_b32 s2, s65, 1
	s_or_b32 s5, s5, s35
	s_or_b32 s4, s2, s36
	s_cmp_lt_i32 s5, s30
	s_cselect_b64 s[2:3], -1, 0
	s_cmp_lt_i32 s4, s31
	s_cselect_b64 s[12:13], -1, 0
	s_and_b64 s[12:13], s[2:3], s[12:13]
	s_mov_b64 s[2:3], -1
	s_and_b64 vcc, exec, s[12:13]
                                        ; implicit-def: $sgpr12
	s_cbranch_vccz .LBB0_5
; %bb.4:                                ; %Flow4375
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_andn2_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_2
	s_branch .LBB0_6
.LBB0_5:                                ; %._crit_edge2641
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_add_i32 s12, s65, 1
	s_cbranch_execnz .LBB0_2
.LBB0_6:                                ;   in Loop: Header=BB0_3 Depth=1
	s_lshl_b32 s27, s5, 8
	v_readfirstlane_b32 s67, v0
	s_mul_i32 s2, s27, s8
	s_lshl_b32 s26, s4, 8
	s_lshr_b32 s66, s67, 6
	s_ashr_i32 s3, s2, 31
	s_add_u32 s12, s11, s2
	s_addc_u32 s2, s37, s3
	s_and_b32 s13, s2, 0xffff
	s_mul_i32 s2, s26, s9
	s_ashr_i32 s3, s2, 31
	s_add_u32 s20, s38, s2
	s_addc_u32 s2, s39, s3
	s_and_b32 s21, s2, 0xffff
	s_mul_i32 s2, s44, s5
	s_ashr_i32 s3, s2, 31
	s_add_u32 s2, s42, s2
	s_addc_u32 s3, s43, s3
	s_mul_i32 s4, s47, s4
	s_and_b32 s3, s3, 0xffff
	s_ashr_i32 s5, s4, 31
	s_add_u32 s28, s45, s4
	s_addc_u32 s4, s46, s5
	s_lshr_b32 s62, s67, 8
	s_bfe_u32 s61, s67, 0x20006
	v_lshl_or_b32 v2, s62, 5, v1
	v_or_b32_e32 v2, s61, v2
	s_and_b32 s29, s4, 0xffff
	v_mad_u64_u32 v[134:135], s[4:5], v2, s8, v[130:131]
	v_mad_u64_u32 v[132:133], s[4:5], v2, s9, v[130:131]
	s_mov_b32 s14, s6
	s_mov_b32 s15, s7
	v_add_u32_e32 v135, s48, v134
	v_add_u32_e32 v133, s49, v132
	s_cmp_lg_u32 s65, 0
	s_mul_i32 s63, s62, 0x1080
	s_mul_i32 s64, s61, 0x420
	s_cbranch_scc1 .LBB0_15
; %bb.7:                                ; %NodeBlock
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_lt_i32 s66, 1
	s_cbranch_scc1 .LBB0_10
; %bb.8:                                ; %LeafBlock
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_eq_u32 s66, 1
	s_cbranch_scc0 .LBB0_11
; %bb.9:                                ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b64 s[22:23], -1
	s_mov_b32 s68, 0x21800
	s_branch .LBB0_12
.LBB0_10:                               ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b32 s68, 0x21000
	s_mov_b64 s[4:5], s[2:3]
	s_cbranch_execnz .LBB0_13
	s_branch .LBB0_14
.LBB0_11:                               ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b64 s[22:23], 0
	s_mov_b32 s68, 0x21000
.LBB0_12:                               ; %Flow4373
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b64 s[4:5], s[28:29]
	s_and_b64 vcc, exec, s[22:23]
	s_cbranch_vccz .LBB0_14
.LBB0_13:                               ; %.sink.split
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_lshl_b32 s22, s34, 10
	s_add_i32 m0, s22, s68
	s_nop 0
	buffer_load_dwordx4 v136, s[4:7], 0 offen lds
.LBB0_14:                               ;   in Loop: Header=BB0_3 Depth=1
	s_mul_i32 s4, s34, 0x8400
	s_add_i32 s4, s63, s4
	s_add_i32 s4, s4, s64
	s_mov_b32 m0, s4
	s_add_i32 s5, s4, 0x10800
	buffer_load_dwordx4 v134, s[12:15], 0 offen lds
	s_add_i32 m0, s4, 0x2100
	s_mov_b32 s22, s14
	buffer_load_dwordx4 v135, s[12:15], 0 offen lds
	s_mov_b32 s23, s15
	s_mov_b32 m0, s5
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], 0 offen lds
	s_add_i32 m0, s5, 0x2100
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], 0 offen lds
	s_add_i32 m0, s4, 0x4200
	s_nop 0
	buffer_load_dwordx4 v134, s[12:15], s50 offen lds
	s_add_i32 m0, s4, 0x6300
	s_nop 0
	buffer_load_dwordx4 v135, s[12:15], s50 offen lds
	s_add_i32 m0, s5, 0x4200
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s51 offen lds
	s_add_i32 m0, s5, 0x6300
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s51 offen lds
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
.LBB0_15:                               ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_gt_u32 s61, 1
	s_cselect_b32 s22, 0x1080, 0
	s_lshl_b32 s4, s61, 9
	s_add_i32 s5, s4, 0xfffffc00
	s_cmp_lt_u32 s61, 2
	s_cselect_b32 s68, s4, s5
	s_and_b32 s23, s67, 0xffffff00
	v_add_u32_e32 v140, s23, v138
	s_mov_b64 vcc, s[0:1]
	s_cbranch_vccz .LBB0_17
; %bb.16:                               ; %.._crit_edge_crit_edge
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_mul_i32 s67, s34, 0x8400
	s_mov_b64 s[4:5], 0
	s_branch .LBB0_18
.LBB0_17:                               ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b64 s[4:5], -1
                                        ; implicit-def: $sgpr67
.LBB0_18:                               ; %Flow4371
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_add_i32 s68, s68, s22
	v_lshl_add_u32 v2, s62, 9, v131
	v_add_u32_e32 v142, s68, v131
	v_lshl_or_b32 v144, s61, 8, v138
	v_or_b32_e32 v143, s23, v138
	s_andn2_b64 vcc, exec, s[4:5]
	v_add_u32_e32 v141, 0x10800, v2
	s_cbranch_vccnz .LBB0_58
; %bb.19:                               ; %.lr.ph
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_lshl_b32 s4, s34, 1
	s_xor_b32 s4, s4, 2
	s_mulk_i32 s4, 0x4200
	s_add_i32 s4, s63, s4
	s_add_i32 s4, s4, s64
	s_add_i32 s4, s4, 0x10800
	s_mov_b32 s22, s14
	s_mov_b32 s23, s15
	s_mov_b32 m0, s4
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s52 offen lds
	s_add_i32 m0, s4, 0x2100
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s52 offen lds
	s_add_i32 m0, s4, 0x4200
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s53 offen lds
	s_add_i32 m0, s4, 0x6300
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s53 offen lds
	s_mov_b32 s22, 1
	; sched_barrier mask(0x00000000)
	v_or_b32_e32 v145, 0x21000, v144
	v_add_u32_e32 v146, 0x21800, v143
	v_add_u32_e32 v147, 0x21800, v140
	s_andn2_b64 vcc, exec, s[18:19]
	s_add_i32 s68, s64, s63
	s_cbranch_vccnz .LBB0_59
; %bb.20:                               ; %.lr.ph.new
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_xor_b32 s71, s34, 1
	s_mul_i32 s67, s34, 0x8400
	s_lshl_b32 s70, s71, 10
	s_mul_i32 s71, s71, 0x8400
	s_add_i32 s72, s68, s71
	s_add_i32 s76, s68, s67
	s_lshl_b32 s69, s34, 10
	s_add_i32 s73, s72, 0x2100
	s_add_i32 s77, s76, 0x10800
	s_add_i32 s78, s76, 0x12900
	s_add_i32 s81, s76, 0x2100
	s_add_i32 s84, s72, 0x10800
	s_add_i32 s85, s72, 0x12900
	v_mov_b32_e32 v98, 0
	s_add_i32 s74, s72, 0x4200
	s_add_i32 s75, s73, 0x4200
	s_add_i32 s79, s77, 0x4200
	s_add_i32 s80, s78, 0x4200
	s_add_i32 s82, s76, 0x4200
	s_add_i32 s83, s81, 0x4200
	s_add_i32 s86, s84, 0x4200
	s_add_i32 s87, s85, 0x4200
	s_mov_b32 s4, 0
	v_add_u32_e32 v148, s69, v145
	v_add_u32_e32 v149, s69, v146
	v_add_u32_e32 v150, s67, v142
	v_add_u32_e32 v151, s67, v141
	v_add_u32_e32 v152, s69, v147
	s_mov_b32 s91, 0
	v_mov_b32_e32 v99, v98
	v_mov_b32_e32 v100, v98
	v_mov_b32_e32 v101, v98
	v_mov_b32_e32 v102, v98
	v_mov_b32_e32 v103, v98
	v_mov_b32_e32 v104, v98
	v_mov_b32_e32 v105, v98
	v_mov_b32_e32 v106, v98
	v_mov_b32_e32 v107, v98
	v_mov_b32_e32 v108, v98
	v_mov_b32_e32 v109, v98
	v_mov_b32_e32 v110, v98
	v_mov_b32_e32 v111, v98
	v_mov_b32_e32 v112, v98
	v_mov_b32_e32 v113, v98
	v_mov_b32_e32 v114, v98
	v_mov_b32_e32 v115, v98
	v_mov_b32_e32 v116, v98
	v_mov_b32_e32 v117, v98
	v_mov_b32_e32 v118, v98
	v_mov_b32_e32 v119, v98
	v_mov_b32_e32 v120, v98
	v_mov_b32_e32 v121, v98
	v_mov_b32_e32 v122, v98
	v_mov_b32_e32 v123, v98
	v_mov_b32_e32 v124, v98
	v_mov_b32_e32 v125, v98
	v_mov_b32_e32 v126, v98
	v_mov_b32_e32 v127, v98
	v_mov_b32_e32 v128, v98
	v_mov_b32_e32 v129, v98
	v_mov_b32_e32 v82, v98
	v_mov_b32_e32 v83, v98
	v_mov_b32_e32 v84, v98
	v_mov_b32_e32 v85, v98
	v_mov_b32_e32 v86, v98
	v_mov_b32_e32 v87, v98
	v_mov_b32_e32 v88, v98
	v_mov_b32_e32 v89, v98
	v_mov_b32_e32 v90, v98
	v_mov_b32_e32 v91, v98
	v_mov_b32_e32 v92, v98
	v_mov_b32_e32 v93, v98
	v_mov_b32_e32 v94, v98
	v_mov_b32_e32 v95, v98
	v_mov_b32_e32 v96, v98
	v_mov_b32_e32 v97, v98
	v_mov_b32_e32 v66, v98
	v_mov_b32_e32 v67, v98
	v_mov_b32_e32 v68, v98
	v_mov_b32_e32 v69, v98
	v_mov_b32_e32 v70, v98
	v_mov_b32_e32 v71, v98
	v_mov_b32_e32 v72, v98
	v_mov_b32_e32 v73, v98
	v_mov_b32_e32 v74, v98
	v_mov_b32_e32 v75, v98
	v_mov_b32_e32 v76, v98
	v_mov_b32_e32 v77, v98
	v_mov_b32_e32 v78, v98
	v_mov_b32_e32 v79, v98
	v_mov_b32_e32 v80, v98
	v_mov_b32_e32 v81, v98
	v_mov_b32_e32 v50, v98
	v_mov_b32_e32 v51, v98
	v_mov_b32_e32 v52, v98
	v_mov_b32_e32 v53, v98
	v_mov_b32_e32 v54, v98
	v_mov_b32_e32 v55, v98
	v_mov_b32_e32 v56, v98
	v_mov_b32_e32 v57, v98
	v_mov_b32_e32 v58, v98
	v_mov_b32_e32 v59, v98
	v_mov_b32_e32 v60, v98
	v_mov_b32_e32 v61, v98
	v_mov_b32_e32 v62, v98
	v_mov_b32_e32 v63, v98
	v_mov_b32_e32 v64, v98
	v_mov_b32_e32 v65, v98
	v_mov_b32_e32 v34, v98
	v_mov_b32_e32 v35, v98
	v_mov_b32_e32 v36, v98
	v_mov_b32_e32 v37, v98
	v_mov_b32_e32 v38, v98
	v_mov_b32_e32 v39, v98
	v_mov_b32_e32 v40, v98
	v_mov_b32_e32 v41, v98
	v_mov_b32_e32 v42, v98
	v_mov_b32_e32 v43, v98
	v_mov_b32_e32 v44, v98
	v_mov_b32_e32 v45, v98
	v_mov_b32_e32 v46, v98
	v_mov_b32_e32 v47, v98
	v_mov_b32_e32 v48, v98
	v_mov_b32_e32 v49, v98
	v_mov_b32_e32 v18, v98
	v_mov_b32_e32 v19, v98
	v_mov_b32_e32 v20, v98
	v_mov_b32_e32 v21, v98
	v_mov_b32_e32 v22, v98
	v_mov_b32_e32 v23, v98
	v_mov_b32_e32 v24, v98
	v_mov_b32_e32 v25, v98
	v_mov_b32_e32 v26, v98
	v_mov_b32_e32 v27, v98
	v_mov_b32_e32 v28, v98
	v_mov_b32_e32 v29, v98
	v_mov_b32_e32 v30, v98
	v_mov_b32_e32 v31, v98
	v_mov_b32_e32 v32, v98
	v_mov_b32_e32 v33, v98
	v_mov_b32_e32 v2, v98
	v_mov_b32_e32 v3, v98
	v_mov_b32_e32 v4, v98
	v_mov_b32_e32 v5, v98
	v_mov_b32_e32 v6, v98
	v_mov_b32_e32 v7, v98
	v_mov_b32_e32 v8, v98
	v_mov_b32_e32 v9, v98
	v_mov_b32_e32 v10, v98
	v_mov_b32_e32 v11, v98
	v_mov_b32_e32 v12, v98
	v_mov_b32_e32 v13, v98
	v_mov_b32_e32 v14, v98
	v_mov_b32_e32 v15, v98
	v_mov_b32_e32 v16, v98
	v_mov_b32_e32 v17, v98
	s_branch .LBB0_22
	.p2align	5
.LBB0_21:                               ;   in Loop: Header=BB0_22 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[168:175], v[176:183], v[66:69], v156, v155 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[160:167], v[176:183], v[70:73], v156, v155 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[216:223], v[176:183], v[74:77], v156, v155 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[208:215], v[176:183], v[78:81], v156, v155 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[168:175], v[192:199], v[18:21], v156, v155 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[160:167], v[192:199], v[22:25], v156, v155 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[216:223], v[192:199], v[26:29], v156, v155 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[208:215], v[192:199], v[30:33], v156, v155 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[168:175], v[184:191], v[2:5], v156, v155 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[160:167], v[184:191], v[6:9], v156, v155 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[216:223], v[184:191], v[10:13], v156, v155 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[208:215], v[184:191], v[14:17], v156, v155 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_cmp_lg_u32 s60, s91
	s_cbranch_scc0 .LBB0_60
.LBB0_22:                               ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ds_read_b32 v153, v148
	ds_read_b32 v155, v149
	ds_read_b128 v[188:191], v150
	ds_read_b128 v[192:195], v150 offset:64
	ds_read_b128 v[172:175], v150 offset:8448
	ds_read_b128 v[176:179], v150 offset:8512
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[228:231], v151
	ds_read_b128 v[232:235], v151 offset:64
	ds_read_b128 v[220:223], v151 offset:4224
	ds_read_b128 v[224:227], v151 offset:4288
	ds_read_b128 v[212:215], v151 offset:8448
	ds_read_b128 v[216:219], v151 offset:8512
	ds_read_b128 v[204:207], v151 offset:12672
	ds_read_b128 v[208:211], v151 offset:12736
	ds_read_b128 v[164:167], v151 offset:16896
	ds_read_b128 v[168:171], v151 offset:16960
	ds_read_b128 v[156:159], v151 offset:21120
	ds_read_b128 v[160:163], v151 offset:21184
	ds_read_b32 v154, v152 offset:512
	; sched_barrier mask(0x00000000)
	s_mov_b32 s89, s91
	s_mov_b32 s88, s4
	s_cmp_lt_i32 s66, 1
	s_cbranch_scc1 .LBB0_25
; %bb.23:                               ; %LeafBlock4257
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_cmp_eq_u32 s66, 1
	s_cbranch_scc0 .LBB0_26
; %bb.24:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b64 s[22:23], -1
	s_mov_b32 s90, 0x21800
	s_branch .LBB0_27
	.p2align	5
.LBB0_25:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 s90, 0x21000
	s_mov_b32 s91, s16
	s_mov_b64 s[4:5], s[2:3]
	s_cbranch_execnz .LBB0_28
	s_branch .LBB0_29
	.p2align	5
.LBB0_26:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b64 s[22:23], 0
	s_mov_b32 s90, 0x21000
.LBB0_27:                               ; %Flow4365
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 s91, s17
	s_mov_b64 s[4:5], s[28:29]
	s_and_b64 vcc, exec, s[22:23]
	s_cbranch_vccz .LBB0_29
.LBB0_28:                               ; %.sink.split.i
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_add_i32 s22, s89, 1
	s_cmp_lg_u32 s90, -1
	s_cselect_b32 s23, s90, 0
	s_mul_i32 s22, s91, s22
	s_add_i32 m0, s70, s23
	s_nop 0
	buffer_load_dwordx4 v136, s[4:7], s22 offen lds
.LBB0_29:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 m0, s72
	s_add_i32 s4, s88, 0x80
	buffer_load_dwordx4 v134, s[12:15], s4 offen lds
	s_mov_b32 m0, s73
	s_add_i32 s90, s50, s88
	buffer_load_dwordx4 v135, s[12:15], s4 offen lds
	s_add_i32 s4, s90, 0x80
	s_mov_b32 m0, s74
	s_nop 0
	buffer_load_dwordx4 v134, s[12:15], s4 offen lds
	s_mov_b32 m0, s75
	s_nop 0
	buffer_load_dwordx4 v135, s[12:15], s4 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[228:235], v[188:195], v[98:101], v155, v153 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[220:227], v[188:195], v[102:105], v155, v153 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[196:199], v150 offset:16896
	ds_read_b128 v[200:203], v150 offset:16960
	ds_read_b128 v[180:183], v150 offset:25344
	ds_read_b128 v[184:187], v150 offset:25408
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[212:219], v[188:195], v[106:109], v155, v153 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[204:211], v[188:195], v[110:113], v155, v153 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[228:235], v[172:179], v[114:117], v155, v153 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[220:227], v[172:179], v[118:121], v155, v153 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[212:219], v[172:179], v[122:125], v155, v153 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[204:211], v[172:179], v[126:129], v155, v153 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[228:235], v[196:203], v[50:53], v155, v153 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[220:227], v[196:203], v[54:57], v155, v153 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[212:219], v[196:203], v[58:61], v155, v153 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[204:211], v[196:203], v[62:65], v155, v153 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[228:235], v[180:187], v[34:37], v155, v153 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[220:227], v[180:187], v[38:41], v155, v153 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[212:219], v[180:187], v[42:45], v155, v153 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[204:211], v[180:187], v[46:49], v155, v153 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[212:215], v151 offset:25344
	ds_read_b128 v[216:219], v151 offset:25408
	ds_read_b128 v[204:207], v151 offset:29568
	ds_read_b128 v[208:211], v151 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[164:171], v[188:195], v[82:85], v154, v153 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[156:163], v[188:195], v[86:89], v154, v153 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[212:219], v[188:195], v[90:93], v154, v153 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[204:211], v[188:195], v[94:97], v154, v153 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s91, s89, 2
	s_cmp_ge_i32 s91, s33
	s_cbranch_scc1 .LBB0_31
; %bb.30:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 m0, s77
	s_add_i32 s4, s88, 0x100
	s_mov_b32 s22, s14
	s_mov_b32 s23, s15
	buffer_load_dwordx4 v132, s[20:23], s4 offen lds
	s_mov_b32 m0, s78
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s4 offen lds
	s_add_i32 s4, s4, s51
	s_mov_b32 m0, s79
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s4 offen lds
	s_mov_b32 m0, s80
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s4 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_31:                               ;   in Loop: Header=BB0_22 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[164:171], v[172:179], v[66:69], v154, v153 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[156:163], v[172:179], v[70:73], v154, v153 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[212:219], v[172:179], v[74:77], v154, v153 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[204:211], v[172:179], v[78:81], v154, v153 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[164:171], v[196:203], v[18:21], v154, v153 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[156:163], v[196:203], v[22:25], v154, v153 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[212:219], v[196:203], v[26:29], v154, v153 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[204:211], v[196:203], v[30:33], v154, v153 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[164:171], v[180:187], v[2:5], v154, v153 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[156:163], v[180:187], v[6:9], v154, v153 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[212:219], v[180:187], v[10:13], v154, v153 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[204:211], v[180:187], v[14:17], v154, v153 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	v_add_u32_e32 v155, s70, v145
	v_add_u32_e32 v156, s70, v146
	v_add_u32_e32 v154, s71, v142
	ds_read_b32 v158, v155
	ds_read_b32 v160, v156
	ds_read_b128 v[202:205], v154
	ds_read_b128 v[206:209], v154 offset:64
	ds_read_b128 v[178:181], v154 offset:8448
	ds_read_b128 v[182:185], v154 offset:8512
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v153, s71, v141
	v_add_u32_e32 v157, s70, v147
	ds_read_b128 v[234:237], v153
	ds_read_b128 v[238:241], v153 offset:64
	ds_read_b128 v[226:229], v153 offset:4224
	ds_read_b128 v[230:233], v153 offset:4288
	ds_read_b128 v[218:221], v153 offset:8448
	ds_read_b128 v[222:225], v153 offset:8512
	ds_read_b128 v[210:213], v153 offset:12672
	ds_read_b128 v[214:217], v153 offset:12736
	ds_read_b128 v[170:173], v153 offset:16896
	ds_read_b128 v[174:177], v153 offset:16960
	ds_read_b128 v[162:165], v153 offset:21120
	ds_read_b128 v[166:169], v153 offset:21184
	ds_read_b32 v159, v157 offset:512
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s66, 1
	s_cbranch_scc1 .LBB0_34
; %bb.32:                               ; %LeafBlock4261
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_cmp_eq_u32 s66, 1
	s_cbranch_scc0 .LBB0_35
; %bb.33:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b64 s[22:23], -1
	s_mov_b32 s92, 0x21800
	s_branch .LBB0_36
	.p2align	5
.LBB0_34:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 s92, 0x21000
	s_mov_b32 s93, s16
	s_mov_b64 s[4:5], s[2:3]
	s_cbranch_execnz .LBB0_37
	s_branch .LBB0_38
	.p2align	5
.LBB0_35:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b64 s[22:23], 0
	s_mov_b32 s92, 0x21000
.LBB0_36:                               ; %Flow4363
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 s93, s17
	s_mov_b64 s[4:5], s[28:29]
	s_and_b64 vcc, exec, s[22:23]
	s_cbranch_vccz .LBB0_38
.LBB0_37:                               ; %.sink.split.i.1
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_cmp_lg_u32 s92, -1
	s_cselect_b32 s23, s92, 0
	s_mul_i32 s22, s93, s91
	s_add_i32 m0, s69, s23
	s_nop 0
	buffer_load_dwordx4 v136, s[4:7], s22 offen lds
.LBB0_38:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.1
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 m0, s76
	s_add_i32 s4, s88, 0x100
	buffer_load_dwordx4 v134, s[12:15], s4 offen lds
	s_mov_b32 m0, s81
	s_nop 0
	buffer_load_dwordx4 v135, s[12:15], s4 offen lds
	s_add_i32 s4, s90, 0x100
	s_mov_b32 m0, s82
	s_nop 0
	buffer_load_dwordx4 v134, s[12:15], s4 offen lds
	s_mov_b32 m0, s83
	s_nop 0
	buffer_load_dwordx4 v135, s[12:15], s4 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[234:241], v[202:209], v[98:101], v160, v158 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[226:233], v[202:209], v[102:105], v160, v158 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[194:197], v154 offset:16896
	ds_read_b128 v[198:201], v154 offset:16960
	ds_read_b128 v[186:189], v154 offset:25344
	ds_read_b128 v[190:193], v154 offset:25408
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[218:225], v[202:209], v[106:109], v160, v158 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[210:217], v[202:209], v[110:113], v160, v158 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[234:241], v[178:185], v[114:117], v160, v158 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[226:233], v[178:185], v[118:121], v160, v158 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[218:225], v[178:185], v[122:125], v160, v158 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[210:217], v[178:185], v[126:129], v160, v158 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[234:241], v[194:201], v[50:53], v160, v158 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[226:233], v[194:201], v[54:57], v160, v158 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[218:225], v[194:201], v[58:61], v160, v158 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[210:217], v[194:201], v[62:65], v160, v158 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[234:241], v[186:193], v[34:37], v160, v158 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[226:233], v[186:193], v[38:41], v160, v158 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[218:225], v[186:193], v[42:45], v160, v158 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[210:217], v[186:193], v[46:49], v160, v158 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[218:221], v153 offset:25344
	ds_read_b128 v[222:225], v153 offset:25408
	ds_read_b128 v[210:213], v153 offset:29568
	ds_read_b128 v[214:217], v153 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[170:177], v[202:209], v[82:85], v159, v158 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[162:169], v[202:209], v[86:89], v159, v158 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[218:225], v[202:209], v[90:93], v159, v158 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[210:217], v[202:209], v[94:97], v159, v158 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s91, s89, 3
	s_cmp_ge_i32 s91, s33
	s_cbranch_scc1 .LBB0_40
; %bb.39:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 m0, s84
	s_add_i32 s4, s88, 0x180
	s_mov_b32 s22, s14
	s_mov_b32 s23, s15
	buffer_load_dwordx4 v132, s[20:23], s4 offen lds
	s_mov_b32 m0, s85
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s4 offen lds
	s_add_i32 s4, s4, s51
	s_mov_b32 m0, s86
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s4 offen lds
	s_mov_b32 m0, s87
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s4 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_40:                               ;   in Loop: Header=BB0_22 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[170:177], v[178:185], v[66:69], v159, v158 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[162:169], v[178:185], v[70:73], v159, v158 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[218:225], v[178:185], v[74:77], v159, v158 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[210:217], v[178:185], v[78:81], v159, v158 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[170:177], v[194:201], v[18:21], v159, v158 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[162:169], v[194:201], v[22:25], v159, v158 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[218:225], v[194:201], v[26:29], v159, v158 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[210:217], v[194:201], v[30:33], v159, v158 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[170:177], v[186:193], v[2:5], v159, v158 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[162:169], v[186:193], v[6:9], v159, v158 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[218:225], v[186:193], v[10:13], v159, v158 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[210:217], v[186:193], v[14:17], v159, v158 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	ds_read_b32 v158, v148
	ds_read_b32 v160, v149
	ds_read_b128 v[202:205], v150
	ds_read_b128 v[206:209], v150 offset:64
	ds_read_b128 v[178:181], v150 offset:8448
	ds_read_b128 v[182:185], v150 offset:8512
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[234:237], v151
	ds_read_b128 v[238:241], v151 offset:64
	ds_read_b128 v[226:229], v151 offset:4224
	ds_read_b128 v[230:233], v151 offset:4288
	ds_read_b128 v[218:221], v151 offset:8448
	ds_read_b128 v[222:225], v151 offset:8512
	ds_read_b128 v[210:213], v151 offset:12672
	ds_read_b128 v[214:217], v151 offset:12736
	ds_read_b128 v[170:173], v151 offset:16896
	ds_read_b128 v[174:177], v151 offset:16960
	ds_read_b128 v[162:165], v151 offset:21120
	ds_read_b128 v[166:169], v151 offset:21184
	ds_read_b32 v159, v152 offset:512
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s66, 1
	s_cbranch_scc1 .LBB0_43
; %bb.41:                               ; %LeafBlock4265
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_cmp_eq_u32 s66, 1
	s_cbranch_scc0 .LBB0_44
; %bb.42:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b64 s[22:23], -1
	s_mov_b32 s92, 0x21800
	s_branch .LBB0_45
	.p2align	5
.LBB0_43:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 s92, 0x21000
	s_mov_b32 s93, s16
	s_mov_b64 s[4:5], s[2:3]
	s_cbranch_execnz .LBB0_46
	s_branch .LBB0_47
	.p2align	5
.LBB0_44:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b64 s[22:23], 0
	s_mov_b32 s92, 0x21000
.LBB0_45:                               ; %Flow4361
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 s93, s17
	s_mov_b64 s[4:5], s[28:29]
	s_and_b64 vcc, exec, s[22:23]
	s_cbranch_vccz .LBB0_47
.LBB0_46:                               ; %.sink.split.i.2
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_cmp_lg_u32 s92, -1
	s_cselect_b32 s23, s92, 0
	s_mul_i32 s22, s93, s91
	s_add_i32 m0, s70, s23
	s_nop 0
	buffer_load_dwordx4 v136, s[4:7], s22 offen lds
.LBB0_47:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.2
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 m0, s72
	s_add_i32 s4, s88, 0x180
	buffer_load_dwordx4 v134, s[12:15], s4 offen lds
	s_mov_b32 m0, s73
	s_nop 0
	buffer_load_dwordx4 v135, s[12:15], s4 offen lds
	s_add_i32 s4, s90, 0x180
	s_mov_b32 m0, s74
	s_nop 0
	buffer_load_dwordx4 v134, s[12:15], s4 offen lds
	s_mov_b32 m0, s75
	s_nop 0
	buffer_load_dwordx4 v135, s[12:15], s4 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[234:241], v[202:209], v[98:101], v160, v158 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[226:233], v[202:209], v[102:105], v160, v158 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[194:197], v150 offset:16896
	ds_read_b128 v[198:201], v150 offset:16960
	ds_read_b128 v[186:189], v150 offset:25344
	ds_read_b128 v[190:193], v150 offset:25408
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[218:225], v[202:209], v[106:109], v160, v158 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[210:217], v[202:209], v[110:113], v160, v158 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[234:241], v[178:185], v[114:117], v160, v158 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[226:233], v[178:185], v[118:121], v160, v158 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[218:225], v[178:185], v[122:125], v160, v158 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[210:217], v[178:185], v[126:129], v160, v158 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[234:241], v[194:201], v[50:53], v160, v158 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[226:233], v[194:201], v[54:57], v160, v158 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[218:225], v[194:201], v[58:61], v160, v158 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[210:217], v[194:201], v[62:65], v160, v158 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[234:241], v[186:193], v[34:37], v160, v158 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[226:233], v[186:193], v[38:41], v160, v158 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[218:225], v[186:193], v[42:45], v160, v158 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[210:217], v[186:193], v[46:49], v160, v158 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[218:221], v151 offset:25344
	ds_read_b128 v[222:225], v151 offset:25408
	ds_read_b128 v[210:213], v151 offset:29568
	ds_read_b128 v[214:217], v151 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[170:177], v[202:209], v[82:85], v159, v158 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[162:169], v[202:209], v[86:89], v159, v158 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[218:225], v[202:209], v[90:93], v159, v158 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[210:217], v[202:209], v[94:97], v159, v158 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s91, s89, 4
	s_cmp_ge_i32 s91, s33
	s_cbranch_scc1 .LBB0_49
; %bb.48:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 m0, s77
	s_add_i32 s4, s88, 0x200
	s_mov_b32 s22, s14
	s_mov_b32 s23, s15
	buffer_load_dwordx4 v132, s[20:23], s4 offen lds
	s_mov_b32 m0, s78
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s4 offen lds
	s_add_i32 s4, s4, s51
	s_mov_b32 m0, s79
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s4 offen lds
	s_mov_b32 m0, s80
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s4 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_49:                               ;   in Loop: Header=BB0_22 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[170:177], v[178:185], v[66:69], v159, v158 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[162:169], v[178:185], v[70:73], v159, v158 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[218:225], v[178:185], v[74:77], v159, v158 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[210:217], v[178:185], v[78:81], v159, v158 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[170:177], v[194:201], v[18:21], v159, v158 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[162:169], v[194:201], v[22:25], v159, v158 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[218:225], v[194:201], v[26:29], v159, v158 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[210:217], v[194:201], v[30:33], v159, v158 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[170:177], v[186:193], v[2:5], v159, v158 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[162:169], v[186:193], v[6:9], v159, v158 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[218:225], v[186:193], v[10:13], v159, v158 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[210:217], v[186:193], v[14:17], v159, v158 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	ds_read_b32 v155, v155
	ds_read_b32 v158, v156
	ds_read_b128 v[200:203], v154
	ds_read_b128 v[204:207], v154 offset:64
	ds_read_b128 v[176:179], v154 offset:8448
	ds_read_b128 v[180:183], v154 offset:8512
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[232:235], v153
	ds_read_b128 v[236:239], v153 offset:64
	ds_read_b128 v[224:227], v153 offset:4224
	ds_read_b128 v[228:231], v153 offset:4288
	ds_read_b128 v[216:219], v153 offset:8448
	ds_read_b128 v[220:223], v153 offset:8512
	ds_read_b128 v[208:211], v153 offset:12672
	ds_read_b128 v[212:215], v153 offset:12736
	ds_read_b128 v[168:171], v153 offset:16896
	ds_read_b128 v[172:175], v153 offset:16960
	ds_read_b128 v[160:163], v153 offset:21120
	ds_read_b128 v[164:167], v153 offset:21184
	ds_read_b32 v156, v157 offset:512
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s66, 1
	s_cbranch_scc1 .LBB0_52
; %bb.50:                               ; %LeafBlock4269
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_cmp_eq_u32 s66, 1
	s_cbranch_scc0 .LBB0_53
; %bb.51:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b64 s[22:23], -1
	s_mov_b32 s92, 0x21800
	s_branch .LBB0_54
	.p2align	5
.LBB0_52:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 s92, 0x21000
	s_mov_b32 s93, s16
	s_mov_b64 s[4:5], s[2:3]
	s_cbranch_execnz .LBB0_55
	s_branch .LBB0_56
	.p2align	5
.LBB0_53:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b64 s[22:23], 0
	s_mov_b32 s92, 0x21000
.LBB0_54:                               ; %Flow4359
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 s93, s17
	s_mov_b64 s[4:5], s[28:29]
	s_and_b64 vcc, exec, s[22:23]
	s_cbranch_vccz .LBB0_56
.LBB0_55:                               ; %.sink.split.i.3
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_cmp_lg_u32 s92, -1
	s_cselect_b32 s23, s92, 0
	s_mul_i32 s22, s93, s91
	s_add_i32 m0, s69, s23
	s_nop 0
	buffer_load_dwordx4 v136, s[4:7], s22 offen lds
.LBB0_56:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.3
                                        ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 m0, s76
	s_add_i32 s4, s88, 0x200
	buffer_load_dwordx4 v134, s[12:15], s4 offen lds
	s_mov_b32 m0, s81
	s_addk_i32 s90, 0x200
	buffer_load_dwordx4 v135, s[12:15], s4 offen lds
	s_mov_b32 m0, s82
	s_nop 0
	buffer_load_dwordx4 v134, s[12:15], s90 offen lds
	s_mov_b32 m0, s83
	s_nop 0
	buffer_load_dwordx4 v135, s[12:15], s90 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[232:239], v[200:207], v[98:101], v158, v155 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[224:231], v[200:207], v[102:105], v158, v155 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[192:195], v154 offset:16896
	ds_read_b128 v[196:199], v154 offset:16960
	ds_read_b128 v[184:187], v154 offset:25344
	ds_read_b128 v[188:191], v154 offset:25408
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[216:223], v[200:207], v[106:109], v158, v155 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[208:215], v[200:207], v[110:113], v158, v155 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[232:239], v[176:183], v[114:117], v158, v155 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[224:231], v[176:183], v[118:121], v158, v155 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[216:223], v[176:183], v[122:125], v158, v155 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[208:215], v[176:183], v[126:129], v158, v155 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[232:239], v[192:199], v[50:53], v158, v155 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[224:231], v[192:199], v[54:57], v158, v155 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[216:223], v[192:199], v[58:61], v158, v155 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[208:215], v[192:199], v[62:65], v158, v155 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[232:239], v[184:191], v[34:37], v158, v155 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[224:231], v[184:191], v[38:41], v158, v155 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[216:223], v[184:191], v[42:45], v158, v155 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[208:215], v[184:191], v[46:49], v158, v155 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[216:219], v153 offset:25344
	ds_read_b128 v[220:223], v153 offset:25408
	ds_read_b128 v[208:211], v153 offset:29568
	ds_read_b128 v[212:215], v153 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[168:175], v[200:207], v[82:85], v156, v155 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[160:167], v[200:207], v[86:89], v156, v155 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[216:223], v[200:207], v[90:93], v156, v155 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[208:215], v[200:207], v[94:97], v156, v155 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s89, s89, 5
	s_cmp_ge_i32 s89, s33
	s_cbranch_scc1 .LBB0_21
; %bb.57:                               ;   in Loop: Header=BB0_22 Depth=2
	s_mov_b32 m0, s84
	s_add_i32 s5, s88, 0x280
	s_mov_b32 s22, s14
	s_mov_b32 s23, s15
	buffer_load_dwordx4 v132, s[20:23], s5 offen lds
	s_mov_b32 m0, s85
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s5 offen lds
	s_add_i32 s5, s5, s51
	s_mov_b32 m0, s86
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s5 offen lds
	s_mov_b32 m0, s87
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s5 offen lds
	; sched_barrier mask(0x00000000)
	s_branch .LBB0_21
.LBB0_58:                               ;   in Loop: Header=BB0_3 Depth=1
	v_mov_b32_e32 v18, 0
	s_mov_b32 s69, s34
	v_mov_b32_e32 v19, v18
	v_mov_b32_e32 v20, v18
	v_mov_b32_e32 v21, v18
	v_mov_b32_e32 v22, v18
	v_mov_b32_e32 v23, v18
	v_mov_b32_e32 v24, v18
	v_mov_b32_e32 v25, v18
	v_mov_b32_e32 v26, v18
	v_mov_b32_e32 v27, v18
	v_mov_b32_e32 v28, v18
	v_mov_b32_e32 v29, v18
	v_mov_b32_e32 v30, v18
	v_mov_b32_e32 v31, v18
	v_mov_b32_e32 v32, v18
	v_mov_b32_e32 v33, v18
	v_mov_b32_e32 v2, v18
	v_mov_b32_e32 v3, v18
	v_mov_b32_e32 v4, v18
	v_mov_b32_e32 v5, v18
	v_mov_b32_e32 v6, v18
	v_mov_b32_e32 v7, v18
	v_mov_b32_e32 v8, v18
	v_mov_b32_e32 v9, v18
	v_mov_b32_e32 v10, v18
	v_mov_b32_e32 v11, v18
	v_mov_b32_e32 v12, v18
	v_mov_b32_e32 v13, v18
	v_mov_b32_e32 v14, v18
	v_mov_b32_e32 v15, v18
	v_mov_b32_e32 v16, v18
	v_mov_b32_e32 v17, v18
	v_mov_b32_e32 v50, v18
	v_mov_b32_e32 v51, v18
	v_mov_b32_e32 v52, v18
	v_mov_b32_e32 v53, v18
	v_mov_b32_e32 v54, v18
	v_mov_b32_e32 v55, v18
	v_mov_b32_e32 v56, v18
	v_mov_b32_e32 v57, v18
	v_mov_b32_e32 v58, v18
	v_mov_b32_e32 v59, v18
	v_mov_b32_e32 v60, v18
	v_mov_b32_e32 v61, v18
	v_mov_b32_e32 v62, v18
	v_mov_b32_e32 v63, v18
	v_mov_b32_e32 v64, v18
	v_mov_b32_e32 v65, v18
	v_mov_b32_e32 v34, v18
	v_mov_b32_e32 v35, v18
	v_mov_b32_e32 v36, v18
	v_mov_b32_e32 v37, v18
	v_mov_b32_e32 v38, v18
	v_mov_b32_e32 v39, v18
	v_mov_b32_e32 v40, v18
	v_mov_b32_e32 v41, v18
	v_mov_b32_e32 v42, v18
	v_mov_b32_e32 v43, v18
	v_mov_b32_e32 v44, v18
	v_mov_b32_e32 v45, v18
	v_mov_b32_e32 v46, v18
	v_mov_b32_e32 v47, v18
	v_mov_b32_e32 v48, v18
	v_mov_b32_e32 v49, v18
	v_mov_b32_e32 v82, v18
	v_mov_b32_e32 v83, v18
	v_mov_b32_e32 v84, v18
	v_mov_b32_e32 v85, v18
	v_mov_b32_e32 v86, v18
	v_mov_b32_e32 v87, v18
	v_mov_b32_e32 v88, v18
	v_mov_b32_e32 v89, v18
	v_mov_b32_e32 v90, v18
	v_mov_b32_e32 v91, v18
	v_mov_b32_e32 v92, v18
	v_mov_b32_e32 v93, v18
	v_mov_b32_e32 v94, v18
	v_mov_b32_e32 v95, v18
	v_mov_b32_e32 v96, v18
	v_mov_b32_e32 v97, v18
	v_mov_b32_e32 v66, v18
	v_mov_b32_e32 v67, v18
	v_mov_b32_e32 v68, v18
	v_mov_b32_e32 v69, v18
	v_mov_b32_e32 v70, v18
	v_mov_b32_e32 v71, v18
	v_mov_b32_e32 v72, v18
	v_mov_b32_e32 v73, v18
	v_mov_b32_e32 v74, v18
	v_mov_b32_e32 v75, v18
	v_mov_b32_e32 v76, v18
	v_mov_b32_e32 v77, v18
	v_mov_b32_e32 v78, v18
	v_mov_b32_e32 v79, v18
	v_mov_b32_e32 v80, v18
	v_mov_b32_e32 v81, v18
	v_mov_b32_e32 v98, v18
	v_mov_b32_e32 v99, v18
	v_mov_b32_e32 v100, v18
	v_mov_b32_e32 v101, v18
	v_mov_b32_e32 v102, v18
	v_mov_b32_e32 v103, v18
	v_mov_b32_e32 v104, v18
	v_mov_b32_e32 v105, v18
	v_mov_b32_e32 v106, v18
	v_mov_b32_e32 v107, v18
	v_mov_b32_e32 v108, v18
	v_mov_b32_e32 v109, v18
	v_mov_b32_e32 v110, v18
	v_mov_b32_e32 v111, v18
	v_mov_b32_e32 v112, v18
	v_mov_b32_e32 v113, v18
	v_mov_b32_e32 v114, v18
	v_mov_b32_e32 v115, v18
	v_mov_b32_e32 v116, v18
	v_mov_b32_e32 v117, v18
	v_mov_b32_e32 v118, v18
	v_mov_b32_e32 v119, v18
	v_mov_b32_e32 v120, v18
	v_mov_b32_e32 v121, v18
	v_mov_b32_e32 v122, v18
	v_mov_b32_e32 v123, v18
	v_mov_b32_e32 v124, v18
	v_mov_b32_e32 v125, v18
	v_mov_b32_e32 v126, v18
	v_mov_b32_e32 v127, v18
	v_mov_b32_e32 v128, v18
	v_mov_b32_e32 v129, v18
	s_branch .LBB0_72
.LBB0_59:                               ;   in Loop: Header=BB0_3 Depth=1
	v_mov_b32_e32 v17, 0
	s_mov_b32 s70, 0
	v_mov_b32_e32 v16, v17
	v_mov_b32_e32 v15, v17
	v_mov_b32_e32 v14, v17
	v_mov_b32_e32 v13, v17
	v_mov_b32_e32 v12, v17
	v_mov_b32_e32 v11, v17
	v_mov_b32_e32 v10, v17
	v_mov_b32_e32 v9, v17
	v_mov_b32_e32 v8, v17
	v_mov_b32_e32 v7, v17
	v_mov_b32_e32 v6, v17
	v_mov_b32_e32 v5, v17
	v_mov_b32_e32 v4, v17
	v_mov_b32_e32 v3, v17
	v_mov_b32_e32 v2, v17
	v_mov_b32_e32 v33, v17
	v_mov_b32_e32 v32, v17
	v_mov_b32_e32 v31, v17
	v_mov_b32_e32 v30, v17
	v_mov_b32_e32 v29, v17
	v_mov_b32_e32 v28, v17
	v_mov_b32_e32 v27, v17
	v_mov_b32_e32 v26, v17
	v_mov_b32_e32 v25, v17
	v_mov_b32_e32 v24, v17
	v_mov_b32_e32 v23, v17
	v_mov_b32_e32 v22, v17
	v_mov_b32_e32 v21, v17
	v_mov_b32_e32 v20, v17
	v_mov_b32_e32 v19, v17
	v_mov_b32_e32 v18, v17
	v_mov_b32_e32 v49, v17
	v_mov_b32_e32 v48, v17
	v_mov_b32_e32 v47, v17
	v_mov_b32_e32 v46, v17
	v_mov_b32_e32 v45, v17
	v_mov_b32_e32 v44, v17
	v_mov_b32_e32 v43, v17
	v_mov_b32_e32 v42, v17
	v_mov_b32_e32 v41, v17
	v_mov_b32_e32 v40, v17
	v_mov_b32_e32 v39, v17
	v_mov_b32_e32 v38, v17
	v_mov_b32_e32 v37, v17
	v_mov_b32_e32 v36, v17
	v_mov_b32_e32 v35, v17
	v_mov_b32_e32 v34, v17
	v_mov_b32_e32 v65, v17
	v_mov_b32_e32 v64, v17
	v_mov_b32_e32 v63, v17
	v_mov_b32_e32 v62, v17
	v_mov_b32_e32 v61, v17
	v_mov_b32_e32 v60, v17
	v_mov_b32_e32 v59, v17
	v_mov_b32_e32 v58, v17
	v_mov_b32_e32 v57, v17
	v_mov_b32_e32 v56, v17
	v_mov_b32_e32 v55, v17
	v_mov_b32_e32 v54, v17
	v_mov_b32_e32 v53, v17
	v_mov_b32_e32 v52, v17
	v_mov_b32_e32 v51, v17
	v_mov_b32_e32 v50, v17
	v_mov_b32_e32 v81, v17
	v_mov_b32_e32 v80, v17
	v_mov_b32_e32 v79, v17
	v_mov_b32_e32 v78, v17
	v_mov_b32_e32 v77, v17
	v_mov_b32_e32 v76, v17
	v_mov_b32_e32 v75, v17
	v_mov_b32_e32 v74, v17
	v_mov_b32_e32 v73, v17
	v_mov_b32_e32 v72, v17
	v_mov_b32_e32 v71, v17
	v_mov_b32_e32 v70, v17
	v_mov_b32_e32 v69, v17
	v_mov_b32_e32 v68, v17
	v_mov_b32_e32 v67, v17
	v_mov_b32_e32 v66, v17
	v_mov_b32_e32 v97, v17
	v_mov_b32_e32 v96, v17
	v_mov_b32_e32 v95, v17
	v_mov_b32_e32 v94, v17
	v_mov_b32_e32 v93, v17
	v_mov_b32_e32 v92, v17
	v_mov_b32_e32 v91, v17
	v_mov_b32_e32 v90, v17
	v_mov_b32_e32 v89, v17
	v_mov_b32_e32 v88, v17
	v_mov_b32_e32 v87, v17
	v_mov_b32_e32 v86, v17
	v_mov_b32_e32 v85, v17
	v_mov_b32_e32 v84, v17
	v_mov_b32_e32 v83, v17
	v_mov_b32_e32 v82, v17
	v_mov_b32_e32 v129, v17
	v_mov_b32_e32 v128, v17
	v_mov_b32_e32 v127, v17
	v_mov_b32_e32 v126, v17
	v_mov_b32_e32 v125, v17
	v_mov_b32_e32 v124, v17
	v_mov_b32_e32 v123, v17
	v_mov_b32_e32 v122, v17
	v_mov_b32_e32 v121, v17
	v_mov_b32_e32 v120, v17
	v_mov_b32_e32 v119, v17
	v_mov_b32_e32 v118, v17
	v_mov_b32_e32 v117, v17
	v_mov_b32_e32 v116, v17
	v_mov_b32_e32 v115, v17
	v_mov_b32_e32 v114, v17
	v_mov_b32_e32 v113, v17
	v_mov_b32_e32 v112, v17
	v_mov_b32_e32 v111, v17
	v_mov_b32_e32 v110, v17
	v_mov_b32_e32 v109, v17
	v_mov_b32_e32 v108, v17
	v_mov_b32_e32 v107, v17
	v_mov_b32_e32 v106, v17
	v_mov_b32_e32 v105, v17
	v_mov_b32_e32 v104, v17
	v_mov_b32_e32 v103, v17
	v_mov_b32_e32 v102, v17
	v_mov_b32_e32 v101, v17
	v_mov_b32_e32 v100, v17
	v_mov_b32_e32 v99, v17
	v_mov_b32_e32 v98, v17
                                        ; implicit-def: $sgpr67
	s_mov_b32 s69, s34
	s_cbranch_execnz .LBB0_61
	s_branch .LBB0_72
.LBB0_60:                               ; %._crit_edge.loopexit.unr-lcssa
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_add_i32 s22, s91, 1
	s_mov_b32 s70, s60
	s_mov_b64 s[4:5], s[24:25]
	s_and_b64 vcc, exec, s[4:5]
	s_mov_b32 s69, s34
	s_cbranch_vccz .LBB0_72
.LBB0_61:                               ; %.epil.preheader
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b32 s71, 0
	s_mov_b32 s69, s34
	s_branch .LBB0_63
	.p2align	5
.LBB0_62:                               ;   in Loop: Header=BB0_63 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[162:169], v[170:177], v[66:69], v149, v148 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[154:161], v[170:177], v[70:73], v149, v148 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[210:217], v[170:177], v[74:77], v149, v148 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[202:209], v[170:177], v[78:81], v149, v148 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[162:169], v[194:201], v[18:21], v149, v148 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[154:161], v[194:201], v[22:25], v149, v148 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[210:217], v[194:201], v[26:29], v149, v148 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[202:209], v[194:201], v[30:33], v149, v148 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[162:169], v[178:185], v[2:5], v149, v148 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[154:161], v[178:185], v[6:9], v149, v148 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[210:217], v[178:185], v[10:13], v149, v148 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[202:209], v[178:185], v[14:17], v149, v148 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_add_i32 s22, s70, 1
	s_add_i32 s71, s71, 1
	s_cmp_lg_u32 s71, s59
	s_cbranch_scc0 .LBB0_72
.LBB0_63:                               ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_mul_i32 s72, s69, 0x8400
	v_add_u32_e32 v152, s72, v142
	s_lshl_b32 s4, s69, 10
	ds_read_b128 v[186:189], v152
	ds_read_b128 v[190:193], v152 offset:64
	ds_read_b128 v[170:173], v152 offset:8448
	ds_read_b128 v[174:177], v152 offset:8512
	v_add_u32_e32 v148, s4, v145
	v_add_u32_e32 v149, s4, v146
	ds_read_b32 v148, v148
	ds_read_b32 v151, v149
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v150, s72, v141
	ds_read_b128 v[226:229], v150
	ds_read_b128 v[230:233], v150 offset:64
	ds_read_b128 v[218:221], v150 offset:4224
	ds_read_b128 v[222:225], v150 offset:4288
	ds_read_b128 v[210:213], v150 offset:8448
	ds_read_b128 v[214:217], v150 offset:8512
	ds_read_b128 v[202:205], v150 offset:12672
	ds_read_b128 v[206:209], v150 offset:12736
	ds_read_b128 v[162:165], v150 offset:16896
	ds_read_b128 v[166:169], v150 offset:16960
	ds_read_b128 v[154:157], v150 offset:21120
	ds_read_b128 v[158:161], v150 offset:21184
	v_add_u32_e32 v149, s4, v147
	ds_read_b32 v149, v149 offset:512
	; sched_barrier mask(0x00000000)
	s_mov_b32 s73, s70
	s_mov_b32 s70, s22
	s_cmp_lt_i32 s66, 1
	s_cbranch_scc1 .LBB0_66
; %bb.64:                               ; %LeafBlock4273
                                        ;   in Loop: Header=BB0_63 Depth=2
	s_cmp_eq_u32 s66, 1
	s_cbranch_scc0 .LBB0_67
; %bb.65:                               ;   in Loop: Header=BB0_63 Depth=2
	s_mov_b64 s[22:23], -1
	s_mov_b32 s67, 0x21800
	s_branch .LBB0_68
	.p2align	5
.LBB0_66:                               ;   in Loop: Header=BB0_63 Depth=2
	s_mov_b32 s67, 0x21000
	s_mov_b32 s74, s16
	s_mov_b64 s[4:5], s[2:3]
	s_xor_b32 s69, s69, 1
	s_cbranch_execnz .LBB0_69
	s_branch .LBB0_70
	.p2align	5
.LBB0_67:                               ;   in Loop: Header=BB0_63 Depth=2
	s_mov_b64 s[22:23], 0
	s_mov_b32 s67, 0x21000
.LBB0_68:                               ; %Flow4367
                                        ;   in Loop: Header=BB0_63 Depth=2
	s_mov_b32 s74, s17
	s_mov_b64 s[4:5], s[28:29]
	s_xor_b32 s69, s69, 1
	s_and_b64 vcc, exec, s[22:23]
	s_cbranch_vccz .LBB0_70
.LBB0_69:                               ; %.sink.split.i.epil
                                        ;   in Loop: Header=BB0_63 Depth=2
	s_lshl_b32 s23, s69, 10
	s_cmp_lg_u32 s67, -1
	s_cselect_b32 s67, s67, 0
	s_mul_i32 s22, s74, s70
	s_add_i32 m0, s23, s67
	s_nop 0
	buffer_load_dwordx4 v136, s[4:7], s22 offen lds
.LBB0_70:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.epil
                                        ;   in Loop: Header=BB0_63 Depth=2
	s_mul_i32 s67, s69, 0x8400
	s_add_i32 s5, s68, s67
	s_lshl_b32 s4, s70, 7
	s_mov_b32 m0, s5
	s_nop 0
	buffer_load_dwordx4 v134, s[12:15], s4 offen lds
	s_add_i32 m0, s5, 0x2100
	s_nop 0
	buffer_load_dwordx4 v135, s[12:15], s4 offen lds
	s_add_i32 s4, s70, s8
	s_lshl_b32 s4, s4, 7
	s_add_i32 m0, s5, 0x4200
	s_nop 0
	buffer_load_dwordx4 v134, s[12:15], s4 offen lds
	s_add_i32 m0, s5, 0x6300
	s_nop 0
	buffer_load_dwordx4 v135, s[12:15], s4 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[226:233], v[186:193], v[98:101], v151, v148 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[218:225], v[186:193], v[102:105], v151, v148 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[194:197], v152 offset:16896
	ds_read_b128 v[198:201], v152 offset:16960
	ds_read_b128 v[178:181], v152 offset:25344
	ds_read_b128 v[182:185], v152 offset:25408
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[210:217], v[186:193], v[106:109], v151, v148 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[202:209], v[186:193], v[110:113], v151, v148 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[226:233], v[170:177], v[114:117], v151, v148 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[218:225], v[170:177], v[118:121], v151, v148 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[210:217], v[170:177], v[122:125], v151, v148 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[202:209], v[170:177], v[126:129], v151, v148 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[226:233], v[194:201], v[50:53], v151, v148 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[218:225], v[194:201], v[54:57], v151, v148 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[210:217], v[194:201], v[58:61], v151, v148 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[202:209], v[194:201], v[62:65], v151, v148 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[226:233], v[178:185], v[34:37], v151, v148 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[218:225], v[178:185], v[38:41], v151, v148 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[210:217], v[178:185], v[42:45], v151, v148 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[202:209], v[178:185], v[46:49], v151, v148 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[210:213], v150 offset:25344
	ds_read_b128 v[214:217], v150 offset:25408
	ds_read_b128 v[202:205], v150 offset:29568
	ds_read_b128 v[206:209], v150 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[162:169], v[186:193], v[82:85], v149, v148 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[154:161], v[186:193], v[86:89], v149, v148 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[210:217], v[186:193], v[90:93], v149, v148 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[202:209], v[186:193], v[94:97], v149, v148 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s4, s73, 2
	s_cmp_ge_i32 s4, s33
	s_cbranch_scc1 .LBB0_62
; %bb.71:                               ;   in Loop: Header=BB0_63 Depth=2
	s_add_i32 s22, s68, s72
	s_add_i32 s72, s22, 0x10800
	s_lshl_b32 s5, s4, 7
	s_mov_b32 s22, s14
	s_mov_b32 s23, s15
	s_mov_b32 m0, s72
	s_add_i32 s4, s4, s9
	buffer_load_dwordx4 v132, s[20:23], s5 offen lds
	s_add_i32 m0, s72, 0x2100
	s_lshl_b32 s4, s4, 7
	buffer_load_dwordx4 v133, s[20:23], s5 offen lds
	s_add_i32 m0, s72, 0x4200
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s4 offen lds
	s_add_i32 m0, s72, 0x6300
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s4 offen lds
	; sched_barrier mask(0x00000000)
	s_branch .LBB0_62
.LBB0_72:                               ; %._crit_edge
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_lshl_b32 s2, s69, 10
	v_add_u32_e32 v142, s67, v142
	v_add_u32_e32 v141, s67, v141
	v_or_b32_e32 v144, s2, v144
	s_add_i32 s2, s2, 0x21800
	ds_read_b128 v[170:173], v142
	ds_read_b128 v[174:177], v142 offset:64
	ds_read_b128 v[162:165], v142 offset:8448
	ds_read_b128 v[166:169], v142 offset:8512
	ds_read_b128 v[154:157], v142 offset:16896
	ds_read_b128 v[158:161], v142 offset:16960
	ds_read_b128 v[146:149], v142 offset:25344
	ds_read_b128 v[150:153], v142 offset:25408
	ds_read_b128 v[202:205], v141
	ds_read_b128 v[206:209], v141 offset:64
	ds_read_b128 v[194:197], v141 offset:4224
	ds_read_b128 v[198:201], v141 offset:4288
	ds_read_b128 v[186:189], v141 offset:8448
	ds_read_b128 v[190:193], v141 offset:8512
	ds_read_b128 v[178:181], v141 offset:12672
	ds_read_b128 v[182:185], v141 offset:12736
	s_add_i32 s12, s65, 1
	v_add_u32_e32 v143, s2, v143
	v_add_u32_e32 v140, s2, v140
	s_lshr_b32 s15, s12, 1
	s_and_b32 s2, s12, 1
	s_add_i32 s15, s15, s35
	s_or_b32 s14, s2, s36
	s_cmp_lg_u32 s65, 3
	s_cselect_b64 s[2:3], -1, 0
	s_cmp_lt_i32 s15, s30
	v_add_u32_e32 v144, 0x21000, v144
	s_cselect_b64 s[4:5], -1, 0
	s_cmp_lt_i32 s14, s31
	ds_read_b32 v144, v144
	ds_read_b32 v143, v143
	s_waitcnt lgkmcnt(0)
	ds_read_b32 v140, v140 offset:512
	s_cselect_b64 s[20:21], -1, 0
	s_and_b64 s[4:5], s[4:5], s[20:21]
	s_and_b64 s[4:5], s[4:5], s[2:3]
	v_cndmask_b32_e64 v142, 0, 1, s[4:5]
	v_cmp_ne_u32_e64 s[2:3], 1, v142
	s_andn2_b64 vcc, exec, s[4:5]
	s_xor_b32 s13, s69, 1
	s_cbranch_vccnz .LBB0_80
; %bb.73:                               ; %NodeBlock4279
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_lt_i32 s66, 1
	s_mov_b64 s[4:5], -1
	s_cbranch_scc1 .LBB0_77
; %bb.74:                               ; %LeafBlock4277
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_eq_u32 s66, 1
	s_cbranch_scc0 .LBB0_76
; %bb.75:                               ;   in Loop: Header=BB0_3 Depth=1
	s_mul_i32 s4, s47, s14
	s_ashr_i32 s5, s4, 31
	s_add_u32 s4, s45, s4
	s_addc_u32 s5, s46, s5
	s_lshl_b32 s20, s13, 10
	s_and_b32 s5, s5, 0xffff
	s_add_i32 m0, s20, 0x21800
	s_nop 0
	buffer_load_dwordx4 v136, s[4:7], 0 offen lds
.LBB0_76:                               ; %Flow
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b64 s[4:5], 0
.LBB0_77:                               ; %Flow4356
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_andn2_b64 vcc, exec, s[4:5]
	s_cbranch_vccnz .LBB0_79
; %bb.78:                               ;   in Loop: Header=BB0_3 Depth=1
	s_mul_i32 s4, s44, s15
	s_ashr_i32 s5, s4, 31
	s_add_u32 s4, s42, s4
	s_addc_u32 s5, s43, s5
	s_lshl_b32 s20, s13, 10
	s_and_b32 s5, s5, 0xffff
	s_add_i32 m0, s20, 0x21000
	s_nop 0
	buffer_load_dwordx4 v136, s[4:7], 0 offen lds
.LBB0_79:                               ;   in Loop: Header=BB0_3 Depth=1
	s_mul_i32 s4, s54, s15
	s_ashr_i32 s5, s4, 31
	s_add_u32 s4, s11, s4
	s_addc_u32 s5, s37, s5
	s_mul_i32 s14, s55, s14
	s_and_b32 s5, s5, 0xffff
	s_ashr_i32 s15, s14, 31
	s_add_u32 s20, s38, s14
	s_addc_u32 s14, s39, s15
	s_and_b32 s21, s14, 0xffff
	s_mul_i32 s14, s13, 0x8400
	s_add_i32 s15, s64, s63
	s_add_i32 s14, s15, s14
	s_mov_b32 m0, s14
	s_add_i32 s15, s14, 0x10800
	buffer_load_dwordx4 v134, s[4:7], 0 offen lds
	s_add_i32 m0, s14, 0x2100
	s_mov_b32 s22, s6
	s_mov_b32 s23, s7
	buffer_load_dwordx4 v135, s[4:7], 0 offen lds
	s_mov_b32 m0, s15
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], 0 offen lds
	s_add_i32 m0, s15, 0x2100
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], 0 offen lds
	s_add_i32 m0, s14, 0x4200
	s_nop 0
	buffer_load_dwordx4 v134, s[4:7], s50 offen lds
	s_add_i32 m0, s14, 0x6300
	s_nop 0
	buffer_load_dwordx4 v135, s[4:7], s50 offen lds
	s_add_i32 m0, s15, 0x4200
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s51 offen lds
	s_add_i32 m0, s15, 0x6300
	s_nop 0
	buffer_load_dwordx4 v133, s[20:23], s51 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_80:                               ;   in Loop: Header=BB0_3 Depth=1
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[202:209], v[170:177], v[98:101], v143, v144 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[194:201], v[170:177], v[102:105], v143, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[186:193], v[170:177], v[106:109], v143, v144 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[178:185], v[170:177], v[110:113], v143, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[202:209], v[162:169], v[114:117], v143, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[194:201], v[162:169], v[118:121], v143, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[186:193], v[162:169], v[122:125], v143, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[178:185], v[162:169], v[126:129], v143, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[202:209], v[154:161], v[50:53], v143, v144 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[194:201], v[154:161], v[54:57], v143, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[186:193], v[154:161], v[58:61], v143, v144 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[178:185], v[154:161], v[62:65], v143, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[202:209], v[146:153], v[34:37], v143, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[194:201], v[146:153], v[38:41], v143, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[186:193], v[146:153], v[42:45], v143, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[178:185], v[146:153], v[46:49], v143, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[202:205], v141 offset:16896
	ds_read_b128 v[206:209], v141 offset:16960
	ds_read_b128 v[194:197], v141 offset:21120
	ds_read_b128 v[198:201], v141 offset:21184
	ds_read_b128 v[186:189], v141 offset:25344
	ds_read_b128 v[190:193], v141 offset:25408
	ds_read_b128 v[178:181], v141 offset:29568
	ds_read_b128 v[182:185], v141 offset:29632
	s_waitcnt lgkmcnt(6)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[202:209], v[170:177], v[82:85], v140, v144 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[194:201], v[170:177], v[86:89], v140, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[186:193], v[170:177], v[90:93], v140, v144 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[178:185], v[170:177], v[94:97], v140, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[202:209], v[162:169], v[66:69], v140, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[194:201], v[162:169], v[70:73], v140, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[186:193], v[162:169], v[74:77], v140, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[178:185], v[162:169], v[78:81], v140, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[202:209], v[154:161], v[18:21], v140, v144 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[194:201], v[154:161], v[22:25], v140, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[186:193], v[154:161], v[26:29], v140, v144 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[178:185], v[154:161], v[30:33], v140, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[202:209], v[146:153], v[2:5], v140, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[194:201], v[146:153], v[6:9], v140, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[186:193], v[146:153], v[10:13], v140, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[178:185], v[146:153], v[14:17], v140, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_1
; %bb.81:                               ;   in Loop: Header=BB0_3 Depth=1
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b32 s34, s13
	s_branch .LBB0_1
.LBB0_82:
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
		.amdhsa_next_free_vgpr 242
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 244
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
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_vgpr, 242
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_agpr, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.numbered_sgpr, 94
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_named_barrier, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.private_seg_size, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_vcc, 1
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_flat_scratch, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_dyn_sized_stack, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_recursion, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 10512
; TotalNumSgprs: 100
; NumVgprs: 242
; NumAgprs: 0
; TotalNumVgprs: 242
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 139264 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 30
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 242
; AccumOffset: 244
; Occupancy: 2
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 60
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.section	.AMDGPU.csdata,"",@progbits
	.type	__hip_cuid_12c357c2c3a2ad91,@object ; @__hip_cuid_12c357c2c3a2ad91
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_12c357c2c3a2ad91
__hip_cuid_12c357c2c3a2ad91:
	.byte	0                               ; 0x0
	.size	__hip_cuid_12c357c2c3a2ad91, 1

	.ident	"AMD clang version 23.0.0git (https://github.com/ROCm/llvm-project.git 46fcb339fb61119b337f973c7ca9e710a319fdd0+PATCHED:440716f8b87be9d8e20ed910e10e5b6d14d57cf6)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_12c357c2c3a2ad91
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
    .max_flat_workgroup_size: 512
    .name:           _Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
    .private_segment_fixed_size: 0
    .sgpr_count:     100
    .sgpr_spill_count: 0
    .symbol:         _Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     242
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
