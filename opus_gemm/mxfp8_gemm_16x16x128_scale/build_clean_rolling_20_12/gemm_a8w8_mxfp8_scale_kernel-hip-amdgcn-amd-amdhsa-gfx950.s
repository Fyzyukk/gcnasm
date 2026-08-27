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
	v_readfirstlane_b32 s45, v0
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
	s_load_dwordx4 s[28:31], s[0:1], 0x0
	s_load_dwordx2 s[34:35], s[0:1], 0x10
	s_load_dwordx4 s[12:15], s[0:1], 0x28
	s_load_dwordx2 s[36:37], s[0:1], 0x38
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
	s_sub_i32 s2, s2, s0
	s_ashr_i32 s0, s16, 31
	s_lshr_b32 s0, s0, 25
	s_add_i32 s0, s16, s0
	s_ashr_i32 s33, s0, 7
	s_waitcnt lgkmcnt(0)
	s_mul_i32 s0, s10, s3
	s_lshr_b32 s38, s45, 6
	s_ashr_i32 s1, s0, 31
	s_add_u32 s0, s4, s0
	s_mul_i32 s4, s8, s33
	s_mul_i32 s4, s4, s24
	s_addc_u32 s1, s5, s1
	s_ashr_i32 s5, s4, 31
	s_add_u32 s4, s0, s4
	s_addc_u32 s0, s1, s5
	s_and_b32 s5, s0, 0xffff
	s_mul_i32 s0, s11, s3
	s_ashr_i32 s1, s0, 31
	s_add_u32 s0, s6, s0
	s_mul_i32 s6, s9, s33
	s_mul_i32 s6, s6, s2
	s_addc_u32 s1, s7, s1
	s_ashr_i32 s7, s6, 31
	s_add_u32 s20, s0, s6
	s_addc_u32 s0, s1, s7
	s_and_b32 s21, s0, 0xffff
	v_lshlrev_b32_e32 v1, 4, v0
	s_mov_b32 s19, 0x20000
	s_mov_b32 s18, -1
	v_and_b32_e32 v137, 0x3f0, v1
	s_cmp_lt_i32 s38, 1
	s_mov_b64 s[0:1], -1
	s_cbranch_scc1 .LBB0_4
; %bb.1:                                ; %LeafBlock
	s_cmp_eq_u32 s38, 1
	s_cbranch_scc0 .LBB0_3
; %bb.2:
	s_mov_b32 s22, s18
	s_mov_b32 s23, s19
	s_mov_b32 m0, 0x21800
	s_nop 0
	buffer_load_dwordx4 v137, s[20:23], 0 offen lds
.LBB0_3:                                ; %Flow3996
	s_mov_b64 s[0:1], 0
.LBB0_4:                                ; %Flow3997
	s_andn2_b64 vcc, exec, s[0:1]
	s_cbranch_vccnz .LBB0_6
; %bb.5:
	s_mov_b32 s6, s18
	s_mov_b32 s7, s19
	s_mov_b32 m0, 0x21000
	s_nop 0
	buffer_load_dwordx4 v137, s[4:7], 0 offen lds
.LBB0_6:
	s_lshl_b32 s0, s2, 8
	s_mul_i32 s2, s15, s3
	s_lshl_b32 s1, s24, 8
	s_ashr_i32 s6, s2, 31
	s_add_u32 s2, s28, s2
	s_mul_i32 s7, s1, s12
	s_addc_u32 s6, s29, s6
	s_ashr_i32 s10, s7, 31
	s_add_u32 s24, s2, s7
	s_addc_u32 s2, s6, s10
	s_and_b32 s25, s2, 0xffff
	s_mul_i32 s2, s36, s3
	s_ashr_i32 s6, s2, 31
	s_add_u32 s2, s30, s2
	s_mul_i32 s7, s0, s13
	s_addc_u32 s6, s31, s6
	s_ashr_i32 s10, s7, 31
	s_add_u32 s28, s2, s7
	v_lshrrev_b32_e32 v2, 1, v0
	s_addc_u32 s2, s6, s10
	s_lshr_b32 s11, s45, 8
	v_and_b32_e32 v3, 28, v2
	s_and_b32 s29, s2, 0xffff
	s_and_b32 s10, s38, 3
	v_lshl_or_b32 v3, s11, 5, v3
	v_and_b32_e32 v2, 0x70, v1
	v_or_b32_e32 v3, s10, v3
	s_cmp_gt_u32 s10, 1
	v_mad_u64_u32 v[130:131], s[6:7], v3, s12, v[2:3]
	s_cselect_b32 s17, 0x1080, 0
	s_lshl_b32 s2, s10, 9
	s_add_i32 s6, s2, 0xfffffc00
	s_cmp_lt_u32 s10, 2
	s_cselect_b32 s23, s2, s6
	s_mul_i32 s2, s11, 0x1080
	s_mul_i32 s15, s10, 0x420
	s_add_i32 s15, s15, s2
	s_mov_b32 s27, 0x20000
	s_mov_b32 s26, -1
	s_mov_b32 m0, s15
	s_add_i32 s36, s15, 0x2100
	v_lshl_add_u32 v138, s12, 6, v130
	buffer_load_dwordx4 v130, s[24:27], 0 offen lds
	s_mov_b32 m0, s36
	s_add_i32 s39, s15, 0x10800
	s_mov_b32 s30, s26
	s_mov_b32 s31, s27
	v_mad_u64_u32 v[132:133], s[6:7], v3, s13, v[2:3]
	buffer_load_dwordx4 v138, s[24:27], 0 offen lds
	s_mov_b32 m0, s39
	s_add_i32 s40, s39, 0x2100
	v_lshl_add_u32 v139, s13, 6, v132
	buffer_load_dwordx4 v132, s[28:31], 0 offen lds
	s_mov_b32 m0, s40
	s_add_i32 s42, s15, 0x4200
	buffer_load_dwordx4 v139, s[28:31], 0 offen lds
	s_lshl_b32 s41, s12, 7
	s_mov_b32 m0, s42
	s_add_i32 s43, s15, 0x6300
	buffer_load_dwordx4 v130, s[24:27], s41 offen lds
	s_mov_b32 m0, s43
	s_lshl_b32 s44, s13, 7
	buffer_load_dwordx4 v138, s[24:27], s41 offen lds
	s_add_i32 m0, s39, 0x4200
	v_and_b32_e32 v2, 3, v0
	buffer_load_dwordx4 v132, s[28:31], s44 offen lds
	s_add_i32 m0, s39, 0x6300
	v_lshlrev_b32_e32 v3, 5, v0
	buffer_load_dwordx4 v139, s[28:31], s44 offen lds
	v_mul_u32_u24_e32 v2, 0x420, v2
	v_and_b32_e32 v3, 0x180, v3
	v_and_b32_e32 v4, 48, v0
	v_add3_u32 v3, v2, v4, v3
	v_and_b32_e32 v2, 0xf0, v1
	v_lshrrev_b32_e32 v1, 2, v0
	s_mov_b32 s2, 0
	s_add_i32 s23, s23, s17
	s_lshl_b32 s22, s10, 8
	v_and_b32_e32 v1, 12, v1
	s_and_b32 s17, s45, 0xffffff00
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_cmpk_gt_i32 s16, 0xff
	v_add3_u32 v131, s17, v2, v1
	s_cbranch_scc1 .LBB0_8
; %bb.7:                                ; %.._crit_edge_crit_edge
	s_mov_b64 s[6:7], 0
	s_branch .LBB0_9
.LBB0_8:
	s_mov_b64 s[6:7], -1
.LBB0_9:                                ; %Flow3995
	v_add_u32_e32 v134, s23, v3
	v_lshl_add_u32 v133, s11, 9, v3
	v_or3_b32 v135, s22, v2, v1
	s_andn2_b64 vcc, exec, s[6:7]
	v_or3_b32 v136, v1, v2, s17
	s_cbranch_vccnz .LBB0_49
; %bb.10:                               ; %.lr.ph
	s_add_i32 m0, s39, 0x8400
	s_mov_b32 s30, s26
	s_mov_b32 s31, s27
	s_movk_i32 s2, 0x80
	buffer_load_dwordx4 v132, s[28:31], s2 offen lds
	s_add_i32 m0, s39, 0xa500
	s_nop 0
	buffer_load_dwordx4 v139, s[28:31], s2 offen lds
	s_add_i32 s2, s44, 0x80
	s_add_i32 m0, s39, 0xc600
	s_nop 0
	buffer_load_dwordx4 v132, s[28:31], s2 offen lds
	s_add_i32 m0, s39, 0xe700
	s_nop 0
	buffer_load_dwordx4 v139, s[28:31], s2 offen lds
	; sched_barrier mask(0x00000000)
	s_max_i32 s6, s33, 2
	s_add_i32 s6, s6, -1
	s_and_b32 s22, s6, 3
	v_or_b32_e32 v140, 0x21000, v135
	v_add_u32_e32 v141, 0x21800, v136
	v_add_u32_e32 v142, 0x10800, v133
	v_add_u32_e32 v143, 0x21800, v131
	s_cmpk_lt_i32 s16, 0x280
	s_mov_b32 s2, 0
	s_cbranch_scc1 .LBB0_50
; %bb.11:                               ; %.lr.ph.new
	v_mov_b32_e32 v98, 0
	s_and_b32 s23, s6, -4
	s_add_i32 s45, s15, 0x8400
	s_add_i32 s46, s15, 0xa500
	s_add_i32 s47, s15, 0xc600
	s_add_i32 s48, s15, 0xe700
	s_add_i32 s49, s15, 0x14a00
	s_add_i32 s50, s15, 0x16b00
	s_add_i32 s51, s15, 0x18c00
	s_add_i32 s52, s15, 0x1ad00
	s_add_i32 s53, s15, 0x1ce00
	s_add_i32 s54, s15, 0x1ef00
	s_mov_b32 s6, 0
	s_mov_b32 s58, 0
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
	s_branch .LBB0_13
	.p2align	5
.LBB0_12:                               ;   in Loop: Header=BB0_13 Depth=1
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[156:163], v[164:171], v[66:69], v145, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[148:155], v[164:171], v[70:73], v145, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[204:211], v[164:171], v[74:77], v145, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[196:203], v[164:171], v[78:81], v145, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[156:163], v[180:187], v[18:21], v145, v144 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[148:155], v[180:187], v[22:25], v145, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[204:211], v[180:187], v[26:29], v145, v144 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[196:203], v[180:187], v[30:33], v145, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[156:163], v[172:179], v[2:5], v145, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[148:155], v[172:179], v[6:9], v145, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[204:211], v[172:179], v[10:13], v145, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[196:203], v[172:179], v[14:17], v145, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_cmp_lg_u32 s23, s58
	s_cbranch_scc0 .LBB0_51
.LBB0_13:                               ; =>This Inner Loop Header: Depth=1
	ds_read_b32 v144, v140
	ds_read_b32 v146, v141
	ds_read_b128 v[180:183], v134
	ds_read_b128 v[184:187], v134 offset:64
	ds_read_b128 v[164:167], v134 offset:8448
	ds_read_b128 v[168:171], v134 offset:8512
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[220:223], v142
	ds_read_b128 v[224:227], v142 offset:64
	ds_read_b128 v[212:215], v142 offset:4224
	ds_read_b128 v[216:219], v142 offset:4288
	ds_read_b128 v[204:207], v142 offset:8448
	ds_read_b128 v[208:211], v142 offset:8512
	ds_read_b128 v[196:199], v142 offset:12672
	ds_read_b128 v[200:203], v142 offset:12736
	ds_read_b128 v[156:159], v142 offset:16896
	ds_read_b128 v[160:163], v142 offset:16960
	ds_read_b128 v[148:151], v142 offset:21120
	ds_read_b128 v[152:155], v142 offset:21184
	ds_read_b32 v145, v143 offset:512
	; sched_barrier mask(0x00000000)
	s_mov_b32 s56, s58
	s_mov_b32 s55, s6
	s_cmp_lt_i32 s38, 1
	s_cbranch_scc1 .LBB0_16
; %bb.14:                               ; %LeafBlock3904
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_cmp_eq_u32 s38, 1
	s_cbranch_scc0 .LBB0_17
; %bb.15:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b64 s[6:7], -1
	s_mov_b32 s30, 0x21800
	s_branch .LBB0_18
	.p2align	5
.LBB0_16:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s30, 0x21000
	s_mov_b32 s31, s8
	s_mov_b64 s[16:17], s[4:5]
	s_cbranch_execnz .LBB0_19
	s_branch .LBB0_20
	.p2align	5
.LBB0_17:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b64 s[6:7], 0
	s_mov_b32 s30, 0x21000
.LBB0_18:                               ; %Flow3989
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s31, s9
	s_mov_b64 s[16:17], s[20:21]
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_20
.LBB0_19:                               ; %.sink.split.i
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_add_i32 s6, s56, 1
	s_cmp_lg_u32 s30, -1
	s_cselect_b32 s7, s30, 0
	s_mul_i32 s6, s31, s6
	s_add_i32 m0, s7, 0x400
	s_nop 0
	buffer_load_dwordx4 v137, s[16:19], s6 offen lds
.LBB0_20:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s45
	s_add_i32 s6, s55, 0x80
	buffer_load_dwordx4 v130, s[24:27], s6 offen lds
	s_mov_b32 m0, s46
	s_add_i32 s57, s41, s55
	buffer_load_dwordx4 v138, s[24:27], s6 offen lds
	s_add_i32 s6, s57, 0x80
	s_mov_b32 m0, s47
	s_nop 0
	buffer_load_dwordx4 v130, s[24:27], s6 offen lds
	s_mov_b32 m0, s48
	s_nop 0
	buffer_load_dwordx4 v138, s[24:27], s6 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[220:227], v[180:187], v[98:101], v146, v144 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[212:219], v[180:187], v[102:105], v146, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[188:191], v134 offset:16896
	ds_read_b128 v[192:195], v134 offset:16960
	ds_read_b128 v[172:175], v134 offset:25344
	ds_read_b128 v[176:179], v134 offset:25408
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[204:211], v[180:187], v[106:109], v146, v144 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[196:203], v[180:187], v[110:113], v146, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[220:227], v[164:171], v[114:117], v146, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[212:219], v[164:171], v[118:121], v146, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[204:211], v[164:171], v[122:125], v146, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[196:203], v[164:171], v[126:129], v146, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[220:227], v[188:195], v[50:53], v146, v144 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[212:219], v[188:195], v[54:57], v146, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[204:211], v[188:195], v[58:61], v146, v144 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[196:203], v[188:195], v[62:65], v146, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[220:227], v[172:179], v[34:37], v146, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[212:219], v[172:179], v[38:41], v146, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[204:211], v[172:179], v[42:45], v146, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[196:203], v[172:179], v[46:49], v146, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[204:207], v142 offset:25344
	ds_read_b128 v[208:211], v142 offset:25408
	ds_read_b128 v[196:199], v142 offset:29568
	ds_read_b128 v[200:203], v142 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[156:163], v[180:187], v[82:85], v145, v144 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[148:155], v[180:187], v[86:89], v145, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[204:211], v[180:187], v[90:93], v145, v144 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[196:203], v[180:187], v[94:97], v145, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s58, s56, 2
	s_cmp_ge_i32 s58, s33
	s_cbranch_scc1 .LBB0_22
; %bb.21:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s39
	s_add_i32 s6, s55, 0x100
	s_mov_b32 s30, s26
	s_mov_b32 s31, s27
	buffer_load_dwordx4 v132, s[28:31], s6 offen lds
	s_mov_b32 m0, s40
	s_nop 0
	buffer_load_dwordx4 v139, s[28:31], s6 offen lds
	s_add_i32 s6, s6, s44
	s_mov_b32 m0, s49
	s_nop 0
	buffer_load_dwordx4 v132, s[28:31], s6 offen lds
	s_mov_b32 m0, s50
	s_nop 0
	buffer_load_dwordx4 v139, s[28:31], s6 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_22:                               ;   in Loop: Header=BB0_13 Depth=1
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[156:163], v[164:171], v[66:69], v145, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[148:155], v[164:171], v[70:73], v145, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[204:211], v[164:171], v[74:77], v145, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[196:203], v[164:171], v[78:81], v145, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[156:163], v[188:195], v[18:21], v145, v144 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[148:155], v[188:195], v[22:25], v145, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[204:211], v[188:195], v[26:29], v145, v144 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[196:203], v[188:195], v[30:33], v145, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[156:163], v[172:179], v[2:5], v145, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[148:155], v[172:179], v[6:9], v145, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[204:211], v[172:179], v[10:13], v145, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[196:203], v[172:179], v[14:17], v145, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	ds_read_b32 v144, v140 offset:1024
	ds_read_b32 v146, v141 offset:1024
	ds_read_b128 v[188:191], v134 offset:33792
	ds_read_b128 v[192:195], v134 offset:33856
	ds_read_b128 v[164:167], v134 offset:42240
	ds_read_b128 v[168:171], v134 offset:42304
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[220:223], v142 offset:33792
	ds_read_b128 v[224:227], v142 offset:33856
	ds_read_b128 v[212:215], v142 offset:38016
	ds_read_b128 v[216:219], v142 offset:38080
	ds_read_b128 v[204:207], v142 offset:42240
	ds_read_b128 v[208:211], v142 offset:42304
	ds_read_b128 v[196:199], v142 offset:46464
	ds_read_b128 v[200:203], v142 offset:46528
	ds_read_b128 v[156:159], v142 offset:50688
	ds_read_b128 v[160:163], v142 offset:50752
	ds_read_b128 v[148:151], v142 offset:54912
	ds_read_b128 v[152:155], v142 offset:54976
	ds_read_b32 v145, v143 offset:1536
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s38, 1
	s_cbranch_scc1 .LBB0_25
; %bb.23:                               ; %LeafBlock3908
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_cmp_eq_u32 s38, 1
	s_cbranch_scc0 .LBB0_26
; %bb.24:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b64 s[6:7], -1
	s_mov_b32 s30, 0x21800
	s_branch .LBB0_27
	.p2align	5
.LBB0_25:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s30, 0x21000
	s_mov_b32 s31, s8
	s_mov_b64 s[16:17], s[4:5]
	s_cbranch_execnz .LBB0_28
	s_branch .LBB0_29
	.p2align	5
.LBB0_26:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b64 s[6:7], 0
	s_mov_b32 s30, 0x21000
.LBB0_27:                               ; %Flow3987
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s31, s9
	s_mov_b64 s[16:17], s[20:21]
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_29
.LBB0_28:                               ; %.sink.split.i.1
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_cmp_lg_u32 s30, -1
	s_mul_i32 s6, s31, s58
	s_cselect_b32 m0, s30, 0
	s_nop 0
	buffer_load_dwordx4 v137, s[16:19], s6 offen lds
.LBB0_29:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.1
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s15
	s_add_i32 s6, s55, 0x100
	buffer_load_dwordx4 v130, s[24:27], s6 offen lds
	s_mov_b32 m0, s36
	s_nop 0
	buffer_load_dwordx4 v138, s[24:27], s6 offen lds
	s_add_i32 s6, s57, 0x100
	s_mov_b32 m0, s42
	s_nop 0
	buffer_load_dwordx4 v130, s[24:27], s6 offen lds
	s_mov_b32 m0, s43
	s_nop 0
	buffer_load_dwordx4 v138, s[24:27], s6 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[220:227], v[188:195], v[98:101], v146, v144 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[212:219], v[188:195], v[102:105], v146, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[180:183], v134 offset:50688
	ds_read_b128 v[184:187], v134 offset:50752
	ds_read_b128 v[172:175], v134 offset:59136
	ds_read_b128 v[176:179], v134 offset:59200
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[204:211], v[188:195], v[106:109], v146, v144 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[196:203], v[188:195], v[110:113], v146, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[220:227], v[164:171], v[114:117], v146, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[212:219], v[164:171], v[118:121], v146, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[204:211], v[164:171], v[122:125], v146, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[196:203], v[164:171], v[126:129], v146, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[220:227], v[180:187], v[50:53], v146, v144 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[212:219], v[180:187], v[54:57], v146, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[204:211], v[180:187], v[58:61], v146, v144 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[196:203], v[180:187], v[62:65], v146, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[220:227], v[172:179], v[34:37], v146, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[212:219], v[172:179], v[38:41], v146, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[204:211], v[172:179], v[42:45], v146, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[196:203], v[172:179], v[46:49], v146, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[204:207], v142 offset:59136
	ds_read_b128 v[208:211], v142 offset:59200
	ds_read_b128 v[196:199], v142 offset:63360
	ds_read_b128 v[200:203], v142 offset:63424
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[156:163], v[188:195], v[82:85], v145, v144 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[148:155], v[188:195], v[86:89], v145, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[204:211], v[188:195], v[90:93], v145, v144 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[196:203], v[188:195], v[94:97], v145, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s58, s56, 3
	s_cmp_ge_i32 s58, s33
	s_cbranch_scc1 .LBB0_31
; %bb.30:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s51
	s_add_i32 s6, s55, 0x180
	s_mov_b32 s30, s26
	s_mov_b32 s31, s27
	buffer_load_dwordx4 v132, s[28:31], s6 offen lds
	s_mov_b32 m0, s52
	s_nop 0
	buffer_load_dwordx4 v139, s[28:31], s6 offen lds
	s_add_i32 s6, s6, s44
	s_mov_b32 m0, s53
	s_nop 0
	buffer_load_dwordx4 v132, s[28:31], s6 offen lds
	s_mov_b32 m0, s54
	s_nop 0
	buffer_load_dwordx4 v139, s[28:31], s6 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_31:                               ;   in Loop: Header=BB0_13 Depth=1
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[156:163], v[164:171], v[66:69], v145, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[148:155], v[164:171], v[70:73], v145, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[204:211], v[164:171], v[74:77], v145, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[196:203], v[164:171], v[78:81], v145, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[156:163], v[180:187], v[18:21], v145, v144 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[148:155], v[180:187], v[22:25], v145, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[204:211], v[180:187], v[26:29], v145, v144 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[196:203], v[180:187], v[30:33], v145, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[156:163], v[172:179], v[2:5], v145, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[148:155], v[172:179], v[6:9], v145, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[204:211], v[172:179], v[10:13], v145, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[196:203], v[172:179], v[14:17], v145, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	ds_read_b32 v144, v140
	ds_read_b32 v146, v141
	ds_read_b128 v[188:191], v134
	ds_read_b128 v[192:195], v134 offset:64
	ds_read_b128 v[164:167], v134 offset:8448
	ds_read_b128 v[168:171], v134 offset:8512
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[220:223], v142
	ds_read_b128 v[224:227], v142 offset:64
	ds_read_b128 v[212:215], v142 offset:4224
	ds_read_b128 v[216:219], v142 offset:4288
	ds_read_b128 v[204:207], v142 offset:8448
	ds_read_b128 v[208:211], v142 offset:8512
	ds_read_b128 v[196:199], v142 offset:12672
	ds_read_b128 v[200:203], v142 offset:12736
	ds_read_b128 v[156:159], v142 offset:16896
	ds_read_b128 v[160:163], v142 offset:16960
	ds_read_b128 v[148:151], v142 offset:21120
	ds_read_b128 v[152:155], v142 offset:21184
	ds_read_b32 v145, v143 offset:512
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s38, 1
	s_cbranch_scc1 .LBB0_34
; %bb.32:                               ; %LeafBlock3912
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_cmp_eq_u32 s38, 1
	s_cbranch_scc0 .LBB0_35
; %bb.33:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b64 s[6:7], -1
	s_mov_b32 s30, 0x21800
	s_branch .LBB0_36
	.p2align	5
.LBB0_34:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s30, 0x21000
	s_mov_b32 s31, s8
	s_mov_b64 s[16:17], s[4:5]
	s_cbranch_execnz .LBB0_37
	s_branch .LBB0_38
	.p2align	5
.LBB0_35:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b64 s[6:7], 0
	s_mov_b32 s30, 0x21000
.LBB0_36:                               ; %Flow3985
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s31, s9
	s_mov_b64 s[16:17], s[20:21]
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_38
.LBB0_37:                               ; %.sink.split.i.2
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_cmp_lg_u32 s30, -1
	s_cselect_b32 s7, s30, 0
	s_mul_i32 s6, s31, s58
	s_add_i32 m0, s7, 0x400
	s_nop 0
	buffer_load_dwordx4 v137, s[16:19], s6 offen lds
.LBB0_38:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.2
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s45
	s_add_i32 s6, s55, 0x180
	buffer_load_dwordx4 v130, s[24:27], s6 offen lds
	s_mov_b32 m0, s46
	s_nop 0
	buffer_load_dwordx4 v138, s[24:27], s6 offen lds
	s_add_i32 s6, s57, 0x180
	s_mov_b32 m0, s47
	s_nop 0
	buffer_load_dwordx4 v130, s[24:27], s6 offen lds
	s_mov_b32 m0, s48
	s_nop 0
	buffer_load_dwordx4 v138, s[24:27], s6 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[220:227], v[188:195], v[98:101], v146, v144 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[212:219], v[188:195], v[102:105], v146, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[180:183], v134 offset:16896
	ds_read_b128 v[184:187], v134 offset:16960
	ds_read_b128 v[172:175], v134 offset:25344
	ds_read_b128 v[176:179], v134 offset:25408
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[204:211], v[188:195], v[106:109], v146, v144 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[196:203], v[188:195], v[110:113], v146, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[220:227], v[164:171], v[114:117], v146, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[212:219], v[164:171], v[118:121], v146, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[204:211], v[164:171], v[122:125], v146, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[196:203], v[164:171], v[126:129], v146, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[220:227], v[180:187], v[50:53], v146, v144 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[212:219], v[180:187], v[54:57], v146, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[204:211], v[180:187], v[58:61], v146, v144 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[196:203], v[180:187], v[62:65], v146, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[220:227], v[172:179], v[34:37], v146, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[212:219], v[172:179], v[38:41], v146, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[204:211], v[172:179], v[42:45], v146, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[196:203], v[172:179], v[46:49], v146, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[204:207], v142 offset:25344
	ds_read_b128 v[208:211], v142 offset:25408
	ds_read_b128 v[196:199], v142 offset:29568
	ds_read_b128 v[200:203], v142 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[156:163], v[188:195], v[82:85], v145, v144 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[148:155], v[188:195], v[86:89], v145, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[204:211], v[188:195], v[90:93], v145, v144 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[196:203], v[188:195], v[94:97], v145, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s58, s56, 4
	s_cmp_ge_i32 s58, s33
	s_cbranch_scc1 .LBB0_40
; %bb.39:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s39
	s_add_i32 s6, s55, 0x200
	s_mov_b32 s30, s26
	s_mov_b32 s31, s27
	buffer_load_dwordx4 v132, s[28:31], s6 offen lds
	s_mov_b32 m0, s40
	s_nop 0
	buffer_load_dwordx4 v139, s[28:31], s6 offen lds
	s_add_i32 s6, s6, s44
	s_mov_b32 m0, s49
	s_nop 0
	buffer_load_dwordx4 v132, s[28:31], s6 offen lds
	s_mov_b32 m0, s50
	s_nop 0
	buffer_load_dwordx4 v139, s[28:31], s6 offen lds
	; sched_barrier mask(0x00000000)
.LBB0_40:                               ;   in Loop: Header=BB0_13 Depth=1
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[156:163], v[164:171], v[66:69], v145, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[148:155], v[164:171], v[70:73], v145, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[204:211], v[164:171], v[74:77], v145, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[196:203], v[164:171], v[78:81], v145, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[156:163], v[180:187], v[18:21], v145, v144 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[148:155], v[180:187], v[22:25], v145, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[204:211], v[180:187], v[26:29], v145, v144 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[196:203], v[180:187], v[30:33], v145, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[156:163], v[172:179], v[2:5], v145, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[148:155], v[172:179], v[6:9], v145, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[204:211], v[172:179], v[10:13], v145, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[196:203], v[172:179], v[14:17], v145, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	ds_read_b32 v144, v140 offset:1024
	ds_read_b32 v146, v141 offset:1024
	ds_read_b128 v[188:191], v134 offset:33792
	ds_read_b128 v[192:195], v134 offset:33856
	ds_read_b128 v[164:167], v134 offset:42240
	ds_read_b128 v[168:171], v134 offset:42304
	; sched_barrier mask(0x00000000)
	ds_read_b128 v[220:223], v142 offset:33792
	ds_read_b128 v[224:227], v142 offset:33856
	ds_read_b128 v[212:215], v142 offset:38016
	ds_read_b128 v[216:219], v142 offset:38080
	ds_read_b128 v[204:207], v142 offset:42240
	ds_read_b128 v[208:211], v142 offset:42304
	ds_read_b128 v[196:199], v142 offset:46464
	ds_read_b128 v[200:203], v142 offset:46528
	ds_read_b128 v[156:159], v142 offset:50688
	ds_read_b128 v[160:163], v142 offset:50752
	ds_read_b128 v[148:151], v142 offset:54912
	ds_read_b128 v[152:155], v142 offset:54976
	ds_read_b32 v145, v143 offset:1536
	; sched_barrier mask(0x00000000)
	s_cmp_lt_i32 s38, 1
	s_cbranch_scc1 .LBB0_43
; %bb.41:                               ; %LeafBlock3916
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_cmp_eq_u32 s38, 1
	s_cbranch_scc0 .LBB0_44
; %bb.42:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b64 s[6:7], -1
	s_mov_b32 s30, 0x21800
	s_branch .LBB0_45
	.p2align	5
.LBB0_43:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s30, 0x21000
	s_mov_b32 s31, s8
	s_mov_b64 s[16:17], s[4:5]
	s_cbranch_execnz .LBB0_46
	s_branch .LBB0_47
	.p2align	5
.LBB0_44:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b64 s[6:7], 0
	s_mov_b32 s30, 0x21000
.LBB0_45:                               ; %Flow3983
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 s31, s9
	s_mov_b64 s[16:17], s[20:21]
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_47
.LBB0_46:                               ; %.sink.split.i.3
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_cmp_lg_u32 s30, -1
	s_mul_i32 s6, s31, s58
	s_cselect_b32 m0, s30, 0
	s_nop 0
	buffer_load_dwordx4 v137, s[16:19], s6 offen lds
.LBB0_47:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.3
                                        ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s15
	s_add_i32 s6, s55, 0x200
	buffer_load_dwordx4 v130, s[24:27], s6 offen lds
	s_mov_b32 m0, s36
	s_addk_i32 s57, 0x200
	buffer_load_dwordx4 v138, s[24:27], s6 offen lds
	s_mov_b32 m0, s42
	s_nop 0
	buffer_load_dwordx4 v130, s[24:27], s57 offen lds
	s_mov_b32 m0, s43
	s_nop 0
	buffer_load_dwordx4 v138, s[24:27], s57 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[220:227], v[188:195], v[98:101], v146, v144 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[212:219], v[188:195], v[102:105], v146, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[180:183], v134 offset:50688
	ds_read_b128 v[184:187], v134 offset:50752
	ds_read_b128 v[172:175], v134 offset:59136
	ds_read_b128 v[176:179], v134 offset:59200
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[204:211], v[188:195], v[106:109], v146, v144 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[196:203], v[188:195], v[110:113], v146, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[220:227], v[164:171], v[114:117], v146, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[212:219], v[164:171], v[118:121], v146, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[204:211], v[164:171], v[122:125], v146, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[196:203], v[164:171], v[126:129], v146, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[220:227], v[180:187], v[50:53], v146, v144 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[212:219], v[180:187], v[54:57], v146, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[204:211], v[180:187], v[58:61], v146, v144 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[196:203], v[180:187], v[62:65], v146, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[220:227], v[172:179], v[34:37], v146, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[212:219], v[172:179], v[38:41], v146, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[204:211], v[172:179], v[42:45], v146, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[196:203], v[172:179], v[46:49], v146, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[204:207], v142 offset:59136
	ds_read_b128 v[208:211], v142 offset:59200
	ds_read_b128 v[196:199], v142 offset:63360
	ds_read_b128 v[200:203], v142 offset:63424
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[156:163], v[188:195], v[82:85], v145, v144 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[148:155], v[188:195], v[86:89], v145, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[204:211], v[188:195], v[90:93], v145, v144 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[196:203], v[188:195], v[94:97], v145, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s56, s56, 5
	s_cmp_ge_i32 s56, s33
	s_cbranch_scc1 .LBB0_12
; %bb.48:                               ;   in Loop: Header=BB0_13 Depth=1
	s_mov_b32 m0, s51
	s_add_i32 s7, s55, 0x280
	s_mov_b32 s30, s26
	s_mov_b32 s31, s27
	buffer_load_dwordx4 v132, s[28:31], s7 offen lds
	s_mov_b32 m0, s52
	s_nop 0
	buffer_load_dwordx4 v139, s[28:31], s7 offen lds
	s_add_i32 s7, s7, s44
	s_mov_b32 m0, s53
	s_nop 0
	buffer_load_dwordx4 v132, s[28:31], s7 offen lds
	s_mov_b32 m0, s54
	s_nop 0
	buffer_load_dwordx4 v139, s[28:31], s7 offen lds
	; sched_barrier mask(0x00000000)
	s_branch .LBB0_12
.LBB0_49:
	v_mov_b32_e32 v18, 0
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
	s_branch .LBB0_63
.LBB0_50:
	v_mov_b32_e32 v17, 0
	s_mov_b32 s16, 1
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
	s_mov_b32 s23, 0
	s_cbranch_execnz .LBB0_52
	s_branch .LBB0_63
.LBB0_51:                               ; %._crit_edge.loopexit.unr-lcssa
	s_add_i32 s16, s58, 1
	s_cmp_lg_u32 s22, 0
	s_cselect_b64 s[6:7], -1, 0
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_63
.LBB0_52:                               ; %.epil.preheader
	s_mov_b32 s2, 0
	s_mov_b32 s36, 0
	s_branch .LBB0_54
	.p2align	5
.LBB0_53:                               ;   in Loop: Header=BB0_54 Depth=1
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[158:165], v[166:173], v[66:69], v145, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[150:157], v[166:173], v[70:73], v145, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[206:213], v[166:173], v[74:77], v145, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[198:205], v[166:173], v[78:81], v145, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[158:165], v[190:197], v[18:21], v145, v144 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[150:157], v[190:197], v[22:25], v145, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[206:213], v[190:197], v[26:29], v145, v144 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[198:205], v[190:197], v[30:33], v145, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[158:165], v[174:181], v[2:5], v145, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[150:157], v[174:181], v[6:9], v145, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[206:213], v[174:181], v[10:13], v145, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[198:205], v[174:181], v[14:17], v145, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_add_i32 s16, s23, 1
	s_add_i32 s36, s36, 1
	s_cmp_lg_u32 s36, s22
	s_cbranch_scc0 .LBB0_63
.LBB0_54:                               ; =>This Inner Loop Header: Depth=1
	s_mul_i32 s30, s2, 0x8400
	v_add_u32_e32 v148, s30, v134
	s_lshl_b32 s6, s2, 10
	ds_read_b128 v[182:185], v148
	ds_read_b128 v[186:189], v148 offset:64
	ds_read_b128 v[166:169], v148 offset:8448
	ds_read_b128 v[170:173], v148 offset:8512
	v_add_u32_e32 v144, s6, v140
	v_add_u32_e32 v145, s6, v141
	ds_read_b32 v144, v144
	ds_read_b32 v147, v145
	; sched_barrier mask(0x00000000)
	v_add_u32_e32 v146, s30, v142
	ds_read_b128 v[222:225], v146
	ds_read_b128 v[226:229], v146 offset:64
	ds_read_b128 v[214:217], v146 offset:4224
	ds_read_b128 v[218:221], v146 offset:4288
	ds_read_b128 v[206:209], v146 offset:8448
	ds_read_b128 v[210:213], v146 offset:8512
	ds_read_b128 v[198:201], v146 offset:12672
	ds_read_b128 v[202:205], v146 offset:12736
	ds_read_b128 v[158:161], v146 offset:16896
	ds_read_b128 v[162:165], v146 offset:16960
	ds_read_b128 v[150:153], v146 offset:21120
	ds_read_b128 v[154:157], v146 offset:21184
	v_add_u32_e32 v145, s6, v143
	ds_read_b32 v145, v145 offset:512
	; sched_barrier mask(0x00000000)
	s_mov_b32 s31, s23
	s_mov_b32 s23, s16
	s_cmp_lt_i32 s38, 1
	s_cbranch_scc1 .LBB0_57
; %bb.55:                               ; %LeafBlock3920
                                        ;   in Loop: Header=BB0_54 Depth=1
	s_cmp_eq_u32 s38, 1
	s_cbranch_scc0 .LBB0_58
; %bb.56:                               ;   in Loop: Header=BB0_54 Depth=1
	s_mov_b64 s[6:7], -1
	s_mov_b32 s39, 0x21800
	s_branch .LBB0_59
	.p2align	5
.LBB0_57:                               ;   in Loop: Header=BB0_54 Depth=1
	s_mov_b32 s39, 0x21000
	s_mov_b32 s40, s8
	s_mov_b64 s[16:17], s[4:5]
	s_xor_b32 s2, s2, 1
	s_cbranch_execnz .LBB0_60
	s_branch .LBB0_61
	.p2align	5
.LBB0_58:                               ;   in Loop: Header=BB0_54 Depth=1
	s_mov_b64 s[6:7], 0
	s_mov_b32 s39, 0x21000
.LBB0_59:                               ; %Flow3991
                                        ;   in Loop: Header=BB0_54 Depth=1
	s_mov_b32 s40, s9
	s_mov_b64 s[16:17], s[20:21]
	s_xor_b32 s2, s2, 1
	s_and_b64 vcc, exec, s[6:7]
	s_cbranch_vccz .LBB0_61
.LBB0_60:                               ; %.sink.split.i.epil
                                        ;   in Loop: Header=BB0_54 Depth=1
	s_lshl_b32 s7, s2, 10
	s_cmp_lg_u32 s39, -1
	s_cselect_b32 s39, s39, 0
	s_mul_i32 s6, s40, s23
	s_add_i32 m0, s7, s39
	s_nop 0
	buffer_load_dwordx4 v137, s[16:19], s6 offen lds
.LBB0_61:                               ; %_ZZ28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargsENKUlvE_clEv.exit.epil
                                        ;   in Loop: Header=BB0_54 Depth=1
	s_mul_i32 s6, s2, 0x8400
	s_add_i32 s6, s15, s6
	s_lshl_b32 s7, s23, 7
	s_mov_b32 m0, s6
	s_nop 0
	buffer_load_dwordx4 v130, s[24:27], s7 offen lds
	s_add_i32 m0, s6, 0x2100
	s_nop 0
	buffer_load_dwordx4 v138, s[24:27], s7 offen lds
	s_add_i32 s7, s23, s12
	s_lshl_b32 s7, s7, 7
	s_add_i32 m0, s6, 0x4200
	s_nop 0
	buffer_load_dwordx4 v130, s[24:27], s7 offen lds
	s_add_i32 m0, s6, 0x6300
	s_nop 0
	buffer_load_dwordx4 v138, s[24:27], s7 offen lds
	; sched_barrier mask(0x00000000)
	s_waitcnt lgkmcnt(9)
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[222:229], v[182:189], v[98:101], v147, v144 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[214:221], v[182:189], v[102:105], v147, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[190:193], v148 offset:16896
	ds_read_b128 v[194:197], v148 offset:16960
	ds_read_b128 v[174:177], v148 offset:25344
	ds_read_b128 v[178:181], v148 offset:25408
	s_waitcnt lgkmcnt(9)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[206:213], v[182:189], v[106:109], v147, v144 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[198:205], v[182:189], v[110:113], v147, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[222:229], v[166:173], v[114:117], v147, v144 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[214:221], v[166:173], v[118:121], v147, v144 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[206:213], v[166:173], v[122:125], v147, v144 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[198:205], v[166:173], v[126:129], v147, v144 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[222:229], v[190:197], v[50:53], v147, v144 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[214:221], v[190:197], v[54:57], v147, v144 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[206:213], v[190:197], v[58:61], v147, v144 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[198:205], v[190:197], v[62:65], v147, v144 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[222:229], v[174:181], v[34:37], v147, v144 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[214:221], v[174:181], v[38:41], v147, v144 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[206:213], v[174:181], v[42:45], v147, v144 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[198:205], v[174:181], v[46:49], v147, v144 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[206:209], v146 offset:25344
	ds_read_b128 v[210:213], v146 offset:25408
	ds_read_b128 v[198:201], v146 offset:29568
	ds_read_b128 v[202:205], v146 offset:29632
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[158:165], v[182:189], v[82:85], v145, v144 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[150:157], v[182:189], v[86:89], v145, v144 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[206:213], v[182:189], v[90:93], v145, v144 op_sel_hi:[1,0,0]
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[198:205], v[182:189], v[94:97], v145, v144 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	s_waitcnt vmcnt(0) lgkmcnt(0)
	s_barrier
	; sched_barrier mask(0x00000000)
	s_add_i32 s6, s31, 2
	s_cmp_ge_i32 s6, s33
	s_cbranch_scc1 .LBB0_53
; %bb.62:                               ;   in Loop: Header=BB0_54 Depth=1
	s_add_i32 s16, s15, s30
	s_add_i32 s16, s16, 0x10800
	s_lshl_b32 s7, s6, 7
	s_mov_b32 s30, s26
	s_mov_b32 s31, s27
	s_mov_b32 m0, s16
	s_add_i32 s6, s6, s13
	buffer_load_dwordx4 v132, s[28:31], s7 offen lds
	s_add_i32 m0, s16, 0x2100
	s_lshl_b32 s6, s6, 7
	buffer_load_dwordx4 v139, s[28:31], s7 offen lds
	s_add_i32 m0, s16, 0x4200
	s_nop 0
	buffer_load_dwordx4 v132, s[28:31], s6 offen lds
	s_add_i32 m0, s16, 0x6300
	s_nop 0
	buffer_load_dwordx4 v139, s[28:31], s6 offen lds
	; sched_barrier mask(0x00000000)
	s_branch .LBB0_53
.LBB0_63:                               ; %._crit_edge
	s_mul_i32 s4, s37, s3
	s_ashr_i32 s5, s4, 31
	s_lshl_b64 s[4:5], s[4:5], 2
	s_add_u32 s3, s34, s4
	s_mul_i32 s4, s1, s14
	s_addc_u32 s6, s35, s5
	s_ashr_i32 s5, s4, 31
	s_lshl_b64 s[4:5], s[4:5], 2
	s_add_u32 s3, s3, s4
	s_addc_u32 s4, s6, s5
	s_ashr_i32 s1, s0, 31
	s_lshl_b64 s[0:1], s[0:1], 2
	s_add_u32 s0, s3, s0
	s_addc_u32 s1, s4, s1
	s_lshl_b32 s3, s2, 10
	s_mul_i32 s2, s2, 0x8400
	v_or_b32_e32 v130, s3, v135
	s_add_i32 s3, s3, 0x21800
	v_add_u32_e32 v133, s2, v133
	v_add_u32_e32 v130, 0x21000, v130
	v_add_u32_e32 v132, s3, v136
	v_add_u32_e32 v138, s2, v134
	v_add_u32_e32 v133, 0x10800, v133
	v_add_u32_e32 v131, s3, v131
	ds_read_b32 v130, v130
	ds_read_b32 v132, v132
	ds_read_b128 v[158:161], v138
	ds_read_b128 v[162:165], v138 offset:64
	ds_read_b128 v[150:153], v138 offset:8448
	ds_read_b128 v[154:157], v138 offset:8512
	ds_read_b128 v[142:145], v138 offset:16896
	ds_read_b128 v[146:149], v138 offset:16960
	ds_read_b128 v[134:137], v138 offset:25344
	ds_read_b128 v[138:141], v138 offset:25408
	ds_read_b128 v[190:193], v133
	ds_read_b128 v[194:197], v133 offset:64
	ds_read_b128 v[182:185], v133 offset:4224
	ds_read_b128 v[186:189], v133 offset:4288
	ds_read_b128 v[174:177], v133 offset:8448
	ds_read_b128 v[178:181], v133 offset:8512
	ds_read_b128 v[166:169], v133 offset:12672
	ds_read_b128 v[170:173], v133 offset:12736
	s_waitcnt lgkmcnt(0)
	ds_read_b32 v131, v131 offset:512
	s_and_b32 s1, s1, 0xffff
	s_mov_b32 s3, 0x20000
	s_mov_b32 s2, -1
	s_setprio 1
	v_mfma_scale_f32_16x16x128_f8f6f4 v[98:101], v[190:197], v[158:165], v[98:101], v132, v130 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[102:105], v[182:189], v[158:165], v[102:105], v132, v130 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[106:109], v[174:181], v[158:165], v[106:109], v132, v130 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[110:113], v[166:173], v[158:165], v[110:113], v132, v130 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[114:117], v[190:197], v[150:157], v[114:117], v132, v130 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[118:121], v[182:189], v[150:157], v[118:121], v132, v130 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[122:125], v[174:181], v[150:157], v[122:125], v132, v130 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[126:129], v[166:173], v[150:157], v[126:129], v132, v130 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[50:53], v[190:197], v[142:149], v[50:53], v132, v130 op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[54:57], v[182:189], v[142:149], v[54:57], v132, v130 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[58:61], v[174:181], v[142:149], v[58:61], v132, v130 op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[62:65], v[166:173], v[142:149], v[62:65], v132, v130 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[34:37], v[190:197], v[134:141], v[34:37], v132, v130 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[38:41], v[182:189], v[134:141], v[38:41], v132, v130 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[42:45], v[174:181], v[134:141], v[42:45], v132, v130 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[46:49], v[166:173], v[134:141], v[46:49], v132, v130 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	ds_read_b128 v[190:193], v133 offset:16896
	ds_read_b128 v[194:197], v133 offset:16960
	ds_read_b128 v[182:185], v133 offset:21120
	ds_read_b128 v[186:189], v133 offset:21184
	ds_read_b128 v[174:177], v133 offset:25344
	ds_read_b128 v[178:181], v133 offset:25408
	ds_read_b128 v[166:169], v133 offset:29568
	ds_read_b128 v[170:173], v133 offset:29632
	s_waitcnt lgkmcnt(6)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[82:85], v[190:197], v[158:165], v[82:85], v131, v130 op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(4)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[86:89], v[182:189], v[158:165], v[86:89], v131, v130 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(2)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[90:93], v[174:181], v[158:165], v[90:93], v131, v130 op_sel_hi:[1,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[94:97], v[166:173], v[158:165], v[94:97], v131, v130 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[66:69], v[190:197], v[150:157], v[66:69], v131, v130 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	v_mfma_scale_f32_16x16x128_f8f6f4 v[70:73], v[182:189], v[150:157], v[70:73], v131, v130 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	;;#ASMSTART
	;;#ASMEND
	; sched_group_barrier mask(0x00000008) size(1) SyncID(0)
	; sched_group_barrier mask(0x00000002) size(2) SyncID(0)
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[74:77], v[174:181], v[150:157], v[74:77], v131, v130 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[78:81], v[166:173], v[150:157], v[78:81], v131, v130 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	;;#ASMSTART
	;;#ASMEND
	v_mfma_scale_f32_16x16x128_f8f6f4 v[18:21], v[190:197], v[142:149], v[18:21], v131, v130 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[22:25], v[182:189], v[142:149], v[22:25], v131, v130 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[26:29], v[174:181], v[142:149], v[26:29], v131, v130 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[30:33], v[166:173], v[142:149], v[30:33], v131, v130 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	v_mfma_scale_f32_16x16x128_f8f6f4 v[2:5], v[190:197], v[134:141], v[2:5], v131, v130 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[6:9], v[182:189], v[134:141], v[6:9], v131, v130 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_nop 0
	v_mfma_scale_f32_16x16x128_f8f6f4 v[10:13], v[174:181], v[134:141], v[10:13], v131, v130 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_16x16x128_f8f6f4 v[14:17], v[166:173], v[134:141], v[14:17], v131, v130 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	;;#ASMEND
	s_setprio 0
	v_and_b32_e32 v0, 15, v0
	v_lshl_or_b32 v0, s10, 4, v0
	v_lshl_or_b32 v1, s11, 4, v1
	v_mul_lo_u32 v130, v0, s14
	v_add_u32_e32 v131, 32, v1
	v_or_b32_e32 v0, 64, v0
	v_add_lshl_u32 v134, v130, v1, 2
	v_add_u32_e32 v132, 64, v1
	v_add_u32_e32 v133, 0x60, v1
	v_mul_lo_u32 v0, v0, s14
	buffer_store_dwordx4 v[98:101], v134, s[0:3], 0 offen nt
	v_add_lshl_u32 v1, v0, v1, 2
	s_movk_i32 s4, 0x200
	v_add_lshl_u32 v98, v130, v131, 2
	buffer_store_dwordx4 v[102:105], v98, s[0:3], 0 offen nt
	v_add_lshl_u32 v99, v130, v132, 2
	v_add_lshl_u32 v100, v130, v133, 2
	v_add_lshl_u32 v101, v0, v131, 2
	v_add_lshl_u32 v102, v0, v132, 2
	v_add_lshl_u32 v0, v0, v133, 2
	buffer_store_dwordx4 v[106:109], v99, s[0:3], 0 offen nt
	buffer_store_dwordx4 v[110:113], v100, s[0:3], 0 offen nt
	buffer_store_dwordx4 v[114:117], v1, s[0:3], 0 offen nt
	buffer_store_dwordx4 v[118:121], v101, s[0:3], 0 offen nt
	buffer_store_dwordx4 v[122:125], v102, s[0:3], 0 offen nt
	buffer_store_dwordx4 v[126:129], v0, s[0:3], 0 offen nt
	buffer_store_dwordx4 v[82:85], v134, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[86:89], v98, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[90:93], v99, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[94:97], v100, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[66:69], v1, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[70:73], v101, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[74:77], v102, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[78:81], v0, s[0:3], s4 offen nt
	s_lshl_b32 s4, s14, 9
	buffer_store_dwordx4 v[50:53], v134, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[54:57], v98, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[58:61], v99, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[62:65], v100, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[34:37], v1, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[38:41], v101, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[42:45], v102, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[46:49], v0, s[0:3], s4 offen nt
	s_addk_i32 s4, 0x200
	buffer_store_dwordx4 v[18:21], v134, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[22:25], v98, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[26:29], v99, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[30:33], v100, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[2:5], v1, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[6:9], v101, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[10:13], v102, s[0:3], s4 offen nt
	buffer_store_dwordx4 v[14:17], v0, s[0:3], s4 offen nt
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
		.amdhsa_next_free_vgpr 230
		.amdhsa_next_free_sgpr 96
		.amdhsa_accum_offset 232
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
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_vgpr, 230
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_agpr, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.numbered_sgpr, 59
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.num_named_barrier, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.private_seg_size, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_vcc, 1
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.uses_flat_scratch, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_dyn_sized_stack, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_recursion, 0
	.set .L_Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 9768
; TotalNumSgprs: 65
; NumVgprs: 230
; NumAgprs: 0
; TotalNumVgprs: 230
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 139264 bytes/workgroup (compile time only)
; SGPRBlocks: 12
; VGPRBlocks: 28
; NumSGPRsForWavesPerEU: 102
; NumVGPRsForWavesPerEU: 230
; AccumOffset: 232
; Occupancy: 2
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 57
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.section	.AMDGPU.csdata,"",@progbits
	.type	__hip_cuid_6d9f27f50244cd00,@object ; @__hip_cuid_6d9f27f50244cd00
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_6d9f27f50244cd00
__hip_cuid_6d9f27f50244cd00:
	.byte	0                               ; 0x0
	.size	__hip_cuid_6d9f27f50244cd00, 1

	.ident	"AMD clang version 23.0.0git (https://github.com/ROCm/llvm-project.git 46fcb339fb61119b337f973c7ca9e710a319fdd0+PATCHED:440716f8b87be9d8e20ed910e10e5b6d14d57cf6)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_6d9f27f50244cd00
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
    .sgpr_count:     65
    .sgpr_spill_count: 0
    .symbol:         _Z28gemm_a8w8_mxfp8_scale_kernelI28gemm_a8w8_mxfp8_scale_traitsILi256ELi256ELi128ELi1ELi1ELi32EEEv21opus_gemm_scale_kargs.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     230
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
