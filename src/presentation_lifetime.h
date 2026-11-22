#pragma once
#include <QObject>
#include <QPointer>
#include <QQuickItem>

// Keep the shared display mount out of a retiring page's visual subtree.
// Its QObject owner remains the host; C++ reparenting preserves the host's
// QML parent binding, which still moves it into the active display stage.
class PresentationLifetime : public QObject {
    Q_OBJECT
    Q_PROPERTY(QQuickItem *mount READ mount WRITE setMount NOTIFY mountChanged)
public:
    explicit PresentationLifetime(QObject *parent = nullptr) : QObject(parent) {}
    QQuickItem *mount() const { return mount_; }
    void setMount(QQuickItem *item) {
        if (mount_ == item) return;
        disconnect(parentChanged_);
        mount_ = item;
        if (mount_)
            parentChanged_ = connect(mount_, &QQuickItem::parentChanged, this,
                                     [this] { protectOwner(); });
        protectOwner();
        emit mountChanged();
    }
signals:
    void mountChanged();
private:
    void protectOwner() {
        // A null visual parent is teardown/detachment, not a retiring page.
        // Never attach a child back to an owner that is being destroyed.
        if (!mount_ || !mount_->parentItem() || mount_->objectName() != QStringLiteral("pluginDisplayLoader")
                || !mount_->inherits("QQuickLoader")) return;
        auto *owner = qobject_cast<QQuickItem *>(mount_->parent());
        if (!owner || owner == mount_) return;
        for (auto *ancestor = mount_->parentItem(); ancestor; ancestor = ancestor->parentItem())
            if (ancestor == owner) return;
        mount_->setParentItem(owner);
    }
    QPointer<QQuickItem> mount_;
    QMetaObject::Connection parentChanged_;
};
