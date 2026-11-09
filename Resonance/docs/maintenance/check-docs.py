"""Read-only documentation checks. Standard-library Python 3; no build/device calls."""
from pathlib import Path
from urllib.parse import unquote, urlsplit
import argparse, hashlib, json, re, sys, unicodedata

def prose(text):
    out=[]; fence=None
    for line in text.splitlines(keepends=True):
        m=re.match(r'^\s{0,3}(`{3,}|~{3,})',line)
        if m:
            ch=m.group(1)[0]
            if fence is None: fence=ch
            elif fence==ch: fence=None
            out.append('\n' if line.endswith('\n') else '')
        elif fence: out.append('\n' if line.endswith('\n') else '')
        else: out.append(line)
    return ''.join(out)

def slug(title):
    title=re.sub(r'\[([^]]+)\]\([^)]*\)',r'\1',title)
    title=re.sub(r'<[^>]+>','',title).lower().replace(' ','-')
    return ''.join(c for c in title if c in '_-' or unicodedata.category(c)[0] in 'LN')

def anchors(text):
    text=prose(text); ids=set(re.findall(r'<a\s+(?:id|name)=["\']([^"\']+)["\']',text)); counts={}
    for m in re.finditer(r'^#{1,6}\s+(.+?)\s*#*\s*$',text,re.M):
        key=slug(m.group(1)); n=counts.get(key,0); counts[key]=n+1
        ids.add(key+(f'-{n}' if n else ''))
    return ids

def links(text):
    """Yield inline link destinations, allowing nested parentheses and angle destinations."""
    body=prose(text)
    code_ranges=[(m.start(),m.end()) for m in re.finditer(r'(?<!`)(`+)(?!`)[^\n]*?(?<!`)\1(?!`)',body)]
    for m in re.finditer(r'!?\[([^\]\n]*)\]\(',body):
        if any(a<=m.start()<b for a,b in code_ranges): continue
        pos=m.end(); start=pos
        if pos<len(body) and body[pos]=='<':
            end=body.find('>',pos+1)
            if end>=0: yield body[pos+1:end]
            continue
        depth=1; escaped=False
        while pos<len(body) and depth and body[pos]!='\n':
            c=body[pos]
            if escaped: escaped=False
            elif c=='\\' and pos+1<len(body) and body[pos+1] in '()': escaped=True
            elif c=='(': depth+=1
            elif c==')': depth-=1
            pos+=1
        if depth==0:
            target=body[start:pos-1]
            target=re.sub(r'\s+["\'].*["\']\s*$','',target)
            yield target.strip()
    for m in re.finditer(r'^\s{0,3}\[[^]]+\]:\s*<?([^>\n]+)>?\s*$',body,re.M):
        yield re.sub(r'\s+["\'].*["\']\s*$','',m.group(1)).strip()

def resolve(root,file,target,repository):
    target=unquote(target).strip().strip('`')
    if re.match(r'^(https?://|mailto:|data:|app:|codex:|discover:)',target,re.I): return None,None
    if target.startswith('file:///'): target=target[8:]
    parts=target.split('#',1); pathpart=parts[0].split('?',1)[0]; fragment=parts[1] if len(parts)>1 else ''
    pathpart=pathpart.replace('\\','/')
    if not pathpart: path=file
    elif re.match(r'^[A-Za-z]:/',pathpart): path=Path(pathpart)
    else: path=file.parent/pathpart
    path=path.resolve()
    # During staging, references outside docs resolve at the real repository root.
    staging_parent=root.parent.resolve()
    if repository and root!=repository/'docs':
        try:
            rel=path.relative_to(staging_parent)
            if rel.parts and rel.parts[0]!=root.name: path=(repository/rel).resolve()
        except ValueError: pass
    return path,fragment

def check(root,repository):
    files=sorted(root.rglob('*.md')); text={p:p.read_text(encoding='utf-8-sig') for p in files}
    ids={p:anchors(t) for p,t in text.items()}; errors=[]; graph={p:set() for p in files}; count=0
    for p,t in text.items():
        for target in links(t):
            resolved,fragment=resolve(root,p,target,repository)
            if resolved is None: continue
            count+=1
            if not resolved.exists(): errors.append({'file':str(p.relative_to(root)),'target':target,'problem':'missing path'}); continue
            if resolved in graph: graph[p].add(resolved)
            if fragment and resolved.suffix.lower()=='.md':
                actual=ids.get(resolved)
                if actual is None:
                    actual=anchors(resolved.read_text(encoding='utf-8-sig'))
                if fragment not in actual:
                    errors.append({'file':str(p.relative_to(root)),'target':target,'problem':'missing anchor'})
    required=['README.md','working-with-code.md','current.md','components/README.md','history/README.md','issues/README.md','operators/README.md','how-to/ai-task-prompts.md','maintenance/README.md']
    for rel in required:
        if not (root/rel).is_file(): errors.append({'file':rel,'problem':'required page missing'})
    seen=set(); todo=[root/'README.md']
    while todo:
        p=todo.pop()
        if p in seen: continue
        seen.add(p); todo.extend(graph.get(p,set())-seen)
    for p in files:
        rel=p.relative_to(root)
        if rel.parts[0]!='history' and p not in seen:
            errors.append({'file':str(rel),'problem':'current page unreachable from README'})
    mig=root/'maintenance/migration-map.json'; checked_docx=0
    if mig.exists():
        data=json.loads(mig.read_text(encoding='utf-8'))
        for row in data['sections']:
            if row.get('sha256') and row['destination'].endswith('.docx'):
                p=root/row['destination']
                if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=row['sha256']:
                    errors.append({'file':row['destination'],'problem':'publication differs from recorded original'})
                else: checked_docx+=1
        for row in data['sections']:
            if not (root/row['destination']).exists():
                errors.append({'file':row['destination'],'problem':'migration destination missing'})
    bootstrap=sum(len(text.get(root/name,'').split()) for name in ['README.md','working-with-code.md','current.md'])
    current_words=sum(len(t.split()) for p,t in text.items() if p.relative_to(root).parts[0] not in ['history','operators'])
    return {'markdown_files':len(files),'local_links_checked':count,'unchanged_publications':checked_docx,'initial_reading_words':bootstrap,'current_document_words':current_words,'errors':errors}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    parser.add_argument('--repository',type=Path,help='Real repository root when checking a staged docs tree')
    parser.add_argument('--json',action='store_true')
    args=parser.parse_args(); root=args.root.resolve(); repository=args.repository.resolve() if args.repository else root.parent
    result=check(root,repository)
    if args.json: print(json.dumps(result,ensure_ascii=False,indent=2))
    else:
        print(f"{result['markdown_files']} Markdown files; {result['local_links_checked']} local links checked; {result['unchanged_publications']} unchanged Word publications")
        print(f"Initial route: {result['initial_reading_words']} words; current documentation: {result['current_document_words']} words")
        for e in result['errors']: print(f"ERROR: {e['file']}: {e['problem']} {e.get('target','')}")
        print(f"{'PASS' if not result['errors'] else 'FAIL'}: {len(result['errors'])} documentation errors")
    sys.exit(bool(result['errors']))
