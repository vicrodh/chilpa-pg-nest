#!/usr/bin/python3
"""An initially opted-out saved-album provider for isolated host checks."""
import json
import sys

for line in sys.stdin:
    request=json.loads(line)
    if 'id' not in request:
        continue
    method=request.get('method')
    if method=='initialize':
        result={'protocol':1,'capabilities':{'pages':True,'library':['albums']}}
    elif method=='library.list':
        result={'items':[{'kind':'album','ref':'album:'+str(index),'title':'Saved fixture '+str(index),'artist':'Z Fixture source','year':2020+index} for index in range(2)],'total':2}
    elif method=='page.get':
        result={'title':'Saved source fixture','shelves':[]}
    else:
        result={}
    print(json.dumps({'jsonrpc':'2.0','id':request['id'],'result':result}),flush=True)
