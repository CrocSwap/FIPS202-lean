import hashlib, sys
msgs = [('[]', b''), ('abc', b'abc'), ('a3x200', bytes([0xa3])*200),
        ('range 135', bytes(range(135))), ('range 136', bytes(range(136))), ('range 137', bytes(range(137))),
        ('range 103', bytes(range(103))), ('range 104', bytes(range(104))), ('range 168', bytes(range(168)))]
def lean_msg(name):
    if name in ('[]','abc','a3x200'): return name
    return '(bytesUpTo ' + name.split()[1] + ')'
header = open(sys.argv[1]).read()
out=[header]
fns=[('SHA3-224',lambda m:hashlib.sha3_224(m).hexdigest(),'sha3_224 {}'),
     ('SHA3-256',lambda m:hashlib.sha3_256(m).hexdigest(),'sha3_256 {}'),
     ('SHA3-384',lambda m:hashlib.sha3_384(m).hexdigest(),'sha3_384 {}'),
     ('SHA3-512',lambda m:hashlib.sha3_512(m).hexdigest(),'sha3_512 {}'),
     ('SHAKE128, 32 bytes',lambda m:hashlib.shake_128(m).hexdigest(32),'shake128 {} 32'),
     ('SHAKE256, 64 bytes',lambda m:hashlib.shake_256(m).hexdigest(64),'shake256 {} 64')]
for title,f,tmpl in fns:
    out.append(f'/-! ## {title} -/\n')
    for name,m in msgs:
        out.append(f'#guard {tmpl.format(lean_msg(name))} = hex "{f(m)}"')
    out.append('')
out.append('/-! ## Multi-block XOF output -/\n')
out.append(f'#guard shake128 [] 400 = hex "{hashlib.shake_128(b"").hexdigest(400)}"')
out.append(f'#guard shake256 abc 300 = hex "{hashlib.shake_256(b"abc").hexdigest(300)}"')
out.append(f'#guard shake256 a3x200 1000 = hex "{hashlib.shake_256(bytes([0xa3])*200).hexdigest(1000)}"')
out.append(open(sys.argv[2]).read())
open(sys.argv[3],'w').write('\n'.join(out))
