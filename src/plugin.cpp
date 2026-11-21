#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <cstdio>
#include <iostream>
#include <array>

// The worker negotiates lifecycle only. The approved QML uses the host facade.
int main(int argc, char **argv) {
    QCoreApplication application(argc, argv);
    std::array<char, 16386> line{};
    while (std::cin.getline(line.data(), line.size())) {
        if (std::cin.gcount() > 16385) return 2;
        QJsonParseError parseError;
        const auto document = QJsonDocument::fromJson(QByteArray(line.data()), &parseError);
        if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
            const QJsonObject error{{"jsonrpc", "2.0"}, {"id", QJsonValue::Null},
                {"error", QJsonObject{{"code", -32700}, {"message", "Invalid JSON request"}}}};
            std::cout << QJsonDocument(error).toJson(QJsonDocument::Compact).constData() << std::endl;
            continue;
        }
        const auto input = document.object();
        if (!input.contains("id")) continue;
        QJsonObject reply{{"jsonrpc", "2.0"}, {"id", input.value("id")}};
        if (input.value("jsonrpc") != "2.0" || !input.value("method").isString()) {
            reply.insert("error", QJsonObject{{"code", -32600}, {"message", "Invalid request"}});
        } else if (input.value("method") == "initialize") {
            reply.insert("result", QJsonObject{{"protocol", 1}, {"capabilities", QJsonObject{}}});
        } else {
            reply.insert("error", QJsonObject{{"code", -32601}, {"message", "Method not found"}});
        }
        std::cout << QJsonDocument(reply).toJson(QJsonDocument::Compact).constData() << std::endl;
        if (!std::cout) return 0;
    }
    return std::cin.eof() ? 0 : 2;
}
