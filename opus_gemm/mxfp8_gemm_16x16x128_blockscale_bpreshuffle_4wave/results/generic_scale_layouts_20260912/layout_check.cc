#include "traits.hpp"
#include "tmpl_generic.hpp"

using T = FourWaveTraits<false>;
using namespace blockscale_generic;

template<int Vec, class Layout>
__device__ constexpr int address(const Layout& layout) {
    return opus::layout_to_offsets<Vec>(layout)[0];
}

__device__ constexpr bool check_sfa_panel() {
    int panel[T::SFA_PANEL_BYTES] = {};
    bool written[T::SFA_PANEL_BYTES] = {};
    constexpr int stride_m = 768;
    for (int tid = 0; tid < 256; ++tid) {
        for (int pass = 0; pass < 4; ++pass) {
            const int k = tid / 16 + pass * 16;
            for (int word = 0; word < 4; ++word) {
                const int dst = address<4>(make_layout_ssfa_scale<T>(tid, pass, word));
                if (dst < 0 || dst + 4 > T::SFA_PANEL_BYTES || dst % 4) return false;
                for (int repeat = 0; repeat < 4; ++repeat) {
                    if (written[dst + repeat]) return false;
                    written[dst + repeat] = true;
                    // The unchanged quad transpose exchanges the producer's
                    // M-repeat index with its row-within-word index.
                    const int source_tid = (tid / 4) * 4 + repeat;
                    const int source = address<16>(make_layout_gsfa_scale<T>(source_tid, k, stride_m, 64));
                    panel[dst + repeat] = source + word * 4 + tid % 4;
                }
            }
        }
    }
    for (bool covered : written) if (!covered) return false;
    for (int k = 0; k < 64; ++k) {
        for (int wave = 0; wave < 4; ++wave) {
            const int wave_m = wave % 2;
            for (int lane = 0; lane < 64; ++lane) {
                const int pair = address<8>(make_layout_rsfa_scale<T, 8>(lane, wave_m, k));
                if (pair % 8) return false;
                for (int half = 0; half < 2; ++half) {
                    const int single = address<4>(make_layout_rsfa_scale<T, 4>(lane, wave_m, k, half));
                    if (single != pair + half * 4) return false;
                    for (int repeat = 0; repeat < 4; ++repeat) {
                        const int logical_m = half * 128 + repeat * 32 + wave_m * 16 + lane % 16;
                        if (panel[single + repeat] != k * stride_m + logical_m) return false;
                    }
                }
            }
        }
    }
    return true;
}

__device__ constexpr bool check_sfb_panel() {
    int panel[T::SFB_PANEL_BYTES] = {};
    bool written[T::SFB_PANEL_BYTES] = {};
    for (int half = 0; half < 2; ++half) {
        for (int lane = 0; lane < 64; ++lane) {
            const int src = address<1>(make_layout_gsfb_scale(lane, 64)) + half * 64;
            const int dst = address<4>(make_layout_ssfb_scale<T>(lane, half));
            if (dst < 0 || dst + 4 > T::SFB_PANEL_BYTES || dst % 4) return false;
            for (int byte = 0; byte < 4; ++byte) {
                if (written[dst + byte]) return false;
                written[dst + byte] = true;
                panel[dst + byte] = src;
            }
        }
    }
    for (bool covered : written) if (!covered) return false;
    for (int k = 0; k < 64; ++k) {
        const int pair = address<8>(make_layout_rsfb_scale<T, 8>(k));
        if (pair % 8) return false;
        for (int half = 0; half < 2; ++half) {
            const int single = address<4>(make_layout_rsfb_scale<T, 4>(k, half));
            if (single != pair + half * 4) return false;
            for (int byte = 0; byte < 4; ++byte) {
                if (panel[single + byte] != half * 64 + k) return false;
            }
        }
    }
    return true;
}

__device__ constexpr bool check_panel_boundaries() {
    constexpr int lengths[] = {1, 2, 3, 63, 64, 65, 127, 128, 129, 257};
    constexpr int stride_m = 768;
    for (int count : lengths) {
        for (int begin = 0; begin < count; begin += 64) {
            for (int tid = 0; tid < 256; ++tid) {
                for (int pass = 0; pass < 4; ++pass) {
                    const int requested = begin + tid / 16 + pass * 16;
                    const int valid = requested < count ? requested : count - 1;
                    const int actual = address<16>(make_layout_gsfa_scale<T>(tid, valid, stride_m, count));
                    const int logical_m = ((tid / 8) % 2) * 128 + (tid % 4) * 32 + ((tid / 4) % 2) * 16;
                    if (actual != valid * stride_m + logical_m || actual + 16 > count * stride_m) return false;
                }
            }
            for (int lane = 0; lane < 64; ++lane) {
                const int requested = begin + lane;
                const int valid = requested < count ? requested : count - 1;
                if (address<1>(make_layout_gsfb_scale(valid, count)) != valid) return false;
            }
        }
        for (int k = 0; k < count; ++k) {
            if (address<8>(make_layout_rsfa_scale<T, 8>(0, 0, k)) != (k % 64) * 256) return false;
            if (address<8>(make_layout_rsfb_scale<T, 8>(k)) != (k % 64) * 8) return false;
        }
    }
    return true;
}

static_assert(check_sfa_panel(), "SFA global/transpose/LDS/MFMA mapping or coverage differs");
static_assert(check_sfb_panel(), "SFB global/replication/LDS/MFMA mapping or coverage differs");
static_assert(check_panel_boundaries(), "Runtime K bounds or panel wrap differs");
