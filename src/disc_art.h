#pragma once
#include <QQuickPaintedItem>
#include <QImage>
#include <QColor>
#include <QUrl>

// One 256-square texture, repainted only after its source changes.
class DiscArt : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY changed)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY changed)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY changed)
public:
    explicit DiscArt(QQuickItem *parent = nullptr);
    QUrl source() const { return m_source; }
    bool active() const { return m_active; }
    void setSource(const QUrl &source);
    void setActive(bool active);
    QColor color() const { return m_color; }
    void setColor(const QColor &value) { if (m_color != value) { m_color=value; emit changed(); update(); } }
    void paint(QPainter *painter) override;
signals:
    void changed();
private:
    void request();
    QUrl m_source;
    QImage m_image;
    QColor m_color = QColor("#35383b");
    bool m_active = false;
    bool m_busy = false;
};
