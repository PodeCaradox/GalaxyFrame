// Host-side check for the composite's timewarp (platform/src/xr/timewarp.h):
//   c++ -O1 -o timewarp_test tools/timewarp_test/timewarp_test.cpp && ./timewarp_test
// For eyes turned against each other, every pixel of the eye image shown is
// sent to the place in the rendered picture where the same direction in the
// room was drawn; the same eye gives the identity.
#include "../../platform/src/xr/timewarp.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

namespace {

xm::Quat axisAngle(xm::Vec3 axis, float deg) {
    float h = deg * 0.5f * 3.14159265f / 180.0f;
    return {axis.x * sinf(h), axis.y * sinf(h), axis.z * sinf(h), cosf(h)};
}

xm::Quat mul(xm::Quat a, xm::Quat b) {
    return {a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y, a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
            a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w, a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z};
}

// Where the room direction `world` is drawn in the picture of an eye looking
// `q` with field of view `f` (uv, y up); false when it is behind the eye.
bool project(const xm::Quat& q, const vr::FovTan& f, xm::Vec3 world, float* u, float* v) {
    xm::Vec3 e = xm::rotate(xm::conj(q), world);
    if (e.z >= 0.0f) return false;
    *u = (e.x / -e.z - f.left) / (f.right - f.left);
    *v = (e.y / -e.z - f.down) / (f.up - f.down);
    return true;
}

int failures = 0;

void check(const char* name, const xm::Quat& from, const vr::FovTan& ff, const xm::Quat& to, const vr::FovTan& tf) {
    float m[9];
    vr::warpMatrix(from, ff, to, tf, m);
    float worst = 0.0f;
    for (int iy = 0; iy <= 8; iy++) {
        for (int ix = 0; ix <= 8; ix++) {
            float u = ix / 8.0f, v = iy / 8.0f;
            // The room direction of the shown pixel...
            xm::Vec3 dir = xm::rotate(to, {tf.left + u * (tf.right - tf.left), tf.down + v * (tf.up - tf.down), -1.0f});
            float eu, ev;
            if (!project(from, ff, dir, &eu, &ev)) continue;
            // ...against the matrix's answer.
            float h0 = m[0] * u + m[3] * v + m[6], h1 = m[1] * u + m[4] * v + m[7], h2 = m[2] * u + m[5] * v + m[8];
            float err = fmaxf(fabsf(h0 / h2 - eu), fabsf(h1 / h2 - ev));
            worst = fmaxf(worst, err);
        }
    }
    bool ok = worst < 1e-4f;
    printf("%-34s worst uv error %.2e %s\n", name, worst, ok ? "ok" : "FAILED");
    failures += !ok;
}

}  // namespace

int main() {
    // A Quest 3 / Steam Frame like eye: wider outwards and downwards.
    const vr::FovTan fov{tanf(-0.94f), tanf(0.80f), tanf(0.84f), tanf(-0.98f)};
    const xm::Quat head = mul(axisAngle({0, 1, 0}, 30.0f), axisAngle({1, 0, 0}, -20.0f));
    float m[9];
    if (vr::warpMatrix(head, fov, head, fov, m) || m[0] != 1.0f || m[4] != 1.0f || m[8] != 1.0f || m[1] != 0.0f) {
        printf("same eye: not the identity FAILED\n");
        failures++;
    } else {
        printf("%-34s identity ok\n", "same eye");
    }
    check("yaw 2 deg (a refresh at 240 deg/s)", head, fov, mul(axisAngle({0, 1, 0}, 2.0f), head), fov);
    check("yaw -4, pitch 3", head, fov, mul(axisAngle({1, 0, 0}, 3.0f), mul(axisAngle({0, 1, 0}, -4.0f), head)), fov);
    check("roll 5", head, fov, mul(head, axisAngle({0, 0, 1}, 5.0f)), fov);
    vr::FovTan wider{tanf(-1.0f), tanf(0.9f), tanf(0.9f), tanf(-1.0f)};
    check("yaw 3, another field of view", head, fov, mul(axisAngle({0, 1, 0}, 3.0f), head), wider);
    return failures ? 1 : 0;
}
