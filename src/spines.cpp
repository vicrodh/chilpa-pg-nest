#include "spines.h"
#include <algorithm>
#include <QBuffer>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImageIOHandler>
#include <QImageReader>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStandardPaths>
#include <QTransform>
#include <QUrlQuery>
#include <QUuid>

namespace {
qint64 lastSearch = 0;
bool allowed(const QUrl &url) {
    const QString host = url.host().toLower();
    return url.toString().size() <= 4096 && url.scheme() == "https" && url.userInfo().isEmpty() && (url.port() == -1 || url.port() == 443)
        && (host == "musicbrainz.org" || host == "coverartarchive.org" || host == "archive.org" || host.endsWith(".archive.org"));
}
QString quoted(QString text) { text.replace('\\', "\\\\"); text.replace('"', "\\\""); return '"' + text.left(250) + '"'; }
}
SpineLibrary::SpineLibrary(QObject *parent) : QObject(parent) {}
SpineLibrary::~SpineLibrary() { cancel(); }
void SpineLibrary::cancel() { ++generation; if (reply) { reply->disconnect(this); reply->abort(); reply->deleteLater(); reply = nullptr; } m_busy = false; emit changed(); }
void SpineLibrary::fail(const QString &message) { m_error = message; m_busy = false; emit changed(); }
void SpineLibrary::search(const QString &artist, const QString &album) {
    cancel(); m_error.clear(); m_releases.clear(); m_candidates.clear();
    const auto now = QDateTime::currentMSecsSinceEpoch();
    if (now - lastSearch < 1100) return fail(QStringLiteral("Wait a second before searching again."));
    lastSearch = now;
    QUrl url("https://musicbrainz.org/ws/2/release/");
    QUrlQuery query; query.addQueryItem("query", "artist:" + quoted(artist) + " AND release:" + quoted(album));
    query.addQueryItem("fmt", "json"); query.addQueryItem("limit", "16"); url.setQuery(query);
    get(url, "search");
}
void SpineLibrary::images(const QString &release) {
    cancel(); m_error.clear(); m_candidates.clear();
    static const QRegularExpression uuid("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");
    if (!uuid.match(release).hasMatch()) return fail(QStringLiteral("The edition has no valid identifier."));
    get(QUrl("https://coverartarchive.org/release/" + release), "images");
}
bool SpineLibrary::previewLocal(const QUrl &source) {
    m_error.clear();
    QImageReader reader(source.toLocalFile());
    const QSize size = reader.size();
    const qint64 pixels = qint64(size.width()) * size.height();
    if (!source.isLocalFile() || QFileInfo(source.toLocalFile()).size() > 12 * 1024 * 1024 || !size.isValid()
        || pixels > 40000000 || (pixels > 4000000 && !reader.supportsOption(QImageIOHandler::ScaledSize))) {
        fail(QStringLiteral("The image exceeds the preview limits."));
        return false;
    }
    emit changed();
    return true;
}
void SpineLibrary::save(const QUrl &source, const QRectF &crop) {
    cancel(); m_error.clear(); selectedCrop = crop;
    if (crop.x() < 0 || crop.y() < 0 || crop.width() <= 0 || crop.height() <= 0 || crop.right() > 1.00001 || crop.bottom() > 1.00001)
        return fail(QStringLiteral("The crop must stay inside the image."));
    if (source.isLocalFile()) {
        QFile file(source.toLocalFile());
        if (!file.open(QIODevice::ReadOnly) || file.size() > 12 * 1024 * 1024) return fail(QStringLiteral("Could not open the image; the limit is 12 MiB."));
        store(file.readAll());
    } else get(source, "asset");
}
void SpineLibrary::get(const QUrl &url, const QString &kind, int redirects) {
    if (!allowed(url) || redirects > 5) return fail(QStringLiteral("The image address is outside the allowed archive."));
    m_busy = true; emit changed();
    const auto ticket = generation;
    QNetworkRequest request(url);
    request.setRawHeader("User-Agent", "ChilpaNest/0.4 (https://github.com/vicrodh/chilpa)");
    request.setRawHeader("Accept", kind == "asset" ? "image/*" : "application/json");
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::ManualRedirectPolicy);
    request.setTransferTimeout(15000);
    auto *current = network.get(request); reply = current;
    auto data = QSharedPointer<QByteArray>::create();
    const qsizetype limit = kind == "asset" ? 12 * 1024 * 1024 : 1024 * 1024;
    connect(current, &QNetworkReply::readyRead, this, [this, current, data, limit] {
        if (data->size() + current->bytesAvailable() > limit) { current->abort(); fail(QStringLiteral("The response exceeded the size limit.")); }
        else data->append(current->readAll());
    });
    connect(current, &QNetworkReply::finished, this, [this, current, data, limit, ticket, kind, redirects] {
        current->deleteLater(); if (reply == current) reply = nullptr;
        if (ticket != generation) return;
        const QUrl redirect = current->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
        if (!redirect.isEmpty()) return get(current->url().resolved(redirect), kind, redirects + 1);
        if (current->error() != QNetworkReply::NoError) return fail(current->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() == 404
            ? QStringLiteral("This edition has no images in the cover archive.") : QStringLiteral("Could not query the archive. Try again later."));
        data->append(current->readAll());
        if (data->size() > limit) return fail(QStringLiteral("The response exceeded the size limit."));
        if (kind == "asset") return store(*data);
        QJsonParseError parseError; const auto doc = QJsonDocument::fromJson(*data, &parseError);
        if (parseError.error != QJsonParseError::NoError || !doc.isObject()) return fail(QStringLiteral("The archive returned an unreadable response."));
        if (kind == "search") {
            for (const auto &value : doc.object().value("releases").toArray()) {
                if (m_releases.size() >= 16) break;
                const auto item = value.toObject(); QStringList formats;
                for (const auto &medium : item.value("media").toArray()) formats << medium.toObject().value("format").toString();
                const bool cd = std::any_of(formats.cbegin(), formats.cend(), [](const QString &format) { return format.contains("CD"); });
                m_releases << QVariantMap{{"id",item.value("id").toString()},{"title",item.value("title").toString().left(250)},
                    {"cd",cd},{"date",item.value("date").toString().left(32)},{"score",item.value("score").toInt()},
                    {"detail",QStringList{item.value("date").toString(),item.value("country").toString(),formats.join(" / "),item.value("disambiguation").toString()}.join(" · ").left(300)}};
            }
            if (m_releases.isEmpty()) m_error = QStringLiteral("No editions found. You can import a local scan.");
        } else {
            for (const auto &value : doc.object().value("images").toArray()) {
                if (m_candidates.size() >= 32) break;
                const auto image = value.toObject(); QStringList types;
                for (const auto &type : image.value("types").toArray()) types << type.toString();
                if ((!types.contains("Spine") && !types.contains("Back")) || image.value("approved").toBool() == false) continue;
                QUrl url(image.value("image").toString()); if (url.scheme() == "http") url.setScheme("https");
                QUrl thumb(image.value("thumbnails").toObject().value("large").toString()); if (thumb.scheme() == "http") thumb.setScheme("https");
                if (!allowed(url)) continue;
                m_candidates << QVariantMap{{"url",url.toString()},{"preview",allowed(thumb) ? thumb.toString() : url.toString()},
                    {"label",types.contains("Spine") ? types.join(" + ") : QStringLiteral("Back scan · check whether it includes the spine")},{"spine",types.contains("Spine")},{"combined",types.contains("Back") || types.contains("Tray")},{"comment",image.value("comment").toString().left(240)}};
            }
            if (m_candidates.isEmpty()) m_error = QStringLiteral("This edition has no scan tagged as a spine. Keeping the solid color.");
        }
        m_busy = false; emit changed();
    });
}
void SpineLibrary::store(const QByteArray &bytes) {
    QBuffer buffer; buffer.setData(bytes); buffer.open(QIODevice::ReadOnly);
    QImageReader reader(&buffer); reader.setAutoTransform(true);
    const QSize original = reader.size(); const qint64 pixels = qint64(original.width()) * original.height();
    if (!original.isValid() || pixels > 40000000 || (pixels > 4000000 && !reader.supportsOption(QImageIOHandler::ScaledSize)))
        return fail(QStringLiteral("The image is too large to process here."));
    if (original.width() > 2048 || original.height() > 2048) reader.setScaledSize(original.scaled(2048, 2048, Qt::KeepAspectRatio));
    QImage image = reader.read();
    if (image.isNull()) return fail(QStringLiteral("Could not decode the image."));
    QRect rect(qRound(selectedCrop.x()*image.width()),qRound(selectedCrop.y()*image.height()),qMax(1,qRound(selectedCrop.width()*image.width())),qMax(1,qRound(selectedCrop.height()*image.height())));
    image = image.copy(rect.intersected(image.rect()));
    if (image.width() > image.height()) image = image.transformed(QTransform().rotate(90));
    image = image.scaled(64, 1024, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    QDir cache(QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/chilpa-nest/spines");
    if (!cache.mkpath(".")) return fail(QStringLiteral("Could not create the spine cache."));
    qint64 total = 0; const auto existing = cache.entryInfoList({"*.png"},QDir::Files,QDir::Time | QDir::Reversed);
    for (const auto &file : existing) total += file.size();
    for (const auto &file : existing) { if (total < 63 * 1024 * 1024) break; if (QFile::remove(file.absoluteFilePath())) total -= file.size(); }
    const QString path = cache.filePath(QUuid::createUuid().toString(QUuid::WithoutBraces) + ".png");
    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly) || !image.save(&file,"PNG") || !file.commit()) return fail(QStringLiteral("Could not save the spine."));
    m_busy = false; emit changed(); emit saved(QUrl::fromLocalFile(path));
}
