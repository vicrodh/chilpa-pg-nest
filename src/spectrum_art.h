#pragma once
#include <QQuickItem>
#include <QVariantList>
#include <QTimer>
#include <array>

class SpectrumBitmap;
class QPainter;

// One geometry node or bounded bitmap; animation frames stay in native code.
class SpectrumArt : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(QVariantList levels READ levels WRITE setLevels NOTIFY changed)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool accelerated READ accelerated WRITE setAccelerated NOTIFY acceleratedChanged)
public:
    explicit SpectrumArt(QQuickItem *parent=nullptr);
    QVariantList levels() const;
    void setLevels(const QVariantList &levels);
    bool active() const {return m_active;}
    bool accelerated() const {return m_accelerated;}
    void setActive(bool active);
    void setAccelerated(bool accelerated);
signals:
    void changed();
    void activeChanged();
    void acceleratedChanged();
    void frameChanged();
protected:
    QSGNode *updatePaintNode(QSGNode *node,UpdatePaintNodeData *) override;
    void geometryChange(const QRectF &next,const QRectF &previous) override;
private:
    friend class SpectrumBitmap;
    void paintBitmap(QPainter *painter) const;
    void advance();
    void redraw();
    std::array<int,16> m_input{},m_values{},m_peaks{},m_holds{};
    QTimer m_clock;
    SpectrumBitmap *m_bitmap;
    bool m_active=false;
    bool m_accelerated=false;
};
