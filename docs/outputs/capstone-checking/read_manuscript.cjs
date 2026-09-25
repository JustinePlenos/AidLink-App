const fs=require('fs'),zlib=require('zlib'),path=require('path');
const input='C:/Users/juzzp/Downloads/AidLink_ Manuscript.pdf';
const raw=fs.readFileSync(input).toString('latin1');
const objects=new Map();
for(const m of raw.matchAll(/(\d+) 0 obj\s*([\s\S]*?)endobj/g)) objects.set(+m[1],m[2]);
function stream(id){const t=objects.get(id)||'';let start=t.indexOf('stream');if(start<0)return '';start+=6;if(t[start]==='\r')start++;if(t[start]==='\n')start++;const b=Buffer.from(t.slice(start,t.lastIndexOf('endstream')),'latin1');return (t.slice(0,start).includes('/FlateDecode')?zlib.inflateSync(b):b).toString('latin1');}
const fonts=new Map();
for(const [id,t] of objects){const ref=t.match(/\/ToUnicode (\d+) 0 R/);if(!ref)continue;const s=stream(+ref[1]),map=new Map();for(const block of s.matchAll(/beginbfchar([\s\S]*?)endbfchar/g)){for(const pair of block[1].matchAll(/<([0-9A-F]+)>\s*<([0-9A-F]+)>/g))map.set(parseInt(pair[1],16),String.fromCharCode(...pair[2].match(/.{4}/g).map(v=>parseInt(v,16))));}for(const block of s.matchAll(/beginbfrange([\s\S]*?)endbfrange/g)){for(const pair of block[1].matchAll(/<([0-9A-F]+)>\s*<([0-9A-F]+)>\s*<([0-9A-F]+)>/g)){const lo=parseInt(pair[1],16),hi=parseInt(pair[2],16),base=parseInt(pair[3],16);for(let k=lo;k<=hi;k++)map.set(k,String.fromCodePoint(base+k-lo));}}fonts.set(id,map);}
const catalog=[...objects.values()].find(t=>/\/Type\s*\/Catalog\b/.test(t));
const root=+catalog.match(/\/Pages (\d+) 0 R/)[1];const pageIds=[];
function walk(id){const t=objects.get(id);if(/\/Type\s*\/Page\b/.test(t)){pageIds.push(id);return;}const kids=t.match(/\/Kids\s*\[([^\]]+)\]/)[1];for(const m of kids.matchAll(/(\d+) 0 R/g))walk(+m[1]);}walk(root);
const pages=pageIds.map((id,i)=>{const t=objects.get(id),refs=new Map([...t.matchAll(/\/(F\d+) (\d+) 0 R/g)].map(m=>[m[1],+m[2]]));const contents=t.match(/\/Contents (\d+) 0 R/);if(!contents)return {page:i+1,text:'[No direct text stream]'};const s=stream(+contents[1]);let font,txt='',unknown=0;for(const m of s.matchAll(/\/(F\d+) [\d.]+ Tf|<([0-9A-F]+)>\s*Tj|\/MCID\s+\d+/g)){if(m[1])font=fonts.get(refs.get(m[1]));else if(m[2])txt+=m[2].match(/.{4}/g).map(h=>{const ch=font?.get(parseInt(h,16));if(ch===undefined){unknown++;return '�';}return ch;}).join('');else txt+='\n';}return {page:i+1,text:txt.trim(),unknown};});
fs.writeFileSync(path.join(__dirname,'manuscript-extracted.json'),JSON.stringify(pages,null,2));
fs.writeFileSync(path.join(__dirname,'manuscript-extracted.txt'),pages.map(p=>'\n=== PDF PAGE '+p.page+' ===\n'+p.text).join('\n'));
console.log('Extracted '+pages.length+' pages; unmapped glyphs: '+pages.reduce((a,p)=>a+(p.unknown||0),0));
for(const p of pages)if(p.page<=3||/general objective|specific objectives|scope and limitation|objectives of the study/i.test(p.text))console.log('\nPAGE '+p.page+'\n'+p.text);
