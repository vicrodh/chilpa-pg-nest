#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QPointer>
#include <QRectF>
#include <QUrl>
#include <QVariantList>

class SpineLibrary : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY changed)
    Q_PROPERTY(QString error READ error NOTIFY changed)
    Q_PROPERTY(QVariantList releases READ releases NOTIFY changed)
    Q_PROPERTY(QVariantList candidates READ candidates NOTIFY changed)
public:
    explicit SpineLibrary(QObject *parent = nullptr);
    ~SpineLibrary() override;
    bool busy() const { return m_busy; }
    QString error() const { return m_error; }
    QVariantList releases() const { return m_releases; }
    QVariantList candidates() const { return m_candidates; }
    Q_INVOKABLE void search(const QString &artist, const QString &album);
    Q_INVOKABLE void images(const QString &release);
    Q_INVOKABLE void save(const QUrl &source, const QRectF &crop);
    Q_INVOKABLE bool previewLocal(const QUrl &source);
    Q_INVOKABLE void cancel();
signals:
    void changed();
    void saved(const QUrl &url);
private:
    void get(const QUrl &url, const QString &kind, int redirects = 0);
    void fail(const QString &message);
    void store(const QByteArray &bytes);
    QNetworkAccessManager network;
    QPointer<QNetworkReply> reply;
    QVariantList m_releases, m_candidates;
    QString m_error;
    bool m_busy = false;
    quint64 generation = 0;
    QRectF selectedCrop;
};
