#include "case_pose.h"
#include <cmath>

CasePose::CasePose(QObject *parent) : QQuickTransform(parent) {
    connect(this, &CasePose::changed, this, [this] { update(); });
}
void CasePose::applyTo(QMatrix4x4 *matrix) const {
    const qreal lift = std::sin(qBound(qreal(0), reveal, qreal(1)) * 3.141592653589793);
    QMatrix4x4 pose;
    pose.translate(span / 2, faceHeight / 2);
    QMatrix4x4 camera;
    camera(3, 2) = -1.0f / qMax(qreal(800), faceHeight * 4);
    pose *= camera;
    pose.translate(0, -faceHeight * .035 * lift, faceHeight * .17 * lift);
    pose.rotate(-90 * (1 - reveal) + turn, 0, 1, 0);
    pose.translate(-faceWidth / 2, -faceHeight / 2, 0);
    // Keep perspective in X/Y/W. Qt Quick reserves Z for its stacking order,
    // so project the assembled box onto the same plane as the shelf.
    for (int column = 0; column < 4; ++column)
        pose(2, column) = 0;
    *matrix *= pose;
}
