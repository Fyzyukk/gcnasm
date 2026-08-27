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
	s_load_dwordx4 s[24:27], s[0:1], 0x0
	s_load_dwordx2 s[28:29], s[0:1], 0x10
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_load_dwordx2 s[30:31], s[0:1], 0x38
	s_load_dwordx8 s[4:11], s[0:1], 0x40
	s_waitcnt lgkmcnt(0)
	s_add_i32 s0, s16, 0xff
	s_ashr_i32 s1, s0, 31
	s_lshr_b32 s1, s1, 24
	s_add_i32 s0, s0, s1
	s_ashr_i32 s33, s0, 8
	s_add_i32 s0, s33, 3
	s_lshr_b32 s1, s0, 30
	s_add_i32 s0, s0, s1
	s_ashr_i32 s0, s0, 2
	s_abs_i32 s1, s0
	v_cvt_f32_u32_e32 v1, s1
	s_sub_i32 s19, 0, s1
	s_add_i32 s16, s17, 0x7f
	s_ashr_i32 s17, s16, 31
	v_rcp_iflag_f32_e32 v1, v1
	s_abs_i32 s18, s2
	s_lshr_b32 s17, s17, 25
	s_add_i32 s17, s16, s17
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	v_cvt_u32_f32_e32 v1, v1
	s_ashr_i32 s34, s17, 7
	s_xor_b32 s17, s2, s0
	s_ashr_i32 s17, s17, 31
	v_readfirstlane_b32 s20, v1
	s_mul_i32 s19, s19, s20
	s_mul_hi_u32 s19, s20, s19
	s_add_i32 s20, s20, s19
	s_mul_hi_u32 s19, s18, s20
	s_mul_i32 s20, s19, s1
	s_sub_i32 s18, s18, s20
	s_add_i32 s20, s19, 1
	s_sub_i32 s21, s18, s1
	s_cmp_ge_u32 s18, s1
	s_cselect_b32 s19, s20, s19
	s_cselect_b32 s18, s21, s18
	s_add_i32 s20, s19, 1
	s_cmp_ge_u32 s18, s1
	s_cselect_b32 s1, s20, s19
	s_xor_b32 s1, s1, s17
	s_sub_i32 s1, s1, s17
	s_mul_i32 s0, s1, s0
	s_sub_i32 s0, s2, s0
	s_lshl_b32 s36, s0, 2
	s_mul_i32 s0, s15, s3
	s_lshl_b32 s2, s1, 8
	s_mul_i32 s17, s8, s1
	s_add_i32 s37, s33, -1
	s_ashr_i32 s1, s0, 31
	s_add_u32 s0, s24, s0
	s_mul_i32 s15, s2, s12
	s_addc_u32 s1, s25, s1
	s_ashr_i32 s19, s15, 31
	s_add_u32 s20, s0, s15
	s_addc_u32 s0, s1, s19
	s_and_b32 s21, s0, 0xffff
	s_mul_i32 s0, s30, s3
	s_ashr_i32 s1, s0, 31
	s_add_u32 s15, s26, s0
	s_mul_i32 s0, s31, s3
	s_addc_u32 s38, s27, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s24, s28, s0
	s_mul_i32 s0, s2, s14
	s_addc_u32 s25, s29, s1
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s39, s24, s0
	s_mul_i32 s0, s10, s3
	s_addc_u32 s40, s25, s1
	s_ashr_i32 s1, s0, 31
	s_add_u32 s0, s4, s0
	s_mul_i32 s17, s17, s34
	s_addc_u32 s1, s5, s1
	s_ashr_i32 s2, s17, 31
	s_add_u32 s0, s0, s17
	s_addc_u32 s1, s1, s2
	s_mul_i32 s2, s11, s3
	s_and_b32 s1, s1, 0xffff
	s_ashr_i32 s3, s2, 31
	v_and_b32_e32 v3, 3, v0
	v_lshlrev_b32_e32 v4, 5, v0
	s_add_u32 s41, s6, s2
	v_mul_u32_u24_e32 v3, 0x420, v3
	v_and_b32_e32 v4, 0x180, v4
	v_and_b32_e32 v5, 48, v0
	s_addc_u32 s42, s7, s3
	s_lshl_b32 s44, s12, 6
	v_add3_u32 v131, v3, v5, v4
	s_lshl_b32 s45, s13, 6
	v_lshrrev_b32_e32 v3, 2, v0
	s_lshl_b32 s46, s12, 7
	s_lshl_b32 s47, s13, 7
	v_lshlrev_b32_e32 v2, 4, v0
	v_and_b32_e32 v137, 12, v3
	s_movk_i32 s2, 0xf0
	s_cmpk_lt_i32 s16, 0x100
	v_and_or_b32 v138, v2, s2, v137
	s_cselect_b64 s[10:11], -1, 0
	s_max_i32 s2, s34, 2
	s_lshl_b32 s50, s14, 9
	s_add_i32 s2, s2, -1
	s_add_i32 s49, s47, 0x80
	s_add_i32 s52, s50, 0x200
	s_and_b32 s53, s2, 3
	s_cmpk_gt_i32 s16, 0x27f
	s_cselect_b64 s[28:29], -1, 0
	s_and_b32 s54, s2, -4
	s_mov_b32 s18, -1
	s_mov_b32 s19, 0x20000
	v_lshrrev_b32_e32 v1, 1, v0
	s_cmp_lg_u32 s53, 0
	s_mov_b32 s35, 0
	s_mov_b32 s22, s18
	s_mov_b32 s23, s19
	s_mul_i32 s43, s9, s34
	v_and_b32_e32 v1, 28, v1
	v_and_b32_e32 v130, 0x70, v2
	v_and_b32_e32 v136, 0x3f0, v2
	s_movk_i32 s48, 0x80
	v_and_b32_e32 v139, 15, v0
	s_movk_i32 s51, 0x200
	s_cselect_b64 s[30:31], -1, 0
	s_branch .LBB0_3
.LBB0_1:                                ;   in Loop: Header=BB0_3 Depth=1
	s_add_i32 s35, s35, 1
	s_cmp_eq_u32 s35, 4
	s_cselect_b64 s[2:3], -1, 0
.LBB0_2:                                ; %Flow3995
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_and_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_68
.LBB0_3:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_16 Depth 2
                                        ;     Child Loop BB0_57 Depth 2
	s_add_i32 s55, s35, s36
	s_cmp_ge_i32 s55, s33
	s_mov_b64 s[2:3], -1
	s_cbranch_scc1 .LBB0_2
; %bb.4:                                ;   in Loop: Header=BB0_3 Depth=1
	v_readfirstlane_b32 s24, v0
	s_mul_i32 s2, s43, s55
	s_lshr_b32 s59, s24, 6
	s_ashr_i32 s3, s2, 31
	s_add_u32 s16, s41, s2
	s_addc_u32 s2, s42, s3
	s_and_b32 s17, s2, 0xffff
	s_cmp_lt_i32 s59, 1
	s_mov_b64 s[2:3], -1
	s_cbranch_scc1 .LBB0_8
; %bb.5:                                ; %LeafBlock
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_cmp_eq_u32 s59, 1
	s_cbranch_scc0 .LBB0_7
; %bb.6:                                ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b32 m0, 0x21800
	s_nop 0
	buffer_load_dwordx4 v136, s[16:19], 0 offen lds
.LBB0_7:                                ; %Flow3993
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b64 s[2:3], 0
.LBB0_8:                                ; %Flow3994
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_andn2_b64 vcc, exec, s[2:3]
	s_cbranch_vccnz .LBB0_10
; %bb.9:                                ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b32 s2, s22
	s_mov_b32 s3, s23
	s_mov_b32 m0, 0x21000
	s_nop 0
	buffer_load_dwordx4 v136, s[0:3], 0 offen lds
.LBB0_10:                               ;   in Loop: Header=BB0_3 Depth=1
	s_lshl_b32 s2, s55, 8
	s_mul_i32 s3, s2, s13
	s_ashr_i32 s5, s3, 31
	s_add_u32 s4, s15, s3
	s_addc_u32 s3, s38, s5
	s_lshr_b32 s57, s24, 8
	s_and_b32 s5, s3, 0xffff
	s_and_b32 s56, s59, 3
	v_lshl_or_b32 v2, s57, 5, v1
	v_or_b32_e32 v2, s56, v2
	s_cmp_gt_u32 s56, 1
	v_mad_u64_u32 v[132:133], s[26:27], v2, s12, v[130:131]
	s_cselect_b32 s25, 0x1080, 0
	s_lshl_b32 s3, s56, 9
	s_add_i32 s26, s3, 0xfffffc00
	s_cmp_lt_u32 s56, 2
	s_cselect_b32 s26, s3, s26
	s_mul_i32 s3, s57, 0x1080
	s_mul_i32 s27, s56, 0x420
	v_mad_u64_u32 v[134:135], s[60:61], v2, s13, v[130:131]
	s_add_i32 s3, s27, s3
	s_mov_b32 m0, s3
	s_add_i32 s60, s3, 0x2100
	v_add_u32_e32 v143, s44, v132
	buffer_load_dwordx4 v132, s[20:23], 0 offen lds
	s_mov_b32 m0, s60
	s_add_i32 s61, s3, 0x10800
	s_mov_b32 s6, s18
	s_mov_b32 s7, s19
	buffer_load_dwordx4 v143, s[20:23], 0 offen lds
	s_mov_b32 m0, s61
	s_add_i32 s62, s61, 0x2100
	v_add_u32_e32 v144, s45, v134
	buffer_load_dwordx4 v134, s[4:7], 0 offen lds
	s_mov_b32 m0, s62
	s_add_i32 s63, s3, 0x4200
	buffer_load_dwordx4 v144, s[4:7], 0 offen lds
	s_mov_b32 m0, s63
	s_add_i32 s64, s3, 0x6300
	buffer_load_dwordx4 v132, s[20:23], s46 offen lds
	s_mov_b32 m0, s64
	s_and_b32 s24, s24, 0xffffff00
	buffer_load_dwordx4 v143, s[20:23], s46 offen lds
	s_add_i32 m0, s61, 0x4200
	s_nop 0
	buffer_load_dwordx4 v134, s[4:7], s47 offen lds
	s_add_i32 m0, s61, 0x6300
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s47 offen lds
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_mov_b64 s[6:7], -1
	s_andn2_b64 vcc, exec, s[10:11]
	v_add_u32_e32 v133, s24, v138
	s_cbranch_vccnz .LBB0_12
; %bb.11:                               ; %.._crit_edge_crit_edge
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b64 s[6:7], 0
.LBB0_12:                               ; %Flow3992
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_add_i32 s26, s26, s25
	v_add_u32_e32 v140, s26, v131
	v_lshl_add_u32 v135, s57, 9, v131
	v_lshl_or_b32 v141, s56, 8, v138
	s_andn2_b64 vcc, exec, s[6:7]
	v_or_b32_e32 v142, s24, v138
	s_cbranch_vccnz .LBB0_52
; %bb.13:                               ; %.lr.ph
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_add_i32 m0, s61, 0x8400
	s_mov_b32 s6, s22
	s_mov_b32 s7, s23
	buffer_load_dwordx4 v134, s[4:7], s48 offen lds
	s_add_i32 m0, s61, 0xa500
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s48 offen lds
	s_add_i32 m0, s61, 0xc600
	s_nop 0
	buffer_load_dwordx4 v134, s[4:7], s49 offen lds
	s_add_i32 m0, s61, 0xe700
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s49 offen lds
	; sched_barrier mask(0x00000000)
	v_or_b32_e32 v145, 0x21000, v141
	v_add_u32_e32 v146, 0x21800, v142
	v_add_u32_e32 v147, 0x10800, v135
	v_add_u32_e32 v148, 0x21800, v133
	s_mov_b32 s24, 1
	s_andn2_b64 vcc, exec, s[28:29]
	s_mov_b32 s58, 0
	s_cbranch_vccnz .LBB0_53
; %bb.14:                               ; %.lr.ph.new
                                        ;   in Loop: Header=BB0_3 Depth=1
	v_mov_b32_e32 v114, 0
	s_add_i32 s65, s3, 0x8400
	s_add_i32 s66, s3, 0xa500
	s_add_i32 s67, s3, 0xc600
	s_add_i32 s68, s3, 0xe700
	s_add_i32 s69, s3, 0x14a00
	s_add_i32 s70, s3, 0x16b00
	s_add_i32 s71, s3, 0x18c00
	s_add_i32 s72, s3, 0x1ad00
	s_add_i32 s73, s3, 0x1ce00
	s_add_i32 s74, s3, 0x1ef00
	s_mov_b32 s24, 0
	s_mov_b32 s78, 0
	v_mov_b32_e32 v115, v114
	v_mov_b32_e32 v116, v114
	v_mov_b32_e32 v117, v114
	v_mov_b32_e32 v118, v114
	v_mov_b32_e32 v119, v114
	v_mov_b32_e32 v120, v114
	v_mov_b32_e32 v121, v114
	v_mov_b32_e32 v122, v114
	v_mov_b32_e32 v123, v114
	v_mov_b32_e32 v124, v114
	v_mov_b32_e32 v125, v114
	v_mov_b32_e32 v126, v114
	v_mov_b32_e32 v127, v114
	v_mov_b32_e32 v128, v114
	v_mov_b32_e32 v129, v114
	v_mov_b32_e32 v98, v114
	v_mov_b32_e32 v99, v114
	v_mov_b32_e32 v100, v114
	v_mov_b32_e32 v101, v114
	v_mov_b32_e32 v102, v114
	v_mov_b32_e32 v103, v114
	v_mov_b32_e32 v104, v114
	v_mov_b32_e32 v105, v114
	v_mov_b32_e32 v106, v114
	v_mov_b32_e32 v107, v114
	v_mov_b32_e32 v108, v114
	v_mov_b32_e32 v109, v114
	v_mov_b32_e32 v110, v114
	v_mov_b32_e32 v111, v114
	v_mov_b32_e32 v112, v114
	v_mov_b32_e32 v113, v114
	v_mov_b32_e32 v82, v114
	v_mov_b32_e32 v83, v114
	v_mov_b32_e32 v84, v114
	v_mov_b32_e32 v85, v114
	v_mov_b32_e32 v86, v114
	v_mov_b32_e32 v87, v114
	v_mov_b32_e32 v88, v114
	v_mov_b32_e32 v89, v114
	v_mov_b32_e32 v90, v114
	v_mov_b32_e32 v91, v114
	v_mov_b32_e32 v92, v114
	v_mov_b32_e32 v93, v114
	v_mov_b32_e32 v94, v114
	v_mov_b32_e32 v95, v114
	v_mov_b32_e32 v96, v114
	v_mov_b32_e32 v97, v114
	v_mov_b32_e32 v66, v114
	v_mov_b32_e32 v67, v114
	v_mov_b32_e32 v68, v114
	v_mov_b32_e32 v69, v114
	v_mov_b32_e32 v70, v114
	v_mov_b32_e32 v71, v114
	v_mov_b32_e32 v72, v114
	v_mov_b32_e32 v73, v114
	v_mov_b32_e32 v74, v114
	v_mov_b32_e32 v75, v114
	v_mov_b32_e32 v76, v114
	v_mov_b32_e32 v77, v114
	v_mov_b32_e32 v78, v114
	v_mov_b32_e32 v79, v114
	v_mov_b32_e32 v80, v114
	v_mov_b32_e32 v81, v114
	v_mov_b32_e32 v50, v114
	v_mov_b32_e32 v51, v114
	v_mov_b32_e32 v52, v114
	v_mov_b32_e32 v53, v114
	v_mov_b32_e32 v54, v114
	v_mov_b32_e32 v55, v114
	v_mov_b32_e32 v56, v114
	v_mov_b32_e32 v57, v114
	v_mov_b32_e32 v58, v114
	v_mov_b32_e32 v59, v114
	v_mov_b32_e32 v60, v114
	v_mov_b32_e32 v61, v114
	v_mov_b32_e32 v62, v114
	v_mov_b32_e32 v63, v114
	v_mov_b32_e32 v64, v114
	v_mov_b32_e32 v65, v114
	v_mov_b32_e32 v34, v114
	v_mov_b32_e32 v35, v114
	v_mov_b32_e32 v36, v114
	v_mov_b32_e32 v37, v114
	v_mov_b32_e32 v38, v114
	v_mov_b32_e32 v39, v114
	v_mov_b32_e32 v40, v114
	v_mov_b32_e32 v41, v114
	v_mov_b32_e32 v42, v114
	v_mov_b32_e32 v43, v114
	v_mov_b32_e32 v44, v114
	v_mov_b32_e32 v45, v114
	v_mov_b32_e32 v46, v114
	v_mov_b32_e32 v47, v114
	v_mov_b32_e32 v48, v114
	v_mov_b32_e32 v49, v114
	v_mov_b32_e32 v18, v114
	v_mov_b32_e32 v19, v114
	v_mov_b32_e32 v20, v114
	v_mov_b32_e32 v21, v114
	v_mov_b32_e32 v22, v114
	v_mov_b32_e32 v23, v114
	v_mov_b32_e32 v24, v114
	v_mov_b32_e32 v25, v114
	v_mov_b32_e32 v26, v114
	v_mov_b32_e32 v27, v114
	v_mov_b32_e32 v28, v114
	v_mov_b32_e32 v29, v114
	v_mov_b32_e32 v30, v114
	v_mov_b32_e32 v31, v114
	v_mov_b32_e32 v32, v114
	v_mov_b32_e32 v33, v114
	v_mov_b32_e32 v2, v114
	v_mov_b32_e32 v3, v114
	v_mov_b32_e32 v4, v114
	v_mov_b32_e32 v5, v114
	v_mov_b32_e32 v6, v114
	v_mov_b32_e32 v7, v114
	v_mov_b32_e32 v8, v114
	v_mov_b32_e32 v9, v114
	v_mov_b32_e32 v10, v114
	v_mov_b32_e32 v11, v114
	v_mov_b32_e32 v12, v114
	v_mov_b32_e32 v13, v114
	v_mov_b32_e32 v14, v114
	v_mov_b32_e32 v15, v114
	v_mov_b32_e32 v16, v114
	v_mov_b32_e32 v17, v114
	s_branch .LBB0_16
	.p2align	5
.LBB0_15:                               ;   in Loop: Header=BB0_16 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[160:167], v[168:175], v[66:69], v150, v149 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[152:159], v[168:175], v[70:73], v150, v149 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[208:215], v[168:175], v[74:77], v150, v149 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[200:207], v[168:175], v[78:81], v150, v149 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[160:167], v[184:191], v[18:21], v150, v149 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[152:159], v[184:191], v[22:25], v150, v149 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[208:215], v[184:191], v[26:29], v150, v149 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[200:207], v[184:191], v[30:33], v150, v149 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[160:167], v[176:183], v[2:5], v150, v149 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[152:159], v[176:183], v[6:9], v150, v149 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[208:215], v[176:183], v[10:13], v150, v149 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[200:207], v[176:183], v[14:17], v150, v149 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_cmp_lg_u32 s54, s78
	s_cbranch_scc0 .LBB0_54
.LBB0_16:                               ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	ds_read_b32 v149, v145
	ds_read_b32 v151, v146
	ds_read_b128 v[184:187], v140
	ds_read_b128 v[188:191], v140 offset:64
	ds_read_b128 v[168:171], v140 offset:8448
	ds_read_b128 v[172:175], v140 offset:8512
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[224:227], v147
	ds_read_b128 v[228:231], v147 offset:64
	ds_read_b128 v[216:219], v147 offset:4224
	ds_read_b128 v[220:223], v147 offset:4288
	ds_read_b128 v[208:211], v147 offset:8448
	ds_read_b128 v[212:215], v147 offset:8512
	ds_read_b128 v[200:203], v147 offset:12672
	ds_read_b128 v[204:207], v147 offset:12736
	ds_read_b128 v[160:163], v147 offset:16896
	ds_read_b128 v[164:167], v147 offset:16960
	ds_read_b128 v[152:155], v147 offset:21120
	ds_read_b128 v[156:159], v147 offset:21184
	ds_read_b32 v150, v148 offset:512
	; sched_barrier mask(0x00000000)
	s_mov_b32 s76, s78
	s_mov_b32 s75, s24
	s_cmp_lt_i32 s59, 1
	s_cbranch_scc1 .LBB0_19
; %bb.17:                               ; %LeafBlock3901
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_cmp_eq_u32 s59, 1
	s_cbranch_scc0 .LBB0_20
; %bb.18:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b64 s[6:7], -1
	s_mov_b32 s77, 0x21800
	s_branch .LBB0_21
	.p2align	5
.LBB0_19:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 s77, 0x21000
	s_mov_b32 s78, s8
	s_mov_b64 s[24:25], s[0:1]
	s_mov_b64 s[26:27], s[22:23]
	s_cbranch_execnz .LBB0_22
	s_branch .LBB0_23
	.p2align	5
.LBB0_20:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b64 s[6:7], 0
	s_mov_b32 s77, 0x21000
.LBB0_21:                               ; %Flow3986
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 s78, s9
	s_mov_b64 s[24:25], s[16:17]
	s_mov_b64 s[26:27], s[18:19]
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_23
.LBB0_22:                               ; %.sink.split.i
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_add_i32 s6, s76, 1
	s_cmp_lg_u32 s77, -1
	s_cselect_b32 s7, s77, 0
	s_mul_i32 s6, s78, s6
	s_add_i32 m0, s7, 0x400
	s_nop 0
	buffer_load_dwordx4 v136, s[24:27], s6 offen lds
.LBB0_23:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 m0, s65
	s_add_i32 s6, s75, 0x80
	buffer_load_dwordx4 v132, s[20:23], s6 offen lds
	s_mov_b32 m0, s66
	s_add_i32 s77, s46, s75
	buffer_load_dwordx4 v143, s[20:23], s6 offen lds
	s_add_i32 s6, s77, 0x80
	s_mov_b32 m0, s67
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s6 offen lds
	s_mov_b32 m0, s68
	s_nop 0
	buffer_load_dwordx4 v143, s[20:23], s6 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[224:231], v[184:191], v[114:117], v151, v149 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[216:223], v[184:191], v[118:121], v151, v149 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[192:195], v140 offset:16896
	ds_read_b128 v[196:199], v140 offset:16960
	ds_read_b128 v[176:179], v140 offset:25344
	ds_read_b128 v[180:183], v140 offset:25408
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[208:215], v[184:191], v[122:125], v151, v149 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[200:207], v[184:191], v[126:129], v151, v149 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[224:231], v[168:175], v[98:101], v151, v149 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[216:223], v[168:175], v[102:105], v151, v149 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[208:215], v[168:175], v[106:109], v151, v149 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[200:207], v[168:175], v[110:113], v151, v149 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[224:231], v[192:199], v[50:53], v151, v149 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[216:223], v[192:199], v[54:57], v151, v149 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[208:215], v[192:199], v[58:61], v151, v149 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[200:207], v[192:199], v[62:65], v151, v149 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[224:231], v[176:183], v[34:37], v151, v149 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[216:223], v[176:183], v[38:41], v151, v149 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[208:215], v[176:183], v[42:45], v151, v149 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[200:207], v[176:183], v[46:49], v151, v149 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[208:211], v147 offset:25344
	ds_read_b128 v[212:215], v147 offset:25408
	ds_read_b128 v[200:203], v147 offset:29568
	ds_read_b128 v[204:207], v147 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[160:167], v[184:191], v[82:85], v150, v149 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[152:159], v[184:191], v[86:89], v150, v149 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[208:215], v[184:191], v[90:93], v150, v149 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[200:207], v[184:191], v[94:97], v150, v149 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s78, s76, 2
	s_cmp_ge_i32 s78, s34
	s_cbranch_scc1 .LBB0_25
; %bb.24:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 m0, s61
	s_add_i32 s24, s75, 0x100
	s_mov_b32 s6, s22
	s_mov_b32 s7, s23
	buffer_load_dwordx4 v134, s[4:7], s24 offen lds
	s_mov_b32 m0, s62
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s24 offen lds
	s_add_i32 s24, s24, s47
	s_mov_b32 m0, s69
	s_nop 0
	buffer_load_dwordx4 v134, s[4:7], s24 offen lds
	s_mov_b32 m0, s70
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s24 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_25:                               ;   in Loop: Header=BB0_16 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[160:167], v[168:175], v[66:69], v150, v149 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[152:159], v[168:175], v[70:73], v150, v149 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[208:215], v[168:175], v[74:77], v150, v149 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[200:207], v[168:175], v[78:81], v150, v149 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[160:167], v[192:199], v[18:21], v150, v149 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[152:159], v[192:199], v[22:25], v150, v149 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[208:215], v[192:199], v[26:29], v150, v149 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[200:207], v[192:199], v[30:33], v150, v149 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[160:167], v[176:183], v[2:5], v150, v149 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[152:159], v[176:183], v[6:9], v150, v149 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[208:215], v[176:183], v[10:13], v150, v149 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[200:207], v[176:183], v[14:17], v150, v149 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	ds_read_b32 v149, v145 offset:1024
	ds_read_b32 v151, v146 offset:1024
	ds_read_b128 v[192:195], v140 offset:33792
	ds_read_b128 v[196:199], v140 offset:33856
	ds_read_b128 v[168:171], v140 offset:42240
	ds_read_b128 v[172:175], v140 offset:42304
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[224:227], v147 offset:33792
	ds_read_b128 v[228:231], v147 offset:33856
	ds_read_b128 v[216:219], v147 offset:38016
	ds_read_b128 v[220:223], v147 offset:38080
	ds_read_b128 v[208:211], v147 offset:42240
	ds_read_b128 v[212:215], v147 offset:42304
	ds_read_b128 v[200:203], v147 offset:46464
	ds_read_b128 v[204:207], v147 offset:46528
	ds_read_b128 v[160:163], v147 offset:50688
	ds_read_b128 v[164:167], v147 offset:50752
	ds_read_b128 v[152:155], v147 offset:54912
	ds_read_b128 v[156:159], v147 offset:54976
	ds_read_b32 v150, v148 offset:1536
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s59, 1
	s_cbranch_scc1 .LBB0_28
; %bb.26:                               ; %LeafBlock3905
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_cmp_eq_u32 s59, 1
	s_cbranch_scc0 .LBB0_29
; %bb.27:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b64 s[6:7], -1
	s_mov_b32 s79, 0x21800
	s_branch .LBB0_30
	.p2align	5
.LBB0_28:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 s79, 0x21000
	s_mov_b32 s80, s8
	s_mov_b64 s[24:25], s[0:1]
	s_mov_b64 s[26:27], s[22:23]
	s_cbranch_execnz .LBB0_31
	s_branch .LBB0_32
	.p2align	5
.LBB0_29:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b64 s[6:7], 0
	s_mov_b32 s79, 0x21000
.LBB0_30:                               ; %Flow3984
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 s80, s9
	s_mov_b64 s[24:25], s[16:17]
	s_mov_b64 s[26:27], s[18:19]
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_32
.LBB0_31:                               ; %.sink.split.i.1
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_cmp_lg_u32 s79, -1
	s_mul_i32 s6, s80, s78
	s_cselect_b32 m0, s79, 0
	s_nop 0
	buffer_load_dwordx4 v136, s[24:27], s6 offen lds
.LBB0_32:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.1
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 m0, s3
	s_add_i32 s6, s75, 0x100
	buffer_load_dwordx4 v132, s[20:23], s6 offen lds
	s_mov_b32 m0, s60
	s_nop 0
	buffer_load_dwordx4 v143, s[20:23], s6 offen lds
	s_add_i32 s6, s77, 0x100
	s_mov_b32 m0, s63
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s6 offen lds
	s_mov_b32 m0, s64
	s_nop 0
	buffer_load_dwordx4 v143, s[20:23], s6 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[224:231], v[192:199], v[114:117], v151, v149 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[216:223], v[192:199], v[118:121], v151, v149 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[184:187], v140 offset:50688
	ds_read_b128 v[188:191], v140 offset:50752
	ds_read_b128 v[176:179], v140 offset:59136
	ds_read_b128 v[180:183], v140 offset:59200
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[208:215], v[192:199], v[122:125], v151, v149 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[200:207], v[192:199], v[126:129], v151, v149 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[224:231], v[168:175], v[98:101], v151, v149 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[216:223], v[168:175], v[102:105], v151, v149 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[208:215], v[168:175], v[106:109], v151, v149 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[200:207], v[168:175], v[110:113], v151, v149 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[224:231], v[184:191], v[50:53], v151, v149 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[216:223], v[184:191], v[54:57], v151, v149 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[208:215], v[184:191], v[58:61], v151, v149 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[200:207], v[184:191], v[62:65], v151, v149 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[224:231], v[176:183], v[34:37], v151, v149 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[216:223], v[176:183], v[38:41], v151, v149 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[208:215], v[176:183], v[42:45], v151, v149 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[200:207], v[176:183], v[46:49], v151, v149 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[208:211], v147 offset:59136
	ds_read_b128 v[212:215], v147 offset:59200
	ds_read_b128 v[200:203], v147 offset:63360
	ds_read_b128 v[204:207], v147 offset:63424
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[160:167], v[192:199], v[82:85], v150, v149 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[152:159], v[192:199], v[86:89], v150, v149 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[208:215], v[192:199], v[90:93], v150, v149 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[200:207], v[192:199], v[94:97], v150, v149 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s78, s76, 3
	s_cmp_ge_i32 s78, s34
	s_cbranch_scc1 .LBB0_34
; %bb.33:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 m0, s71
	s_add_i32 s24, s75, 0x180
	s_mov_b32 s6, s22
	s_mov_b32 s7, s23
	buffer_load_dwordx4 v134, s[4:7], s24 offen lds
	s_mov_b32 m0, s72
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s24 offen lds
	s_add_i32 s24, s24, s47
	s_mov_b32 m0, s73
	s_nop 0
	buffer_load_dwordx4 v134, s[4:7], s24 offen lds
	s_mov_b32 m0, s74
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s24 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_34:                               ;   in Loop: Header=BB0_16 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[160:167], v[168:175], v[66:69], v150, v149 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[152:159], v[168:175], v[70:73], v150, v149 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[208:215], v[168:175], v[74:77], v150, v149 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[200:207], v[168:175], v[78:81], v150, v149 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[160:167], v[184:191], v[18:21], v150, v149 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[152:159], v[184:191], v[22:25], v150, v149 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[208:215], v[184:191], v[26:29], v150, v149 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[200:207], v[184:191], v[30:33], v150, v149 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[160:167], v[176:183], v[2:5], v150, v149 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[152:159], v[176:183], v[6:9], v150, v149 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[208:215], v[176:183], v[10:13], v150, v149 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[200:207], v[176:183], v[14:17], v150, v149 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	ds_read_b32 v149, v145
	ds_read_b32 v151, v146
	ds_read_b128 v[192:195], v140
	ds_read_b128 v[196:199], v140 offset:64
	ds_read_b128 v[168:171], v140 offset:8448
	ds_read_b128 v[172:175], v140 offset:8512
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[224:227], v147
	ds_read_b128 v[228:231], v147 offset:64
	ds_read_b128 v[216:219], v147 offset:4224
	ds_read_b128 v[220:223], v147 offset:4288
	ds_read_b128 v[208:211], v147 offset:8448
	ds_read_b128 v[212:215], v147 offset:8512
	ds_read_b128 v[200:203], v147 offset:12672
	ds_read_b128 v[204:207], v147 offset:12736
	ds_read_b128 v[160:163], v147 offset:16896
	ds_read_b128 v[164:167], v147 offset:16960
	ds_read_b128 v[152:155], v147 offset:21120
	ds_read_b128 v[156:159], v147 offset:21184
	ds_read_b32 v150, v148 offset:512
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s59, 1
	s_cbranch_scc1 .LBB0_37
; %bb.35:                               ; %LeafBlock3909
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_cmp_eq_u32 s59, 1
	s_cbranch_scc0 .LBB0_38
; %bb.36:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b64 s[6:7], -1
	s_mov_b32 s79, 0x21800
	s_branch .LBB0_39
	.p2align	5
.LBB0_37:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 s79, 0x21000
	s_mov_b32 s80, s8
	s_mov_b64 s[24:25], s[0:1]
	s_mov_b64 s[26:27], s[22:23]
	s_cbranch_execnz .LBB0_40
	s_branch .LBB0_41
	.p2align	5
.LBB0_38:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b64 s[6:7], 0
	s_mov_b32 s79, 0x21000
.LBB0_39:                               ; %Flow3982
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 s80, s9
	s_mov_b64 s[24:25], s[16:17]
	s_mov_b64 s[26:27], s[18:19]
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_41
.LBB0_40:                               ; %.sink.split.i.2
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_cmp_lg_u32 s79, -1
	s_cselect_b32 s7, s79, 0
	s_mul_i32 s6, s80, s78
	s_add_i32 m0, s7, 0x400
	s_nop 0
	buffer_load_dwordx4 v136, s[24:27], s6 offen lds
.LBB0_41:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.2
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 m0, s65
	s_add_i32 s6, s75, 0x180
	buffer_load_dwordx4 v132, s[20:23], s6 offen lds
	s_mov_b32 m0, s66
	s_nop 0
	buffer_load_dwordx4 v143, s[20:23], s6 offen lds
	s_add_i32 s6, s77, 0x180
	s_mov_b32 m0, s67
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s6 offen lds
	s_mov_b32 m0, s68
	s_nop 0
	buffer_load_dwordx4 v143, s[20:23], s6 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[224:231], v[192:199], v[114:117], v151, v149 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[216:223], v[192:199], v[118:121], v151, v149 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[184:187], v140 offset:16896
	ds_read_b128 v[188:191], v140 offset:16960
	ds_read_b128 v[176:179], v140 offset:25344
	ds_read_b128 v[180:183], v140 offset:25408
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[208:215], v[192:199], v[122:125], v151, v149 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[200:207], v[192:199], v[126:129], v151, v149 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[224:231], v[168:175], v[98:101], v151, v149 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[216:223], v[168:175], v[102:105], v151, v149 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[208:215], v[168:175], v[106:109], v151, v149 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[200:207], v[168:175], v[110:113], v151, v149 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[224:231], v[184:191], v[50:53], v151, v149 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[216:223], v[184:191], v[54:57], v151, v149 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[208:215], v[184:191], v[58:61], v151, v149 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[200:207], v[184:191], v[62:65], v151, v149 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[224:231], v[176:183], v[34:37], v151, v149 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[216:223], v[176:183], v[38:41], v151, v149 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[208:215], v[176:183], v[42:45], v151, v149 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[200:207], v[176:183], v[46:49], v151, v149 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[208:211], v147 offset:25344
	ds_read_b128 v[212:215], v147 offset:25408
	ds_read_b128 v[200:203], v147 offset:29568
	ds_read_b128 v[204:207], v147 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[160:167], v[192:199], v[82:85], v150, v149 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[152:159], v[192:199], v[86:89], v150, v149 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[208:215], v[192:199], v[90:93], v150, v149 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[200:207], v[192:199], v[94:97], v150, v149 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s78, s76, 4
	s_cmp_ge_i32 s78, s34
	s_cbranch_scc1 .LBB0_43
; %bb.42:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 m0, s61
	s_add_i32 s24, s75, 0x200
	s_mov_b32 s6, s22
	s_mov_b32 s7, s23
	buffer_load_dwordx4 v134, s[4:7], s24 offen lds
	s_mov_b32 m0, s62
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s24 offen lds
	s_add_i32 s24, s24, s47
	s_mov_b32 m0, s69
	s_nop 0
	buffer_load_dwordx4 v134, s[4:7], s24 offen lds
	s_mov_b32 m0, s70
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s24 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_43:                               ;   in Loop: Header=BB0_16 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[160:167], v[168:175], v[66:69], v150, v149 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[152:159], v[168:175], v[70:73], v150, v149 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[208:215], v[168:175], v[74:77], v150, v149 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[200:207], v[168:175], v[78:81], v150, v149 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[160:167], v[184:191], v[18:21], v150, v149 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[152:159], v[184:191], v[22:25], v150, v149 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[208:215], v[184:191], v[26:29], v150, v149 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[200:207], v[184:191], v[30:33], v150, v149 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[160:167], v[176:183], v[2:5], v150, v149 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[152:159], v[176:183], v[6:9], v150, v149 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[208:215], v[176:183], v[10:13], v150, v149 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[200:207], v[176:183], v[14:17], v150, v149 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	ds_read_b32 v149, v145 offset:1024
	ds_read_b32 v151, v146 offset:1024
	ds_read_b128 v[192:195], v140 offset:33792
	ds_read_b128 v[196:199], v140 offset:33856
	ds_read_b128 v[168:171], v140 offset:42240
	ds_read_b128 v[172:175], v140 offset:42304
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[224:227], v147 offset:33792
	ds_read_b128 v[228:231], v147 offset:33856
	ds_read_b128 v[216:219], v147 offset:38016
	ds_read_b128 v[220:223], v147 offset:38080
	ds_read_b128 v[208:211], v147 offset:42240
	ds_read_b128 v[212:215], v147 offset:42304
	ds_read_b128 v[200:203], v147 offset:46464
	ds_read_b128 v[204:207], v147 offset:46528
	ds_read_b128 v[160:163], v147 offset:50688
	ds_read_b128 v[164:167], v147 offset:50752
	ds_read_b128 v[152:155], v147 offset:54912
	ds_read_b128 v[156:159], v147 offset:54976
	ds_read_b32 v150, v148 offset:1536
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s59, 1
	s_cbranch_scc1 .LBB0_46
; %bb.44:                               ; %LeafBlock3913
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_cmp_eq_u32 s59, 1
	s_cbranch_scc0 .LBB0_47
; %bb.45:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b64 s[6:7], -1
	s_mov_b32 s79, 0x21800
	s_branch .LBB0_48
	.p2align	5
.LBB0_46:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 s79, 0x21000
	s_mov_b32 s80, s8
	s_mov_b64 s[24:25], s[0:1]
	s_mov_b64 s[26:27], s[22:23]
	s_cbranch_execnz .LBB0_49
	s_branch .LBB0_50
	.p2align	5
.LBB0_47:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b64 s[6:7], 0
	s_mov_b32 s79, 0x21000
.LBB0_48:                               ; %Flow3980
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 s80, s9
	s_mov_b64 s[24:25], s[16:17]
	s_mov_b64 s[26:27], s[18:19]
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_50
.LBB0_49:                               ; %.sink.split.i.3
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_cmp_lg_u32 s79, -1
	s_mul_i32 s6, s80, s78
	s_cselect_b32 m0, s79, 0
	s_nop 0
	buffer_load_dwordx4 v136, s[24:27], s6 offen lds
.LBB0_50:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.3
                                        ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 m0, s3
	s_add_i32 s24, s75, 0x200
	buffer_load_dwordx4 v132, s[20:23], s24 offen lds
	s_mov_b32 m0, s60
	s_addk_i32 s77, 0x200
	buffer_load_dwordx4 v143, s[20:23], s24 offen lds
	s_mov_b32 m0, s63
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s77 offen lds
	s_mov_b32 m0, s64
	s_nop 0
	buffer_load_dwordx4 v143, s[20:23], s77 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[224:231], v[192:199], v[114:117], v151, v149 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[216:223], v[192:199], v[118:121], v151, v149 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[184:187], v140 offset:50688
	ds_read_b128 v[188:191], v140 offset:50752
	ds_read_b128 v[176:179], v140 offset:59136
	ds_read_b128 v[180:183], v140 offset:59200
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[208:215], v[192:199], v[122:125], v151, v149 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[200:207], v[192:199], v[126:129], v151, v149 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[224:231], v[168:175], v[98:101], v151, v149 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[216:223], v[168:175], v[102:105], v151, v149 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[208:215], v[168:175], v[106:109], v151, v149 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[200:207], v[168:175], v[110:113], v151, v149 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[224:231], v[184:191], v[50:53], v151, v149 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[216:223], v[184:191], v[54:57], v151, v149 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[208:215], v[184:191], v[58:61], v151, v149 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[200:207], v[184:191], v[62:65], v151, v149 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[224:231], v[176:183], v[34:37], v151, v149 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[216:223], v[176:183], v[38:41], v151, v149 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[208:215], v[176:183], v[42:45], v151, v149 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[200:207], v[176:183], v[46:49], v151, v149 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[208:211], v147 offset:59136
	ds_read_b128 v[212:215], v147 offset:59200
	ds_read_b128 v[200:203], v147 offset:63360
	ds_read_b128 v[204:207], v147 offset:63424
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[160:167], v[192:199], v[82:85], v150, v149 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[152:159], v[192:199], v[86:89], v150, v149 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[208:215], v[192:199], v[90:93], v150, v149 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[200:207], v[192:199], v[94:97], v150, v149 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s76, s76, 5
	s_cmp_ge_i32 s76, s34
	s_cbranch_scc1 .LBB0_15
; %bb.51:                               ;   in Loop: Header=BB0_16 Depth=2
	s_mov_b32 m0, s71
	s_add_i32 s25, s75, 0x280
	s_mov_b32 s6, s22
	s_mov_b32 s7, s23
	buffer_load_dwordx4 v134, s[4:7], s25 offen lds
	s_mov_b32 m0, s72
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s25 offen lds
	s_add_i32 s25, s25, s47
	s_mov_b32 m0, s73
	s_nop 0
	buffer_load_dwordx4 v134, s[4:7], s25 offen lds
	s_mov_b32 m0, s74
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s25 offen lds
	; sched_barrier mask(0x00000000)
	s_branch .LBB0_15
.LBB0_52:                               ;   in Loop: Header=BB0_3 Depth=1
	v_mov_b32_e32 v18, 0
	s_mov_b32 s58, 0
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
	s_branch .LBB0_66
.LBB0_53:                               ;   in Loop: Header=BB0_3 Depth=1
	v_mov_b32_e32 v17, 0
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
	s_mov_b32 s60, 0
	s_cbranch_execnz .LBB0_55
	s_branch .LBB0_66
.LBB0_54:                               ; %._crit_edge.loopexit.unr-lcssa
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_add_i32 s24, s78, 1
	s_mov_b32 s60, s54
	s_mov_b64 s[6:7], s[30:31]
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_66
.LBB0_55:                               ; %.epil.preheader
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_mov_b32 s58, 0
	s_mov_b32 s61, 0
	s_branch .LBB0_57
	.p2align	5
.LBB0_56:                               ;   in Loop: Header=BB0_57 Depth=2
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[162:169], v[170:177], v[66:69], v150, v149 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[154:161], v[170:177], v[70:73], v150, v149 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[210:217], v[170:177], v[74:77], v150, v149 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[202:209], v[170:177], v[78:81], v150, v149 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[162:169], v[194:201], v[18:21], v150, v149 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[154:161], v[194:201], v[22:25], v150, v149 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[210:217], v[194:201], v[26:29], v150, v149 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[202:209], v[194:201], v[30:33], v150, v149 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[162:169], v[178:185], v[2:5], v150, v149 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[154:161], v[178:185], v[6:9], v150, v149 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[210:217], v[178:185], v[10:13], v150, v149 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[202:209], v[178:185], v[14:17], v150, v149 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_add_i32 s24, s60, 1
	s_add_i32 s61, s61, 1
	s_cmp_lg_u32 s61, s53
	s_cbranch_scc0 .LBB0_66
.LBB0_57:                               ;   Parent Loop BB0_3 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_mul_i32 s62, s58, 0x8400
	v_add_u32_e32 v153, s62, v140
	s_lshl_b32 s6, s58, 10
	ds_read_b128 v[186:189], v153
	ds_read_b128 v[190:193], v153 offset:64
	ds_read_b128 v[170:173], v153 offset:8448
	ds_read_b128 v[174:177], v153 offset:8512
	v_add_u32_e32 v149, s6, v145
	v_add_u32_e32 v150, s6, v146
	ds_read_b32 v149, v149
	ds_read_b32 v152, v150
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v151, s62, v147
	ds_read_b128 v[226:229], v151
	ds_read_b128 v[230:233], v151 offset:64
	ds_read_b128 v[218:221], v151 offset:4224
	ds_read_b128 v[222:225], v151 offset:4288
	ds_read_b128 v[210:213], v151 offset:8448
	ds_read_b128 v[214:217], v151 offset:8512
	ds_read_b128 v[202:205], v151 offset:12672
	ds_read_b128 v[206:209], v151 offset:12736
	ds_read_b128 v[162:165], v151 offset:16896
	ds_read_b128 v[166:169], v151 offset:16960
	ds_read_b128 v[154:157], v151 offset:21120
	ds_read_b128 v[158:161], v151 offset:21184
	v_add_u32_e32 v150, s6, v148
	ds_read_b32 v150, v150 offset:512
	; sched_barrier mask(0x00000000)
	s_mov_b32 s63, s60
	s_mov_b32 s60, s24
	s_cmp_lt_i32 s59, 1
	s_cbranch_scc1 .LBB0_60
; %bb.58:                               ; %LeafBlock3917
                                        ;   in Loop: Header=BB0_57 Depth=2
	s_cmp_eq_u32 s59, 1
	s_cbranch_scc0 .LBB0_61
; %bb.59:                               ;   in Loop: Header=BB0_57 Depth=2
	s_mov_b64 s[6:7], -1
	s_mov_b32 s64, 0x21800
	s_branch .LBB0_62
	.p2align	5
.LBB0_60:                               ;   in Loop: Header=BB0_57 Depth=2
	s_mov_b32 s64, 0x21000
	s_mov_b32 s65, s8
	s_mov_b64 s[24:25], s[0:1]
	s_mov_b64 s[26:27], s[22:23]
	s_xor_b32 s58, s58, 1
	s_cbranch_execnz .LBB0_63
	s_branch .LBB0_64
	.p2align	5
.LBB0_61:                               ;   in Loop: Header=BB0_57 Depth=2
	s_mov_b64 s[6:7], 0
	s_mov_b32 s64, 0x21000
.LBB0_62:                               ; %Flow3988
                                        ;   in Loop: Header=BB0_57 Depth=2
	s_mov_b32 s65, s9
	s_mov_b64 s[24:25], s[16:17]
	s_mov_b64 s[26:27], s[18:19]
	s_xor_b32 s58, s58, 1
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_64
.LBB0_63:                               ; %.sink.split.i.epil
                                        ;   in Loop: Header=BB0_57 Depth=2
	s_lshl_b32 s7, s58, 10
	s_cmp_lg_u32 s64, -1
	s_cselect_b32 s64, s64, 0
	s_mul_i32 s6, s65, s60
	s_add_i32 m0, s7, s64
	s_nop 0
	buffer_load_dwordx4 v136, s[24:27], s6 offen lds
.LBB0_64:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.epil
                                        ;   in Loop: Header=BB0_57 Depth=2
	s_mul_i32 s6, s58, 0x8400
	s_add_i32 s6, s3, s6
	s_lshl_b32 s7, s60, 7
	s_mov_b32 m0, s6
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s7 offen lds
	s_add_i32 m0, s6, 0x2100
	s_nop 0
	buffer_load_dwordx4 v143, s[20:23], s7 offen lds
	s_add_i32 s7, s60, s12
	s_lshl_b32 s7, s7, 7
	s_add_i32 m0, s6, 0x4200
	s_nop 0
	buffer_load_dwordx4 v132, s[20:23], s7 offen lds
	s_add_i32 m0, s6, 0x6300
	s_nop 0
	buffer_load_dwordx4 v143, s[20:23], s7 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[226:233], v[186:193], v[114:117], v152, v149 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[218:225], v[186:193], v[118:121], v152, v149 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[194:197], v153 offset:16896
	ds_read_b128 v[198:201], v153 offset:16960
	ds_read_b128 v[178:181], v153 offset:25344
	ds_read_b128 v[182:185], v153 offset:25408
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[210:217], v[186:193], v[122:125], v152, v149 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[202:209], v[186:193], v[126:129], v152, v149 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[226:233], v[170:177], v[98:101], v152, v149 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[218:225], v[170:177], v[102:105], v152, v149 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[210:217], v[170:177], v[106:109], v152, v149 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[202:209], v[170:177], v[110:113], v152, v149 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[226:233], v[194:201], v[50:53], v152, v149 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[218:225], v[194:201], v[54:57], v152, v149 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[210:217], v[194:201], v[58:61], v152, v149 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[202:209], v[194:201], v[62:65], v152, v149 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[226:233], v[178:185], v[34:37], v152, v149 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[218:225], v[178:185], v[38:41], v152, v149 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[210:217], v[178:185], v[42:45], v152, v149 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[202:209], v[178:185], v[46:49], v152, v149 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[210:213], v151 offset:25344
	ds_read_b128 v[214:217], v151 offset:25408
	ds_read_b128 v[202:205], v151 offset:29568
	ds_read_b128 v[206:209], v151 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[162:169], v[186:193], v[82:85], v150, v149 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[154:161], v[186:193], v[86:89], v150, v149 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[210:217], v[186:193], v[90:93], v150, v149 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[202:209], v[186:193], v[94:97], v150, v149 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s24, s63, 2
	s_cmp_ge_i32 s24, s34
	s_cbranch_scc1 .LBB0_56
; %bb.65:                               ;   in Loop: Header=BB0_57 Depth=2
	s_add_i32 s6, s3, s62
	s_add_i32 s26, s6, 0x10800
	s_lshl_b32 s25, s24, 7
	s_mov_b32 s6, s22
	s_mov_b32 s7, s23
	s_mov_b32 m0, s26
	s_add_i32 s24, s24, s13
	buffer_load_dwordx4 v134, s[4:7], s25 offen lds
	s_add_i32 m0, s26, 0x2100
	s_lshl_b32 s24, s24, 7
	buffer_load_dwordx4 v144, s[4:7], s25 offen lds
	s_add_i32 m0, s26, 0x4200
	s_nop 0
	buffer_load_dwordx4 v134, s[4:7], s24 offen lds
	s_add_i32 m0, s26, 0x6300
	s_nop 0
	buffer_load_dwordx4 v144, s[4:7], s24 offen lds
	; sched_barrier mask(0x00000000)
	s_branch .LBB0_56
.LBB0_66:                               ; %._crit_edge
                                        ;   in Loop: Header=BB0_3 Depth=1
	s_ashr_i32 s3, s2, 31
	s_lshl_b64 s[2:3], s[2:3], 2
	s_add_u32 s16, s39, s2
	s_addc_u32 s2, s40, s3
	s_lshl_b32 s3, s58, 10
	s_mul_i32 s4, s58, 0x8400
	v_or_b32_e32 v132, s3, v141
	s_add_i32 s3, s3, 0x21800
	v_add_u32_e32 v135, s4, v135
	v_add_u32_e32 v132, 0x21000, v132
	v_add_u32_e32 v134, s3, v142
	v_add_u32_e32 v144, s4, v140
	v_add_u32_e32 v135, 0x10800, v135
	v_add_u32_e32 v133, s3, v133
	ds_read_b32 v132, v132
	ds_read_b32 v134, v134
	ds_read_b128 v[164:167], v144
	ds_read_b128 v[168:171], v144 offset:64
	ds_read_b128 v[156:159], v144 offset:8448
	ds_read_b128 v[160:163], v144 offset:8512
	ds_read_b128 v[148:151], v144 offset:16896
	ds_read_b128 v[152:155], v144 offset:16960
	ds_read_b128 v[140:143], v144 offset:25344
	ds_read_b128 v[144:147], v144 offset:25408
	ds_read_b128 v[196:199], v135
	ds_read_b128 v[200:203], v135 offset:64
	ds_read_b128 v[188:191], v135 offset:4224
	ds_read_b128 v[192:195], v135 offset:4288
	ds_read_b128 v[180:183], v135 offset:8448
	ds_read_b128 v[184:187], v135 offset:8512
	ds_read_b128 v[172:175], v135 offset:12672
	ds_read_b128 v[176:179], v135 offset:12736
	s_waitcnt lgkmcnt(0)
	ds_read_b32 v133, v133 offset:512
	s_and_b32 s17, s2, 0xffff
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[196:203], v[164:171], v[114:117], v134, v132 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[188:195], v[164:171], v[118:121], v134, v132 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[180:187], v[164:171], v[122:125], v134, v132 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[172:179], v[164:171], v[126:129], v134, v132 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[196:203], v[156:163], v[98:101], v134, v132 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[188:195], v[156:163], v[102:105], v134, v132 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[180:187], v[156:163], v[106:109], v134, v132 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[172:179], v[156:163], v[110:113], v134, v132 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[196:203], v[148:155], v[50:53], v134, v132 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[188:195], v[148:155], v[54:57], v134, v132 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[180:187], v[148:155], v[58:61], v134, v132 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[172:179], v[148:155], v[62:65], v134, v132 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[196:203], v[140:147], v[34:37], v134, v132 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[188:195], v[140:147], v[38:41], v134, v132 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[180:187], v[140:147], v[42:45], v134, v132 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[172:179], v[140:147], v[46:49], v134, v132 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[196:199], v135 offset:16896
	ds_read_b128 v[200:203], v135 offset:16960
	ds_read_b128 v[188:191], v135 offset:21120
	ds_read_b128 v[192:195], v135 offset:21184
	ds_read_b128 v[180:183], v135 offset:25344
	ds_read_b128 v[184:187], v135 offset:25408
	ds_read_b128 v[172:175], v135 offset:29568
	ds_read_b128 v[176:179], v135 offset:29632
	s_waitcnt lgkmcnt(6)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[196:203], v[164:171], v[82:85], v133, v132 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[188:195], v[164:171], v[86:89], v133, v132 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[180:187], v[164:171], v[90:93], v133, v132 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[172:179], v[164:171], v[94:97], v133, v132 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[196:203], v[156:163], v[66:69], v133, v132 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[188:195], v[156:163], v[70:73], v133, v132 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[180:187], v[156:163], v[74:77], v133, v132 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[172:179], v[156:163], v[78:81], v133, v132 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[196:203], v[148:155], v[18:21], v133, v132 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[188:195], v[148:155], v[22:25], v133, v132 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[180:187], v[148:155], v[26:29], v133, v132 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[172:179], v[148:155], v[30:33], v133, v132 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[196:203], v[140:147], v[2:5], v133, v132 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[188:195], v[140:147], v[6:9], v133, v132 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[180:187], v[140:147], v[10:13], v133, v132 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[172:179], v[140:147], v[14:17], v133, v132 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	v_lshl_or_b32 v133, s56, 4, v139
	s_cmp_lg_u32 s35, 3
	v_lshl_or_b32 v132, s57, 4, v137
	v_mul_lo_u32 v134, v133, s14
	v_or_b32_e32 v133, 64, v133
	s_cselect_b64 s[2:3], -1, 0
	s_cmp_lt_i32 s55, s37
	v_add_u32_e32 v135, 32, v132
	v_add_u32_e32 v140, 64, v132
	v_add_u32_e32 v141, 0x60, v132
	v_mul_lo_u32 v133, v133, s14
	v_add_lshl_u32 v142, v134, v132, 2
	s_cselect_b64 s[4:5], -1, 0
	buffer_store_dwordx4 v[114:117], v142, s[16:19], 0 offen nt
	s_and_b64 s[2:3], s[2:3], s[4:5]
	s_andn2_b64 vcc, exec, s[2:3]
	v_add_lshl_u32 v114, v134, v135, 2
	v_add_lshl_u32 v115, v134, v140, 2
	v_add_lshl_u32 v116, v134, v141, 2
	v_add_lshl_u32 v117, v133, v132, 2
	buffer_store_dwordx4 v[118:121], v114, s[16:19], 0 offen nt
	buffer_store_dwordx4 v[122:125], v115, s[16:19], 0 offen nt
	buffer_store_dwordx4 v[126:129], v116, s[16:19], 0 offen nt
	buffer_store_dwordx4 v[98:101], v117, s[16:19], 0 offen nt
	s_nop 1
	v_add_lshl_u32 v98, v133, v135, 2
	v_add_lshl_u32 v99, v133, v140, 2
	v_add_lshl_u32 v100, v133, v141, 2
	buffer_store_dwordx4 v[102:105], v98, s[16:19], 0 offen nt
	buffer_store_dwordx4 v[106:109], v99, s[16:19], 0 offen nt
	buffer_store_dwordx4 v[110:113], v100, s[16:19], 0 offen nt
	buffer_store_dwordx4 v[82:85], v142, s[16:19], s51 offen nt
	buffer_store_dwordx4 v[86:89], v114, s[16:19], s51 offen nt
	buffer_store_dwordx4 v[90:93], v115, s[16:19], s51 offen nt
	buffer_store_dwordx4 v[94:97], v116, s[16:19], s51 offen nt
	buffer_store_dwordx4 v[66:69], v117, s[16:19], s51 offen nt
	buffer_store_dwordx4 v[70:73], v98, s[16:19], s51 offen nt
	buffer_store_dwordx4 v[74:77], v99, s[16:19], s51 offen nt
	buffer_store_dwordx4 v[78:81], v100, s[16:19], s51 offen nt
	buffer_store_dwordx4 v[50:53], v142, s[16:19], s50 offen nt
	buffer_store_dwordx4 v[54:57], v114, s[16:19], s50 offen nt
	buffer_store_dwordx4 v[58:61], v115, s[16:19], s50 offen nt
	buffer_store_dwordx4 v[62:65], v116, s[16:19], s50 offen nt
	buffer_store_dwordx4 v[34:37], v117, s[16:19], s50 offen nt
	buffer_store_dwordx4 v[38:41], v98, s[16:19], s50 offen nt
	buffer_store_dwordx4 v[42:45], v99, s[16:19], s50 offen nt
	buffer_store_dwordx4 v[46:49], v100, s[16:19], s50 offen nt
	buffer_store_dwordx4 v[18:21], v142, s[16:19], s52 offen nt
	buffer_store_dwordx4 v[22:25], v114, s[16:19], s52 offen nt
	buffer_store_dwordx4 v[26:29], v115, s[16:19], s52 offen nt
	buffer_store_dwordx4 v[30:33], v116, s[16:19], s52 offen nt
	buffer_store_dwordx4 v[2:5], v117, s[16:19], s52 offen nt
	buffer_store_dwordx4 v[6:9], v98, s[16:19], s52 offen nt
	buffer_store_dwordx4 v[10:13], v99, s[16:19], s52 offen nt
	buffer_store_dwordx4 v[14:17], v100, s[16:19], s52 offen nt
	s_cbranch_vccnz .LBB0_1
; %bb.67:                               ;   in Loop: Header=BB0_3 Depth=1
	s_barrier
	s_branch .LBB0_1
.LBB0_68:                               ; %.critedge
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
		.amdhsa_next_free_vgpr 234
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 236
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
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_vgpr, 234
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_agpr, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.numbered_sgpr, 81
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_named_barrier, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.private_seg_size, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_vcc, 1
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_flat_scratch, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_dyn_sized_stack, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_recursion, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 9904
; TotalNumSgprs: 87
; NumVgprs: 234
; NumAgprs: 0
; TotalNumVgprs: 234
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 139264 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 29
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 234
; AccumOffset: 236
; Occupancy: 2
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 58
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.section	.AMDGPU.csdata,"",@progbits
	.type	__hip_cuid_40869f96b77763e5,@object ; @__hip_cuid_40869f96b77763e5
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_40869f96b77763e5
__hip_cuid_40869f96b77763e5:
	.byte	0                               ; 0x0
	.size	__hip_cuid_40869f96b77763e5, 1

	.ident	"AMD clang version 23.0.0git (https://github.com/ROCm/llvm-project.git 46fcb339fb61119b337f973c7ca9e710a319fdd0+PATCHED:440716f8b87be9d8e20ed910e10e5b6d14d57cf6)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_40869f96b77763e5
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
    .sgpr_count:     87
    .sgpr_spill_count: 0
    .symbol:         _Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     234
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
