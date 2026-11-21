import QtQuick
import "NestTranslations.js" as Translations
QtObject {
    property string language:"en"
    function t(message,args){
        let key=String(message || "")
        let values=args || {}
        const edition=/^Checking edition (\d+) of (\d+)$/.exec(key)
        if(edition){key="Checking edition {current} of {total}";values={current:edition[1],total:edition[2]}}
        const table=Translations.catalogs[language.split(/[-_]/)[0]] || Translations.catalogs.en
        let text=table[key] || key
        for(const name of Object.keys(values))text=text.split("{"+name+"}").join(String(values[name]))
        return text
    }
}
