#include "disc_art.h"
#include <QCoreApplication>
#include <QFileInfo>
#include <QImageReader>
#include <QImageIOHandler>
#include <QPainter>
#include <QPainterPath>
#include <QLinearGradient>
#include <QPointer>
#include <QThreadPool>
#include <atomic>

namespace {
std::atomic<int> pendingDecodes{0};
QThreadPool &artPool() {
    static auto *pool = [] { auto *p = new QThreadPool(qApp); p->setMaxThreadCount(1); p->setExpiryTimeout(1000); return p; }();
    return *pool;
}
QImage readArt(const QUrl &url) {
    if (!url.isLocalFile() || QFileInfo(url.toLocalFile()).size() > 16*1024*1024) return {};
    QImageReader reader(url.toLocalFile());
    reader.setAutoTransform(true);
    const QSize size = reader.size();
    const qint64 pixels = qint64(size.width())*size.height();
    if (!size.isValid() || pixels > 40000000 || (pixels > 4000000 && !reader.supportsOption(QImageIOHandler::ScaledSize))) return {};
    reader.setScaledSize(size.scaled(256,256,Qt::KeepAspectRatioByExpanding));
    return reader.read();
}
}
DiscArt::DiscArt(QQuickItem *parent) : QQuickPaintedItem(parent) { setAntialiasing(true); }
void DiscArt::setSource(const QUrl &value) {
    if (m_source == value) return;
    m_source = value; m_image = {}; update(); emit changed(); request();
}
void DiscArt::setActive(bool value) {
    if (m_active == value) return;
    m_active = value;
    if (!value) { m_image = {}; update(); }
    emit changed(); request();
}
void DiscArt::request() {
    if (!m_active || m_busy || m_source.isEmpty()) return;
    if (pendingDecodes.fetch_add(1) >= 4) { pendingDecodes.fetch_sub(1); return; }
    m_busy = true;
    const QUrl source = m_source;
    QPointer<DiscArt> guard(this);
    // At most one in-flight decode per disc. Changes coalesce until it returns.
    artPool().start([guard, source] {
        const QImage image = readArt(source);
        pendingDecodes.fetch_sub(1);
        QMetaObject::invokeMethod(qApp,[guard,source,image] {
            if (!guard) return;
            guard->m_busy = false;
            if (!guard->m_active) return;
            if (guard->m_source != source) { guard->request(); return; }
            guard->m_image = image; guard->update();
        },Qt::QueuedConnection);
    });
}
void DiscArt::paint(QPainter *painter) {
    painter->setRenderHint(QPainter::Antialiasing);
    const QRectF outer = boundingRect();
    const QPointF center(width()/2,height()/2);
    QPainterPath disc;
    disc.addEllipse(outer);
    disc.addEllipse(center,width()*.062,height()*.062);
    painter->setClipPath(disc);
    QLinearGradient metal(0,0,width(),height());
    metal.setColorAt(0,QColor("#c9ced3")); metal.setColorAt(.3,QColor("#e6e2d6"));
    metal.setColorAt(.55,QColor("#b9c4cc")); metal.setColorAt(.8,QColor("#d3ccd8")); metal.setColorAt(1,QColor("#c3cfc9"));
    painter->fillPath(disc,metal);
    QPainterPath annulus;
    annulus.addEllipse(QRectF(width()*.0125,height()*.0125,width()*.975,height()*.975));
    annulus.addEllipse(QRectF(width()*.3085,height()*.3085,width()*.383,height()*.383));
    painter->save();
    painter->setClipPath(annulus,Qt::IntersectClip);
    painter->fillRect(outer,m_color);
    if (!m_image.isNull()) {
        painter->setRenderHint(QPainter::SmoothPixmapTransform);
        const int side = qMin(m_image.width(),m_image.height());
        painter->drawImage(outer,m_image,QRectF((m_image.width()-side)/2,(m_image.height()-side)/2,side,side));
    }
    painter->restore();
    painter->setBrush(QColor(120,130,138,150)); painter->setPen(QColor("#b7c3c6"));
    painter->drawEllipse(center,width()*.1375,height()*.1375);
}
