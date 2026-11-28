from http.server import HTTPServer, SimpleHTTPRequestHandler
import gzip, os, pathlib
ROOT=pathlib.Path(os.environ['WEB_ROOT'])
class Handler(SimpleHTTPRequestHandler):
 def __init__(self,*args,**kw): super().__init__(*args,directory=str(ROOT),**kw)
 def send_head(self):
  original=self.translate_path(self.path)
  compressed=original+'.gz'
  if 'gzip' in self.headers.get('Accept-Encoding','') and os.path.isfile(compressed):
   data=open(compressed,'rb'); self.send_response(200); self.send_header('Content-Type',self.guess_type(original)); self.send_header('Content-Encoding','gzip'); self.send_header('Content-Length',str(os.path.getsize(compressed))); self.send_header('Cache-Control','public, max-age=3600'); self.end_headers(); return data
  return super().send_head()
if __name__=='__main__':
 for p in ROOT.iterdir():
  if p.is_file() and p.suffix in ('.wasm','.pck','.js','.html'):
   (ROOT / (p.name + '.gz')).write_bytes(gzip.compress(p.read_bytes(),compresslevel=9,mtime=0))
 HTTPServer(('127.0.0.1',8765),Handler).serve_forever()
