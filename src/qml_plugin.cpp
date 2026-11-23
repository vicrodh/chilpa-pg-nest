#include "palette.h"
#include "presentation_lifetime.h"
#include "spines.h"
#include "case_pose.h"
#include "disc_art.h"
#include "spectrum_art.h"
#include <QQmlExtensionPlugin>
#include <qqml.h>

class NestNativePlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface/1.0")
public:
    void registerTypes(const char *uri) override {
        qmlRegisterType<PresentationLifetime>(uri, 1, 0, "PresentationLifetime");
        qmlRegisterType<SpinePalette>(uri, 1, 0, "SpinePalette");
        qmlRegisterType<SpinePalettePreloader>(uri, 1, 0, "SpinePalettePreloader");
        qmlRegisterType<SpineLibrary>(uri, 1, 0, "SpineLibrary");
        qmlRegisterType<CasePose>(uri, 1, 0, "CasePose");
        qmlRegisterType<DiscArt>(uri, 1, 0, "DiscArt");
        qmlRegisterType<SpectrumArt>(uri, 1, 0, "SpectrumArt");
    }
};
#include "qml_plugin.moc"
