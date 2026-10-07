// The composite's timewarp (vr::compositeEye): where a pixel of the eye image
// shown now lies in the picture rendered for an earlier pose of the eye.
// tools/timewarp_test checks it.
#pragma once

#include <string.h>

#include "xmath.h"

namespace vr {

// A field of view as the tangents of its angles (left and down negative).
struct FovTan {
    float left, right, up, down;
};

// The eye image's uv (0..1, y up) for an eye looking `to` with field of view
// `toFov` -> uv in the picture rendered for `from` with `fromFov`, as a
// homogeneous 3x3 matrix (column-major, for a mat3 uniform; divide by z).
// Rotation only, the scene taken as far away: the eye's millimetres of
// travel in between are not made up for.  False, with the identity, when
// the two are the same.
inline bool warpMatrix(const xm::Quat& from, const FovTan& fromFov, const xm::Quat& to, const FovTan& toFov, float out[9]) {
    static const float kIdentity[9] = {1, 0, 0, 0, 1, 0, 0, 0, 1};
    memcpy(out, kIdentity, sizeof(kIdentity));
    float fdx = fromFov.right - fromFov.left, fdy = fromFov.up - fromFov.down;
    bool same = from.x == to.x && from.y == to.y && from.z == to.z && from.w == to.w && fromFov.left == toFov.left &&
                fromFov.right == toFov.right && fromFov.up == toFov.up && fromFov.down == toFov.down;
    if (same || fdx <= 0.0f || fdy <= 0.0f) {
        return false;
    }
    // uv -> a direction in `to`'s eye space, (x, y, -1).
    const float a[3][3] = {{toFov.right - toFov.left, 0.0f, toFov.left}, {0.0f, toFov.up - toFov.down, toFov.down}, {0.0f, 0.0f, -1.0f}};
    // `to`'s eye space -> `from`'s.
    float q[3][3];
    for (int j = 0; j < 3; j++) {
        xm::Vec3 v = xm::rotate(xm::conj(from), xm::rotate(to, {j == 0 ? 1.0f : 0.0f, j == 1 ? 1.0f : 0.0f, j == 2 ? 1.0f : 0.0f}));
        q[0][j] = v.x;
        q[1][j] = v.y;
        q[2][j] = v.z;
    }
    // A direction in `from`'s eye space -> its uv, homogeneous.
    const float b[3][3] = {{1.0f / fdx, 0.0f, fromFov.left / fdx}, {0.0f, 1.0f / fdy, fromFov.down / fdy}, {0.0f, 0.0f, -1.0f}};
    float qa[3][3];
    for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
            qa[r][c] = q[r][0] * a[0][c] + q[r][1] * a[1][c] + q[r][2] * a[2][c];
        }
    }
    for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
            out[c * 3 + r] = b[r][0] * qa[0][c] + b[r][1] * qa[1][c] + b[r][2] * qa[2][c];
        }
    }
    return true;
}

}  // namespace vr
