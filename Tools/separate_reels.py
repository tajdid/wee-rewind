"""Create a CC BY 4.0 derivative with two independently pivoted reel meshes.
Requires Apple's usdcat/usdzip; Python standard library only.
Usage: python3 separate_reels.py source.usdz AnimatedCassette.usdz
"""
import ast, math, re, subprocess, sys, tempfile, zipfile
from pathlib import Path

SEGMENTS = 64
RADIUS = 6.7
CENTERS = [(-22.637353, -5.247789), (22.302620, -5.357114)]

def interpolate(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))

def clip(poly, nx, nz, distance):
    inside, outside = [], []
    for a, b in zip(poly, poly[1:] + poly[:1]):
        da, db = nx*a[0]+nz*a[2]-distance, nx*b[0]+nz*b[2]-distance
        (inside if da <= 0 else outside).append(a)
        if (da < 0 < db) or (db < 0 < da):
            v = interpolate(a, b, da/(da-db))
            inside.append(v); outside.append(v)
    return inside, outside

def area(tri):
    a,b,c = tri
    u=[b[i]-a[i] for i in range(3)];v=[c[i]-a[i] for i in range(3)]
    cross=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
    return math.sqrt(sum(x*x for x in cross))/2

def triangles(poly):
    return [t for i in range(1,len(poly)-1) if area(t:=[poly[0],poly[i],poly[i+1]])>1e-8]

def partition(tris, center):
    shell, reel = [], []
    cx,cz = center
    for tri in tris:
        # Partition into disjoint outside strips and one convex inside polygon.
        remaining=tri
        for i in range(SEGMENTS):
            angle=2*math.pi*i/SEGMENTS
            nx,nz=math.cos(angle),math.sin(angle)
            remaining, piece=clip(remaining,nx,nz,RADIUS+nx*cx+nz*cz)
            shell.extend(triangles(piece))
            if not remaining: break
        reel.extend(triangles(remaining))
    return shell,reel

def fmt(v):
    if isinstance(v,tuple):return '('+', '.join(f'{x:.8g}' for x in v)+')'
    return str(v)

def single_mesh(name, tris, center=(0,0), back=False):
    points=[];uv=[]; cx,cz=center
    for tri in tris:
        for v in tri:
            points.append((v[0]-cx,v[1],v[2]-cz));uv.append((0.99181614-v[3] if back else v[3],v[4]))
    return f'''def Mesh "{name}" (prepend apiSchemas = ["MaterialBindingAPI"]) {{
        uniform bool doubleSided = true
        int[] faceVertexCounts = [{', '.join(['3']*len(tris))}]
        int[] faceVertexIndices = [{', '.join(map(str,range(len(points))))}]
        point3f[] points = [{', '.join(map(fmt,points))}]
        texCoord2f[] primvars:st0 = [{', '.join(map(fmt,uv))}] (interpolation = "vertex")
        rel material:binding = </scene/Materials/cassette>
        uniform token subdivisionScheme = "none"
    }}'''


def mesh(name, tris, center=(0,0)):
    # Reverse only the back-face atlas coordinate so lettering is readable
    # from behind. Separate entities let RealityKit apply the Side B artwork.
    front, back = [], []
    for tri in tris:
        ys=[v[1] for v in tri]
        (back if abs(sum(ys)/3)<0.05 and max(ys)-min(ys)<0.05 else front).append(tri)
    return single_mesh(name,front,center) + "\n" + single_mesh(name+"SideB",back,center,True)

def main():
    source,destination=map(lambda x:Path(x).resolve(),sys.argv[1:])
    with tempfile.TemporaryDirectory() as directory:
        folder=Path(directory)
        with zipfile.ZipFile(source) as z:z.extractall(folder)
        subprocess.run(['usdcat',str(folder/'scene.usdc'),'-o',str(folder/'scene.usda')],check=True)
        text=(folder/'scene.usda').read_text()
        def array(name):return ast.literal_eval(re.search(r'\b'+re.escape(name)+r' = (\[.*?\])',text).group(1))
        points,indices,uv=array('points'),array('faceVertexIndices'),array('primvars:st0')
        original=[[tuple(points[n])+tuple(uv[n]) for n in indices[i:i+3]] for i in range(0,len(indices),3)]
        shell,left=partition(original,CENTERS[0]);shell,right=partition(shell,CENTERS[1])
        before=sum(map(area,original));after=sum(map(area,shell+left+right))
        assert abs(before-after)<before*1e-6,(before,after)
        assert left and right and shell
        # Replace the sole original mesh, preserving its complete transform chain.
        start=text.index('def Mesh "cassette_cassette_0"');brace=text.index('{',start);depth=1;end=brace+1
        while depth:
            depth+=(text[end]=='{')-(text[end]=='}');end+=1
        replacement=mesh('Shell',shell)
        for name,tris,(cx,cz) in zip(['LeftReel','RightReel'],[left,right],CENTERS):
            replacement+=f'''\ndef Xform "{name}" {{
                double3 xformOp:translate = ({cx}, 0, {cz})
                uniform token[] xformOpOrder = ["xformOp:translate"]
                {mesh(name+'Mesh',tris,(cx,cz))}
            }}'''
        text=(text[:start]+replacement+text[end:]).replace('token inputs:varname', 'string inputs:varname')
        (folder/'animated.usda').write_text(text)
        subprocess.run(['usdcat',str(folder/'animated.usda'),'-o',str(folder/'animated.usdc')],check=True)
        subprocess.run(['usdzip','--asset',str(folder/'animated.usdc'),str(destination)],check=True)
        print(f'Shell: {len(shell)} triangles; left: {len(left)}; right: {len(right)}. Surface area preserved: {before:.6f} -> {after:.6f}')

if __name__=='__main__':main()
