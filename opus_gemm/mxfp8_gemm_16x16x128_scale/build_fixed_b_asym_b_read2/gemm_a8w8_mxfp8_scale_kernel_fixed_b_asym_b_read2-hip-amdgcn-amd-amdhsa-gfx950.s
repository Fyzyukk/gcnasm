	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.section	.text._Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,"axG",@progbits,_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,comdat
	.protected	_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs ; -- Begin function _Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
	.globl	_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
	.p2align	8
	.type	_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,@function
_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs: ; @_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
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
	s_ashr_i32 s0, s0, 8
	s_abs_i32 s1, s0
	v_cvt_f32_u32_e32 v1, s1
	s_add_i32 s28, s6, 0x7f
	s_sub_i32 s6, 0, s1
	s_ashr_i32 s4, s28, 31
	v_rcp_iflag_f32_e32 v1, v1
	s_abs_i32 s5, s2
	s_lshr_b32 s4, s4, 25
	s_add_i32 s4, s28, s4
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_ashr_i32 s36, s4, 7
	s_xor_b32 s4, s2, s0
	s_ashr_i32 s4, s4, 31
	v_readfirstlane_b32 s7, v1
	s_mul_i32 s6, s6, s7
	s_mul_hi_u32 s6, s7, s6
	s_add_i32 s7, s7, s6
	s_mul_hi_u32 s6, s5, s7
	s_mul_i32 s7, s6, s1
	s_sub_i32 s5, s5, s7
	s_add_i32 s7, s6, 1
	s_sub_i32 s29, s5, s1
	s_cmp_ge_u32 s5, s1
	s_cselect_b32 s6, s7, s6
	s_cselect_b32 s5, s29, s5
	s_add_i32 s7, s6, 1
	s_cmp_ge_u32 s5, s1
	s_cselect_b32 s1, s7, s6
	s_xor_b32 s1, s1, s4
	s_sub_i32 s1, s1, s4
	s_mul_i32 s0, s1, s0
	s_sub_i32 s2, s2, s0
	s_lshl_b32 s38, s1, 2
	s_mul_i32 s1, s11, s3
	s_lshl_b32 s0, s2, 8
	s_ashr_i32 s4, s1, 31
	s_add_u32 s11, s20, s1
	s_mul_i32 s1, s26, s3
	s_addc_u32 s39, s21, s4
	s_ashr_i32 s4, s1, 31
	s_add_u32 s1, s22, s1
	s_addc_u32 s5, s23, s4
	s_mul_i32 s4, s0, s9
	s_ashr_i32 s6, s4, 31
	s_add_u32 s4, s1, s4
	s_mul_i32 s20, s27, s3
	s_addc_u32 s1, s5, s6
	s_ashr_i32 s21, s20, 31
	s_and_b32 s5, s1, 0xffff
	s_lshl_b64 s[20:21], s[20:21], 2
	s_add_u32 s20, s24, s20
	s_addc_u32 s21, s25, s21
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s40, s20, s0
	s_mul_i32 s0, s18, s3
	s_addc_u32 s41, s21, s1
	s_ashr_i32 s1, s0, 31
	s_add_u32 s42, s12, s0
	s_mul_i32 s0, s19, s3
	s_mul_i32 s2, s17, s2
	s_addc_u32 s43, s13, s1
	s_ashr_i32 s1, s0, 31
	s_add_u32 s0, s14, s0
	s_mul_i32 s2, s2, s36
	s_addc_u32 s1, s15, s1
	s_ashr_i32 s3, s2, 31
	s_add_u32 s12, s0, s2
	s_addc_u32 s0, s1, s3
	s_and_b32 s13, s0, 0xffff
	s_lshl_b32 s45, s8, 6
	s_lshl_b32 s46, s9, 6
	s_lshl_b32 s47, s9, 5
	s_lshl_b32 s48, s8, 7
	s_lshl_b32 s49, s9, 7
	s_cmpk_lt_i32 s28, 0x100
	s_cselect_b64 s[0:1], -1, 0
	s_max_i32 s2, s36, 2
	s_lshl_b32 s53, s10, 9
	s_add_i32 s2, s2, -1
	s_add_i32 s51, s49, 0x80
	s_lshl_b32 s52, s8, 8
	s_add_i32 s55, s53, 0x200
	s_and_b32 s56, s2, 3
	v_and_b32_e32 v2, 63, v0
	s_cmpk_gt_i32 s28, 0x27f
	v_lshlrev_b32_e32 v136, 4, v2
	v_lshrrev_b32_e32 v2, 2, v0
	s_cselect_b64 s[76:77], -1, 0
	s_and_b32 s57, s2, -4
	v_lshlrev_b32_e32 v4, 4, v0
	v_and_b32_e32 v137, 12, v2
	s_movk_i32 s3, 0xf0
	s_cmp_lg_u32 s56, 0
	v_and_or_b32 v139, v4, s3, v137
	s_cselect_b64 s[2:3], -1, 0
                                        ; implicit-def: $vgpr242 : SGPR spill to VGPR lane
	s_mul_i32 s44, s16, s36
	v_writelane_b32 v242, s2, 0
	v_bfe_u32 v3, v0, 3, 3
	v_and_b32_e32 v5, 3, v0
	v_lshlrev_b32_e32 v6, 5, v0
	v_writelane_b32 v242, s3, 1
	s_ashr_i32 s2, s44, 31
	s_mov_b32 s23, 0x20000
	s_mov_b32 s22, -1
	v_lshlrev_b32_e32 v1, 2, v3
	v_and_b32_e32 v130, 0x70, v4
	v_mul_u32_u24_e32 v5, 0x420, v5
	v_and_b32_e32 v6, 0x180, v6
	v_and_b32_e32 v7, 48, v0
	v_mul_lo_u32 v3, s9, v3
	v_writelane_b32 v242, s2, 2
	s_mov_b32 s37, 0
	s_mov_b32 s6, s22
	s_mov_b32 s7, s23
	v_add3_u32 v131, v5, v7, v6
	s_movk_i32 s19, 0x80
	v_and_b32_e32 v138, 15, v0
	s_movk_i32 s54, 0x200
	v_lshl_add_u32 v140, v3, 2, v130
	s_add_i32 s58, s33, -1
	s_ashr_i32 s59, s52, 31
	s_and_b64 s[0:1], exec, s[0:1]
	s_mov_b32 s61, 0
	v_writelane_b32 v242, s76, 3
	s_nop 1
	v_writelane_b32 v242, s77, 4
	s_branch .LBB0_3
.LBB0_1:                                ;   in Loop: Header=BB0_3 Depth=1
	s_mul_i32 s2, s62, s10
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[2:3], s[2:3], 2
	s_add_u32 s20, s40, s2
	v_lshl_or_b32 v133, s63, 4, v138
	s_addc_u32 s2, s41, s3
	v_lshl_or_b32 v132, s64, 4, v137
	v_mul_lo_u32 v134, v133, s10
	s_and_b32 s21, s2, 0xffff
	v_add_u32_e32 v135, 32, v132
	v_or_b32_e32 v133, 64, v133
	v_add_lshl_u32 v143, v134, v132, 2
	v_add_u32_e32 v141, 64, v132
	v_add_u32_e32 v142, 0x60, v132
	v_mul_lo_u32 v133, v133, s10
	buffer_store_dwordx4 v[98:101], v143, s[20:23], 0 offen nt
	s_nop 1
	v_add_lshl_u32 v98, v134, v135, 2
	buffer_store_dwordx4 v[102:105], v98, s[20:23], 0 offen nt
	v_add_lshl_u32 v99, v134, v141, 2
	v_add_lshl_u32 v100, v134, v142, 2
	v_add_lshl_u32 v101, v133, v132, 2
	v_add_lshl_u32 v102, v133, v135, 2
	v_add_lshl_u32 v103, v133, v141, 2
	v_add_lshl_u32 v104, v133, v142, 2
	buffer_store_dwordx4 v[106:109], v99, s[20:23], 0 offen nt
	buffer_store_dwordx4 v[110:113], v100, s[20:23], 0 offen nt
	buffer_store_dwordx4 v[114:117], v101, s[20:23], 0 offen nt
	buffer_store_dwordx4 v[118:121], v102, s[20:23], 0 offen nt
	buffer_store_dwordx4 v[122:125], v103, s[20:23], 0 offen nt
	buffer_store_dwordx4 v[126:129], v104, s[20:23], 0 offen nt
	buffer_store_dwordx4 v[82:85], v143, s[20:23], s54 offen nt
	buffer_store_dwordx4 v[86:89], v98, s[20:23], s54 offen nt
	buffer_store_dwordx4 v[90:93], v99, s[20:23], s54 offen nt
	buffer_store_dwordx4 v[94:97], v100, s[20:23], s54 offen nt
	buffer_store_dwordx4 v[66:69], v101, s[20:23], s54 offen nt
	buffer_store_dwordx4 v[70:73], v102, s[20:23], s54 offen nt
	buffer_store_dwordx4 v[74:77], v103, s[20:23], s54 offen nt
	buffer_store_dwordx4 v[78:81], v104, s[20:23], s54 offen nt
	buffer_store_dwordx4 v[50:53], v143, s[20:23], s53 offen nt
	buffer_store_dwordx4 v[54:57], v98, s[20:23], s53 offen nt
	buffer_store_dwordx4 v[58:61], v99, s[20:23], s53 offen nt
	buffer_store_dwordx4 v[62:65], v100, s[20:23], s53 offen nt
	buffer_store_dwordx4 v[34:37], v101, s[20:23], s53 offen nt
	buffer_store_dwordx4 v[38:41], v102, s[20:23], s53 offen nt
	buffer_store_dwordx4 v[42:45], v103, s[20:23], s53 offen nt
	buffer_store_dwordx4 v[46:49], v104, s[20:23], s53 offen nt
	buffer_store_dwordx4 v[18:21], v143, s[20:23], s55 offen nt
	buffer_store_dwordx4 v[22:25], v98, s[20:23], s55 offen nt
	buffer_store_dwordx4 v[26:29], v99, s[20:23], s55 offen nt
	buffer_store_dwordx4 v[30:33], v100, s[20:23], s55 offen nt
	buffer_store_dwordx4 v[2:5], v101, s[20:23], s55 offen nt
	buffer_store_dwordx4 v[6:9], v102, s[20:23], s55 offen nt
	buffer_store_dwordx4 v[10:13], v103, s[20:23], s55 offen nt
	buffer_store_dwordx4 v[14:17], v104, s[20:23], s55 offen nt
.LBB0_2:                                ;   in Loop: Header=BB0_3 Depth=1
	s_add_i32 s61, s61, 1
	s_cmp_eq_u32 s61, 4
	s_cselect_b64 s[2:3], -1, 0
	s_or_b64 s[2:3], s[30:31], s[2:3]
	s_andn2_b64 vcc, exec, s[2:3]
	s_cbranch_vccz .LBB0_89
.LBB0_3:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_20 Depth 2
                                        ;     Child Loop BB0_69 Depth 2
	s_or_b32 s70, s61, s38
	s_cmp_ge_i32 s70, s33
	s_cselect_b64 s[30:31], -1, 0
	s_and_b64 vcc, exec, s[30:31]
	s_cbranch_vccnz .LBB0_2
; %bb.4:                                ;   in Loop: Header=BB0_3 Depth=1
	s_lshl_b32 s62, s70, 8
	v_readfirstlane_b32 s14, v0
	s_mul_i32 s2, s62, s8
	s_lshr_b32 s69, s14, 6
	s_ashr_i32 s3, s2, 31
	s_add_u32 s20, s11, s2
	s_addc_u32 s65, s39, s3
	s_mul_i32 s2, s44, s70
	s_and_b32 s21, s65, 0xffff
	s_ashr_i32 s3, s2, 31
	s_add_u32 s34, s42, s2
	s_addc_u32 s68, s43, s3
	s_lshr_b32 s64, s14, 8
	s_bfe_u32 s63, s14, 0x20006
	v_lshl_or_b32 v2, s64, 5, v1
	v_or_b32_e32 v2, s63, v2
	v_mad_u64_u32 v[132:133], s[2:3], v2, s8, v[130:131]
	s_mul_i32 s3, s63, s9
	s_mul_i32 s2, s64, s47
	v_add_u32_e32 v147, s3, v140
	s_and_b32 s35, s68, 0xffff
	v_add_u32_e32 v142, s2, v147
	v_add_u32_e32 v141, s45, v132
	v_add_u32_e32 v133, s46, v142
	s_cmp_lg_u32 s61, 0
	s_mul_i32 s66, s64, 0x1080
	s_mul_i32 s67, s63, 0x420
	s_cbranch_scc1 .LBB0_13
; %bb.5:                                ; %NodeBlock
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_lt_i32 s69, 1
	s_cbranch_scc1 .LBB0_8
; %bb.6:                                ; %LeafBlock
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_eq_u32 s69, 1
	s_cbranch_scc0 .LBB0_9
; %bb.7:                                ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b64 s[2:3], -1
	s_mov_b32 s15, 0x21800
	s_branch .LBB0_10
.LBB0_8:                                ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b32 s15, 0x21000
	s_mov_b64 s[24:25], s[34:35]
	s_mov_b64 s[26:27], s[22:23]
	s_cbranch_execnz .LBB0_11
	s_branch .LBB0_12
.LBB0_9:                                ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b64 s[2:3], 0
	s_mov_b32 s15, 0x21000
.LBB0_10:                               ; %Flow4355
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b64 s[24:25], s[12:13]
	s_mov_b64 s[26:27], s[6:7]
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccz .LBB0_12
.LBB0_11:                               ; %.sink.split
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_lshl_b32 s2, s37, 10
	s_add_i32 m0, s2, s15
	s_nop 0
	buffer_load_dwordx4 v136, s[24:27], 0 offen lds
.LBB0_12:                               ;   in Loop: Header=BB0_3 Depth=1
	s_mul_i32 s2, s37, 0x8400
	s_add_i32 s2, s66, s2
	s_add_i32 s2, s2, s67
	s_mov_b32 m0, s2
	s_add_i32 s3, s2, 0x10800
	buffer_load_dwordx4 v132, s[20:23], 0 offen lds
	s_add_i32 m0, s2, 0x2100
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], 0 offen lds
	s_mov_b32 m0, s3
	s_nop 0
	buffer_load_dwordx4 v142, s[4:7], 0 offen lds
	s_add_i32 m0, s3, 0x2100
	s_nop 0
	buffer_load_dwordx4 v133, s[4:7], 0 offen lds
	s_add_i32 m0, s2, 0x4200
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s48 offen lds
	s_add_i32 m0, s2, 0x6300
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], s48 offen lds
	s_add_i32 m0, s3, 0x4200
	s_nop 0
	buffer_load_dwordx4 v142, s[4:7], s49 offen lds
	s_add_i32 m0, s3, 0x6300
	s_nop 0
	buffer_load_dwordx4 v133, s[4:7], s49 offen lds
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
.LBB0_13:                               ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_gt_u32 s63, 1
	s_cselect_b32 s15, 0x1080, 0
	s_lshl_b32 s2, s63, 9
	s_add_i32 s3, s2, 0xfffffc00
	s_cmp_lt_u32 s63, 2
	s_cselect_b32 s18, s2, s3
	s_mov_b64 s[2:3], -1
	s_mov_b64 vcc, s[0:1]
                                        ; implicit-def: $sgpr71
	s_cbranch_vccz .LBB0_15
; %bb.14:                               ; %.._crit_edge_crit_edge
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_mul_i32 s71, s37, 0x8400
	s_mov_b64 s[2:3], 0
.LBB0_15:                               ; %Flow4353
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_add_i32 s18, s18, s15
	v_lshl_add_u32 v2, s64, 9, v131
	s_and_b32 s14, s14, 0xffffff00
	v_add_u32_e32 v143, s18, v131
	v_lshl_or_b32 v146, s63, 8, v139
	v_or_b32_e32 v145, s14, v139
	s_andn2_b64 vcc, exec, s[2:3]
	v_add_u32_e32 v144, 0x10800, v2
	s_cbranch_vccnz .LBB0_63
; %bb.16:                               ; %.lr.ph
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_lshl_b32 s2, s37, 1
	s_xor_b32 s2, s2, 2
	s_mulk_i32 s2, 0x4200
	s_add_i32 s2, s66, s2
	s_add_i32 s2, s2, s67
	s_add_i32 s2, s2, 0x10800
	s_mov_b32 m0, s2
	v_add_u32_e32 v148, s46, v147
	buffer_load_dwordx4 v142, s[4:7], s19 offen lds
	s_add_i32 m0, s2, 0x2100
	v_add_u32_e32 v149, s47, v147
	buffer_load_dwordx4 v133, s[4:7], s19 offen lds
	s_add_i32 m0, s2, 0x4200
	v_add_u32_e32 v150, s47, v148
	buffer_load_dwordx4 v142, s[4:7], s51 offen lds
	s_add_i32 m0, s2, 0x6300
	s_mov_b32 s24, 1
	buffer_load_dwordx4 v133, s[4:7], s51 offen lds
	; sched_barrier mask(0x00000000)
	s_add_i32 s72, s67, s66
	s_cmp_eq_u32 s64, 1
	v_or_b32_e32 v151, 0x21000, v146
	s_cselect_b64 s[2:3], -1, 0
	s_andn2_b64 vcc, exec, s[76:77]
	v_add_u32_e32 v152, 0x21800, v145
	s_cbranch_vccnz .LBB0_64
; %bb.17:                               ; %.lr.ph.new
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_xor_b32 s75, s37, 1
	s_mul_i32 s71, s37, 0x8400
	s_lshl_b32 s74, s75, 10
	s_mul_i32 s75, s75, 0x8400
	s_add_i32 s76, s72, s75
	s_add_i32 s81, s71, s67
	s_add_i32 s88, s72, s71
	s_add_i32 s93, s75, s67
	s_lshl_b32 s73, s37, 10
	s_add_i32 s77, s76, 0x2100
	s_add_i32 s80, s81, 0x10800
	s_add_i32 s81, s81, 0x12900
	s_add_i32 s89, s88, 0x2100
	s_add_i32 s92, s93, 0x10800
	s_add_i32 s93, s93, 0x12900
	v_mov_b32_e32 v98, 0
	v_add_u32_e32 v153, s73, v152
	s_add_i32 s78, s76, 0x4200
	s_add_i32 s79, s77, 0x4200
	s_add_i32 s82, s80, 0x1080
	s_add_i32 s83, s81, 0x1080
	s_add_i32 s84, s80, 0x4200
	s_add_i32 s85, s81, 0x4200
	s_add_i32 s86, s80, 0x5280
	s_add_i32 s87, s81, 0x5280
	v_add_u32_e32 v154, s74, v152
	s_add_i32 s90, s88, 0x4200
	s_add_i32 s91, s89, 0x4200
	s_add_i32 s94, s92, 0x1080
	s_add_i32 s95, s93, 0x1080
	s_add_i32 s96, s92, 0x4200
	s_add_i32 s97, s93, 0x4200
	s_add_i32 s98, s92, 0x5280
	s_add_i32 s99, s93, 0x5280
	s_mov_b32 s14, 0
	v_add_u32_e32 v155, s73, v151
	v_add_u32_e32 v156, s71, v143
	v_add_u32_e32 v157, s71, v144
	s_mov_b32 s28, 0
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
	s_branch .LBB0_20
	.p2align	5
.LBB0_18:                               ;   in Loop: Header=BB0_20 Depth=2
	; sched_barrier mask(0x00000000)
.LBB0_19:                               ;   in Loop: Header=BB0_20 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[170:177], v[178:185], v[66:69], v135, v160 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[162:169], v[178:185], v[70:73], v135, v160 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[218:225], v[178:185], v[74:77], v135, v160 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[210:217], v[178:185], v[78:81], v135, v160 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[170:177], v[194:201], v[18:21], v135, v160 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[162:169], v[194:201], v[22:25], v135, v160 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[218:225], v[194:201], v[26:29], v135, v160 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[210:217], v[194:201], v[30:33], v135, v160 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[170:177], v[186:193], v[2:5], v135, v160 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[162:169], v[186:193], v[6:9], v135, v160 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[218:225], v[186:193], v[10:13], v135, v160 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[210:217], v[186:193], v[14:17], v135, v160 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_cmp_lg_u32 s57, s28
	s_cbranch_scc0 .LBB0_65
.LBB0_20:                               ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ds_read_b32 v158, v155
	;;#ASMSTART
	ds_read2st64_b32 v[134:135], v153 offset0:0 offset1:2

	;;#ASMEND
	ds_read_b128 v[192:195], v156
	ds_read_b128 v[196:199], v156 offset:64
	ds_read_b128 v[176:179], v156 offset:8448
	ds_read_b128 v[180:183], v156 offset:8512
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[232:235], v157
	ds_read_b128 v[236:239], v157 offset:64
	ds_read_b128 v[224:227], v157 offset:4224
	ds_read_b128 v[228:231], v157 offset:4288
	ds_read_b128 v[216:219], v157 offset:8448
	ds_read_b128 v[220:223], v157 offset:8512
	ds_read_b128 v[208:211], v157 offset:12672
	ds_read_b128 v[212:215], v157 offset:12736
	ds_read_b128 v[168:171], v157 offset:16896
	ds_read_b128 v[172:175], v157 offset:16960
	ds_read_b128 v[160:163], v157 offset:21120
	ds_read_b128 v[164:167], v157 offset:21184
	; sched_barrier mask(0x00000000)
	s_mov_b32 s50, s28
	s_mov_b32 s60, s14
	s_cmp_lt_i32 s69, 1
	s_cbranch_scc1 .LBB0_23
; %bb.21:                               ; %LeafBlock4234
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_cmp_eq_u32 s69, 1
	s_cbranch_scc0 .LBB0_24
; %bb.22:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b64 s[14:15], -1
	s_mov_b32 s28, 0x21800
	s_branch .LBB0_25
	.p2align	5
.LBB0_23:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 s28, 0x21000
	s_mov_b32 s18, s16
	s_mov_b64 s[24:25], s[34:35]
	s_mov_b64 s[26:27], s[22:23]
	s_cbranch_execnz .LBB0_26
	s_branch .LBB0_27
	.p2align	5
.LBB0_24:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b64 s[14:15], 0
	s_mov_b32 s28, 0x21000
.LBB0_25:                               ; %Flow4346
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 s18, s17
	s_mov_b64 s[24:25], s[12:13]
	s_mov_b64 s[26:27], s[6:7]
	s_and_b64 vcc, exec, s[14:15]
	s_cbranch_vccz .LBB0_27
.LBB0_26:                               ; %.sink.split.i
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_add_i32 s14, s50, 1
	s_cmp_lg_u32 s28, -1
	s_cselect_b32 s15, s28, 0
	s_mul_i32 s14, s18, s14
	s_add_i32 m0, s74, s15
	s_nop 0
	buffer_load_dwordx4 v136, s[24:27], s14 offen lds
.LBB0_27:                               ; %_ZZ49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 m0, s76
	s_add_i32 s14, s60, 0x80
	buffer_load_dwordx4 v132, s[20:23], s14 offen lds
	s_mov_b32 m0, s77
	s_add_i32 s29, s48, s60
	buffer_load_dwordx4 v141, s[20:23], s14 offen lds
	s_add_i32 s14, s29, 0x80
	s_mov_b32 m0, s78
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s14 offen lds
	s_mov_b32 m0, s79
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], s14 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(8)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[232:239], v[192:199], v[98:101], v134, v158 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[224:231], v[192:199], v[102:105], v134, v158 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[200:203], v156 offset:16896
	ds_read_b128 v[204:207], v156 offset:16960
	ds_read_b128 v[184:187], v156 offset:25344
	ds_read_b128 v[188:191], v156 offset:25408
	s_waitcnt lgkmcnt(8)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[216:223], v[192:199], v[106:109], v134, v158 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[208:215], v[192:199], v[110:113], v134, v158 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[232:239], v[176:183], v[114:117], v134, v158 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[224:231], v[176:183], v[118:121], v134, v158 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[216:223], v[176:183], v[122:125], v134, v158 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[208:215], v[176:183], v[126:129], v134, v158 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[232:239], v[200:207], v[50:53], v134, v158 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[224:231], v[200:207], v[54:57], v134, v158 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[216:223], v[200:207], v[58:61], v134, v158 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[208:215], v[200:207], v[62:65], v134, v158 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[232:239], v[184:191], v[34:37], v134, v158 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[224:231], v[184:191], v[38:41], v134, v158 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[216:223], v[184:191], v[42:45], v134, v158 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[208:215], v[184:191], v[46:49], v134, v158 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[216:219], v157 offset:25344
	ds_read_b128 v[220:223], v157 offset:25408
	ds_read_b128 v[208:211], v157 offset:29568
	ds_read_b128 v[212:215], v157 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[168:175], v[192:199], v[82:85], v135, v158 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[160:167], v[192:199], v[86:89], v135, v158 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[216:223], v[192:199], v[90:93], v135, v158 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[208:215], v[192:199], v[94:97], v135, v158 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s28, s50, 2
	s_cmp_ge_i32 s28, s36
	s_cbranch_scc1 .LBB0_31
; %bb.28:                               ;   in Loop: Header=BB0_20 Depth=2
	s_andn2_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_30
; %bb.29:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 m0, s80
	s_add_i32 s14, s60, 0x100
	buffer_load_dwordx4 v147, s[4:7], s14 offen lds
	s_mov_b32 m0, s81
	s_nop 0
	buffer_load_dwordx4 v148, s[4:7], s14 offen lds
	s_mov_b32 m0, s82
	s_nop 0
	buffer_load_dwordx4 v149, s[4:7], s14 offen lds
	s_mov_b32 m0, s83
	s_nop 0
	buffer_load_dwordx4 v150, s[4:7], s14 offen lds
	s_add_i32 s14, s14, s49
	s_mov_b32 m0, s84
	s_nop 0
	buffer_load_dwordx4 v147, s[4:7], s14 offen lds
	s_mov_b32 m0, s85
	s_nop 0
	buffer_load_dwordx4 v148, s[4:7], s14 offen lds
	s_mov_b32 m0, s86
	s_nop 0
	buffer_load_dwordx4 v149, s[4:7], s14 offen lds
	s_mov_b32 m0, s87
	s_nop 0
	buffer_load_dwordx4 v150, s[4:7], s14 offen lds
.LBB0_30:                               ;   in Loop: Header=BB0_20 Depth=2
	; sched_barrier mask(0x00000000)
.LBB0_31:                               ;   in Loop: Header=BB0_20 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[168:175], v[176:183], v[66:69], v135, v158 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[160:167], v[176:183], v[70:73], v135, v158 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[216:223], v[176:183], v[74:77], v135, v158 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[208:215], v[176:183], v[78:81], v135, v158 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[168:175], v[200:207], v[18:21], v135, v158 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[160:167], v[200:207], v[22:25], v135, v158 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[216:223], v[200:207], v[26:29], v135, v158 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[208:215], v[200:207], v[30:33], v135, v158 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[168:175], v[184:191], v[2:5], v135, v158 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[160:167], v[184:191], v[6:9], v135, v158 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[216:223], v[184:191], v[10:13], v135, v158 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[208:215], v[184:191], v[14:17], v135, v158 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	v_add_u32_e32 v160, s74, v151
	ds_read_b32 v161, v160
	;;#ASMSTART
	ds_read2st64_b32 v[134:135], v154 offset0:0 offset1:2

	;;#ASMEND
	v_add_u32_e32 v159, s75, v143
	ds_read_b128 v[202:205], v159
	ds_read_b128 v[206:209], v159 offset:64
	ds_read_b128 v[178:181], v159 offset:8448
	ds_read_b128 v[182:185], v159 offset:8512
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v158, s75, v144
	ds_read_b128 v[234:237], v158
	ds_read_b128 v[238:241], v158 offset:64
	ds_read_b128 v[226:229], v158 offset:4224
	ds_read_b128 v[230:233], v158 offset:4288
	ds_read_b128 v[218:221], v158 offset:8448
	ds_read_b128 v[222:225], v158 offset:8512
	ds_read_b128 v[210:213], v158 offset:12672
	ds_read_b128 v[214:217], v158 offset:12736
	ds_read_b128 v[170:173], v158 offset:16896
	ds_read_b128 v[174:177], v158 offset:16960
	ds_read_b128 v[162:165], v158 offset:21120
	ds_read_b128 v[166:169], v158 offset:21184
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s69, 1
	s_cbranch_scc1 .LBB0_34
; %bb.32:                               ; %LeafBlock4238
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_cmp_eq_u32 s69, 1
	s_cbranch_scc0 .LBB0_35
; %bb.33:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b64 s[14:15], -1
	s_mov_b32 s18, 0x21800
	s_branch .LBB0_36
	.p2align	5
.LBB0_34:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 s18, 0x21000
	s_mov_b32 s19, s16
	s_mov_b64 s[24:25], s[34:35]
	s_mov_b64 s[26:27], s[22:23]
	s_cbranch_execnz .LBB0_37
	s_branch .LBB0_38
	.p2align	5
.LBB0_35:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b64 s[14:15], 0
	s_mov_b32 s18, 0x21000
.LBB0_36:                               ; %Flow4343
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 s19, s17
	s_mov_b64 s[24:25], s[12:13]
	s_mov_b64 s[26:27], s[6:7]
	s_and_b64 vcc, exec, s[14:15]
	s_cbranch_vccz .LBB0_38
.LBB0_37:                               ; %.sink.split.i.1
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_cmp_lg_u32 s18, -1
	s_cselect_b32 s15, s18, 0
	s_mul_i32 s14, s19, s28
	s_add_i32 m0, s73, s15
	s_nop 0
	buffer_load_dwordx4 v136, s[24:27], s14 offen lds
.LBB0_38:                               ; %_ZZ49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.1
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 m0, s88
	s_add_i32 s14, s60, 0x100
	buffer_load_dwordx4 v132, s[20:23], s14 offen lds
	s_mov_b32 m0, s89
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], s14 offen lds
	s_add_i32 s14, s29, 0x100
	s_mov_b32 m0, s90
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s14 offen lds
	s_mov_b32 m0, s91
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], s14 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(8)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[234:241], v[202:209], v[98:101], v134, v161 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[226:233], v[202:209], v[102:105], v134, v161 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[194:197], v159 offset:16896
	ds_read_b128 v[198:201], v159 offset:16960
	ds_read_b128 v[186:189], v159 offset:25344
	ds_read_b128 v[190:193], v159 offset:25408
	s_waitcnt lgkmcnt(8)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[218:225], v[202:209], v[106:109], v134, v161 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[210:217], v[202:209], v[110:113], v134, v161 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[234:241], v[178:185], v[114:117], v134, v161 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[226:233], v[178:185], v[118:121], v134, v161 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[218:225], v[178:185], v[122:125], v134, v161 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[210:217], v[178:185], v[126:129], v134, v161 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[234:241], v[194:201], v[50:53], v134, v161 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[226:233], v[194:201], v[54:57], v134, v161 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[218:225], v[194:201], v[58:61], v134, v161 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[210:217], v[194:201], v[62:65], v134, v161 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[234:241], v[186:193], v[34:37], v134, v161 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[226:233], v[186:193], v[38:41], v134, v161 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[218:225], v[186:193], v[42:45], v134, v161 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[210:217], v[186:193], v[46:49], v134, v161 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[218:221], v158 offset:25344
	ds_read_b128 v[222:225], v158 offset:25408
	ds_read_b128 v[210:213], v158 offset:29568
	ds_read_b128 v[214:217], v158 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[170:177], v[202:209], v[82:85], v135, v161 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[162:169], v[202:209], v[86:89], v135, v161 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[218:225], v[202:209], v[90:93], v135, v161 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[210:217], v[202:209], v[94:97], v135, v161 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s28, s50, 3
	s_cmp_ge_i32 s28, s36
	s_cbranch_scc1 .LBB0_42
; %bb.39:                               ;   in Loop: Header=BB0_20 Depth=2
	s_andn2_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_41
; %bb.40:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 m0, s92
	s_add_i32 s14, s60, 0x180
	buffer_load_dwordx4 v147, s[4:7], s14 offen lds
	s_mov_b32 m0, s93
	s_nop 0
	buffer_load_dwordx4 v148, s[4:7], s14 offen lds
	s_mov_b32 m0, s94
	s_nop 0
	buffer_load_dwordx4 v149, s[4:7], s14 offen lds
	s_mov_b32 m0, s95
	s_nop 0
	buffer_load_dwordx4 v150, s[4:7], s14 offen lds
	s_add_i32 s14, s14, s49
	s_mov_b32 m0, s96
	s_nop 0
	buffer_load_dwordx4 v147, s[4:7], s14 offen lds
	s_mov_b32 m0, s97
	s_nop 0
	buffer_load_dwordx4 v148, s[4:7], s14 offen lds
	s_mov_b32 m0, s98
	s_nop 0
	buffer_load_dwordx4 v149, s[4:7], s14 offen lds
	s_mov_b32 m0, s99
	s_nop 0
	buffer_load_dwordx4 v150, s[4:7], s14 offen lds
.LBB0_41:                               ;   in Loop: Header=BB0_20 Depth=2
	; sched_barrier mask(0x00000000)
.LBB0_42:                               ;   in Loop: Header=BB0_20 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[170:177], v[178:185], v[66:69], v135, v161 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[162:169], v[178:185], v[70:73], v135, v161 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[218:225], v[178:185], v[74:77], v135, v161 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[210:217], v[178:185], v[78:81], v135, v161 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[170:177], v[194:201], v[18:21], v135, v161 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[162:169], v[194:201], v[22:25], v135, v161 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[218:225], v[194:201], v[26:29], v135, v161 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[210:217], v[194:201], v[30:33], v135, v161 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[170:177], v[186:193], v[2:5], v135, v161 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[162:169], v[186:193], v[6:9], v135, v161 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[218:225], v[186:193], v[10:13], v135, v161 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[210:217], v[186:193], v[14:17], v135, v161 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	ds_read_b32 v161, v155
	;;#ASMSTART
	ds_read2st64_b32 v[134:135], v153 offset0:0 offset1:2

	;;#ASMEND
	ds_read_b128 v[202:205], v156
	ds_read_b128 v[206:209], v156 offset:64
	ds_read_b128 v[178:181], v156 offset:8448
	ds_read_b128 v[182:185], v156 offset:8512
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[234:237], v157
	ds_read_b128 v[238:241], v157 offset:64
	ds_read_b128 v[226:229], v157 offset:4224
	ds_read_b128 v[230:233], v157 offset:4288
	ds_read_b128 v[218:221], v157 offset:8448
	ds_read_b128 v[222:225], v157 offset:8512
	ds_read_b128 v[210:213], v157 offset:12672
	ds_read_b128 v[214:217], v157 offset:12736
	ds_read_b128 v[170:173], v157 offset:16896
	ds_read_b128 v[174:177], v157 offset:16960
	ds_read_b128 v[162:165], v157 offset:21120
	ds_read_b128 v[166:169], v157 offset:21184
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s69, 1
	s_cbranch_scc1 .LBB0_45
; %bb.43:                               ; %LeafBlock4242
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_cmp_eq_u32 s69, 1
	s_cbranch_scc0 .LBB0_46
; %bb.44:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b64 s[14:15], -1
	s_mov_b32 s18, 0x21800
	s_branch .LBB0_47
	.p2align	5
.LBB0_45:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 s18, 0x21000
	s_mov_b32 s19, s16
	s_mov_b64 s[24:25], s[34:35]
	s_mov_b64 s[26:27], s[22:23]
	s_cbranch_execnz .LBB0_48
	s_branch .LBB0_49
	.p2align	5
.LBB0_46:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b64 s[14:15], 0
	s_mov_b32 s18, 0x21000
.LBB0_47:                               ; %Flow4340
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 s19, s17
	s_mov_b64 s[24:25], s[12:13]
	s_mov_b64 s[26:27], s[6:7]
	s_and_b64 vcc, exec, s[14:15]
	s_cbranch_vccz .LBB0_49
.LBB0_48:                               ; %.sink.split.i.2
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_cmp_lg_u32 s18, -1
	s_cselect_b32 s15, s18, 0
	s_mul_i32 s14, s19, s28
	s_add_i32 m0, s74, s15
	s_nop 0
	buffer_load_dwordx4 v136, s[24:27], s14 offen lds
.LBB0_49:                               ; %_ZZ49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.2
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 m0, s76
	s_add_i32 s14, s60, 0x180
	buffer_load_dwordx4 v132, s[20:23], s14 offen lds
	s_mov_b32 m0, s77
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], s14 offen lds
	s_add_i32 s14, s29, 0x180
	s_mov_b32 m0, s78
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s14 offen lds
	s_mov_b32 m0, s79
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], s14 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(8)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[234:241], v[202:209], v[98:101], v134, v161 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[226:233], v[202:209], v[102:105], v134, v161 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[194:197], v156 offset:16896
	ds_read_b128 v[198:201], v156 offset:16960
	ds_read_b128 v[186:189], v156 offset:25344
	ds_read_b128 v[190:193], v156 offset:25408
	s_waitcnt lgkmcnt(8)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[218:225], v[202:209], v[106:109], v134, v161 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[210:217], v[202:209], v[110:113], v134, v161 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[234:241], v[178:185], v[114:117], v134, v161 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[226:233], v[178:185], v[118:121], v134, v161 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[218:225], v[178:185], v[122:125], v134, v161 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[210:217], v[178:185], v[126:129], v134, v161 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[234:241], v[194:201], v[50:53], v134, v161 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[226:233], v[194:201], v[54:57], v134, v161 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[218:225], v[194:201], v[58:61], v134, v161 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[210:217], v[194:201], v[62:65], v134, v161 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[234:241], v[186:193], v[34:37], v134, v161 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[226:233], v[186:193], v[38:41], v134, v161 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[218:225], v[186:193], v[42:45], v134, v161 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[210:217], v[186:193], v[46:49], v134, v161 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[218:221], v157 offset:25344
	ds_read_b128 v[222:225], v157 offset:25408
	ds_read_b128 v[210:213], v157 offset:29568
	ds_read_b128 v[214:217], v157 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[170:177], v[202:209], v[82:85], v135, v161 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[162:169], v[202:209], v[86:89], v135, v161 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[218:225], v[202:209], v[90:93], v135, v161 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[210:217], v[202:209], v[94:97], v135, v161 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s28, s50, 4
	s_cmp_ge_i32 s28, s36
	s_cbranch_scc1 .LBB0_53
; %bb.50:                               ;   in Loop: Header=BB0_20 Depth=2
	s_andn2_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_52
; %bb.51:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 m0, s80
	s_add_i32 s14, s60, 0x200
	buffer_load_dwordx4 v147, s[4:7], s14 offen lds
	s_mov_b32 m0, s81
	s_nop 0
	buffer_load_dwordx4 v148, s[4:7], s14 offen lds
	s_mov_b32 m0, s82
	s_nop 0
	buffer_load_dwordx4 v149, s[4:7], s14 offen lds
	s_mov_b32 m0, s83
	s_nop 0
	buffer_load_dwordx4 v150, s[4:7], s14 offen lds
	s_add_i32 s14, s14, s49
	s_mov_b32 m0, s84
	s_nop 0
	buffer_load_dwordx4 v147, s[4:7], s14 offen lds
	s_mov_b32 m0, s85
	s_nop 0
	buffer_load_dwordx4 v148, s[4:7], s14 offen lds
	s_mov_b32 m0, s86
	s_nop 0
	buffer_load_dwordx4 v149, s[4:7], s14 offen lds
	s_mov_b32 m0, s87
	s_nop 0
	buffer_load_dwordx4 v150, s[4:7], s14 offen lds
.LBB0_52:                               ;   in Loop: Header=BB0_20 Depth=2
	; sched_barrier mask(0x00000000)
.LBB0_53:                               ;   in Loop: Header=BB0_20 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[170:177], v[178:185], v[66:69], v135, v161 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[162:169], v[178:185], v[70:73], v135, v161 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[218:225], v[178:185], v[74:77], v135, v161 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[210:217], v[178:185], v[78:81], v135, v161 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[170:177], v[194:201], v[18:21], v135, v161 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[162:169], v[194:201], v[22:25], v135, v161 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[218:225], v[194:201], v[26:29], v135, v161 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[210:217], v[194:201], v[30:33], v135, v161 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[170:177], v[186:193], v[2:5], v135, v161 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[162:169], v[186:193], v[6:9], v135, v161 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[218:225], v[186:193], v[10:13], v135, v161 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[210:217], v[186:193], v[14:17], v135, v161 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	ds_read_b32 v160, v160
	;;#ASMSTART
	ds_read2st64_b32 v[134:135], v154 offset0:0 offset1:2

	;;#ASMEND
	ds_read_b128 v[202:205], v159
	ds_read_b128 v[206:209], v159 offset:64
	ds_read_b128 v[178:181], v159 offset:8448
	ds_read_b128 v[182:185], v159 offset:8512
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[234:237], v158
	ds_read_b128 v[238:241], v158 offset:64
	ds_read_b128 v[226:229], v158 offset:4224
	ds_read_b128 v[230:233], v158 offset:4288
	ds_read_b128 v[218:221], v158 offset:8448
	ds_read_b128 v[222:225], v158 offset:8512
	ds_read_b128 v[210:213], v158 offset:12672
	ds_read_b128 v[214:217], v158 offset:12736
	ds_read_b128 v[170:173], v158 offset:16896
	ds_read_b128 v[174:177], v158 offset:16960
	ds_read_b128 v[162:165], v158 offset:21120
	ds_read_b128 v[166:169], v158 offset:21184
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s69, 1
	s_cbranch_scc1 .LBB0_56
; %bb.54:                               ; %LeafBlock4246
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_cmp_eq_u32 s69, 1
	s_cbranch_scc0 .LBB0_57
; %bb.55:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b64 s[14:15], -1
	s_mov_b32 s18, 0x21800
	s_branch .LBB0_58
	.p2align	5
.LBB0_56:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 s18, 0x21000
	s_mov_b32 s19, s16
	s_mov_b64 s[24:25], s[34:35]
	s_mov_b64 s[26:27], s[22:23]
	s_cbranch_execnz .LBB0_59
	s_branch .LBB0_60
	.p2align	5
.LBB0_57:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b64 s[14:15], 0
	s_mov_b32 s18, 0x21000
.LBB0_58:                               ; %Flow4337
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 s19, s17
	s_mov_b64 s[24:25], s[12:13]
	s_mov_b64 s[26:27], s[6:7]
	s_and_b64 vcc, exec, s[14:15]
	s_cbranch_vccz .LBB0_60
.LBB0_59:                               ; %.sink.split.i.3
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_cmp_lg_u32 s18, -1
	s_cselect_b32 s15, s18, 0
	s_mul_i32 s14, s19, s28
	s_add_i32 m0, s73, s15
	s_nop 0
	buffer_load_dwordx4 v136, s[24:27], s14 offen lds
.LBB0_60:                               ; %_ZZ49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.3
                                        ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 m0, s88
	s_add_i32 s14, s60, 0x200
	buffer_load_dwordx4 v132, s[20:23], s14 offen lds
	s_mov_b32 m0, s89
	s_addk_i32 s29, 0x200
	buffer_load_dwordx4 v141, s[20:23], s14 offen lds
	s_mov_b32 m0, s90
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s29 offen lds
	s_mov_b32 m0, s91
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], s29 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(8)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[234:241], v[202:209], v[98:101], v134, v160 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[226:233], v[202:209], v[102:105], v134, v160 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[194:197], v159 offset:16896
	ds_read_b128 v[198:201], v159 offset:16960
	ds_read_b128 v[186:189], v159 offset:25344
	ds_read_b128 v[190:193], v159 offset:25408
	s_waitcnt lgkmcnt(8)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[218:225], v[202:209], v[106:109], v134, v160 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[210:217], v[202:209], v[110:113], v134, v160 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[234:241], v[178:185], v[114:117], v134, v160 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[226:233], v[178:185], v[118:121], v134, v160 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[218:225], v[178:185], v[122:125], v134, v160 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[210:217], v[178:185], v[126:129], v134, v160 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[234:241], v[194:201], v[50:53], v134, v160 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[226:233], v[194:201], v[54:57], v134, v160 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[218:225], v[194:201], v[58:61], v134, v160 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[210:217], v[194:201], v[62:65], v134, v160 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[234:241], v[186:193], v[34:37], v134, v160 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[226:233], v[186:193], v[38:41], v134, v160 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[218:225], v[186:193], v[42:45], v134, v160 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[210:217], v[186:193], v[46:49], v134, v160 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[218:221], v158 offset:25344
	ds_read_b128 v[222:225], v158 offset:25408
	ds_read_b128 v[210:213], v158 offset:29568
	ds_read_b128 v[214:217], v158 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[170:177], v[202:209], v[82:85], v135, v160 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[162:169], v[202:209], v[86:89], v135, v160 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[218:225], v[202:209], v[90:93], v135, v160 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[210:217], v[202:209], v[94:97], v135, v160 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s50, s50, 5
	s_cmp_ge_i32 s50, s36
	s_cbranch_scc1 .LBB0_19
; %bb.61:                               ;   in Loop: Header=BB0_20 Depth=2
	s_andn2_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_18
; %bb.62:                               ;   in Loop: Header=BB0_20 Depth=2
	s_mov_b32 m0, s92
	s_add_i32 s15, s60, 0x280
	buffer_load_dwordx4 v147, s[4:7], s15 offen lds
	s_mov_b32 m0, s93
	s_nop 0
	buffer_load_dwordx4 v148, s[4:7], s15 offen lds
	s_mov_b32 m0, s94
	s_nop 0
	buffer_load_dwordx4 v149, s[4:7], s15 offen lds
	s_mov_b32 m0, s95
	s_nop 0
	buffer_load_dwordx4 v150, s[4:7], s15 offen lds
	s_add_i32 s15, s15, s49
	s_mov_b32 m0, s96
	s_nop 0
	buffer_load_dwordx4 v147, s[4:7], s15 offen lds
	s_mov_b32 m0, s97
	s_nop 0
	buffer_load_dwordx4 v148, s[4:7], s15 offen lds
	s_mov_b32 m0, s98
	s_nop 0
	buffer_load_dwordx4 v149, s[4:7], s15 offen lds
	s_mov_b32 m0, s99
	s_nop 0
	buffer_load_dwordx4 v150, s[4:7], s15 offen lds
	s_branch .LBB0_18
.LBB0_63:                               ;   in Loop: Header=BB0_3 Depth=1
	v_mov_b32_e32 v18, 0
	s_mov_b32 s28, s37
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
	s_branch .LBB0_79
.LBB0_64:                               ;   in Loop: Header=BB0_3 Depth=1
	v_mov_b32_e32 v17, 0
	s_mov_b32 s29, 0
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
                                        ; implicit-def: $sgpr71
	s_mov_b32 s28, s37
	s_cbranch_execnz .LBB0_66
	s_branch .LBB0_79
.LBB0_65:                               ; %._crit_edge.loopexit.unr-lcssa
                                        ;   in Loop: Header=BB0_3 Depth=1
	v_readlane_b32 s14, v242, 0
	v_readlane_b32 s76, v242, 3
	s_add_i32 s24, s28, 1
	s_mov_b32 s29, s57
	v_readlane_b32 s15, v242, 1
	s_movk_i32 s19, 0x80
	v_readlane_b32 s77, v242, 4
	s_and_b64 vcc, exec, s[14:15]
	s_mov_b32 s28, s37
	s_cbranch_vccz .LBB0_79
.LBB0_66:                               ; %.epil.preheader
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b32 s50, 0
	s_mov_b32 s28, s37
	s_branch .LBB0_69
.LBB0_67:                               ;   in Loop: Header=BB0_69 Depth=2
	; sched_barrier mask(0x00000000)
.LBB0_68:                               ;   in Loop: Header=BB0_69 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[164:171], v[172:179], v[66:69], v135, v153 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[156:163], v[172:179], v[70:73], v135, v153 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[212:219], v[172:179], v[74:77], v135, v153 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[204:211], v[172:179], v[78:81], v135, v153 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[164:171], v[196:203], v[18:21], v135, v153 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[156:163], v[196:203], v[22:25], v135, v153 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[212:219], v[196:203], v[26:29], v135, v153 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[204:211], v[196:203], v[30:33], v135, v153 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[164:171], v[180:187], v[2:5], v135, v153 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[156:163], v[180:187], v[6:9], v135, v153 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[212:219], v[180:187], v[10:13], v135, v153 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[204:211], v[180:187], v[14:17], v135, v153 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_add_i32 s24, s29, 1
	s_add_i32 s50, s50, 1
	s_cmp_lg_u32 s50, s56
	s_cbranch_scc0 .LBB0_79
.LBB0_69:                               ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_lshl_b32 s14, s28, 10
	v_add_u32_e32 v134, s14, v151
	ds_read_b32 v153, v134
	v_add_u32_e32 v134, s14, v152
	s_mul_i32 s60, s28, 0x8400
	;;#ASMSTART
	ds_read2st64_b32 v[134:135], v134 offset0:0 offset1:2

	;;#ASMEND
	v_add_u32_e32 v155, s60, v143
	ds_read_b128 v[188:191], v155
	ds_read_b128 v[192:195], v155 offset:64
	ds_read_b128 v[172:175], v155 offset:8448
	ds_read_b128 v[176:179], v155 offset:8512
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v154, s60, v144
	ds_read_b128 v[228:231], v154
	ds_read_b128 v[232:235], v154 offset:64
	ds_read_b128 v[220:223], v154 offset:4224
	ds_read_b128 v[224:227], v154 offset:4288
	ds_read_b128 v[212:215], v154 offset:8448
	ds_read_b128 v[216:219], v154 offset:8512
	ds_read_b128 v[204:207], v154 offset:12672
	ds_read_b128 v[208:211], v154 offset:12736
	ds_read_b128 v[164:167], v154 offset:16896
	ds_read_b128 v[168:171], v154 offset:16960
	ds_read_b128 v[156:159], v154 offset:21120
	ds_read_b128 v[160:163], v154 offset:21184
	; sched_barrier mask(0x00000000)
	s_mov_b32 s73, s29
	s_mov_b32 s29, s24
	s_cmp_lt_i32 s69, 1
	s_cbranch_scc1 .LBB0_72
; %bb.70:                               ; %LeafBlock4250
                                        ;   in Loop: Header=BB0_69 Depth=2
	s_cmp_eq_u32 s69, 1
	s_cbranch_scc0 .LBB0_73
; %bb.71:                               ;   in Loop: Header=BB0_69 Depth=2
	s_mov_b64 s[14:15], -1
	s_mov_b32 s71, 0x21800
	s_branch .LBB0_74
.LBB0_72:                               ;   in Loop: Header=BB0_69 Depth=2
	s_mov_b32 s71, 0x21000
	s_mov_b32 s18, s16
	s_mov_b64 s[24:25], s[34:35]
	s_mov_b64 s[26:27], s[22:23]
	s_xor_b32 s28, s28, 1
	s_cbranch_execnz .LBB0_75
	s_branch .LBB0_76
.LBB0_73:                               ;   in Loop: Header=BB0_69 Depth=2
	s_mov_b64 s[14:15], 0
	s_mov_b32 s71, 0x21000
.LBB0_74:                               ; %Flow4349
                                        ;   in Loop: Header=BB0_69 Depth=2
	s_mov_b32 s18, s17
	s_mov_b64 s[24:25], s[12:13]
	s_mov_b64 s[26:27], s[6:7]
	s_xor_b32 s28, s28, 1
	s_and_b64 vcc, exec, s[14:15]
	s_cbranch_vccz .LBB0_76
.LBB0_75:                               ; %.sink.split.i.epil
                                        ;   in Loop: Header=BB0_69 Depth=2
	s_lshl_b32 s15, s28, 10
	s_cmp_lg_u32 s71, -1
	s_mul_i32 s14, s18, s29
	s_cselect_b32 s18, s71, 0
	s_add_i32 m0, s15, s18
	s_nop 0
	buffer_load_dwordx4 v136, s[24:27], s14 offen lds
.LBB0_76:                               ; %_ZZ49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.epil
                                        ;   in Loop: Header=BB0_69 Depth=2
	s_mul_i32 s71, s28, 0x8400
	s_add_i32 s15, s72, s71
	s_lshl_b32 s14, s29, 7
	s_mov_b32 m0, s15
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s14 offen lds
	s_add_i32 m0, s15, 0x2100
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], s14 offen lds
	s_add_i32 s14, s29, s8
	s_lshl_b32 s14, s14, 7
	s_add_i32 m0, s15, 0x4200
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s14 offen lds
	s_add_i32 m0, s15, 0x6300
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], s14 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(8)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[228:235], v[188:195], v[98:101], v134, v153 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[220:227], v[188:195], v[102:105], v134, v153 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[196:199], v155 offset:16896
	ds_read_b128 v[200:203], v155 offset:16960
	ds_read_b128 v[180:183], v155 offset:25344
	ds_read_b128 v[184:187], v155 offset:25408
	s_waitcnt lgkmcnt(8)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[212:219], v[188:195], v[106:109], v134, v153 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[204:211], v[188:195], v[110:113], v134, v153 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[228:235], v[172:179], v[114:117], v134, v153 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[220:227], v[172:179], v[118:121], v134, v153 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[212:219], v[172:179], v[122:125], v134, v153 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[204:211], v[172:179], v[126:129], v134, v153 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[228:235], v[196:203], v[50:53], v134, v153 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[220:227], v[196:203], v[54:57], v134, v153 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[212:219], v[196:203], v[58:61], v134, v153 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[204:211], v[196:203], v[62:65], v134, v153 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[228:235], v[180:187], v[34:37], v134, v153 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[220:227], v[180:187], v[38:41], v134, v153 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[212:219], v[180:187], v[42:45], v134, v153 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[204:211], v[180:187], v[46:49], v134, v153 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[212:215], v154 offset:25344
	ds_read_b128 v[216:219], v154 offset:25408
	ds_read_b128 v[204:207], v154 offset:29568
	ds_read_b128 v[208:211], v154 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[164:171], v[188:195], v[82:85], v135, v153 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[156:163], v[188:195], v[86:89], v135, v153 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[212:219], v[188:195], v[90:93], v135, v153 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[204:211], v[188:195], v[94:97], v135, v153 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s14, s73, 2
	s_cmp_ge_i32 s14, s36
	s_cbranch_scc1 .LBB0_68
; %bb.77:                               ;   in Loop: Header=BB0_69 Depth=2
	s_andn2_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_67
; %bb.78:                               ;   in Loop: Header=BB0_69 Depth=2
	s_add_i32 s18, s60, s67
	s_add_i32 s18, s18, 0x10800
	s_lshl_b32 s15, s14, 7
	s_mov_b32 m0, s18
	s_add_i32 s14, s14, s9
	buffer_load_dwordx4 v147, s[4:7], s15 offen lds
	s_add_i32 m0, s18, 0x2100
	s_lshl_b32 s14, s14, 7
	buffer_load_dwordx4 v148, s[4:7], s15 offen lds
	s_add_i32 m0, s18, 0x1080
	s_nop 0
	buffer_load_dwordx4 v149, s[4:7], s15 offen lds
	s_add_i32 m0, s18, 0x3180
	s_nop 0
	buffer_load_dwordx4 v150, s[4:7], s15 offen lds
	s_add_i32 m0, s18, 0x4200
	s_nop 0
	buffer_load_dwordx4 v147, s[4:7], s14 offen lds
	s_add_i32 m0, s18, 0x6300
	s_nop 0
	buffer_load_dwordx4 v148, s[4:7], s14 offen lds
	s_add_i32 m0, s18, 0x5280
	s_nop 0
	buffer_load_dwordx4 v149, s[4:7], s14 offen lds
	s_add_i32 m0, s18, 0x7380
	s_nop 0
	buffer_load_dwordx4 v150, s[4:7], s14 offen lds
	s_branch .LBB0_67
.LBB0_79:                               ; %._crit_edge
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_lshl_b32 s2, s28, 10
	v_or_b32_e32 v134, s2, v146
	v_add_u32_e32 v134, 0x21000, v134
	s_add_i32 s2, s2, 0x21800
	ds_read_b32 v146, v134
	v_add_u32_e32 v134, s2, v145
	;;#ASMSTART
	ds_read2st64_b32 v[134:135], v134 offset0:0 offset1:2

	;;#ASMEND
	v_add_u32_e32 v143, s71, v143
	ds_read_b128 v[172:175], v143
	ds_read_b128 v[176:179], v143 offset:64
	ds_read_b128 v[164:167], v143 offset:8448
	ds_read_b128 v[168:171], v143 offset:8512
	ds_read_b128 v[156:159], v143 offset:16896
	ds_read_b128 v[160:163], v143 offset:16960
	ds_read_b128 v[148:151], v143 offset:25344
	ds_read_b128 v[152:155], v143 offset:25408
	v_add_u32_e32 v143, s71, v144
	ds_read_b128 v[204:207], v143
	ds_read_b128 v[208:211], v143 offset:64
	ds_read_b128 v[196:199], v143 offset:4224
	ds_read_b128 v[200:203], v143 offset:4288
	ds_read_b128 v[188:191], v143 offset:8448
	ds_read_b128 v[192:195], v143 offset:8512
	ds_read_b128 v[180:183], v143 offset:12672
	ds_read_b128 v[184:187], v143 offset:12736
	s_cmp_lg_u32 s61, 3
	s_cselect_b64 s[2:3], -1, 0
	s_cmp_lt_i32 s70, s58
	s_cselect_b64 s[14:15], -1, 0
	s_and_b64 s[14:15], s[2:3], s[14:15]
	v_cndmask_b32_e64 v144, 0, 1, s[14:15]
	v_cmp_ne_u32_e64 s[2:3], 1, v144
	s_andn2_b64 vcc, exec, s[14:15]
	s_xor_b32 s24, s28, 1
	s_waitcnt lgkmcnt(0)
	s_cbranch_vccnz .LBB0_87
; %bb.80:                               ; %NodeBlock4256
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_lt_i32 s69, 1
	s_mov_b64 s[14:15], -1
	s_cbranch_scc1 .LBB0_84
; %bb.81:                               ; %LeafBlock4254
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_eq_u32 s69, 1
	s_cbranch_scc0 .LBB0_83
; %bb.82:                               ;   in Loop: Header=BB0_3 Depth=1
	s_lshl_b32 s14, s24, 10
	s_add_i32 m0, s14, 0x21800
	s_mov_b32 s14, s6
	s_mov_b32 s15, s7
	buffer_load_dwordx4 v136, s[12:15], 0 offen lds
.LBB0_83:                               ; %Flow
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b64 s[14:15], 0
.LBB0_84:                               ; %Flow4333
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_andn2_b64 vcc, exec, s[14:15]
	s_cbranch_vccnz .LBB0_86
; %bb.85:                               ;   in Loop: Header=BB0_3 Depth=1
	s_add_u32 s72, s34, s44
	v_readlane_b32 s14, v242, 2
	s_addc_u32 s14, s68, s14
	s_and_b32 s73, s14, 0xffff
	s_lshl_b32 s14, s24, 10
	s_mov_b32 s74, s22
	s_mov_b32 s75, s23
	s_add_i32 m0, s14, 0x21000
	s_nop 0
	buffer_load_dwordx4 v136, s[72:75], 0 offen lds
.LBB0_86:                               ;   in Loop: Header=BB0_3 Depth=1
	s_add_u32 s20, s20, s52
	s_addc_u32 s14, s65, s59
	s_and_b32 s21, s14, 0xffff
	s_mul_i32 s14, s24, 0x8400
	s_add_i32 s15, s67, s66
	s_add_i32 s14, s15, s14
	s_mov_b32 m0, s14
	s_add_i32 s15, s14, 0x10800
	buffer_load_dwordx4 v132, s[20:23], 0 offen lds
	s_add_i32 m0, s14, 0x2100
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], 0 offen lds
	s_mov_b32 m0, s15
	s_nop 0
	buffer_load_dwordx4 v142, s[4:7], 0 offen lds
	s_add_i32 m0, s15, 0x2100
	s_nop 0
	buffer_load_dwordx4 v133, s[4:7], 0 offen lds
	s_add_i32 m0, s14, 0x4200
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s48 offen lds
	s_add_i32 m0, s14, 0x6300
	s_nop 0
	buffer_load_dwordx4 v141, s[20:23], s48 offen lds
	s_add_i32 m0, s15, 0x4200
	s_nop 0
	buffer_load_dwordx4 v142, s[4:7], s49 offen lds
	s_add_i32 m0, s15, 0x6300
	s_nop 0
	buffer_load_dwordx4 v133, s[4:7], s49 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_87:                               ;   in Loop: Header=BB0_3 Depth=1
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[204:211], v[172:179], v[98:101], v134, v146 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[196:203], v[172:179], v[102:105], v134, v146 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[188:195], v[172:179], v[106:109], v134, v146 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[180:187], v[172:179], v[110:113], v134, v146 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[204:211], v[164:171], v[114:117], v134, v146 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[196:203], v[164:171], v[118:121], v134, v146 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[188:195], v[164:171], v[122:125], v134, v146 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[180:187], v[164:171], v[126:129], v134, v146 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[204:211], v[156:163], v[50:53], v134, v146 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[196:203], v[156:163], v[54:57], v134, v146 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[188:195], v[156:163], v[58:61], v134, v146 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[180:187], v[156:163], v[62:65], v134, v146 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[204:211], v[148:155], v[34:37], v134, v146 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[196:203], v[148:155], v[38:41], v134, v146 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[188:195], v[148:155], v[42:45], v134, v146 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[180:187], v[148:155], v[46:49], v134, v146 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[204:207], v143 offset:16896
	ds_read_b128 v[208:211], v143 offset:16960
	ds_read_b128 v[196:199], v143 offset:21120
	ds_read_b128 v[200:203], v143 offset:21184
	ds_read_b128 v[188:191], v143 offset:25344
	ds_read_b128 v[192:195], v143 offset:25408
	ds_read_b128 v[180:183], v143 offset:29568
	ds_read_b128 v[184:187], v143 offset:29632
	s_waitcnt lgkmcnt(6)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[204:211], v[172:179], v[82:85], v135, v146 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[196:203], v[172:179], v[86:89], v135, v146 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[188:195], v[172:179], v[90:93], v135, v146 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[180:187], v[172:179], v[94:97], v135, v146 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[204:211], v[164:171], v[66:69], v135, v146 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[196:203], v[164:171], v[70:73], v135, v146 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[188:195], v[164:171], v[74:77], v135, v146 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[180:187], v[164:171], v[78:81], v135, v146 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[204:211], v[156:163], v[18:21], v135, v146 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[196:203], v[156:163], v[22:25], v135, v146 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[188:195], v[156:163], v[26:29], v135, v146 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[180:187], v[156:163], v[30:33], v135, v146 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[204:211], v[148:155], v[2:5], v135, v146 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[196:203], v[148:155], v[6:9], v135, v146 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[188:195], v[148:155], v[10:13], v135, v146 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[180:187], v[148:155], v[14:17], v135, v146 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_1
; %bb.88:                               ;   in Loop: Header=BB0_3 Depth=1
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b32 s37, s24
	s_branch .LBB0_1
.LBB0_89:
	s_endpgm
.Lfunc_end0:
	.size	_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs, .Lfunc_end0-_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
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
		.amdhsa_next_free_vgpr 243
		.amdhsa_next_free_sgpr 100
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
	.section	.text._Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,"axG",@progbits,_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs,comdat
                                        ; -- End function
	.set .L_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_vgpr, 243
	.set .L_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_agpr, 0
	.set .L_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.numbered_sgpr, 100
	.set .L_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_named_barrier, 0
	.set .L_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.private_seg_size, 0
	.set .L_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_vcc, 1
	.set .L_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_flat_scratch, 0
	.set .L_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_dyn_sized_stack, 0
	.set .L_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_recursion, 0
	.set .L_Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 10912
; TotalNumSgprs: 106
; NumVgprs: 243
; NumAgprs: 0
; TotalNumVgprs: 243
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 139264 bytes/workgroup (compile time only)
; SGPRBlocks: 13
; VGPRBlocks: 30
; NumSGPRsForWavesPerEU: 106
; NumVGPRsForWavesPerEU: 243
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
	.type	__hip_cuid_802a6759c45a5bd6,@object ; @__hip_cuid_802a6759c45a5bd6
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_802a6759c45a5bd6
__hip_cuid_802a6759c45a5bd6:
	.byte	0                               ; 0x0
	.size	__hip_cuid_802a6759c45a5bd6, 1

	.ident	"AMD clang version 23.0.0git (https://github.com/ROCm/llvm-project.git 46fcb339fb61119b337f973c7ca9e710a319fdd0+PATCHED:440716f8b87be9d8e20ed910e10e5b6d14d57cf6)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_802a6759c45a5bd6
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
    .name:           _Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs
    .private_segment_fixed_size: 0
    .sgpr_count:     106
    .sgpr_spill_count: 5
    .symbol:         _Z49gemm_a8w8_mxfp8_scale_fixed_b_asym_b_read2_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     243
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
