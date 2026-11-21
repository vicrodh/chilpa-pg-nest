#pragma once
#include <QQuickItem>
#include <QMatrix4x4>

// One rigid box transform, shared by its six faces. No render loop or engine.
class CasePose : public QQuickTransform {
    Q_OBJECT
    Q_PROPERTY(qreal faceWidth MEMBER faceWidth NOTIFY changed)
    Q_PROPERTY(qreal faceHeight MEMBER faceHeight NOTIFY changed)
    Q_PROPERTY(qreal depth MEMBER depth NOTIFY changed)
    Q_PROPERTY(qreal span MEMBER span NOTIFY changed)
    Q_PROPERTY(qreal reveal MEMBER reveal NOTIFY changed)
    Q_PROPERTY(qreal turn MEMBER turn NOTIFY changed)
public:
    explicit CasePose(QObject *parent = nullptr);
    void applyTo(QMatrix4x4 *matrix) const override;
signals:
    void changed();
private:
    qreal faceWidth = 300, faceHeight = 290, depth = 20, span = 300, reveal = 1, turn = 0;
};
