#include "spectrum_art.h"
#include <QPainter>
#include <QQuickPaintedItem>
#include <QSGGeometryNode>
#include <QSGVertexColorMaterial>
#include <algorithm>
#include <cmath>

namespace {
constexpr int bands=16,segments=12;
constexpr int peakUnits=20,peakFall=7; // 0.35 segments per 40 ms, after a 600 ms hold.
const QColor background(8,10,9);
const QColor colors[3][2]={{QColor(20,34,25),QColor(95,211,111)},
    {QColor(42,35,18),QColor(255,178,74)},{QColor(44,22,20),QColor(255,84,70)}};
const QColor &segmentColor(int segment,bool on){return colors[segment>=10 ? 2:segment>=7 ? 1:0][on ? 1:0];}
QRectF cell(qreal width,qreal height,int band,int segment){
    const qreal bw=(width-16)/bands,sh=(height-16)/segments;
    // Match the bitmap's pixel edges on the GPU, including fractional cell sizes.
    const int left=qRound(8+band*bw),top=qRound(height-8-(segment+1)*sh);
    const int right=std::min(qRound(8+(band+1)*bw),qRound(8+band*bw+std::max(1.,bw-2)));
    const int bottom=std::min(qRound(height-8-segment*sh),qRound(height-8-(segment+1)*sh+std::max(1.,sh-1)));
    return QRectF(left,top,right-left,bottom-top);
}
void rectangle(QSGGeometry::ColoredPoint2D *&out,const QRectF &rect,const QColor &color){
    out[0].set(rect.left(),rect.top(),color.red(),color.green(),color.blue(),255);out[1]=out[0];
    out[2]=out[0];out[2].x=rect.right();
    out[3]=out[0];out[3].y=rect.bottom();out[4]=out[3];out[4].x=rect.right();out[5]=out[4];
    out+=6;
}
}

class SpectrumBitmap : public QQuickPaintedItem {
public:
    explicit SpectrumBitmap(SpectrumArt *meter):QQuickPaintedItem(meter),m_meter(meter){
        setObjectName("nestSpectrumBitmap");setTextureSize(QSize(256,96));
    }
    void paint(QPainter *painter) override {m_meter->paintBitmap(painter);}
private:
    SpectrumArt *m_meter;
};

SpectrumArt::SpectrumArt(QQuickItem *parent):QQuickItem(parent),m_bitmap(new SpectrumBitmap(this)){
    setFlag(ItemHasContents);
    m_clock.setInterval(40);
    connect(&m_clock,&QTimer::timeout,this,&SpectrumArt::advance);
}
QVariantList SpectrumArt::levels() const {QVariantList out;out.reserve(bands);for(int v:m_input)out<<v/double(segments);return out;}
void SpectrumArt::setLevels(const QVariantList &levels){
    std::array<int,bands> next{};
    for(int band=0;band<bands;++band){
        const int from=band*levels.size()/bands,to=std::max(from+1,(band+1)*int(levels.size())/bands);
        double peak=0;
        for(int n=from;n<to && n<levels.size();++n){const double v=levels[n].toDouble();if(std::isfinite(v))peak=std::max(peak,std::clamp(v,0.,1.));}
        next[band]=int(std::round(peak*segments));
    }
    if(next==m_input)return;
    m_input=next;emit changed();
    if(m_active && !m_clock.isActive())m_clock.start();
}
void SpectrumArt::setActive(bool active){
    if(active==m_active)return;
    m_active=active;emit activeChanged();
    if(active){advance();m_clock.start();}
    else{m_clock.stop();m_values.fill(0);m_peaks.fill(0);m_holds.fill(0);redraw();}
}
void SpectrumArt::setAccelerated(bool accelerated){
    if(accelerated==m_accelerated)return;
    m_accelerated=accelerated;m_bitmap->setVisible(!accelerated);emit acceleratedChanged();
    update();if(!accelerated)m_bitmap->update();
}
void SpectrumArt::advance(){
    bool changedPixels=false,settled=true;
    for(int band=0;band<bands;++band){
        const int value=std::max(m_input[band],m_values[band]-1);
        int peak=m_peaks[band];
        if(value*peakUnits>=peak){peak=value*peakUnits;m_holds[band]=15;}
        else if(m_holds[band]>0)--m_holds[band];
        else peak=std::max(value*peakUnits,peak-peakFall);
        changedPixels|=value!=m_values[band] || (peak+peakUnits/2)/peakUnits!=(m_peaks[band]+peakUnits/2)/peakUnits;
        m_values[band]=value;m_peaks[band]=peak;
        settled&=value==m_input[band] && peak==value*peakUnits;
    }
    if(changedPixels)redraw();
    if(settled)m_clock.stop();
}
void SpectrumArt::redraw(){emit frameChanged();if(m_accelerated)update();else m_bitmap->update();}
void SpectrumArt::geometryChange(const QRectF &next,const QRectF &previous){
    QQuickItem::geometryChange(next,previous);
    if(next.size()!=previous.size()){
        m_bitmap->setSize(next.size());
        m_bitmap->setTextureSize(QSize(std::clamp(qRound(next.width()),1,256),std::clamp(qRound(next.height()),1,96)));
        update();
    }
}
void SpectrumArt::paintBitmap(QPainter *painter) const {
    painter->fillRect(boundingRect(),background);
    for(int band=0;band<bands;++band)for(int segment=0;segment<segments;++segment)
        painter->fillRect(cell(width(),height(),band,segment),segmentColor(segment,m_active && (segment<m_values[band] || segment==(m_peaks[band]+peakUnits/2)/peakUnits-1)));
}
QSGNode *SpectrumArt::updatePaintNode(QSGNode *oldNode,UpdatePaintNodeData *){
    if(!m_accelerated || width()<=16 || height()<=16){delete oldNode;return nullptr;}
    auto *node=static_cast<QSGGeometryNode *>(oldNode);
    if(!node){
        node=new QSGGeometryNode;
        auto *geometry=new QSGGeometry(QSGGeometry::defaultAttributes_ColoredPoint2D(),(4+bands*segments*3)*6);
        geometry->setDrawingMode(QSGGeometry::DrawTriangleStrip);geometry->setVertexDataPattern(QSGGeometry::DynamicPattern);
        node->setGeometry(geometry);node->setFlag(QSGNode::OwnsGeometry);
        auto *material=new QSGVertexColorMaterial;material->setFlag(QSGMaterial::Blending,false);
        node->setMaterial(material);node->setFlag(QSGNode::OwnsMaterial);
    }
    auto *out=node->geometry()->vertexDataAsColoredPoint2D();
    // Background strips never overlap the LEDs. This preserves inherited
    // opacity and avoids depth collisions without a layer or another draw.
    rectangle(out,QRectF(0,0,8,height()),background);
    rectangle(out,QRectF(width()-8,0,8,height()),background);
    rectangle(out,QRectF(8,0,width()-16,8),background);
    rectangle(out,QRectF(8,height()-8,width()-16,8),background);
    const qreal bw=(width()-16)/bands,sh=(height()-16)/segments;
    for(int band=0;band<bands;++band)for(int segment=0;segment<segments;++segment){
        const QRectF led=cell(width(),height(),band,segment);
        const int right=qRound(8+(band+1)*bw),bottom=qRound(height()-8-segment*sh);
        rectangle(out,led,segmentColor(segment,m_active && (segment<m_values[band] || segment==(m_peaks[band]+peakUnits/2)/peakUnits-1)));
        rectangle(out,QRectF(led.right(),led.top(),right-led.right(),bottom-led.top()),background);
        rectangle(out,QRectF(led.left(),led.bottom(),led.width(),bottom-led.bottom()),background);
    }
    node->geometry()->markVertexDataDirty();node->markDirty(QSGNode::DirtyGeometry);
    return node;
}
