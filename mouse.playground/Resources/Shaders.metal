
#include <metal_stdlib>

using namespace metal;

kernel void compute(texture2d<float, access::write> output [[texture(0)]],
                    constant float2 &mouse [[buffer(1)]],
                    device float2 *out [[buffer(2)]],
                    uint2 gid [[thread_position_in_grid]])
{
    out[0] = mouse[0];
    out[1] = mouse[1];
    output.write(float4(0, 0.5, 0.5, 1), gid);
}
