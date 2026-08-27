	.amdgcn_target "amdgcn-amd-amdhsa--gfx950"
	.amdhsa_code_object_version 6
	.section	.text._ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf,"axG",@progbits,_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf,comdat
	.globl	_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf ; -- Begin function _ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf
	.p2align	8
	.type	_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf,@function
_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf: ; @_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf
; %bb.0:
	s_load_dwordx4 s[4:7], s[0:1], 0x0
	s_waitcnt lgkmcnt(0)
	s_cmp_eq_u32 s4, 0
	s_cselect_b64 s[2:3], -1, 0
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s4, 0, 0x3800
	s_cselect_b32 s9, 0, 56
	s_cselect_b32 s8, 0x3800, 0
	s_cselect_b32 s10, 56, 0
	s_or_b32 s4, s9, s4
	s_and_b32 s9, s4, 0x3838
	s_lshl_b32 s4, s4, 16
	s_or_b32 s13, s9, s4
	s_or_b32 s4, s10, s8
	s_and_b32 s8, s4, 0x3838
	s_lshl_b32 s4, s4, 16
	s_or_b32 s12, s8, s4
	v_cmp_eq_u32_e32 vcc, s5, v0
	v_mov_b32_e32 v2, s13
	v_mov_b32_e32 v9, s13
	v_mov_b32_e32 v10, s12
	v_mov_b32_e32 v17, s12
	v_mov_b32_e32 v3, s13
	v_mov_b32_e32 v4, s13
	v_mov_b32_e32 v5, s13
	v_mov_b32_e32 v6, s13
	v_mov_b32_e32 v7, s13
	v_mov_b32_e32 v8, s13
	v_mov_b32_e32 v11, s12
	v_mov_b32_e32 v12, s12
	v_mov_b32_e32 v13, s12
	v_mov_b32_e32 v14, s12
	v_mov_b32_e32 v15, s12
	v_mov_b32_e32 v16, s12
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB0_7
; %bb.1:
	s_cmp_eq_u32 s6, 0
	s_cbranch_scc1 .LBB0_3
; %bb.2:                                ; %.preheader70
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s6, s12, 56
	s_and_b32 s6, s6, 0xff
	s_or_b32 s6, s6, 0x3800
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s8, 56, s13
	s_and_b32 s8, s8, 0xff
	s_or_b32 s10, s8, 0x3800
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s6, s12, s6
	s_and_b32 s6, s6, 0xffff
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s8, s10, s13
	s_and_b32 s8, s8, 0xffff
	s_or_b32 s6, s6, 0x380000
	s_or_b32 s10, s8, 0x380000
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s6, s12, s6
	s_cselect_b32 s8, s10, s13
	s_and_b32 s6, s6, 0xffffff
	s_and_b32 s8, s8, 0xffffff
	s_or_b32 s6, s6, 0x38000000
	s_or_b32 s10, s8, 0x38000000
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s8, s12, s6
	s_and_b32 s6, s12, 0xffffff00
	s_or_b32 s11, s6, 56
	s_and_b64 s[14:15], s[2:3], exec
	s_mov_b32 s9, 0
	s_cselect_b32 s14, s10, s13
	s_and_b32 s6, s13, 0xffffff00
	s_mov_b32 s15, s9
	s_or_b32 s17, s6, 56
	s_mov_b32 s10, s9
	s_mov_b32 s16, s9
	s_or_b64 s[18:19], s[8:9], s[10:11]
	s_or_b64 s[14:15], s[14:15], s[16:17]
	s_and_b64 s[20:21], s[2:3], exec
	s_cselect_b32 s6, s12, s19
	s_cselect_b32 s8, s12, s18
	s_and_b32 s6, s6, 0xffff00ff
	s_or_b32 s19, s6, 0x3800
	s_and_b64 s[20:21], s[2:3], exec
	s_cselect_b32 s6, s15, s13
	s_cselect_b32 s20, s14, s13
	s_and_b32 s6, s6, 0xffff00ff
	s_mov_b32 s21, s9
	s_or_b32 s15, s6, 0x3800
	s_mov_b32 s18, s9
	s_mov_b32 s14, s9
	s_or_b64 s[18:19], s[8:9], s[18:19]
	s_or_b64 s[14:15], s[20:21], s[14:15]
	s_and_b64 s[20:21], s[2:3], exec
	s_cselect_b32 s6, s12, s19
	s_cselect_b32 s8, s12, s18
	s_and_b32 s20, s6, 0xffff
	s_lshr_b32 s6, s6, 24
	s_lshl_b32 s6, s6, 24
	s_and_b64 s[18:19], s[2:3], exec
	s_cselect_b32 s18, s14, s13
	s_cselect_b32 s14, s15, s13
	s_and_b32 s21, s14, 0xffff
	s_lshr_b32 s14, s14, 24
	s_lshl_b32 s22, s14, 24
	s_or_b32 s6, s6, s20
	s_or_b32 s15, s6, 0x380000
	s_or_b32 s6, s22, s21
	s_mov_b32 s19, s9
	s_mov_b32 s14, s9
	s_or_b32 s21, s6, 0x380000
	s_mov_b32 s20, s9
	s_or_b64 s[14:15], s[8:9], s[14:15]
	s_or_b64 s[18:19], s[18:19], s[20:21]
	s_and_b64 s[20:21], s[2:3], exec
	s_cselect_b32 s8, s12, s15
	s_cselect_b32 s6, s12, s14
	s_and_b32 s20, s8, 0xffff
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s18, s18, s13
	s_cselect_b32 s14, s19, s13
	s_bfe_u32 s8, s8, 0x80010
	s_lshl_b32 s8, s8, 16
	s_or_b32 s8, s8, s20
	s_or_b32 s19, s8, 0x38000000
	s_bfe_u32 s8, s14, 0x80010
	s_and_b32 s15, s14, 0xffff
	s_lshl_b32 s8, s8, 16
	s_or_b32 s8, s8, s15
	s_or_b32 s20, s8, 0x38000000
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s8, s12, 56
	s_and_b32 s8, s8, 0xff
	s_or_b32 s8, s8, 0x3800
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s14, 56, s13
	s_and_b32 s14, s14, 0xff
	s_or_b32 s21, s14, 0x3800
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s8, s12, s8
	s_and_b32 s8, s8, 0xffff
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s14, s21, s13
	s_and_b32 s14, s14, 0xffff
	s_or_b32 s8, s8, 0x380000
	s_or_b32 s21, s14, 0x380000
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s8, s12, s8
	s_cselect_b32 s14, s21, s13
	s_and_b32 s8, s8, 0xffffff
	s_and_b32 s14, s14, 0xffffff
	s_or_b32 s8, s8, 0x38000000
	s_or_b32 s21, s14, 0x38000000
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s8, s12, s8
	s_cselect_b32 s14, s21, s13
	s_mov_b32 s15, s9
	s_or_b64 s[10:11], s[8:9], s[10:11]
	s_or_b64 s[14:15], s[14:15], s[16:17]
	s_and_b64 s[16:17], s[2:3], exec
	s_cselect_b32 s8, s12, s10
	s_cselect_b32 s10, s12, s11
	s_and_b32 s10, s10, 0xffff00ff
	s_or_b32 s11, s10, 0x3800
	s_and_b64 s[16:17], s[2:3], exec
	s_cselect_b32 s10, s15, s13
	s_cselect_b32 s16, s14, s13
	s_and_b32 s10, s10, 0xffff00ff
	s_mov_b32 s17, s9
	s_or_b32 s15, s10, 0x3800
	s_mov_b32 s10, s9
	s_mov_b32 s14, s9
	s_or_b64 s[10:11], s[8:9], s[10:11]
	s_or_b64 s[14:15], s[16:17], s[14:15]
	s_and_b64 s[16:17], s[2:3], exec
	s_cselect_b32 s8, s12, s10
	s_cselect_b32 s10, s12, s11
	s_and_b32 s16, s10, 0xffff
	s_lshr_b32 s10, s10, 24
	s_lshl_b32 s17, s10, 24
	s_and_b64 s[10:11], s[2:3], exec
	s_cselect_b32 s10, s14, s13
	s_cselect_b32 s14, s15, s13
	s_and_b32 s21, s14, 0xffff
	s_lshr_b32 s14, s14, 24
	s_lshl_b32 s22, s14, 24
	s_or_b32 s14, s17, s16
	s_or_b32 s15, s14, 0x380000
	s_mov_b32 s14, s9
	s_or_b64 s[14:15], s[8:9], s[14:15]
	s_or_b32 s8, s22, s21
	s_mov_b32 s11, s9
	s_or_b32 s17, s8, 0x380000
	s_mov_b32 s16, s9
	s_or_b64 s[8:9], s[10:11], s[16:17]
	s_and_b64 s[10:11], s[2:3], exec
	s_cselect_b32 s15, s12, s15
	s_cselect_b32 s14, s12, s14
	s_and_b32 s16, s15, 0xffff
	s_and_b64 s[10:11], s[2:3], exec
	s_cselect_b32 s10, s8, s13
	s_cselect_b32 s8, s9, s13
	s_and_b32 s9, s8, 0xffff
	s_bfe_u32 s11, s15, 0x80010
	s_bfe_u32 s8, s8, 0x80010
	s_lshl_b32 s11, s11, 16
	s_lshl_b32 s8, s8, 16
	s_or_b32 s11, s11, s16
	s_or_b32 s8, s8, s9
	s_or_b32 s11, s11, 0x38000000
	s_or_b32 s15, s8, 0x38000000
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s8, s12, s11
	s_cselect_b32 s9, s12, s19
	s_cselect_b32 s23, s12, s14
	s_cselect_b32 s17, s12, s6
	s_cselect_b32 s14, s15, s13
	s_cselect_b32 s11, s20, s13
	s_cselect_b32 s15, s10, s13
	s_cselect_b32 s16, s18, s13
	s_lshr_b32 s10, s13, 24
	s_and_b32 s6, s13, 0xff0000
	s_lshl_b32 s10, s10, 24
	s_bfe_u32 s20, s13, 0x80010
	s_or_b32 s10, s10, s6
	s_and_b32 s6, s13, 0xff000000
	s_lshl_b32 s20, s20, 16
	s_and_b32 s18, s13, 0xffff
	s_or_b32 s21, s6, s20
	s_or_b32 s19, s18, s10
	s_or_b32 s6, s18, s21
	s_or_b32 s20, s18, s10
	s_or_b32 s10, s18, s21
	s_lshr_b32 s18, s16, 16
	v_mov_b32_e32 v1, s16
	v_mov_b32_e32 v2, 0xc0c0304
	v_perm_b32 v1, s18, v1, v2
	v_mov_b32_e32 v3, 0xc0c0104
	s_bfe_u32 s18, s11, 0x80010
	v_perm_b32 v4, s16, s16, v3
	s_and_b32 s16, s11, 0xff000000
	s_lshl_b32 s18, s18, 16
	v_lshlrev_b32_e32 v1, 16, v1
	s_or_b32 s16, s16, s18
	s_and_b32 s11, s11, 0xffff
	v_or_b32_e32 v6, v4, v1
	s_or_b32 s11, s11, s16
	s_lshr_b32 s16, s15, 16
	v_mov_b32_e32 v1, s15
	v_perm_b32 v1, s16, v1, v2
	s_bfe_u32 s16, s14, 0x80010
	v_perm_b32 v4, s15, s15, v3
	s_and_b32 s15, s14, 0xff000000
	s_lshl_b32 s16, s16, 16
	s_or_b32 s15, s15, s16
	s_and_b32 s14, s14, 0xffff
	s_lshr_b32 s16, s12, 24
	s_or_b32 s14, s14, s15
	s_and_b32 s15, s12, 0xff0000
	s_lshl_b32 s16, s16, 24
	s_bfe_u32 s22, s12, 0x80010
	s_or_b32 s16, s16, s15
	s_and_b32 s15, s12, 0xff000000
	s_lshl_b32 s22, s22, 16
	v_lshlrev_b32_e32 v1, 16, v1
	s_and_b32 s18, s12, 0xffff
	s_or_b32 s24, s15, s22
	v_or_b32_e32 v8, v4, v1
	s_or_b32 s21, s18, s16
	s_or_b32 s15, s18, s24
	s_or_b32 s22, s18, s16
	s_or_b32 s16, s18, s24
	s_lshr_b32 s18, s17, 16
	v_mov_b32_e32 v1, s17
	v_perm_b32 v1, s18, v1, v2
	s_bfe_u32 s18, s9, 0x80010
	v_perm_b32 v4, s17, s17, v3
	s_and_b32 s17, s9, 0xff000000
	s_lshl_b32 s18, s18, 16
	v_lshlrev_b32_e32 v1, 16, v1
	s_or_b32 s17, s17, s18
	s_and_b32 s9, s9, 0xffff
	v_or_b32_e32 v14, v4, v1
	s_or_b32 s17, s9, s17
	s_lshr_b32 s9, s23, 16
	v_mov_b32_e32 v1, s23
	s_bfe_u32 s18, s8, 0x80010
	v_perm_b32 v1, s9, v1, v2
	s_and_b32 s9, s8, 0xff000000
	s_lshl_b32 s18, s18, 16
	v_lshlrev_b32_e32 v1, 16, v1
	v_perm_b32 v2, s23, s23, v3
	s_or_b32 s9, s9, s18
	s_and_b32 s8, s8, 0xffff
	v_or_b32_e32 v16, v2, v1
	s_or_b32 s18, s8, s9
	s_mov_b64 s[8:9], 0
	s_branch .LBB0_4
.LBB0_3:
	s_mov_b64 s[8:9], -1
                                        ; implicit-def: $sgpr18
                                        ; implicit-def: $vgpr16
                                        ; implicit-def: $sgpr17
                                        ; implicit-def: $sgpr16
                                        ; implicit-def: $sgpr22
                                        ; implicit-def: $sgpr15
                                        ; implicit-def: $sgpr21
                                        ; implicit-def: $sgpr14
                                        ; implicit-def: $vgpr8
                                        ; implicit-def: $sgpr11
                                        ; implicit-def: $sgpr10
                                        ; implicit-def: $sgpr20
                                        ; implicit-def: $sgpr6
                                        ; implicit-def: $sgpr19
.LBB0_4:                                ; %Flow
	v_mov_b32_e32 v12, s22
	v_mov_b32_e32 v10, s21
	v_mov_b32_e32 v4, s20
	s_andn2_b64 vcc, exec, s[8:9]
	v_mov_b32_e32 v2, s19
	s_cbranch_vccnz .LBB0_6
; %bb.5:                                ; %.preheader
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s6, s12, 56
	s_and_b32 s6, s6, 0xff
	s_or_b32 s6, s6, 0x3800
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s8, 56, s13
	s_and_b32 s8, s8, 0xff
	s_or_b32 s10, s8, 0x3800
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s6, s12, s6
	s_and_b32 s6, s6, 0xffff
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s8, s10, s13
	s_and_b32 s8, s8, 0xffff
	s_or_b32 s6, s6, 0x380000
	s_or_b32 s10, s8, 0x380000
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s6, s12, s6
	s_cselect_b32 s8, s10, s13
	s_and_b32 s6, s6, 0xffffff
	s_and_b32 s8, s8, 0xffffff
	s_or_b32 s6, s6, 0x38000000
	s_or_b32 s10, s8, 0x38000000
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s8, s12, s6
	s_and_b32 s6, s12, 0xffffff00
	s_or_b32 s11, s6, 56
	s_and_b64 s[14:15], s[2:3], exec
	s_mov_b32 s9, 0
	s_cselect_b32 s14, s10, s13
	s_and_b32 s6, s13, 0xffffff00
	s_mov_b32 s15, s9
	s_or_b32 s17, s6, 56
	s_mov_b32 s10, s9
	s_mov_b32 s16, s9
	s_or_b64 s[18:19], s[8:9], s[10:11]
	s_or_b64 s[14:15], s[14:15], s[16:17]
	s_and_b64 s[20:21], s[2:3], exec
	s_cselect_b32 s6, s12, s19
	s_cselect_b32 s8, s12, s18
	s_and_b32 s6, s6, 0xffff00ff
	s_or_b32 s19, s6, 0x3800
	s_and_b64 s[20:21], s[2:3], exec
	s_cselect_b32 s6, s15, s13
	s_cselect_b32 s20, s14, s13
	s_and_b32 s6, s6, 0xffff00ff
	s_mov_b32 s21, s9
	s_or_b32 s15, s6, 0x3800
	s_mov_b32 s18, s9
	s_mov_b32 s14, s9
	s_or_b64 s[18:19], s[8:9], s[18:19]
	s_or_b64 s[14:15], s[20:21], s[14:15]
	s_and_b64 s[20:21], s[2:3], exec
	s_cselect_b32 s6, s12, s19
	s_cselect_b32 s8, s12, s18
	s_and_b32 s20, s6, 0xffff
	s_lshr_b32 s6, s6, 24
	s_lshl_b32 s6, s6, 24
	s_and_b64 s[18:19], s[2:3], exec
	s_cselect_b32 s18, s14, s13
	s_cselect_b32 s14, s15, s13
	s_and_b32 s21, s14, 0xffff
	s_lshr_b32 s14, s14, 24
	s_lshl_b32 s22, s14, 24
	s_or_b32 s6, s6, s20
	s_or_b32 s15, s6, 0x380000
	s_or_b32 s6, s22, s21
	s_mov_b32 s19, s9
	s_mov_b32 s14, s9
	s_or_b32 s21, s6, 0x380000
	s_mov_b32 s20, s9
	s_or_b64 s[14:15], s[8:9], s[14:15]
	s_or_b64 s[18:19], s[18:19], s[20:21]
	s_and_b64 s[20:21], s[2:3], exec
	s_cselect_b32 s8, s12, s15
	s_cselect_b32 s6, s12, s14
	s_and_b32 s20, s8, 0xffff
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s18, s18, s13
	s_cselect_b32 s14, s19, s13
	s_bfe_u32 s8, s8, 0x80010
	s_lshl_b32 s8, s8, 16
	s_or_b32 s8, s8, s20
	s_or_b32 s19, s8, 0x38000000
	s_bfe_u32 s8, s14, 0x80010
	s_and_b32 s15, s14, 0xffff
	s_lshl_b32 s8, s8, 16
	s_or_b32 s8, s8, s15
	s_or_b32 s20, s8, 0x38000000
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s8, s12, 56
	s_and_b32 s8, s8, 0xff
	s_or_b32 s8, s8, 0x3800
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s14, 56, s13
	s_and_b32 s14, s14, 0xff
	s_or_b32 s21, s14, 0x3800
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s8, s12, s8
	s_and_b32 s8, s8, 0xffff
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s14, s21, s13
	s_and_b32 s14, s14, 0xffff
	s_or_b32 s8, s8, 0x380000
	s_or_b32 s21, s14, 0x380000
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s8, s12, s8
	s_cselect_b32 s14, s21, s13
	s_and_b32 s8, s8, 0xffffff
	s_and_b32 s14, s14, 0xffffff
	s_or_b32 s8, s8, 0x38000000
	s_or_b32 s21, s14, 0x38000000
	s_and_b64 s[14:15], s[2:3], exec
	s_cselect_b32 s8, s12, s8
	s_cselect_b32 s14, s21, s13
	s_mov_b32 s15, s9
	s_or_b64 s[10:11], s[8:9], s[10:11]
	s_or_b64 s[14:15], s[14:15], s[16:17]
	s_and_b64 s[16:17], s[2:3], exec
	s_cselect_b32 s8, s12, s10
	s_cselect_b32 s10, s12, s11
	s_and_b32 s10, s10, 0xffff00ff
	s_or_b32 s11, s10, 0x3800
	s_and_b64 s[16:17], s[2:3], exec
	s_cselect_b32 s10, s15, s13
	s_cselect_b32 s16, s14, s13
	s_and_b32 s10, s10, 0xffff00ff
	s_mov_b32 s17, s9
	s_or_b32 s15, s10, 0x3800
	s_mov_b32 s10, s9
	s_mov_b32 s14, s9
	s_or_b64 s[10:11], s[8:9], s[10:11]
	s_or_b64 s[14:15], s[16:17], s[14:15]
	s_and_b64 s[16:17], s[2:3], exec
	s_cselect_b32 s8, s12, s10
	s_cselect_b32 s10, s12, s11
	s_and_b32 s16, s10, 0xffff
	s_lshr_b32 s10, s10, 24
	s_lshl_b32 s17, s10, 24
	s_and_b64 s[10:11], s[2:3], exec
	s_cselect_b32 s10, s14, s13
	s_cselect_b32 s14, s15, s13
	s_and_b32 s21, s14, 0xffff
	s_lshr_b32 s14, s14, 24
	s_lshl_b32 s22, s14, 24
	s_or_b32 s14, s17, s16
	s_or_b32 s15, s14, 0x380000
	s_mov_b32 s14, s9
	s_or_b64 s[14:15], s[8:9], s[14:15]
	s_or_b32 s8, s22, s21
	s_mov_b32 s11, s9
	s_or_b32 s17, s8, 0x380000
	s_mov_b32 s16, s9
	s_or_b64 s[8:9], s[10:11], s[16:17]
	s_and_b64 s[10:11], s[2:3], exec
	s_cselect_b32 s15, s12, s15
	s_cselect_b32 s14, s12, s14
	s_and_b32 s16, s15, 0xffff
	s_and_b64 s[10:11], s[2:3], exec
	s_cselect_b32 s10, s8, s13
	s_cselect_b32 s8, s9, s13
	s_and_b32 s9, s8, 0xffff
	s_bfe_u32 s11, s15, 0x80010
	s_bfe_u32 s8, s8, 0x80010
	s_lshl_b32 s11, s11, 16
	s_lshl_b32 s8, s8, 16
	s_or_b32 s11, s11, s16
	s_or_b32 s8, s8, s9
	s_or_b32 s11, s11, 0x38000000
	s_or_b32 s15, s8, 0x38000000
	s_and_b64 s[8:9], s[2:3], exec
	s_cselect_b32 s16, s12, s14
	s_cselect_b32 s14, s18, s13
	s_cselect_b32 s8, s12, s11
	s_cselect_b32 s9, s12, s19
	s_cselect_b32 s17, s12, s6
	s_cselect_b32 s11, s15, s13
	s_cselect_b32 s6, s20, s13
	s_cselect_b32 s10, s10, s13
	s_lshr_b32 s15, s14, 16
	v_mov_b32_e32 v1, s14
	v_mov_b32_e32 v3, 0xc0c0304
	v_perm_b32 v1, s15, v1, v3
	v_mov_b32_e32 v5, 0xc0c0104
	s_bfe_u32 s15, s6, 0x80010
	v_perm_b32 v2, s14, s14, v5
	s_and_b32 s14, s6, 0xff000000
	s_lshl_b32 s15, s15, 16
	v_lshlrev_b32_e32 v1, 16, v1
	s_or_b32 s14, s14, s15
	s_and_b32 s6, s6, 0xffff
	v_or_b32_e32 v2, v2, v1
	s_or_b32 s6, s6, s14
	s_lshr_b32 s14, s10, 16
	v_mov_b32_e32 v1, s10
	v_perm_b32 v1, s14, v1, v3
	s_bfe_u32 s14, s11, 0x80010
	v_perm_b32 v4, s10, s10, v5
	s_and_b32 s10, s11, 0xff000000
	s_lshl_b32 s14, s14, 16
	s_or_b32 s10, s10, s14
	s_and_b32 s11, s11, 0xffff
	s_lshr_b32 s14, s13, 24
	s_or_b32 s10, s11, s10
	s_and_b32 s11, s13, 0xff0000
	s_lshl_b32 s14, s14, 24
	s_or_b32 s11, s14, s11
	s_and_b32 s14, s13, 0xffff
	s_or_b32 s19, s14, s11
	s_and_b32 s11, s13, 0xff000000
	s_bfe_u32 s13, s13, 0x80010
	s_lshl_b32 s13, s13, 16
	v_lshlrev_b32_e32 v1, 16, v1
	s_or_b32 s13, s11, s13
	v_or_b32_e32 v4, v4, v1
	s_or_b32 s11, s14, s13
	s_or_b32 s14, s14, s13
	s_lshr_b32 s13, s17, 16
	v_mov_b32_e32 v1, s17
	s_bfe_u32 s15, s9, 0x80010
	v_perm_b32 v1, s13, v1, v3
	s_and_b32 s13, s9, 0xff000000
	s_lshl_b32 s15, s15, 16
	v_lshlrev_b32_e32 v1, 16, v1
	v_perm_b32 v6, s17, s17, v5
	s_or_b32 s13, s13, s15
	s_and_b32 s9, s9, 0xffff
	v_or_b32_e32 v10, v6, v1
	s_or_b32 s15, s9, s13
	s_lshr_b32 s9, s16, 16
	v_mov_b32_e32 v1, s16
	s_bfe_u32 s13, s8, 0x80010
	v_perm_b32 v1, s9, v1, v3
	s_and_b32 s9, s8, 0xff000000
	s_lshl_b32 s13, s13, 16
	s_or_b32 s9, s9, s13
	s_and_b32 s8, s8, 0xffff
	v_perm_b32 v3, s16, s16, v5
	s_or_b32 s16, s8, s9
	s_lshr_b32 s9, s12, 24
	s_and_b32 s8, s12, 0xff0000
	s_lshl_b32 s9, s9, 24
	s_or_b32 s8, s9, s8
	s_and_b32 s9, s12, 0xffff
	s_and_b32 s13, s12, 0xff000000
	s_bfe_u32 s12, s12, 0x80010
	s_lshl_b32 s12, s12, 16
	v_lshlrev_b32_e32 v1, 16, v1
	s_or_b32 s8, s9, s8
	s_or_b32 s12, s13, s12
	v_or_b32_e32 v12, v3, v1
	s_or_b32 s17, s9, s12
	s_or_b32 s18, s9, s12
	v_mov_b32_e32 v16, s8
	v_mov_b32_e32 v14, s8
	v_mov_b32_e32 v8, s19
	v_mov_b32_e32 v6, s19
.LBB0_6:                                ; %Flow151
	v_mov_b32_e32 v3, s6
	v_mov_b32_e32 v5, s10
	v_mov_b32_e32 v7, s11
	v_mov_b32_e32 v9, s14
	v_mov_b32_e32 v11, s15
	v_mov_b32_e32 v13, s16
	v_mov_b32_e32 v15, s17
	v_mov_b32_e32 v17, s18
.LBB0_7:                                ; %.loopexit
	s_or_b64 exec, exec, s[4:5]
	s_mov_b64 s[4:5], src_private_base
	v_mov_b32_e32 v1, 0x7f
	v_mov_b32_e32 v18, 0x80
	v_cmp_eq_u32_e32 vcc, s7, v0
	v_mov_b32_e32 v19, s5
	s_mov_b32 s4, 4
	v_cndmask_b32_e32 v20, v1, v18, vcc
	v_mov_b32_e32 v18, 0
	s_and_b64 s[2:3], s[2:3], exec
	flat_store_dword v[18:19], v20 sc0 sc1
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v18, 4
	s_cselect_b32 s2, 0, s4
	flat_store_dword v[18:19], v1 sc0 sc1
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v18, s2
	s_cselect_b32 s2, s4, 0
	flat_load_dword v1, v[18:19] sc0 sc1
	s_waitcnt vmcnt(0)
	v_mov_b32_e32 v18, s2
	flat_load_dword v18, v[18:19] sc0 sc1
	s_waitcnt vmcnt(0)
	s_load_dwordx2 s[0:1], s[0:1], 0x10
	v_lshlrev_b32_e32 v0, 6, v0
	s_waitcnt lgkmcnt(0)
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[2:9], v[10:17], 0, v1, v18 op_sel_hi:[0,0,0]
	s_nop 15
	s_nop 3
	global_store_dwordx4 v0, v[2:5], s[0:1]
	global_store_dwordx4 v0, v[6:9], s[0:1] offset:16
	global_store_dwordx4 v0, v[10:13], s[0:1] offset:32
	global_store_dwordx4 v0, v[14:17], s[0:1] offset:48
	s_endpgm
.Lfunc_end0:
	.size	_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf, .Lfunc_end0-_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 12
		.amdhsa_kernarg_size 24
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_kernarg_preload_length 0
		.amdhsa_user_sgpr_kernarg_preload_offset 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 1
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 21
		.amdhsa_next_free_sgpr 25
		.amdhsa_accum_offset 24
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
	.section	.text._ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf,"axG",@progbits,_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf,comdat
                                        ; -- End function
	.set .L_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf.num_vgpr, 21
	.set .L_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf.num_agpr, 0
	.set .L_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf.numbered_sgpr, 25
	.set .L_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf.num_named_barrier, 0
	.set .L_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf.private_seg_size, 12
	.set .L_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf.uses_vcc, 1
	.set .L_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf.uses_flat_scratch, 0
	.set .L_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf.has_dyn_sized_stack, 0
	.set .L_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf.has_recursion, 0
	.set .L_ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 3152
; TotalNumSgprs: 31
; NumVgprs: 21
; NumAgprs: 0
; TotalNumVgprs: 21
; ScratchSize: 12
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 3
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 31
; NumVGPRsForWavesPerEU: 21
; AccumOffset: 24
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 1
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 5
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.text._ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi,"axG",@progbits,_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi,comdat
	.globl	_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi ; -- Begin function _ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi
	.p2align	8
	.type	_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi,@function
_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi: ; @_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi
; %bb.0:                                ; %.preheader56
	s_load_dword s3, s[0:1], 0x8
	v_and_b32_e32 v1, 63, v0
	v_add_u32_e32 v16, 15, v1
	v_add_u32_e32 v17, 16, v1
	v_add_u32_e32 v14, 13, v1
	v_add_u32_e32 v15, 14, v1
	v_add_u32_e32 v12, 11, v1
	v_add_u32_e32 v13, 12, v1
	v_add_u32_e32 v10, 9, v1
	v_add_u32_e32 v11, 10, v1
	v_add_u32_e32 v8, 7, v1
	v_add_u32_e32 v9, 8, v1
	v_add_u32_e32 v6, 5, v1
	v_add_u32_e32 v7, 6, v1
	v_add_u32_e32 v4, 3, v1
	v_add_u32_e32 v5, 4, v1
	v_add_u32_e32 v2, 1, v1
	v_add_u32_e32 v3, 2, v1
	v_cvt_f32_ubyte0_e32 v3, v3
	v_cvt_f32_ubyte0_e32 v2, v2
	v_cvt_f32_ubyte0_e32 v5, v5
	v_cvt_f32_ubyte0_e32 v4, v4
	v_cvt_f32_ubyte0_e32 v7, v7
	v_cvt_f32_ubyte0_e32 v6, v6
	v_cvt_f32_ubyte0_e32 v9, v9
	v_cvt_f32_ubyte0_e32 v8, v8
	v_cvt_f32_ubyte0_e32 v11, v11
	v_cvt_f32_ubyte0_e32 v10, v10
	v_cvt_f32_ubyte0_e32 v13, v13
	v_cvt_f32_ubyte0_e32 v12, v12
	v_cvt_f32_ubyte0_e32 v15, v15
	v_cvt_f32_ubyte0_e32 v14, v14
	v_cvt_f32_ubyte0_e32 v17, v17
	v_cvt_f32_ubyte0_e32 v16, v16
	s_mov_b32 s4, 0x35800000
	v_pk_mul_f32 v[16:17], v[16:17], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[14:15], v[14:15], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[12:13], v[12:13], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[10:11], v[10:11], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[6:7], v[6:7], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[4:5], s[4:5] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_i32 s3, 1
	v_pk_mul_f32 v[2:3], v[2:3], s[4:5] op_sel_hi:[1,0]
	s_cbranch_scc1 .LBB1_3
; %bb.1:                                ; %.lr.ph
	v_mul_u32_u24_e32 v25, 3, v0
	v_add_u16_e32 v19, 15, v25
	v_add_u16_e32 v20, 10, v25
	v_mov_b32_e32 v33, 31
	v_add_u16_e32 v18, 5, v25
	v_and_b32_e32 v20, 31, v20
	v_and_b32_sdwa v19, v19, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	s_movk_i32 s4, 0x2020
	v_and_b32_sdwa v18, v18, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v21, 31, v25
	v_bitop3_b16 v19, v19, s4, v20 bitop3:0xfe
	v_bitop3_b16 v18, v18, s4, v21 bitop3:0xfe
	v_lshlrev_b32_e32 v19, 16, v19
	v_or_b32_sdwa v18, v18, v19 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v19, 25, v25
	v_add_u16_e32 v20, 20, v25
	v_add_u16_e32 v21, 3, v25
	v_add_u16_e32 v22, 30, v25
	v_and_b32_e32 v22, 31, v22
	v_and_b32_sdwa v21, v21, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v20, 31, v20
	v_and_b32_sdwa v19, v19, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v23, 18, v25
	v_bitop3_b16 v19, v19, s4, v20 bitop3:0xfe
	v_bitop3_b16 v20, v21, s4, v22 bitop3:0xfe
	v_lshlrev_b32_e32 v20, 16, v20
	v_or_b32_sdwa v19, v19, v20 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v20, 13, v25
	v_add_u16_e32 v21, 8, v25
	v_add_u16_e32 v22, 23, v25
	v_and_b32_e32 v23, 31, v23
	v_and_b32_sdwa v22, v22, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v21, 31, v21
	v_and_b32_sdwa v20, v20, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v24, 6, v25
	v_bitop3_b16 v20, v20, s4, v21 bitop3:0xfe
	v_bitop3_b16 v21, v22, s4, v23 bitop3:0xfe
	v_lshlrev_b32_e32 v21, 16, v21
	v_or_b32_sdwa v20, v20, v21 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v21, 1, v25
	v_add_u16_e32 v22, 28, v25
	v_add_u16_e32 v23, 11, v25
	v_and_b32_e32 v24, 31, v24
	v_and_b32_sdwa v23, v23, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v22, 31, v22
	v_and_b32_sdwa v21, v21, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v26, 21, v25
	v_bitop3_b16 v21, v21, s4, v22 bitop3:0xfe
	v_bitop3_b16 v22, v23, s4, v24 bitop3:0xfe
	v_add_u16_e32 v23, -1, v25
	v_add_u16_e32 v24, 26, v25
	v_lshlrev_b32_e32 v22, 16, v22
	v_and_b32_e32 v24, 31, v24
	v_and_b32_sdwa v23, v23, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_or_b32_sdwa v21, v21, v22 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_bitop3_b16 v22, v25, 48, 31 bitop3:0x6c
	v_and_b32_sdwa v26, v26, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v23, v23, s4, v24 bitop3:0xfe
	s_movk_i32 s5, 0x2000
	v_bitop3_b16 v22, v26, s5, v22 bitop3:0xfe
	v_lshlrev_b32_e32 v23, 16, v23
	v_or_b32_sdwa v22, v22, v23 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v23, 19, v25
	v_add_u16_e32 v24, 14, v25
	v_add_u16_e32 v27, 4, v25
	v_add_u16_e32 v26, 9, v25
	v_and_b32_e32 v24, 31, v24
	v_and_b32_sdwa v23, v23, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v27, 31, v27
	v_and_b32_sdwa v26, v26, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v23, v23, s4, v24 bitop3:0xfe
	v_bitop3_b16 v24, v26, s4, v27 bitop3:0xfe
	v_lshlrev_b32_e32 v23, 16, v23
	v_or_b32_sdwa v23, v24, v23 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v24, 7, v25
	v_add_u16_e32 v26, 2, v25
	v_add_u16_e32 v28, 24, v25
	v_add_u16_e32 v27, 29, v25
	v_and_b32_e32 v26, 31, v26
	v_and_b32_sdwa v24, v24, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v28, 31, v28
	v_and_b32_sdwa v27, v27, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v24, v24, s4, v26 bitop3:0xfe
	v_bitop3_b16 v26, v27, s4, v28 bitop3:0xfe
	v_lshlrev_b32_e32 v24, 16, v24
	v_add_u16_e32 v29, 12, v25
	v_or_b32_sdwa v24, v26, v24 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v26, 17, v25
	v_add_u16_e32 v27, 27, v25
	v_add_u16_e32 v25, 22, v25
	v_and_b32_e32 v25, 31, v25
	v_and_b32_sdwa v27, v27, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v29, 31, v29
	v_and_b32_sdwa v26, v26, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v25, v27, s4, v25 bitop3:0xfe
	v_bitop3_b16 v26, v26, s4, v29 bitop3:0xfe
	v_lshlrev_b32_e32 v25, 16, v25
	v_add_u16_e32 v27, 9, v0
	v_add_u16_e32 v28, 6, v0
	v_or_b32_sdwa v25, v26, v25 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v26, 3, v0
	v_and_b32_e32 v28, 31, v28
	v_and_b32_sdwa v27, v27, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_sdwa v26, v26, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v29, 31, v0
	v_bitop3_b16 v27, v27, s4, v28 bitop3:0xfe
	v_bitop3_b16 v26, v26, s4, v29 bitop3:0xfe
	v_lshlrev_b32_e32 v27, 16, v27
	v_or_b32_sdwa v26, v26, v27 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v27, 15, v0
	v_add_u16_e32 v28, 12, v0
	v_add_u16_e32 v29, 21, v0
	v_add_u16_e32 v30, 18, v0
	v_and_b32_e32 v30, 31, v30
	v_and_b32_sdwa v29, v29, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v28, 31, v28
	v_and_b32_sdwa v27, v27, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v31, 30, v0
	v_bitop3_b16 v27, v27, s4, v28 bitop3:0xfe
	v_bitop3_b16 v28, v29, s4, v30 bitop3:0xfe
	v_lshlrev_b32_e32 v28, 16, v28
	v_or_b32_sdwa v27, v27, v28 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v28, 27, v0
	v_add_u16_e32 v29, 24, v0
	v_add_u16_e32 v30, 1, v0
	v_and_b32_e32 v31, 31, v31
	v_and_b32_sdwa v30, v30, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v29, 31, v29
	v_and_b32_sdwa v28, v28, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v32, 10, v0
	v_bitop3_b16 v28, v28, s4, v29 bitop3:0xfe
	v_bitop3_b16 v29, v30, s4, v31 bitop3:0xfe
	v_lshlrev_b32_e32 v29, 16, v29
	v_or_b32_sdwa v28, v28, v29 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v29, 7, v0
	v_add_u16_e32 v30, 4, v0
	v_add_u16_e32 v31, 13, v0
	v_and_b32_e32 v32, 31, v32
	v_and_b32_sdwa v31, v31, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v30, 31, v30
	v_and_b32_sdwa v29, v29, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v34, 19, v0
	v_bitop3_b16 v29, v29, s4, v30 bitop3:0xfe
	v_bitop3_b16 v30, v31, s4, v32 bitop3:0xfe
	v_add_u16_e32 v31, 25, v0
	v_add_u16_e32 v32, 22, v0
	v_lshlrev_b32_e32 v30, 16, v30
	v_and_b32_e32 v32, 31, v32
	v_and_b32_sdwa v31, v31, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_or_b32_sdwa v29, v29, v30 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_bitop3_b16 v30, v0, 48, 31 bitop3:0x6c
	v_and_b32_sdwa v34, v34, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v31, v31, s4, v32 bitop3:0xfe
	v_bitop3_b16 v30, v34, s5, v30 bitop3:0xfe
	v_lshlrev_b32_e32 v31, 16, v31
	v_or_b32_sdwa v30, v30, v31 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v31, 5, v0
	v_add_u16_e32 v32, 2, v0
	v_add_u16_e32 v35, 28, v0
	v_add_u16_e32 v34, -1, v0
	v_and_b32_e32 v32, 31, v32
	v_and_b32_sdwa v31, v31, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v35, 31, v35
	v_and_b32_sdwa v34, v34, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v31, v31, s4, v32 bitop3:0xfe
	v_bitop3_b16 v32, v34, s4, v35 bitop3:0xfe
	v_lshlrev_b32_e32 v31, 16, v31
	v_or_b32_sdwa v31, v32, v31 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v32, 17, v0
	v_add_u16_e32 v34, 14, v0
	v_add_u16_e32 v36, 8, v0
	v_add_u16_e32 v35, 11, v0
	v_and_b32_e32 v34, 31, v34
	v_and_b32_sdwa v32, v32, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v36, 31, v36
	v_and_b32_sdwa v35, v35, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v32, v32, s4, v34 bitop3:0xfe
	v_bitop3_b16 v34, v35, s4, v36 bitop3:0xfe
	v_lshlrev_b32_e32 v32, 16, v32
	v_or_b32_sdwa v32, v34, v32 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v34, 23, v0
	v_add_u16_e32 v35, 29, v0
	v_add_u16_e32 v36, 26, v0
	v_add_u16_e32 v37, 20, v0
	v_and_b32_sdwa v34, v34, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v36, 31, v36
	v_and_b32_sdwa v33, v35, v33 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v37, 31, v37
	v_bitop3_b16 v33, v33, s4, v36 bitop3:0xfe
	v_bitop3_b16 v34, v34, s4, v37 bitop3:0xfe
	v_lshlrev_b32_e32 v33, 16, v33
	v_or_b32_sdwa v33, v34, v33 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_mov_b32_e32 v34, 0x7f7f7f7f
	.p2align	5, , 4
.LBB1_2:                                ; =>This Inner Loop Header: Depth=1
	s_nop 1
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel_hi:[0,0,0]
	s_add_i32 s3, s3, -1
	s_cmp_eq_u32 s3, 0
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[26:33], v[18:25], v[2:17], v34, v34 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	s_cbranch_scc0 .LBB1_2
.LBB1_3:                                ; %Flow74
	v_cmp_eq_u32_e32 vcc, 0, v1
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB1_5
; %bb.4:                                ; %.preheader
	s_load_dword s3, s[0:1], 0x1c
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	v_lshrrev_b32_e32 v0, 6, v0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v18, s2
	s_waitcnt lgkmcnt(0)
	s_bfe_u32 s0, s3, 0xa0006
	v_mad_u64_u32 v[0:1], s[0:1], s0, v18, v[0:1]
	v_lshlrev_b64 v[0:1], 6, v[0:1]
	v_lshl_add_u64 v[0:1], s[4:5], 0, v[0:1]
	s_nop 5
	global_store_dwordx4 v[0:1], v[2:5], off
	global_store_dwordx4 v[0:1], v[6:9], off offset:16
	global_store_dwordx4 v[0:1], v[10:13], off offset:32
	global_store_dwordx4 v[0:1], v[14:17], off offset:48
.LBB1_5:                                ; %.loopexit
	s_endpgm
.Lfunc_end1:
	.size	_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi, .Lfunc_end1-_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 272
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
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 38
		.amdhsa_next_free_sgpr 6
		.amdhsa_accum_offset 40
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
	.section	.text._ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi,"axG",@progbits,_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi,comdat
                                        ; -- End function
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi.num_vgpr, 38
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi.num_agpr, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi.numbered_sgpr, 6
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi.num_named_barrier, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi.private_seg_size, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi.uses_vcc, 1
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi.uses_flat_scratch, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi.has_dyn_sized_stack, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi.has_recursion, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1988
; TotalNumSgprs: 12
; NumVgprs: 38
; NumAgprs: 0
; TotalNumVgprs: 38
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 4
; NumSGPRsForWavesPerEU: 12
; NumVGPRsForWavesPerEU: 38
; AccumOffset: 40
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 9
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.text._ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi,"axG",@progbits,_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi,comdat
	.globl	_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi ; -- Begin function _ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi
	.p2align	8
	.type	_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi,@function
_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi: ; @_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi
; %bb.0:                                ; %.preheader54
	v_and_b32_e32 v1, 63, v0
	v_add_u32_e32 v18, 17, v1
	v_cvt_f32_ubyte0_e32 v18, v18
	v_mul_f32_e32 v30, 0x35800000, v18
	v_add_u32_e32 v18, 18, v1
	s_load_dword s3, s[0:1], 0x8
	v_cvt_f32_ubyte0_e32 v18, v18
	v_mul_f32_e32 v31, 0x35800000, v18
	v_add_u32_e32 v18, 19, v1
	v_cvt_f32_ubyte0_e32 v18, v18
	v_add_u32_e32 v2, 1, v1
	v_add_u32_e32 v3, 2, v1
	v_add_u32_e32 v4, 3, v1
	v_add_u32_e32 v5, 4, v1
	v_add_u32_e32 v6, 5, v1
	v_add_u32_e32 v7, 6, v1
	v_add_u32_e32 v8, 7, v1
	v_add_u32_e32 v9, 8, v1
	v_add_u32_e32 v10, 9, v1
	v_add_u32_e32 v11, 10, v1
	v_add_u32_e32 v12, 11, v1
	v_add_u32_e32 v13, 12, v1
	v_add_u32_e32 v14, 13, v1
	v_add_u32_e32 v15, 14, v1
	v_add_u32_e32 v16, 15, v1
	v_add_u32_e32 v17, 16, v1
	v_mul_f32_e32 v32, 0x35800000, v18
	v_add_u32_e32 v18, 20, v1
	v_cvt_f32_ubyte0_e32 v2, v2
	v_cvt_f32_ubyte0_e32 v3, v3
	v_cvt_f32_ubyte0_e32 v4, v4
	v_cvt_f32_ubyte0_e32 v5, v5
	v_cvt_f32_ubyte0_e32 v6, v6
	v_cvt_f32_ubyte0_e32 v7, v7
	v_cvt_f32_ubyte0_e32 v8, v8
	v_cvt_f32_ubyte0_e32 v9, v9
	v_cvt_f32_ubyte0_e32 v10, v10
	v_cvt_f32_ubyte0_e32 v11, v11
	v_cvt_f32_ubyte0_e32 v12, v12
	v_cvt_f32_ubyte0_e32 v13, v13
	v_cvt_f32_ubyte0_e32 v14, v14
	v_cvt_f32_ubyte0_e32 v15, v15
	v_cvt_f32_ubyte0_e32 v16, v16
	v_cvt_f32_ubyte0_e32 v17, v17
	v_cvt_f32_ubyte0_e32 v18, v18
	v_mul_f32_e32 v2, 0x35800000, v2
	v_mul_f32_e32 v3, 0x35800000, v3
	v_mul_f32_e32 v4, 0x35800000, v4
	v_mul_f32_e32 v5, 0x35800000, v5
	v_mul_f32_e32 v6, 0x35800000, v6
	v_mul_f32_e32 v7, 0x35800000, v7
	v_mul_f32_e32 v8, 0x35800000, v8
	v_mul_f32_e32 v9, 0x35800000, v9
	v_mul_f32_e32 v10, 0x35800000, v10
	v_mul_f32_e32 v11, 0x35800000, v11
	v_mul_f32_e32 v12, 0x35800000, v12
	v_mul_f32_e32 v13, 0x35800000, v13
	v_mul_f32_e32 v14, 0x35800000, v14
	v_mul_f32_e32 v15, 0x35800000, v15
	v_mul_f32_e32 v16, 0x35800000, v16
	v_mul_f32_e32 v17, 0x35800000, v17
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_i32 s3, 1
	v_mul_f32_e32 v33, 0x35800000, v18
	s_cbranch_scc1 .LBB2_6
; %bb.1:                                ; %.lr.ph
	v_mul_u32_u24_e32 v18, 3, v0
	v_add_u16_e32 v20, 15, v18
	v_add_u16_e32 v21, 10, v18
	v_mov_b32_e32 v22, 31
	v_add_u16_e32 v19, 5, v18
	v_and_b32_e32 v21, 31, v21
	v_and_b32_sdwa v20, v20, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	s_movk_i32 s4, 0x2020
	v_and_b32_sdwa v19, v19, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v23, 31, v18
	v_bitop3_b16 v20, v20, s4, v21 bitop3:0xfe
	v_bitop3_b16 v19, v19, s4, v23 bitop3:0xfe
	v_lshlrev_b32_e32 v20, 16, v20
	v_or_b32_sdwa v34, v19, v20 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v19, 25, v18
	v_add_u16_e32 v20, 20, v18
	v_add_u16_e32 v21, 3, v18
	v_add_u16_e32 v23, 30, v18
	v_and_b32_e32 v23, 31, v23
	v_and_b32_sdwa v21, v21, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v20, 31, v20
	v_and_b32_sdwa v19, v19, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	s_movk_i32 s5, 0x2000
	v_bitop3_b16 v19, v19, s4, v20 bitop3:0xfe
	v_bitop3_b16 v20, v21, s4, v23 bitop3:0xfe
	v_lshlrev_b32_e32 v20, 16, v20
	v_or_b32_sdwa v35, v19, v20 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v19, 13, v18
	v_add_u16_e32 v20, 8, v18
	v_add_u16_e32 v21, 23, v18
	v_add_u16_e32 v23, 18, v18
	v_and_b32_e32 v23, 31, v23
	v_and_b32_sdwa v21, v21, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v20, 31, v20
	v_and_b32_sdwa v19, v19, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v24, 4, v18
	v_bitop3_b16 v19, v19, s4, v20 bitop3:0xfe
	v_bitop3_b16 v20, v21, s4, v23 bitop3:0xfe
	v_lshlrev_b32_e32 v20, 16, v20
	v_or_b32_sdwa v36, v19, v20 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v19, 1, v18
	v_add_u16_e32 v20, 28, v18
	v_add_u16_e32 v21, 11, v18
	v_add_u16_e32 v23, 6, v18
	v_and_b32_e32 v23, 31, v23
	v_and_b32_sdwa v21, v21, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v20, 31, v20
	v_and_b32_sdwa v19, v19, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v24, 31, v24
	v_bitop3_b16 v19, v19, s4, v20 bitop3:0xfe
	v_bitop3_b16 v20, v21, s4, v23 bitop3:0xfe
	v_lshlrev_b32_e32 v20, 16, v20
	v_or_b32_sdwa v37, v19, v20 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v20, -1, v18
	v_add_u16_e32 v21, 26, v18
	v_add_u16_e32 v23, 21, v18
	v_and_b32_e32 v21, 31, v21
	v_and_b32_sdwa v20, v20, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v19, v18, 48, 31 bitop3:0x6c
	v_and_b32_sdwa v23, v23, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v20, v20, s4, v21 bitop3:0xfe
	v_bitop3_b16 v19, v23, s5, v19 bitop3:0xfe
	v_lshlrev_b32_e32 v20, 16, v20
	v_or_b32_sdwa v38, v19, v20 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v19, 19, v18
	v_add_u16_e32 v20, 14, v18
	v_add_u16_e32 v21, 9, v18
	v_and_b32_e32 v20, 31, v20
	v_and_b32_sdwa v19, v19, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_sdwa v21, v21, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v19, v19, s4, v20 bitop3:0xfe
	v_bitop3_b16 v20, v21, s4, v24 bitop3:0xfe
	v_lshlrev_b32_e32 v19, 16, v19
	v_or_b32_sdwa v39, v20, v19 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v19, 7, v18
	v_add_u16_e32 v20, 2, v18
	v_add_u16_e32 v23, 24, v18
	v_add_u16_e32 v21, 29, v18
	v_and_b32_e32 v20, 31, v20
	v_and_b32_sdwa v19, v19, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v23, 31, v23
	v_and_b32_sdwa v21, v21, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v19, v19, s4, v20 bitop3:0xfe
	v_bitop3_b16 v20, v21, s4, v23 bitop3:0xfe
	v_lshlrev_b32_e32 v19, 16, v19
	v_add_u16_e32 v24, 12, v18
	v_or_b32_sdwa v40, v20, v19 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v19, 17, v18
	v_add_u16_e32 v20, 27, v18
	v_add_u16_e32 v18, 22, v18
	v_and_b32_e32 v18, 31, v18
	v_and_b32_sdwa v20, v20, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v24, 31, v24
	v_and_b32_sdwa v19, v19, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v18, v20, s4, v18 bitop3:0xfe
	v_bitop3_b16 v19, v19, s4, v24 bitop3:0xfe
	v_lshlrev_b32_e32 v18, 16, v18
	v_or_b32_sdwa v41, v19, v18 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v19, 9, v0
	v_add_u16_e32 v20, 6, v0
	v_add_u16_e32 v18, 3, v0
	v_and_b32_e32 v20, 31, v20
	v_and_b32_sdwa v19, v19, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_sdwa v18, v18, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v21, 31, v0
	v_bitop3_b16 v19, v19, s4, v20 bitop3:0xfe
	v_bitop3_b16 v18, v18, s4, v21 bitop3:0xfe
	v_lshlrev_b32_e32 v19, 16, v19
	v_or_b32_sdwa v42, v18, v19 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v18, 15, v0
	v_add_u16_e32 v19, 12, v0
	v_add_u16_e32 v20, 21, v0
	v_add_u16_e32 v21, 18, v0
	v_and_b32_e32 v21, 31, v21
	v_and_b32_sdwa v20, v20, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v19, 31, v19
	v_and_b32_sdwa v18, v18, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v23, 28, v0
	v_bitop3_b16 v18, v18, s4, v19 bitop3:0xfe
	v_bitop3_b16 v19, v20, s4, v21 bitop3:0xfe
	v_lshlrev_b32_e32 v19, 16, v19
	v_or_b32_sdwa v43, v18, v19 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v18, 27, v0
	v_add_u16_e32 v19, 24, v0
	v_add_u16_e32 v20, 1, v0
	v_add_u16_e32 v21, 30, v0
	v_and_b32_e32 v21, 31, v21
	v_and_b32_sdwa v20, v20, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v19, 31, v19
	v_and_b32_sdwa v18, v18, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v23, 31, v23
	v_bitop3_b16 v18, v18, s4, v19 bitop3:0xfe
	v_bitop3_b16 v19, v20, s4, v21 bitop3:0xfe
	v_lshlrev_b32_e32 v19, 16, v19
	v_or_b32_sdwa v44, v18, v19 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v18, 7, v0
	v_add_u16_e32 v19, 4, v0
	v_add_u16_e32 v20, 13, v0
	v_add_u16_e32 v21, 10, v0
	v_and_b32_e32 v21, 31, v21
	v_and_b32_sdwa v20, v20, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v19, 31, v19
	v_and_b32_sdwa v18, v18, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_mov_b32_e32 v50, 0x7f7f7f7f
	v_bitop3_b16 v18, v18, s4, v19 bitop3:0xfe
	v_bitop3_b16 v19, v20, s4, v21 bitop3:0xfe
	v_lshlrev_b32_e32 v19, 16, v19
	v_or_b32_sdwa v45, v18, v19 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v19, 25, v0
	v_add_u16_e32 v20, 22, v0
	v_add_u16_e32 v21, 19, v0
	v_and_b32_e32 v20, 31, v20
	v_and_b32_sdwa v19, v19, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v18, v0, 48, 31 bitop3:0x6c
	v_and_b32_sdwa v21, v21, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v19, v19, s4, v20 bitop3:0xfe
	v_bitop3_b16 v18, v21, s5, v18 bitop3:0xfe
	v_lshlrev_b32_e32 v19, 16, v19
	v_or_b32_sdwa v46, v18, v19 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v18, 5, v0
	v_add_u16_e32 v19, 2, v0
	v_add_u16_e32 v20, -1, v0
	v_and_b32_e32 v19, 31, v19
	v_and_b32_sdwa v18, v18, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_sdwa v20, v20, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v18, v18, s4, v19 bitop3:0xfe
	v_bitop3_b16 v19, v20, s4, v23 bitop3:0xfe
	v_lshlrev_b32_e32 v18, 16, v18
	v_or_b32_sdwa v47, v19, v18 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v18, 17, v0
	v_add_u16_e32 v19, 14, v0
	v_add_u16_e32 v21, 8, v0
	v_add_u16_e32 v20, 11, v0
	v_and_b32_e32 v19, 31, v19
	v_and_b32_sdwa v18, v18, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v21, 31, v21
	v_and_b32_sdwa v20, v20, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v18, v18, s4, v19 bitop3:0xfe
	v_bitop3_b16 v19, v20, s4, v21 bitop3:0xfe
	v_lshlrev_b32_e32 v18, 16, v18
	v_or_b32_sdwa v48, v19, v18 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v19, 29, v0
	v_add_u16_e32 v20, 26, v0
	v_add_u16_e32 v23, 20, v0
	v_add_u16_e32 v18, 23, v0
	v_and_b32_e32 v20, 31, v20
	v_and_b32_sdwa v19, v19, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v23, 31, v23
	v_and_b32_sdwa v18, v18, v22 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v19, v19, s4, v20 bitop3:0xfe
	v_bitop3_b16 v18, v18, s4, v23 bitop3:0xfe
	v_lshlrev_b32_e32 v19, 16, v19
	v_or_b32_sdwa v49, v18, v19 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_mov_b32_e32 v18, v6
	v_mov_b32_e32 v19, v7
	v_mov_b32_e32 v20, v8
	v_mov_b32_e32 v21, v9
	v_mov_b32_e32 v22, v10
	v_mov_b32_e32 v23, v11
	v_mov_b32_e32 v24, v12
	v_mov_b32_e32 v25, v13
	v_mov_b32_e32 v26, v14
	v_mov_b32_e32 v27, v15
	v_mov_b32_e32 v28, v16
	v_mov_b32_e32 v29, v17
	.p2align	5, , 4
.LBB2_2:                                ; =>This Inner Loop Header: Depth=1
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel_hi:[0,0,0]
	s_add_i32 s3, s3, -1
	s_cmp_eq_u32 s3, 0
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[42:49], v[34:41], v[2:17], v50, v50 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[42:49], v[34:41], v[18:33], v50, v50 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	s_cbranch_scc0 .LBB2_2
; %bb.3:                                ; %Flow201
	v_cmp_eq_u32_e32 vcc, 0, v1
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB2_5
.LBB2_4:                                ; %.preheader
	s_load_dword s3, s[0:1], 0x1c
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	v_lshrrev_b32_e32 v0, 6, v0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v34, s2
	s_waitcnt lgkmcnt(0)
	s_bfe_u32 s0, s3, 0xa0006
	v_mad_u64_u32 v[0:1], s[0:1], s0, v34, v[0:1]
	v_lshlrev_b64 v[0:1], 7, v[0:1]
	v_lshl_add_u64 v[0:1], s[4:5], 0, v[0:1]
	s_nop 4
	global_store_dwordx4 v[0:1], v[2:5], off
	global_store_dwordx4 v[0:1], v[6:9], off offset:16
	global_store_dwordx4 v[0:1], v[10:13], off offset:32
	global_store_dwordx4 v[0:1], v[14:17], off offset:48
	global_store_dwordx4 v[0:1], v[18:21], off offset:64
	global_store_dwordx4 v[0:1], v[22:25], off offset:80
	global_store_dwordx4 v[0:1], v[26:29], off offset:96
	global_store_dwordx4 v[0:1], v[30:33], off offset:112
.LBB2_5:                                ; %.loopexit
	s_endpgm
.LBB2_6:
	v_mov_b32_e32 v29, v17
	v_mov_b32_e32 v28, v16
	v_mov_b32_e32 v27, v15
	v_mov_b32_e32 v26, v14
	v_mov_b32_e32 v25, v13
	v_mov_b32_e32 v24, v12
	v_mov_b32_e32 v23, v11
	v_mov_b32_e32 v22, v10
	v_mov_b32_e32 v21, v9
	v_mov_b32_e32 v20, v8
	v_mov_b32_e32 v19, v7
	v_mov_b32_e32 v18, v6
	v_cmp_eq_u32_e32 vcc, 0, v1
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execnz .LBB2_4
	s_branch .LBB2_5
.Lfunc_end2:
	.size	_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi, .Lfunc_end2-_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 272
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
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 51
		.amdhsa_next_free_sgpr 6
		.amdhsa_accum_offset 52
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
	.section	.text._ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi,"axG",@progbits,_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi,comdat
                                        ; -- End function
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi.num_vgpr, 51
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi.num_agpr, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi.numbered_sgpr, 6
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi.num_named_barrier, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi.private_seg_size, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi.uses_vcc, 1
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi.uses_flat_scratch, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi.has_dyn_sized_stack, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi.has_recursion, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2240
; TotalNumSgprs: 12
; NumVgprs: 51
; NumAgprs: 0
; TotalNumVgprs: 51
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 6
; NumSGPRsForWavesPerEU: 12
; NumVGPRsForWavesPerEU: 51
; AccumOffset: 52
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 12
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.text._ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi,"axG",@progbits,_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi,comdat
	.globl	_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi ; -- Begin function _ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi
	.p2align	8
	.type	_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi,@function
_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi: ; @_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi
; %bb.0:                                ; %.preheader48
	v_and_b32_e32 v1, 63, v0
	v_add_u32_e32 v18, 17, v1
	v_add_u32_e32 v19, 18, v1
	s_mov_b32 s4, 0x35800000
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_pk_mul_f32 v[62:63], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 19, v1
	v_add_u32_e32 v19, 20, v1
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_pk_mul_f32 v[64:65], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 21, v1
	v_add_u32_e32 v19, 22, v1
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	s_load_dword s3, s[0:1], 0x8
	v_pk_mul_f32 v[30:31], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 23, v1
	v_add_u32_e32 v19, 24, v1
	v_add_u32_e32 v6, 5, v1
	v_add_u32_e32 v7, 6, v1
	v_add_u32_e32 v8, 7, v1
	v_add_u32_e32 v9, 8, v1
	v_add_u32_e32 v10, 9, v1
	v_add_u32_e32 v11, 10, v1
	v_add_u32_e32 v12, 11, v1
	v_add_u32_e32 v13, 12, v1
	v_add_u32_e32 v14, 13, v1
	v_add_u32_e32 v15, 14, v1
	v_add_u32_e32 v16, 15, v1
	v_add_u32_e32 v17, 16, v1
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_add_u32_e32 v2, 1, v1
	v_add_u32_e32 v3, 2, v1
	v_add_u32_e32 v4, 3, v1
	v_add_u32_e32 v5, 4, v1
	v_cvt_f32_ubyte0_e32 v7, v7
	v_cvt_f32_ubyte0_e32 v6, v6
	v_cvt_f32_ubyte0_e32 v9, v9
	v_cvt_f32_ubyte0_e32 v8, v8
	v_cvt_f32_ubyte0_e32 v11, v11
	v_cvt_f32_ubyte0_e32 v10, v10
	v_cvt_f32_ubyte0_e32 v13, v13
	v_cvt_f32_ubyte0_e32 v12, v12
	v_cvt_f32_ubyte0_e32 v15, v15
	v_cvt_f32_ubyte0_e32 v14, v14
	v_cvt_f32_ubyte0_e32 v17, v17
	v_cvt_f32_ubyte0_e32 v16, v16
	v_pk_mul_f32 v[32:33], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 25, v1
	v_add_u32_e32 v19, 26, v1
	v_add_u32_e32 v20, 27, v1
	v_add_u32_e32 v21, 28, v1
	v_cvt_f32_ubyte0_e32 v3, v3
	v_cvt_f32_ubyte0_e32 v2, v2
	v_cvt_f32_ubyte0_e32 v5, v5
	v_cvt_f32_ubyte0_e32 v4, v4
	v_pk_mul_f32 v[6:7], v[6:7], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[10:11], v[10:11], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[12:13], v[12:13], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[14:15], v[14:15], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[16:17], v[16:17], s[4:5] op_sel_hi:[1,0]
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_cvt_f32_ubyte0_e32 v21, v21
	v_cvt_f32_ubyte0_e32 v20, v20
	v_pk_mul_f32 v[2:3], v[2:3], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[4:5], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[46:47], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[48:49], v[20:21], s[4:5] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_i32 s3, 1
	v_mov_b32_e32 v50, v6
	v_mov_b32_e32 v51, v7
	v_mov_b32_e32 v52, v8
	v_mov_b32_e32 v53, v9
	v_mov_b32_e32 v54, v10
	v_mov_b32_e32 v55, v11
	v_mov_b32_e32 v56, v12
	v_mov_b32_e32 v57, v13
	v_mov_b32_e32 v58, v14
	v_mov_b32_e32 v59, v15
	v_mov_b32_e32 v60, v16
	v_mov_b32_e32 v61, v17
	v_mov_b32_e32 v18, v10
	v_mov_b32_e32 v19, v11
	v_mov_b32_e32 v20, v12
	v_mov_b32_e32 v21, v13
	v_mov_b32_e32 v22, v14
	v_mov_b32_e32 v23, v15
	v_mov_b32_e32 v24, v16
	v_mov_b32_e32 v25, v17
	v_mov_b32_e32 v26, v62
	v_mov_b32_e32 v27, v63
	v_mov_b32_e32 v28, v64
	v_mov_b32_e32 v29, v65
	v_mov_b32_e32 v34, v14
	v_mov_b32_e32 v35, v15
	v_mov_b32_e32 v36, v16
	v_mov_b32_e32 v37, v17
	v_mov_b32_e32 v38, v62
	v_mov_b32_e32 v39, v63
	v_mov_b32_e32 v40, v64
	v_mov_b32_e32 v41, v65
	v_mov_b32_e32 v42, v30
	v_mov_b32_e32 v43, v31
	v_mov_b32_e32 v44, v32
	v_mov_b32_e32 v45, v33
	s_cbranch_scc1 .LBB3_3
; %bb.1:                                ; %.lr.ph
	v_mul_u32_u24_e32 v73, 3, v0
	v_add_u16_e32 v67, 15, v73
	v_add_u16_e32 v68, 10, v73
	v_mov_b32_e32 v81, 31
	v_add_u16_e32 v66, 5, v73
	v_and_b32_e32 v68, 31, v68
	v_and_b32_sdwa v67, v67, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	s_movk_i32 s4, 0x2020
	v_and_b32_sdwa v66, v66, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v69, 31, v73
	v_bitop3_b16 v67, v67, s4, v68 bitop3:0xfe
	v_bitop3_b16 v66, v66, s4, v69 bitop3:0xfe
	v_lshlrev_b32_e32 v67, 16, v67
	v_or_b32_sdwa v66, v66, v67 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v67, 25, v73
	v_add_u16_e32 v68, 20, v73
	v_add_u16_e32 v69, 3, v73
	v_add_u16_e32 v70, 30, v73
	v_and_b32_e32 v70, 31, v70
	v_and_b32_sdwa v69, v69, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v68, 31, v68
	v_and_b32_sdwa v67, v67, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v71, 18, v73
	v_bitop3_b16 v67, v67, s4, v68 bitop3:0xfe
	v_bitop3_b16 v68, v69, s4, v70 bitop3:0xfe
	v_lshlrev_b32_e32 v68, 16, v68
	v_or_b32_sdwa v67, v67, v68 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v68, 13, v73
	v_add_u16_e32 v69, 8, v73
	v_add_u16_e32 v70, 23, v73
	v_and_b32_e32 v71, 31, v71
	v_and_b32_sdwa v70, v70, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v69, 31, v69
	v_and_b32_sdwa v68, v68, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v72, 6, v73
	v_bitop3_b16 v68, v68, s4, v69 bitop3:0xfe
	v_bitop3_b16 v69, v70, s4, v71 bitop3:0xfe
	v_lshlrev_b32_e32 v69, 16, v69
	v_or_b32_sdwa v68, v68, v69 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v69, 1, v73
	v_add_u16_e32 v70, 28, v73
	v_add_u16_e32 v71, 11, v73
	v_and_b32_e32 v72, 31, v72
	v_and_b32_sdwa v71, v71, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v70, 31, v70
	v_and_b32_sdwa v69, v69, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v74, 21, v73
	v_bitop3_b16 v69, v69, s4, v70 bitop3:0xfe
	v_bitop3_b16 v70, v71, s4, v72 bitop3:0xfe
	v_add_u16_e32 v71, -1, v73
	v_add_u16_e32 v72, 26, v73
	v_lshlrev_b32_e32 v70, 16, v70
	v_and_b32_e32 v72, 31, v72
	v_and_b32_sdwa v71, v71, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_or_b32_sdwa v69, v69, v70 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_bitop3_b16 v70, v73, 48, 31 bitop3:0x6c
	v_and_b32_sdwa v74, v74, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v71, v71, s4, v72 bitop3:0xfe
	s_movk_i32 s5, 0x2000
	v_bitop3_b16 v70, v74, s5, v70 bitop3:0xfe
	v_lshlrev_b32_e32 v71, 16, v71
	v_or_b32_sdwa v70, v70, v71 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v71, 19, v73
	v_add_u16_e32 v72, 14, v73
	v_add_u16_e32 v75, 4, v73
	v_add_u16_e32 v74, 9, v73
	v_and_b32_e32 v72, 31, v72
	v_and_b32_sdwa v71, v71, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v75, 31, v75
	v_and_b32_sdwa v74, v74, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v71, v71, s4, v72 bitop3:0xfe
	v_bitop3_b16 v72, v74, s4, v75 bitop3:0xfe
	v_lshlrev_b32_e32 v71, 16, v71
	v_or_b32_sdwa v71, v72, v71 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v72, 7, v73
	v_add_u16_e32 v74, 2, v73
	v_add_u16_e32 v76, 24, v73
	v_add_u16_e32 v75, 29, v73
	v_and_b32_e32 v74, 31, v74
	v_and_b32_sdwa v72, v72, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v76, 31, v76
	v_and_b32_sdwa v75, v75, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v72, v72, s4, v74 bitop3:0xfe
	v_bitop3_b16 v74, v75, s4, v76 bitop3:0xfe
	v_lshlrev_b32_e32 v72, 16, v72
	v_add_u16_e32 v77, 12, v73
	v_or_b32_sdwa v72, v74, v72 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v74, 17, v73
	v_add_u16_e32 v75, 27, v73
	v_add_u16_e32 v73, 22, v73
	v_and_b32_e32 v73, 31, v73
	v_and_b32_sdwa v75, v75, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v77, 31, v77
	v_and_b32_sdwa v74, v74, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v73, v75, s4, v73 bitop3:0xfe
	v_bitop3_b16 v74, v74, s4, v77 bitop3:0xfe
	v_lshlrev_b32_e32 v73, 16, v73
	v_add_u16_e32 v75, 9, v0
	v_add_u16_e32 v76, 6, v0
	v_or_b32_sdwa v73, v74, v73 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v74, 3, v0
	v_and_b32_e32 v76, 31, v76
	v_and_b32_sdwa v75, v75, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_sdwa v74, v74, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v77, 31, v0
	v_bitop3_b16 v75, v75, s4, v76 bitop3:0xfe
	v_bitop3_b16 v74, v74, s4, v77 bitop3:0xfe
	v_lshlrev_b32_e32 v75, 16, v75
	v_or_b32_sdwa v74, v74, v75 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v75, 15, v0
	v_add_u16_e32 v76, 12, v0
	v_add_u16_e32 v77, 21, v0
	v_add_u16_e32 v78, 18, v0
	v_and_b32_e32 v78, 31, v78
	v_and_b32_sdwa v77, v77, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v76, 31, v76
	v_and_b32_sdwa v75, v75, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v79, 30, v0
	v_bitop3_b16 v75, v75, s4, v76 bitop3:0xfe
	v_bitop3_b16 v76, v77, s4, v78 bitop3:0xfe
	v_lshlrev_b32_e32 v76, 16, v76
	v_or_b32_sdwa v75, v75, v76 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v76, 27, v0
	v_add_u16_e32 v77, 24, v0
	v_add_u16_e32 v78, 1, v0
	v_and_b32_e32 v79, 31, v79
	v_and_b32_sdwa v78, v78, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v77, 31, v77
	v_and_b32_sdwa v76, v76, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v80, 10, v0
	v_bitop3_b16 v76, v76, s4, v77 bitop3:0xfe
	v_bitop3_b16 v77, v78, s4, v79 bitop3:0xfe
	v_lshlrev_b32_e32 v77, 16, v77
	v_or_b32_sdwa v76, v76, v77 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v77, 7, v0
	v_add_u16_e32 v78, 4, v0
	v_add_u16_e32 v79, 13, v0
	v_and_b32_e32 v80, 31, v80
	v_and_b32_sdwa v79, v79, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v78, 31, v78
	v_and_b32_sdwa v77, v77, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v82, 19, v0
	v_bitop3_b16 v77, v77, s4, v78 bitop3:0xfe
	v_bitop3_b16 v78, v79, s4, v80 bitop3:0xfe
	v_add_u16_e32 v79, 25, v0
	v_add_u16_e32 v80, 22, v0
	v_lshlrev_b32_e32 v78, 16, v78
	v_and_b32_e32 v80, 31, v80
	v_and_b32_sdwa v79, v79, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_or_b32_sdwa v77, v77, v78 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_bitop3_b16 v78, v0, 48, 31 bitop3:0x6c
	v_and_b32_sdwa v82, v82, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v79, v79, s4, v80 bitop3:0xfe
	v_bitop3_b16 v78, v82, s5, v78 bitop3:0xfe
	v_lshlrev_b32_e32 v79, 16, v79
	v_or_b32_sdwa v78, v78, v79 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v79, 5, v0
	v_add_u16_e32 v80, 2, v0
	v_add_u16_e32 v83, 28, v0
	v_add_u16_e32 v82, -1, v0
	v_and_b32_e32 v80, 31, v80
	v_and_b32_sdwa v79, v79, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v83, 31, v83
	v_and_b32_sdwa v82, v82, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v79, v79, s4, v80 bitop3:0xfe
	v_bitop3_b16 v80, v82, s4, v83 bitop3:0xfe
	v_lshlrev_b32_e32 v79, 16, v79
	v_or_b32_sdwa v79, v80, v79 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v80, 17, v0
	v_add_u16_e32 v82, 14, v0
	v_add_u16_e32 v84, 8, v0
	v_add_u16_e32 v83, 11, v0
	v_and_b32_e32 v82, 31, v82
	v_and_b32_sdwa v80, v80, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v84, 31, v84
	v_and_b32_sdwa v83, v83, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v80, v80, s4, v82 bitop3:0xfe
	v_bitop3_b16 v82, v83, s4, v84 bitop3:0xfe
	v_lshlrev_b32_e32 v80, 16, v80
	v_or_b32_sdwa v80, v82, v80 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v82, 23, v0
	v_add_u16_e32 v83, 29, v0
	v_add_u16_e32 v84, 26, v0
	v_add_u16_e32 v85, 20, v0
	v_and_b32_sdwa v82, v82, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v84, 31, v84
	v_and_b32_sdwa v81, v83, v81 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v85, 31, v85
	v_bitop3_b16 v81, v81, s4, v84 bitop3:0xfe
	v_bitop3_b16 v82, v82, s4, v85 bitop3:0xfe
	v_lshlrev_b32_e32 v81, 16, v81
	v_or_b32_sdwa v81, v82, v81 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_mov_b32_e32 v82, 0x7f7f7f7f
	.p2align	5, , 4
.LBB3_2:                                ; =>This Inner Loop Header: Depth=1
	s_nop 1
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[74:81], v[66:73], v[2:17], v82, v82 op_sel_hi:[0,0,0]
	s_add_i32 s3, s3, -1
	s_cmp_eq_u32 s3, 0
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[74:81], v[66:73], v[50:65], v82, v82 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[74:81], v[66:73], v[18:33], v82, v82 op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[74:81], v[66:73], v[34:49], v82, v82 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[74:81], v[66:73], v[2:17], v82, v82 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[74:81], v[66:73], v[50:65], v82, v82 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[74:81], v[66:73], v[18:33], v82, v82 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[74:81], v[66:73], v[34:49], v82, v82 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[74:81], v[66:73], v[2:17], v82, v82 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[74:81], v[66:73], v[50:65], v82, v82 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[74:81], v[66:73], v[18:33], v82, v82 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[74:81], v[66:73], v[34:49], v82, v82 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[74:81], v[66:73], v[2:17], v82, v82 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[74:81], v[66:73], v[50:65], v82, v82 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[74:81], v[66:73], v[18:33], v82, v82 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[74:81], v[66:73], v[34:49], v82, v82 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[74:81], v[66:73], v[2:17], v82, v82 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[74:81], v[66:73], v[50:65], v82, v82 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[74:81], v[66:73], v[18:33], v82, v82 op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[74:81], v[66:73], v[34:49], v82, v82 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[74:81], v[66:73], v[2:17], v82, v82 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[74:81], v[66:73], v[50:65], v82, v82 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[74:81], v[66:73], v[18:33], v82, v82 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[74:81], v[66:73], v[34:49], v82, v82 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[74:81], v[66:73], v[2:17], v82, v82 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[74:81], v[66:73], v[50:65], v82, v82 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[74:81], v[66:73], v[18:33], v82, v82 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[74:81], v[66:73], v[34:49], v82, v82 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[74:81], v[66:73], v[2:17], v82, v82 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[74:81], v[66:73], v[50:65], v82, v82 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[74:81], v[66:73], v[18:33], v82, v82 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[74:81], v[66:73], v[34:49], v82, v82 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	s_cbranch_scc0 .LBB3_2
.LBB3_3:                                ; %Flow500
	v_cmp_eq_u32_e32 vcc, 0, v1
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB3_5
; %bb.4:                                ; %.preheader
	s_load_dword s3, s[0:1], 0x1c
	s_load_dwordx2 s[4:5], s[0:1], 0x0
	v_lshrrev_b32_e32 v0, 6, v0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v66, s2
	s_waitcnt lgkmcnt(0)
	s_bfe_u32 s0, s3, 0xa0006
	v_mad_u64_u32 v[0:1], s[0:1], s0, v66, v[0:1]
	v_lshlrev_b64 v[0:1], 8, v[0:1]
	v_lshl_add_u64 v[0:1], s[4:5], 0, v[0:1]
	s_nop 2
	global_store_dwordx4 v[0:1], v[2:5], off
	global_store_dwordx4 v[0:1], v[6:9], off offset:16
	global_store_dwordx4 v[0:1], v[10:13], off offset:32
	global_store_dwordx4 v[0:1], v[14:17], off offset:48
	global_store_dwordx4 v[0:1], v[50:53], off offset:64
	global_store_dwordx4 v[0:1], v[54:57], off offset:80
	global_store_dwordx4 v[0:1], v[58:61], off offset:96
	global_store_dwordx4 v[0:1], v[62:65], off offset:112
	global_store_dwordx4 v[0:1], v[18:21], off offset:128
	global_store_dwordx4 v[0:1], v[22:25], off offset:144
	global_store_dwordx4 v[0:1], v[26:29], off offset:160
	global_store_dwordx4 v[0:1], v[30:33], off offset:176
	global_store_dwordx4 v[0:1], v[34:37], off offset:192
	global_store_dwordx4 v[0:1], v[38:41], off offset:208
	global_store_dwordx4 v[0:1], v[42:45], off offset:224
	global_store_dwordx4 v[0:1], v[46:49], off offset:240
.LBB3_5:                                ; %.loopexit
	s_endpgm
.Lfunc_end3:
	.size	_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi, .Lfunc_end3-_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 272
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
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 86
		.amdhsa_next_free_sgpr 6
		.amdhsa_accum_offset 88
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
	.section	.text._ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi,"axG",@progbits,_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi,comdat
                                        ; -- End function
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi.num_vgpr, 86
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi.num_agpr, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi.numbered_sgpr, 6
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi.num_named_barrier, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi.private_seg_size, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi.uses_vcc, 1
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi.uses_flat_scratch, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi.has_dyn_sized_stack, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi.has_recursion, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2372
; TotalNumSgprs: 12
; NumVgprs: 86
; NumAgprs: 0
; TotalNumVgprs: 86
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 10
; NumSGPRsForWavesPerEU: 12
; NumVGPRsForWavesPerEU: 86
; AccumOffset: 88
; Occupancy: 5
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 21
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.text._ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi,"axG",@progbits,_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi,comdat
	.globl	_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi ; -- Begin function _ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi
	.p2align	8
	.type	_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi,@function
_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi: ; @_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi
; %bb.0:                                ; %.preheader48
	v_and_b32_e32 v1, 63, v0
	v_add_u32_e32 v18, 17, v1
	v_add_u32_e32 v19, 18, v1
	s_mov_b32 s4, 0x35800000
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_pk_mul_f32 v[126:127], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 19, v1
	v_add_u32_e32 v19, 20, v1
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_pk_mul_f32 v[128:129], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 21, v1
	v_add_u32_e32 v19, 22, v1
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_pk_mul_f32 v[110:111], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 23, v1
	v_add_u32_e32 v19, 24, v1
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_pk_mul_f32 v[112:113], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 25, v1
	v_add_u32_e32 v19, 26, v1
	v_add_u32_e32 v20, 27, v1
	v_add_u32_e32 v21, 28, v1
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_cvt_f32_ubyte0_e32 v21, v21
	v_cvt_f32_ubyte0_e32 v20, v20
	v_pk_mul_f32 v[94:95], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[96:97], v[20:21], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 29, v1
	v_add_u32_e32 v19, 30, v1
	v_add_u32_e32 v20, 31, v1
	v_add_u32_e32 v21, 32, v1
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_cvt_f32_ubyte0_e32 v21, v21
	v_cvt_f32_ubyte0_e32 v20, v20
	v_pk_mul_f32 v[78:79], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[80:81], v[20:21], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 33, v1
	v_add_u32_e32 v19, 34, v1
	v_add_u32_e32 v20, 35, v1
	v_add_u32_e32 v21, 36, v1
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_cvt_f32_ubyte0_e32 v21, v21
	v_cvt_f32_ubyte0_e32 v20, v20
	s_load_dword s3, s[0:1], 0x8
	v_pk_mul_f32 v[62:63], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[64:65], v[20:21], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 37, v1
	v_add_u32_e32 v19, 38, v1
	v_add_u32_e32 v20, 39, v1
	v_add_u32_e32 v21, 40, v1
	v_add_u32_e32 v6, 5, v1
	v_add_u32_e32 v7, 6, v1
	v_add_u32_e32 v8, 7, v1
	v_add_u32_e32 v9, 8, v1
	v_add_u32_e32 v10, 9, v1
	v_add_u32_e32 v11, 10, v1
	v_add_u32_e32 v12, 11, v1
	v_add_u32_e32 v13, 12, v1
	v_add_u32_e32 v14, 13, v1
	v_add_u32_e32 v15, 14, v1
	v_add_u32_e32 v16, 15, v1
	v_add_u32_e32 v17, 16, v1
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_cvt_f32_ubyte0_e32 v21, v21
	v_cvt_f32_ubyte0_e32 v20, v20
	v_add_u32_e32 v2, 1, v1
	v_add_u32_e32 v3, 2, v1
	v_add_u32_e32 v4, 3, v1
	v_add_u32_e32 v5, 4, v1
	v_cvt_f32_ubyte0_e32 v7, v7
	v_cvt_f32_ubyte0_e32 v6, v6
	v_cvt_f32_ubyte0_e32 v9, v9
	v_cvt_f32_ubyte0_e32 v8, v8
	v_cvt_f32_ubyte0_e32 v11, v11
	v_cvt_f32_ubyte0_e32 v10, v10
	v_cvt_f32_ubyte0_e32 v13, v13
	v_cvt_f32_ubyte0_e32 v12, v12
	v_cvt_f32_ubyte0_e32 v15, v15
	v_cvt_f32_ubyte0_e32 v14, v14
	v_cvt_f32_ubyte0_e32 v17, v17
	v_cvt_f32_ubyte0_e32 v16, v16
	v_pk_mul_f32 v[30:31], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[32:33], v[20:21], s[4:5] op_sel_hi:[1,0]
	v_add_u32_e32 v18, 41, v1
	v_add_u32_e32 v19, 42, v1
	v_add_u32_e32 v20, 43, v1
	v_add_u32_e32 v21, 44, v1
	v_cvt_f32_ubyte0_e32 v3, v3
	v_cvt_f32_ubyte0_e32 v2, v2
	v_cvt_f32_ubyte0_e32 v5, v5
	v_cvt_f32_ubyte0_e32 v4, v4
	v_pk_mul_f32 v[6:7], v[6:7], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[8:9], v[8:9], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[10:11], v[10:11], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[12:13], v[12:13], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[14:15], v[14:15], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[16:17], v[16:17], s[4:5] op_sel_hi:[1,0]
	v_cvt_f32_ubyte0_e32 v19, v19
	v_cvt_f32_ubyte0_e32 v18, v18
	v_cvt_f32_ubyte0_e32 v21, v21
	v_cvt_f32_ubyte0_e32 v20, v20
	v_pk_mul_f32 v[2:3], v[2:3], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[4:5], v[4:5], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[46:47], v[18:19], s[4:5] op_sel_hi:[1,0]
	v_pk_mul_f32 v[48:49], v[20:21], s[4:5] op_sel_hi:[1,0]
	s_waitcnt lgkmcnt(0)
	s_cmp_lt_i32 s3, 1
	v_mov_b32_e32 v114, v6
	v_mov_b32_e32 v115, v7
	v_mov_b32_e32 v116, v8
	v_mov_b32_e32 v117, v9
	v_mov_b32_e32 v118, v10
	v_mov_b32_e32 v119, v11
	v_mov_b32_e32 v120, v12
	v_mov_b32_e32 v121, v13
	v_mov_b32_e32 v122, v14
	v_mov_b32_e32 v123, v15
	v_mov_b32_e32 v124, v16
	v_mov_b32_e32 v125, v17
	v_mov_b32_e32 v98, v10
	v_mov_b32_e32 v99, v11
	v_mov_b32_e32 v100, v12
	v_mov_b32_e32 v101, v13
	v_mov_b32_e32 v102, v14
	v_mov_b32_e32 v103, v15
	v_mov_b32_e32 v104, v16
	v_mov_b32_e32 v105, v17
	v_mov_b32_e32 v106, v126
	v_mov_b32_e32 v107, v127
	v_mov_b32_e32 v108, v128
	v_mov_b32_e32 v109, v129
	v_mov_b32_e32 v82, v14
	v_mov_b32_e32 v83, v15
	v_mov_b32_e32 v84, v16
	v_mov_b32_e32 v85, v17
	v_mov_b32_e32 v86, v126
	v_mov_b32_e32 v87, v127
	v_mov_b32_e32 v88, v128
	v_mov_b32_e32 v89, v129
	v_mov_b32_e32 v90, v110
	v_mov_b32_e32 v91, v111
	v_mov_b32_e32 v92, v112
	v_mov_b32_e32 v93, v113
	v_mov_b32_e32 v66, v126
	v_mov_b32_e32 v67, v127
	v_mov_b32_e32 v68, v128
	v_mov_b32_e32 v69, v129
	v_mov_b32_e32 v70, v110
	v_mov_b32_e32 v71, v111
	v_mov_b32_e32 v72, v112
	v_mov_b32_e32 v73, v113
	v_mov_b32_e32 v74, v94
	v_mov_b32_e32 v75, v95
	v_mov_b32_e32 v76, v96
	v_mov_b32_e32 v77, v97
	v_mov_b32_e32 v50, v110
	v_mov_b32_e32 v51, v111
	v_mov_b32_e32 v52, v112
	v_mov_b32_e32 v53, v113
	v_mov_b32_e32 v54, v94
	v_mov_b32_e32 v55, v95
	v_mov_b32_e32 v56, v96
	v_mov_b32_e32 v57, v97
	v_mov_b32_e32 v58, v78
	v_mov_b32_e32 v59, v79
	v_mov_b32_e32 v60, v80
	v_mov_b32_e32 v61, v81
	v_mov_b32_e32 v18, v94
	v_mov_b32_e32 v19, v95
	v_mov_b32_e32 v20, v96
	v_mov_b32_e32 v21, v97
	v_mov_b32_e32 v22, v78
	v_mov_b32_e32 v23, v79
	v_mov_b32_e32 v24, v80
	v_mov_b32_e32 v25, v81
	v_mov_b32_e32 v26, v62
	v_mov_b32_e32 v27, v63
	v_mov_b32_e32 v28, v64
	v_mov_b32_e32 v29, v65
	v_mov_b32_e32 v34, v78
	v_mov_b32_e32 v35, v79
	v_mov_b32_e32 v36, v80
	v_mov_b32_e32 v37, v81
	v_mov_b32_e32 v38, v62
	v_mov_b32_e32 v39, v63
	v_mov_b32_e32 v40, v64
	v_mov_b32_e32 v41, v65
	v_mov_b32_e32 v42, v30
	v_mov_b32_e32 v43, v31
	v_mov_b32_e32 v44, v32
	v_mov_b32_e32 v45, v33
	s_cbranch_scc1 .LBB4_3
; %bb.1:                                ; %.lr.ph
	v_mul_u32_u24_e32 v137, 3, v0
	v_add_u16_e32 v131, 15, v137
	v_add_u16_e32 v132, 10, v137
	v_mov_b32_e32 v145, 31
	v_add_u16_e32 v130, 5, v137
	v_and_b32_e32 v132, 31, v132
	v_and_b32_sdwa v131, v131, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	s_movk_i32 s4, 0x2020
	v_and_b32_sdwa v130, v130, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v133, 31, v137
	v_bitop3_b16 v131, v131, s4, v132 bitop3:0xfe
	v_bitop3_b16 v130, v130, s4, v133 bitop3:0xfe
	v_lshlrev_b32_e32 v131, 16, v131
	v_or_b32_sdwa v130, v130, v131 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v131, 25, v137
	v_add_u16_e32 v132, 20, v137
	v_add_u16_e32 v133, 3, v137
	v_add_u16_e32 v134, 30, v137
	v_and_b32_e32 v134, 31, v134
	v_and_b32_sdwa v133, v133, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v132, 31, v132
	v_and_b32_sdwa v131, v131, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v135, 18, v137
	v_bitop3_b16 v131, v131, s4, v132 bitop3:0xfe
	v_bitop3_b16 v132, v133, s4, v134 bitop3:0xfe
	v_lshlrev_b32_e32 v132, 16, v132
	v_or_b32_sdwa v131, v131, v132 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v132, 13, v137
	v_add_u16_e32 v133, 8, v137
	v_add_u16_e32 v134, 23, v137
	v_and_b32_e32 v135, 31, v135
	v_and_b32_sdwa v134, v134, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v133, 31, v133
	v_and_b32_sdwa v132, v132, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v136, 6, v137
	v_bitop3_b16 v132, v132, s4, v133 bitop3:0xfe
	v_bitop3_b16 v133, v134, s4, v135 bitop3:0xfe
	v_lshlrev_b32_e32 v133, 16, v133
	v_or_b32_sdwa v132, v132, v133 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v133, 1, v137
	v_add_u16_e32 v134, 28, v137
	v_add_u16_e32 v135, 11, v137
	v_and_b32_e32 v136, 31, v136
	v_and_b32_sdwa v135, v135, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v134, 31, v134
	v_and_b32_sdwa v133, v133, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v138, 21, v137
	v_bitop3_b16 v133, v133, s4, v134 bitop3:0xfe
	v_bitop3_b16 v134, v135, s4, v136 bitop3:0xfe
	v_add_u16_e32 v135, -1, v137
	v_add_u16_e32 v136, 26, v137
	v_lshlrev_b32_e32 v134, 16, v134
	v_and_b32_e32 v136, 31, v136
	v_and_b32_sdwa v135, v135, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_or_b32_sdwa v133, v133, v134 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_bitop3_b16 v134, v137, 48, 31 bitop3:0x6c
	v_and_b32_sdwa v138, v138, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v135, v135, s4, v136 bitop3:0xfe
	s_movk_i32 s5, 0x2000
	v_bitop3_b16 v134, v138, s5, v134 bitop3:0xfe
	v_lshlrev_b32_e32 v135, 16, v135
	v_or_b32_sdwa v134, v134, v135 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v135, 19, v137
	v_add_u16_e32 v136, 14, v137
	v_add_u16_e32 v139, 4, v137
	v_add_u16_e32 v138, 9, v137
	v_and_b32_e32 v136, 31, v136
	v_and_b32_sdwa v135, v135, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v139, 31, v139
	v_and_b32_sdwa v138, v138, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v135, v135, s4, v136 bitop3:0xfe
	v_bitop3_b16 v136, v138, s4, v139 bitop3:0xfe
	v_lshlrev_b32_e32 v135, 16, v135
	v_or_b32_sdwa v135, v136, v135 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v136, 7, v137
	v_add_u16_e32 v138, 2, v137
	v_add_u16_e32 v140, 24, v137
	v_add_u16_e32 v139, 29, v137
	v_and_b32_e32 v138, 31, v138
	v_and_b32_sdwa v136, v136, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v140, 31, v140
	v_and_b32_sdwa v139, v139, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v136, v136, s4, v138 bitop3:0xfe
	v_bitop3_b16 v138, v139, s4, v140 bitop3:0xfe
	v_lshlrev_b32_e32 v136, 16, v136
	v_add_u16_e32 v141, 12, v137
	v_or_b32_sdwa v136, v138, v136 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v138, 17, v137
	v_add_u16_e32 v139, 27, v137
	v_add_u16_e32 v137, 22, v137
	v_and_b32_e32 v137, 31, v137
	v_and_b32_sdwa v139, v139, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v141, 31, v141
	v_and_b32_sdwa v138, v138, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v137, v139, s4, v137 bitop3:0xfe
	v_bitop3_b16 v138, v138, s4, v141 bitop3:0xfe
	v_lshlrev_b32_e32 v137, 16, v137
	v_add_u16_e32 v139, 9, v0
	v_add_u16_e32 v140, 6, v0
	v_or_b32_sdwa v137, v138, v137 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v138, 3, v0
	v_and_b32_e32 v140, 31, v140
	v_and_b32_sdwa v139, v139, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_sdwa v138, v138, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v141, 31, v0
	v_bitop3_b16 v139, v139, s4, v140 bitop3:0xfe
	v_bitop3_b16 v138, v138, s4, v141 bitop3:0xfe
	v_lshlrev_b32_e32 v139, 16, v139
	v_or_b32_sdwa v138, v138, v139 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v139, 15, v0
	v_add_u16_e32 v140, 12, v0
	v_add_u16_e32 v141, 21, v0
	v_add_u16_e32 v142, 18, v0
	v_and_b32_e32 v142, 31, v142
	v_and_b32_sdwa v141, v141, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v140, 31, v140
	v_and_b32_sdwa v139, v139, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v143, 30, v0
	v_bitop3_b16 v139, v139, s4, v140 bitop3:0xfe
	v_bitop3_b16 v140, v141, s4, v142 bitop3:0xfe
	v_lshlrev_b32_e32 v140, 16, v140
	v_or_b32_sdwa v139, v139, v140 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v140, 27, v0
	v_add_u16_e32 v141, 24, v0
	v_add_u16_e32 v142, 1, v0
	v_and_b32_e32 v143, 31, v143
	v_and_b32_sdwa v142, v142, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v141, 31, v141
	v_and_b32_sdwa v140, v140, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v144, 10, v0
	v_bitop3_b16 v140, v140, s4, v141 bitop3:0xfe
	v_bitop3_b16 v141, v142, s4, v143 bitop3:0xfe
	v_lshlrev_b32_e32 v141, 16, v141
	v_or_b32_sdwa v140, v140, v141 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v141, 7, v0
	v_add_u16_e32 v142, 4, v0
	v_add_u16_e32 v143, 13, v0
	v_and_b32_e32 v144, 31, v144
	v_and_b32_sdwa v143, v143, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v142, 31, v142
	v_and_b32_sdwa v141, v141, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_add_u16_e32 v146, 19, v0
	v_bitop3_b16 v141, v141, s4, v142 bitop3:0xfe
	v_bitop3_b16 v142, v143, s4, v144 bitop3:0xfe
	v_add_u16_e32 v143, 25, v0
	v_add_u16_e32 v144, 22, v0
	v_lshlrev_b32_e32 v142, 16, v142
	v_and_b32_e32 v144, 31, v144
	v_and_b32_sdwa v143, v143, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_or_b32_sdwa v141, v141, v142 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_bitop3_b16 v142, v0, 48, 31 bitop3:0x6c
	v_and_b32_sdwa v146, v146, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v143, v143, s4, v144 bitop3:0xfe
	v_bitop3_b16 v142, v146, s5, v142 bitop3:0xfe
	v_lshlrev_b32_e32 v143, 16, v143
	v_or_b32_sdwa v142, v142, v143 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v143, 5, v0
	v_add_u16_e32 v144, 2, v0
	v_add_u16_e32 v147, 28, v0
	v_add_u16_e32 v146, -1, v0
	v_and_b32_e32 v144, 31, v144
	v_and_b32_sdwa v143, v143, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v147, 31, v147
	v_and_b32_sdwa v146, v146, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v143, v143, s4, v144 bitop3:0xfe
	v_bitop3_b16 v144, v146, s4, v147 bitop3:0xfe
	v_lshlrev_b32_e32 v143, 16, v143
	v_or_b32_sdwa v143, v144, v143 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v144, 17, v0
	v_add_u16_e32 v146, 14, v0
	v_add_u16_e32 v148, 8, v0
	v_add_u16_e32 v147, 11, v0
	v_and_b32_e32 v146, 31, v146
	v_and_b32_sdwa v144, v144, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v148, 31, v148
	v_and_b32_sdwa v147, v147, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_bitop3_b16 v144, v144, s4, v146 bitop3:0xfe
	v_bitop3_b16 v146, v147, s4, v148 bitop3:0xfe
	v_lshlrev_b32_e32 v144, 16, v144
	v_or_b32_sdwa v144, v146, v144 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_add_u16_e32 v146, 23, v0
	v_add_u16_e32 v147, 29, v0
	v_add_u16_e32 v148, 26, v0
	v_add_u16_e32 v149, 20, v0
	v_and_b32_sdwa v146, v146, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v148, 31, v148
	v_and_b32_sdwa v145, v147, v145 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
	v_and_b32_e32 v149, 31, v149
	v_bitop3_b16 v145, v145, s4, v148 bitop3:0xfe
	v_bitop3_b16 v146, v146, s4, v149 bitop3:0xfe
	v_lshlrev_b32_e32 v145, 16, v145
	v_or_b32_sdwa v145, v146, v145 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:WORD_0 src1_sel:DWORD
	v_mov_b32_e32 v146, 0x7f7f7f7f
	.p2align	5, , 4
.LBB4_2:                                ; =>This Inner Loop Header: Depth=1
	s_nop 1
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[138:145], v[130:137], v[2:17], v146, v146 op_sel_hi:[0,0,0]
	s_add_i32 s3, s3, -1
	s_cmp_eq_u32 s3, 0
	v_mfma_scale_f32_32x32x64_f8f6f4 v[114:129], v[138:145], v[130:137], v[114:129], v146, v146 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[98:113], v[138:145], v[130:137], v[98:113], v146, v146 op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[82:97], v[138:145], v[130:137], v[82:97], v146, v146 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[66:81], v[138:145], v[130:137], v[66:81], v146, v146 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[138:145], v[130:137], v[50:65], v146, v146 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[138:145], v[130:137], v[18:33], v146, v146 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[138:145], v[130:137], v[34:49], v146, v146 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[138:145], v[130:137], v[2:17], v146, v146 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[114:129], v[138:145], v[130:137], v[114:129], v146, v146 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[98:113], v[138:145], v[130:137], v[98:113], v146, v146 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[82:97], v[138:145], v[130:137], v[82:97], v146, v146 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[66:81], v[138:145], v[130:137], v[66:81], v146, v146 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[138:145], v[130:137], v[50:65], v146, v146 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[138:145], v[130:137], v[18:33], v146, v146 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[138:145], v[130:137], v[34:49], v146, v146 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[138:145], v[130:137], v[2:17], v146, v146 op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[114:129], v[138:145], v[130:137], v[114:129], v146, v146 op_sel:[1,0,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[98:113], v[138:145], v[130:137], v[98:113], v146, v146 op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[82:97], v[138:145], v[130:137], v[82:97], v146, v146 op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[66:81], v[138:145], v[130:137], v[66:81], v146, v146 op_sel:[0,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[138:145], v[130:137], v[50:65], v146, v146 op_sel:[1,1,0] op_sel_hi:[0,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[138:145], v[130:137], v[18:33], v146, v146 op_sel:[0,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[138:145], v[130:137], v[34:49], v146, v146 op_sel:[1,1,0] op_sel_hi:[1,0,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[2:17], v[138:145], v[130:137], v[2:17], v146, v146 op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[114:129], v[138:145], v[130:137], v[114:129], v146, v146 op_sel:[1,0,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[98:113], v[138:145], v[130:137], v[98:113], v146, v146 op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[82:97], v[138:145], v[130:137], v[82:97], v146, v146 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[66:81], v[138:145], v[130:137], v[66:81], v146, v146 op_sel:[0,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[50:65], v[138:145], v[130:137], v[50:65], v146, v146 op_sel:[1,1,0] op_sel_hi:[0,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[18:33], v[138:145], v[130:137], v[18:33], v146, v146 op_sel:[0,1,0] op_sel_hi:[1,1,0]
	v_mfma_scale_f32_32x32x64_f8f6f4 v[34:49], v[138:145], v[130:137], v[34:49], v146, v146 op_sel:[1,1,0] op_sel_hi:[1,1,0]
	s_cbranch_scc0 .LBB4_2
.LBB4_3:                                ; %Flow988
	v_cmp_eq_u32_e32 vcc, 0, v1
	s_and_saveexec_b64 s[4:5], vcc
	s_cbranch_execz .LBB4_5
; %bb.4:                                ; %.preheader
	s_load_dword s3, s[0:1], 0x1c
	s_nop 0
	s_load_dwordx2 s[0:1], s[0:1], 0x0
	v_lshrrev_b32_e32 v0, 6, v0
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v130, s2
	s_waitcnt lgkmcnt(0)
	s_bfe_u32 s2, s3, 0xa0006
	v_mad_u64_u32 v[0:1], s[2:3], s2, v130, v[0:1]
	v_lshlrev_b64 v[0:1], 9, v[0:1]
	v_lshl_add_u64 v[0:1], s[0:1], 0, v[0:1]
	global_store_dwordx4 v[0:1], v[2:5], off
	global_store_dwordx4 v[0:1], v[6:9], off offset:16
	global_store_dwordx4 v[0:1], v[10:13], off offset:32
	global_store_dwordx4 v[0:1], v[14:17], off offset:48
	global_store_dwordx4 v[0:1], v[114:117], off offset:64
	global_store_dwordx4 v[0:1], v[118:121], off offset:80
	global_store_dwordx4 v[0:1], v[122:125], off offset:96
	global_store_dwordx4 v[0:1], v[126:129], off offset:112
	global_store_dwordx4 v[0:1], v[98:101], off offset:128
	global_store_dwordx4 v[0:1], v[102:105], off offset:144
	global_store_dwordx4 v[0:1], v[106:109], off offset:160
	global_store_dwordx4 v[0:1], v[110:113], off offset:176
	global_store_dwordx4 v[0:1], v[82:85], off offset:192
	global_store_dwordx4 v[0:1], v[86:89], off offset:208
	global_store_dwordx4 v[0:1], v[90:93], off offset:224
	global_store_dwordx4 v[0:1], v[94:97], off offset:240
	global_store_dwordx4 v[0:1], v[66:69], off offset:256
	global_store_dwordx4 v[0:1], v[70:73], off offset:272
	global_store_dwordx4 v[0:1], v[74:77], off offset:288
	global_store_dwordx4 v[0:1], v[78:81], off offset:304
	global_store_dwordx4 v[0:1], v[50:53], off offset:320
	global_store_dwordx4 v[0:1], v[54:57], off offset:336
	global_store_dwordx4 v[0:1], v[58:61], off offset:352
	global_store_dwordx4 v[0:1], v[62:65], off offset:368
	global_store_dwordx4 v[0:1], v[18:21], off offset:384
	global_store_dwordx4 v[0:1], v[22:25], off offset:400
	global_store_dwordx4 v[0:1], v[26:29], off offset:416
	global_store_dwordx4 v[0:1], v[30:33], off offset:432
	global_store_dwordx4 v[0:1], v[34:37], off offset:448
	global_store_dwordx4 v[0:1], v[38:41], off offset:464
	global_store_dwordx4 v[0:1], v[42:45], off offset:480
	global_store_dwordx4 v[0:1], v[46:49], off offset:496
.LBB4_5:                                ; %.loopexit
	s_endpgm
.Lfunc_end4:
	.size	_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi, .Lfunc_end4-_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 272
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
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 150
		.amdhsa_next_free_sgpr 6
		.amdhsa_accum_offset 152
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
	.section	.text._ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi,"axG",@progbits,_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi,comdat
                                        ; -- End function
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi.num_vgpr, 150
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi.num_agpr, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi.numbered_sgpr, 6
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi.num_named_barrier, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi.private_seg_size, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi.uses_vcc, 1
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi.uses_flat_scratch, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi.has_dyn_sized_stack, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi.has_recursion, 0
	.set .L_ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 2884
; TotalNumSgprs: 12
; NumVgprs: 150
; NumAgprs: 0
; TotalNumVgprs: 150
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 1
; VGPRBlocks: 18
; NumSGPRsForWavesPerEU: 12
; NumVGPRsForWavesPerEU: 150
; AccumOffset: 152
; Occupancy: 3
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 2
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
; COMPUTE_PGM_RSRC3_GFX90A:ACCUM_OFFSET: 37
; COMPUTE_PGM_RSRC3_GFX90A:TG_SPLIT: 0
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.set amdgpu.max_num_named_barrier, 0
	.section	.AMDGPU.csdata,"",@progbits
	.type	__hip_cuid_2205ebfd559c82ad,@object ; @__hip_cuid_2205ebfd559c82ad
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_2205ebfd559c82ad
__hip_cuid_2205ebfd559c82ad:
	.byte	0                               ; 0x0
	.size	__hip_cuid_2205ebfd559c82ad, 1

	.ident	"AMD clang version 23.0.0git (https://github.com/ROCm/llvm-project.git 46fcb339fb61119b337f973c7ca9e710a319fdd0+PATCHED:440716f8b87be9d8e20ed910e10e5b6d14d57cf6)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_2205ebfd559c82ad
	.amdgpu_metadata
---
amdhsa.kernels:
  - .agpr_count:     0
    .args:
      - .offset:         0
        .size:           4
        .value_kind:     by_value
      - .offset:         4
        .size:           4
        .value_kind:     by_value
      - .offset:         8
        .size:           4
        .value_kind:     by_value
      - .offset:         12
        .size:           4
        .value_kind:     by_value
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
    .gfx1250_revision: B0
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 64
    .name:           _ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf
    .private_segment_fixed_size: 12
    .sgpr_count:     31
    .sgpr_spill_count: 0
    .symbol:         _ZN12_GLOBAL__N_118scale_route_kernelEiiiiPf.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     21
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .offset:         8
        .size:           4
        .value_kind:     by_value
      - .offset:         16
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         20
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         24
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         28
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         30
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         32
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         34
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         36
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         38
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         64
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         72
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         80
        .size:           2
        .value_kind:     hidden_grid_dims
    .gfx1250_revision: B0
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           _ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         _ZN12_GLOBAL__N_117throughput_kernelILi1EEEvPfi.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     38
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .offset:         8
        .size:           4
        .value_kind:     by_value
      - .offset:         16
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         20
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         24
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         28
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         30
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         32
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         34
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         36
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         38
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         64
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         72
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         80
        .size:           2
        .value_kind:     hidden_grid_dims
    .gfx1250_revision: B0
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           _ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         _ZN12_GLOBAL__N_117throughput_kernelILi2EEEvPfi.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     51
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .offset:         8
        .size:           4
        .value_kind:     by_value
      - .offset:         16
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         20
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         24
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         28
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         30
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         32
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         34
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         36
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         38
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         64
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         72
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         80
        .size:           2
        .value_kind:     hidden_grid_dims
    .gfx1250_revision: B0
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           _ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         _ZN12_GLOBAL__N_117throughput_kernelILi4EEEvPfi.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     86
    .vgpr_spill_count: 0
    .wavefront_size: 64
  - .agpr_count:     0
    .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .offset:         8
        .size:           4
        .value_kind:     by_value
      - .offset:         16
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         20
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         24
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         28
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         30
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         32
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         34
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         36
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         38
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         56
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         64
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         72
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         80
        .size:           2
        .value_kind:     hidden_grid_dims
    .gfx1250_revision: B0
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 272
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 512
    .name:           _ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi
    .private_segment_fixed_size: 0
    .sgpr_count:     12
    .sgpr_spill_count: 0
    .symbol:         _ZN12_GLOBAL__N_117throughput_kernelILi8EEEvPfi.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     150
    .vgpr_spill_count: 0
    .wavefront_size: 64
amdhsa.target:   amdgcn-amd-amdhsa--gfx950
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
