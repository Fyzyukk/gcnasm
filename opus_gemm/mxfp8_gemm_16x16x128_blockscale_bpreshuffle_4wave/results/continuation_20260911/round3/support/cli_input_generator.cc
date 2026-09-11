#include <hip/hip_fp8.h>
#include <cstddef>
#include <cstdint>

static std::uint64_t mix_bits(std::uint64_t x) {
    x += UINT64_C(0x9e3779b97f4a7c15);
    x = (x ^ (x >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
    x = (x ^ (x >> 27)) * UINT64_C(0x94d049bb133111eb);
    return x ^ (x >> 31);
}
extern "C" void make_fp8(void* dst, std::size_t count, std::uint64_t seed) {
    auto* ptr = reinterpret_cast<__hip_fp8_e4m3*>(dst);
    #pragma omp parallel for
    for (std::size_t i = 0; i < count; ++i) {
        const float unit = static_cast<float>(mix_bits(seed + i) >> 40) * 0x1p-24f;
        ptr[i] = static_cast<__hip_fp8_e4m3>(2.0f * unit - 1.0f);
    }
}
extern "C" void make_scale(void* dst, std::size_t count, std::uint64_t seed) {
    auto* ptr = reinterpret_cast<unsigned char*>(dst);
    #pragma omp parallel for
    for (std::size_t i = 0; i < count; ++i)
        ptr[i] = static_cast<unsigned char>(124 + mix_bits(seed + i) % 7);
}
