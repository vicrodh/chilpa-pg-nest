import QtQuick
import QtTest
import "../qml"
import "../qml/NestTranslations.js" as Translations
TestCase {
    name:"NestLocales"
    NestStrings {id:strings}
    function test_all_host_languages_have_complete_messages(){
        const languages=["en","es","de","fr","pt","ja","nl","ru"]
        compare(Object.keys(Translations.catalogs).sort(),languages.slice().sort())
        const keys=Object.keys(Translations.catalogs.en).sort()
        for(const language of languages){
            compare(Object.keys(Translations.catalogs[language]).sort(),keys)
            for(const key of keys){verify(Translations.catalogs[language][key].length>0,language+":"+key);compare((Translations.catalogs[language][key].match(/\{\w+\}/g)||[]).sort(),(key.match(/\{\w+\}/g)||[]).sort())}
        }
    }
    function test_switching_language_retranslates_and_formats_status(){
        strings.language="en";compare(strings.t("Shelves"),"Shelves")
        strings.language="es";compare(strings.t("Shelves"),"Estantes")
        compare(strings.t("Checking edition 2 of 3"),"Revisando edición 2 de 3")
        strings.language="ja";compare(strings.t("Shelves"),"棚")
        strings.language="de";compare(strings.t("Shelves"),"Regalböden")
        strings.language="fr";compare(strings.t("Volume: {value}",{value:42}),"Volume : 42")
        strings.language="pt";compare(strings.t("Shelves"),"Prateleiras")
        strings.language="nl";compare(strings.t("Shelves"),"Planken")
        strings.language="ru";compare(strings.t("Shelves"),"Полки")
        strings.language="en";compare(strings.t("Shelves"),"Shelves")
    }
}
