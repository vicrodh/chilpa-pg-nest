#include "palette.h"
#include <QCoreApplication>
#include <QFileInfo>
#include <QHash>
#include <QImageReader>
#include <QImageIOHandler>
#include <QPointer>
#include <QQueue>
#include <QSet>
#include <QThreadPool>
#include <array>
#include <algorithm>
#include <cmath>
#include <atomic>
#include <utility>

namespace {
double luminance(const QColor &c) {
    auto linear = [](double v) { return v <= .04045 ? v / 12.92 : std::pow((v + .055) / 1.055, 2.4); };
    return .2126 * linear(c.redF()) + .7152 * linear(c.greenF()) + .0722 * linear(c.blueF());
}
QColor dominant(const QUrl &url) {
    if (!url.isLocalFile()) return QColor("#35383b");
    const QString file = url.toLocalFile();
    if (QFileInfo(file).size() > 16 * 1024 * 1024) return QColor("#35383b");
    QImageReader reader(file);
    reader.setAutoTransform(true);
    const QSize size = reader.size();
    const qint64 pixels = qint64(size.width()) * size.height();
    if (!size.isValid() || pixels > 40000000 ||
        (pixels > 4000000 && !reader.supportsOption(QImageIOHandler::ScaledSize))) return QColor("#35383b");
    reader.setScaledSize(size.scaled(32, 32, Qt::KeepAspectRatio));
    const QImage image = reader.read();
    if (image.isNull()) return QColor("#35383b");
    struct Bin { int count = 0, r = 0, g = 0, b = 0; };
    std::array<Bin, 4096> bins{};
    for (int y = 0; y < image.height(); ++y) for (int x = 0; x < image.width(); ++x) {
        const QColor c = image.pixelColor(x, y);
        if (c.alpha() < 192) continue;
        auto &bin = bins[(c.red() >> 4) * 256 + (c.green() >> 4) * 16 + (c.blue() >> 4)];
        ++bin.count; bin.r += c.red(); bin.g += c.green(); bin.b += c.blue();
    }
    const Bin *best = &bins[0];
    for (const auto &bin : bins) if (bin.count > best->count) best = &bin;
    return best->count ? QColor(best->r / best->count, best->g / best->count, best->b / best->count) : QColor("#35383b");
}
}

class PaletteCache : public QObject {
    Q_OBJECT
public:
    explicit PaletteCache(QObject *parent) : QObject(parent) { pool.setMaxThreadCount(2); pool.setExpiryTimeout(1000); }
    ~PaletteCache() override { pool.waitForDone(); }
    static PaletteCache *instance() { static QPointer<PaletteCache> cache; if (!cache) cache = new PaletteCache(qApp); return cache; }
    bool lookup(const QUrl &url,QColor &color) const {
        const auto found=colors.constFind(url.toString());
        if(found==colors.cend())return false;
        color=found.value();return true;
    }
    void release(const QUrl &url, QObject *owner) {
        const QString key = url.toString();
        watchers[key].remove(owner);
        if (watchers[key].isEmpty()) { watchers.remove(key); if (tickets.contains(key)) tickets[key]->store(false); }
    }
    void request(const QUrl &url, QObject *owner,bool preload=false) {
        const QString key = url.toString();
        if (colors.contains(key)) { order.removeAll(key); order.enqueue(key); if(!preload)emit ready(key, colors.value(key)); return; }
        if (pending.size() >= 512 && !pending.contains(key)) return;
        watchers[key].insert(owner);
        if (pending.contains(key)) { tickets[key]->store(true); return; }
        pending.insert(key);
        auto active = QSharedPointer<std::atomic<bool>>::create(true); tickets.insert(key, active);
        QPointer<PaletteCache> guard(this);
        pool.start([guard, url, key, active] {
            const QColor color = active->load() ? dominant(url) : QColor();
            QMetaObject::invokeMethod(qApp, [guard, key, url, color] {
                if (!guard) return;
                guard->pending.remove(key);
                guard->tickets.remove(key);
                const auto waiting = guard->watchers.take(key);
                if (waiting.isEmpty()) return;
                if (!color.isValid()) { for (auto *owner : waiting) guard->request(url, owner); return; }
                if (guard->colors.size() >= 512) guard->colors.remove(guard->order.dequeue());
                guard->colors.insert(key, color); guard->order.enqueue(key);
                emit guard->ready(key, color);
            }, Qt::QueuedConnection);
        },preload ? -1:0);
    }
signals:
    void ready(const QString &key, const QColor &color);
private:
    QThreadPool pool;
    QHash<QString, QColor> colors;
    QQueue<QString> order;
    QSet<QString> pending;
    QHash<QString, QSet<QObject *>> watchers;
    QHash<QString, QSharedPointer<std::atomic<bool>>> tickets;
};

SpinePalette::SpinePalette(QObject *parent) : QObject(parent) {
    connect(PaletteCache::instance(), &PaletteCache::ready, this, [this](const QString &key, const QColor &color) {
        if (m_active && key == m_source.toString() && (!m_ready || m_background != color)) { m_background = color; m_ready=true; emit changed(); }
    });
}
SpinePalette::~SpinePalette() { PaletteCache::instance()->release(m_source, this); }
QColor SpinePalette::foreground() const { return (luminance(m_background) + .05) / .05 >= 1.05 / (luminance(m_background) + .05) ? QColor(Qt::black) : QColor(Qt::white); }
double SpinePalette::contrast() const { const double l = luminance(m_background); return qMax((l + .05) / .05, 1.05 / (l + .05)); }
void SpinePalette::setSource(const QUrl &value) {
    if(value==m_source)return;
    auto *cache=PaletteCache::instance();cache->release(m_source,this);m_source=value;
    m_ready=cache->lookup(m_source,m_background);
    if(!m_ready)m_background=QColor("#35383b");
    emit changed();request();
}
void SpinePalette::setActive(bool value) { if (value == m_active) return; if (!value) PaletteCache::instance()->release(m_source, this); m_active = value; emit changed(); request(); }
void SpinePalette::request() { if (m_active && !m_source.isEmpty()) PaletteCache::instance()->request(m_source, this); }

SpinePalettePreloader::~SpinePalettePreloader(){if(m_active)for(const auto &url:m_sources)PaletteCache::instance()->release(url,this);}
QVariantList SpinePalettePreloader::sources() const {QVariantList out;out.reserve(m_sources.size());for(const auto &url:m_sources)out<<url;return out;}
void SpinePalettePreloader::setSources(const QVariantList &sources){
    QList<QUrl> next;
    for(int i=0;i<std::min<int>(sources.size(),64);++i){const QUrl url=sources[i].toUrl();if(url.isLocalFile() && url.toString().size()<=4096 && !next.contains(url))next.append(url);}
    if(next==m_sources)return;
    if(m_active){
        auto *cache=PaletteCache::instance();
        for(const auto &url:m_sources)if(!next.contains(url))cache->release(url,this);
        for(const auto &url:next)if(!m_sources.contains(url))cache->request(url,this,true);
    }
    m_sources=std::move(next);emit changed();
}
void SpinePalettePreloader::setActive(bool active){
    if(active==m_active)return;
    m_active=active;auto *cache=PaletteCache::instance();
    for(const auto &url:m_sources){if(active)cache->request(url,this,true);else cache->release(url,this);}
    emit changed();
}

#include "palette.moc"
