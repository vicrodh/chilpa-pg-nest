#pragma once
#include <QColor>
#include <QObject>
#include <QUrl>
#include <QVariantList>

class SpinePalette : public QObject {
    Q_OBJECT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY changed)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY changed)
    Q_PROPERTY(QColor background READ background NOTIFY changed)
    Q_PROPERTY(QColor foreground READ foreground NOTIFY changed)
    Q_PROPERTY(double contrast READ contrast NOTIFY changed)
    Q_PROPERTY(bool ready READ ready NOTIFY changed)
public:
    explicit SpinePalette(QObject *parent = nullptr);
    ~SpinePalette() override;
    QUrl source() const { return m_source; }
    bool active() const { return m_active; }
    QColor background() const { return m_background; }
    QColor foreground() const;
    double contrast() const;
    bool ready() const { return m_ready; }
    void setSource(const QUrl &value);
    void setActive(bool value);
signals:
    void changed();
private:
    void request();
    QUrl m_source;
    bool m_active = false;
    bool m_ready = false;
    QColor m_background = QColor("#35383b");
};

// One metadata/color window per shelf, without extra album delegates or images.
class SpinePalettePreloader : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList sources READ sources WRITE setSources NOTIFY changed)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY changed)
    Q_PROPERTY(int held READ held NOTIFY changed)
public:
    explicit SpinePalettePreloader(QObject *parent=nullptr):QObject(parent){}
    ~SpinePalettePreloader() override;
    QVariantList sources() const;
    void setSources(const QVariantList &sources);
    bool active() const { return m_active; }
    void setActive(bool active);
    int held() const { return m_active ? m_sources.size():0; }
signals:
    void changed();
private:
    QList<QUrl> m_sources;
    bool m_active=false;
};
