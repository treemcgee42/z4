#include <metal_stdlib>
using namespace metal;

struct vs_params_t {
       float4x4 mvp;
};

struct vs_in {
       float4 position [[attribute(0)]];
       float4 color [[attribute(1)]];
};
struct vs_out {
       float4 position [[position]];
       float4 color;
};

vertex vs_out _main(vs_in inp [[stage_in]], constant vs_params_t& params [[buffer(0)]]) {
       vs_out outp;
       outp.position = params.mvp * inp.position;
       outp.color = inp.color;
       return outp;
}