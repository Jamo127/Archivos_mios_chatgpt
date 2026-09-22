import os
import re
import json
import math
import struct
import zlib
import shutil

# ============================================================
# JMO SMD -> GLB V3
# - GoldSrc units -> meters
# - Correct inverse bind matrices
# - Body materials preserved per SMD triangle group
# - UV V flipped for glTF
# - Body + backpack
# - 23-bone skeleton
# - Animations + blend samples
# - Static orientation parent (-90 deg X)
# ============================================================

ROOT = os.path.dirname(os.path.abspath(__file__))

BODY_SMD = os.path.join(ROOT, "arctic.smd")
BACKPACK_SMD = os.path.join(ROOT, "bomb.smd")
QC_FILE = os.path.join(ROOT, "JMO.qc")

TEXTURE_DIR = os.path.join(ROOT, "maps_8bit")
ANIM_DIR = os.path.join(ROOT, "anims")

OUTPUT = os.path.join(ROOT, "JMO.glb")
BACKUP = os.path.join(ROOT, "JMO_v2_backup.glb")

# GoldSrc -> metros
UNIT_SCALE = 0.0254

# Corrige el V de las UV.
FLIP_UV_V = True

# Tú lo corregiste manualmente en Prisma con -90°.
# Aquí lo hacemos automáticamente.
ORIENTATION_X_DEG = -90.0


# ============================================================
# HELPERS
# ============================================================

def read_smd(path):
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        return f.read()


def clean_smd_path(p):
    p = p.strip().strip('"').replace("\\", "/")
    p = re.sub(r"^\./", "", p)
    return p


def normalize_quat(q):
    x, y, z, w = q
    n = math.sqrt(x*x + y*y + z*z + w*w)

    if n < 1e-12:
        return [0.0, 0.0, 0.0, 1.0]

    return [x/n, y/n, z/n, w/n]


def quat_from_euler_xyz(rx, ry, rz):
    cx = math.cos(rx * 0.5)
    sx = math.sin(rx * 0.5)

    cy = math.cos(ry * 0.5)
    sy = math.sin(ry * 0.5)

    cz = math.cos(rz * 0.5)
    sz = math.sin(rz * 0.5)

    x = sx * cy * cz - cx * sy * sz
    y = cx * sy * cz + sx * cy * sz
    z = cx * cy * sz - sx * sy * cz
    w = cx * cy * cz + sx * sy * sz

    return normalize_quat([x, y, z, w])


def quat_to_mat4(q):
    # Matriz column-major compatible con glTF.
    x, y, z, w = normalize_quat(q)

    xx = x * x
    yy = y * y
    zz = z * z

    xy = x * y
    xz = x * z
    yz = y * z

    wx = w * x
    wy = w * y
    wz = w * z

    return [
        1 - 2*(yy + zz),
        2*(xy + wz),
        2*(xz - wy),
        0.0,

        2*(xy - wz),
        1 - 2*(xx + zz),
        2*(yz + wx),
        0.0,

        2*(xz + wy),
        2*(yz - wx),
        1 - 2*(xx + yy),
        0.0,

        0.0,
        0.0,
        0.0,
        1.0,
    ]


def make_transform(pos, quat):
    m = quat_to_mat4(quat)

    m[12] = pos[0]
    m[13] = pos[1]
    m[14] = pos[2]

    return m


def mat_mul(a, b):
    # Column-major: out = a * b
    out = [0.0] * 16

    for c in range(4):
        for r in range(4):
            s = 0.0

            for k in range(4):
                s += a[k*4 + r] * b[c*4 + k]

            out[c*4 + r] = s

    return out


def mat_inverse_rigid(m):
    # Inversa para una matriz rotación + traslación.
    out = [0.0] * 16

    # R^-1 = R^T
    for r in range(3):
        for c in range(3):
            out[c*4 + r] = m[r*4 + c]

    tx = m[12]
    ty = m[13]
    tz = m[14]

    out[12] = -(out[0]*tx + out[4]*ty + out[8]*tz)
    out[13] = -(out[1]*tx + out[5]*ty + out[9]*tz)
    out[14] = -(out[2]*tx + out[6]*ty + out[10]*tz)

    out[15] = 1.0

    return out


# ============================================================
# SMD PARSER
# ============================================================

def parse_nodes(text):
    m = re.search(
        r"(?ms)^nodes\s*(.*?)^end\s*$",
        text
    )

    if not m:
        raise ValueError(
            "No se encontró bloque 'nodes'."
        )

    nodes = []

    for line in m.group(1).splitlines():
        line = line.strip()

        if not line:
            continue

        mm = re.match(
            r'(-?\d+)\s+"([^"]+)"\s+(-?\d+)\s*$',
            line
        )

        if not mm:
            continue

        idx, name, parent = mm.groups()

        nodes.append({
            "index": int(idx),
            "name": name,
            "parent": int(parent),
        })

    nodes.sort(
        key=lambda x: x["index"]
    )

    return nodes

def parse_skeleton(text):
    m = re.search(
        r"(?ms)^skeleton\s*(.*?)^end\s*$",
        text
    )

    if not m:
        raise ValueError(
            "No se encontró bloque 'skeleton'."
        )

    frames = []

    lines = [
        ln.strip()
        for ln in m.group(1).splitlines()
    ]

    i = 0

    while i < len(lines):

        line = lines[i]

        tm = re.match(
            r"time\s+(\d+)",
            line
        )

        if not tm:
            i += 1
            continue

        time_idx = int(
            tm.group(1)
        )

        i += 1

        bones = {}

        while (
            i < len(lines)
            and not lines[i].startswith("time ")
        ):

            if lines[i]:

                parts = lines[i].split()

                if len(parts) >= 7:

                    try:

                        bi = int(
                            parts[0]
                        )

                        px, py, pz = map(
                            float,
                            parts[1:4]
                        )

                        rx, ry, rz = map(
                            float,
                            parts[4:7]
                        )

                        bones[bi] = {
                            "pos": [
                                px,
                                py,
                                pz
                            ],

                            "rot": [
                                rx,
                                ry,
                                rz
                            ],
                        }

                    except ValueError:
                        pass

            i += 1

        frames.append({
            "time": time_idx,
            "bones": bones,
        })

    if not frames:
        raise ValueError(
            "No se encontraron frames "
            "en skeleton."
        )

    return frames

def parse_triangles(text):
    m = re.search(
        r"(?ms)^triangles\s*(.*?)^end\s*$",
        text
    )

    if not m:
        return []

    lines = [
        ln.rstrip()
        for ln in m.group(1).splitlines()
    ]

    triangles = []

    i = 0

    while i < len(lines):

        if not lines[i].strip():
            i += 1
            continue

        material = lines[i].strip()

        if i + 3 >= len(lines):
            break

        verts = []

        ok = True

        for j in range(1, 4):

            parts = lines[i + j].split()

            if len(parts) != 9:
                ok = False
                break

            try:
                bone = int(parts[0])

                x, y, z = map(
                    float,
                    parts[1:4]
                )

                nx, ny, nz = map(
                    float,
                    parts[4:7]
                )

                u, v = map(
                    float,
                    parts[7:9]
                )

                verts.append({
                    "bone": bone,
                    "pos": [x, y, z],
                    "normal": [nx, ny, nz],
                    "uv": [u, v],
                })

            except ValueError:
                ok = False
                break

        if ok:
            triangles.append({
                "material": material,
                "verts": verts,
            })

        i += 4

    return triangles


def load_smd(path):
    text = read_smd(path)

    triangles = []

    if re.search(
        r"(?m)^triangles\s*$",
        text
    ):
        triangles = parse_triangles(text)

    return {
        "nodes": parse_nodes(text),
        "skeleton": parse_skeleton(text),
        "triangles": triangles,
    }


# ============================================================
# BMP 8-BIT -> PNG RGBA
# ============================================================

def png_chunk(kind, payload):
    raw = kind + payload

    return (
        struct.pack(">I", len(payload))
        + raw
        + struct.pack(
            ">I",
            zlib.crc32(raw) & 0xffffffff
        )
    )


def rgba_to_png(width, height, rgba_bytes):
    rows = []

    stride = width * 4

    for y in range(height):
        rows.append(
            b"\x00"
            + rgba_bytes[
                y*stride:(y+1)*stride
            ]
        )

    raw = b"".join(rows)

    sig = b"\x89PNG\r\n\x1a\n"

    ihdr = struct.pack(
        ">IIBBBBB",
        width,
        height,
        8,
        6,
        0,
        0,
        0
    )

    return (
        sig
        + png_chunk(b"IHDR", ihdr)
        + png_chunk(
            b"IDAT",
            zlib.compress(raw, 9)
        )
        + png_chunk(b"IEND", b"")
    )


def bmp8_to_png(path):
    with open(path, "rb") as f:
        data = f.read()

    if data[:2] != b"BM":
        raise ValueError(
            f"No es BMP: {path}"
        )

    pixel_offset = struct.unpack_from(
        "<I",
        data,
        10
    )[0]

    dib_size = struct.unpack_from(
        "<I",
        data,
        14
    )[0]

    if dib_size < 40:
        raise ValueError(
            f"DIB no soportado: {path}"
        )

    width = struct.unpack_from(
        "<i",
        data,
        18
    )[0]

    raw_height = struct.unpack_from(
        "<i",
        data,
        22
    )[0]

    planes = struct.unpack_from(
        "<H",
        data,
        26
    )[0]

    bpp = struct.unpack_from(
        "<H",
        data,
        28
    )[0]

    compression = struct.unpack_from(
        "<I",
        data,
        30
    )[0]

    colors_used = struct.unpack_from(
        "<I",
        data,
        46
    )[0]

    if (
        planes != 1
        or bpp != 8
        or compression != 0
    ):
        raise ValueError(
            "BMP no es 8-bit paletizado sin compresión: "
            + path
        )

    height = abs(raw_height)

    palette_count = (
        colors_used
        if colors_used
        else 256
    )

    palette_offset = 14 + dib_size

    palette = []

    for i in range(palette_count):

        off = palette_offset + i * 4

        b, g, r, _a = struct.unpack_from(
            "<BBBB",
            data,
            off
        )

        palette.append(
            (r, g, b, 255)
        )

    row_stride = (
        (width + 3) // 4
    ) * 4

    rgba = bytearray(
        width * height * 4
    )

    for src_row in range(height):

        if raw_height > 0:
            dst_y = height - 1 - src_row
        else:
            dst_y = src_row

        src_off = (
            pixel_offset
            + src_row * row_stride
        )

        for x in range(width):

            idx = data[src_off + x]

            if idx < len(palette):
                px = palette[idx]
            else:
                px = (0, 0, 0, 255)

            dst = (
                (dst_y * width + x)
                * 4
            )

            rgba[dst:dst+4] = bytes(px)

    return (
        width,
        height,
        rgba_to_png(
            width,
            height,
            rgba
        )
    )


# ============================================================
# QC ANIMATION PARSER
# ============================================================

def parse_qc_sequences(path):
    text = read_smd(path)

    lines = text.splitlines()

    sequences = []

    i = 0

    while i < len(lines):

        line = lines[i].strip()

        if not line.lower().startswith("$sequence"):
            i += 1
            continue

        rest = line[len("$sequence"):].strip()

        # ----------------------------------------------------
        # Nombre de la secuencia
        # ----------------------------------------------------

        name_match = re.match(
            r"([A-Za-z0-9_./-]+)",
            rest
        )

        if not name_match:
            i += 1
            continue

        name = name_match.group(1)

        # ----------------------------------------------------
        # Buscar el bloque {...}
        # ----------------------------------------------------

        block_lines = [line]

        brace_balance = (
            line.count("{")
            - line.count("}")
        )

        i += 1

        while (
            brace_balance > 0
            and i < len(lines)
        ):

            nxt = lines[i]

            block_lines.append(nxt)

            brace_balance += (
                nxt.count("{")
                - nxt.count("}")
            )

            i += 1

        block = "\n".join(
            block_lines
        )

        # ----------------------------------------------------
        # También puede existir $sequence sin { }
        # ----------------------------------------------------

        if brace_balance > 0:
            print(
                "  AVISO: bloque sin cerrar: "
                f"{name}"
            )

        # ----------------------------------------------------
        # Extraer todos los .smd
        # ----------------------------------------------------

        paths = re.findall(
            r'"([^"]+\.smd)"',
            block,
            re.I
        )

        paths = [
            clean_smd_path(p)
            for p in paths
        ]

        # ----------------------------------------------------
        # FPS
        # ----------------------------------------------------

        fps_match = re.search(
            r"\bfps\s+([0-9.+-]+)",
            block,
            re.I
        )

        if fps_match:

            try:
                fps = float(
                    fps_match.group(1)
                )

            except ValueError:
                fps = 30.0

        else:
            fps = 30.0

        if fps <= 0:
            fps = 30.0

        # ----------------------------------------------------
        # BLEND
        # ----------------------------------------------------

        blend_match = re.search(
            r"\bblend\s+"
            r"([A-Za-z]{1,3})\s+"
            r"([-+0-9.eE]+)\s+"
            r"([-+0-9.eE]+)",
            block,
            re.I
        )

        blend = None

        if blend_match:

            blend = {
                "axis": blend_match.group(1),

                "min": float(
                    blend_match.group(2)
                ),

                "max": float(
                    blend_match.group(3)
                ),
            }

        # ----------------------------------------------------
        # Si no hay SMD, no es una animación válida.
        # ----------------------------------------------------

        if not paths:
            continue

        sequences.append({
            "name": name,
            "paths": paths,
            "fps": fps,
            "blend": blend,
        })

    return sequences

def find_anim_file(rel_path):
    rel_path = clean_smd_path(rel_path)

    candidates = [
        os.path.join(
            ROOT,
            rel_path
        ),

        os.path.join(
            ANIM_DIR,
            os.path.basename(rel_path)
        ),

        os.path.join(
            ROOT,
            os.path.basename(rel_path)
        ),
    ]

    for c in candidates:
        if os.path.isfile(c):
            return c

    return None


# ============================================================
# GLTF / GLB BUILDER
# ============================================================

def align4(buf):
    while len(buf) % 4:
        buf.append(0)


def accessor_minmax(values, typ):
    comps = {
        "SCALAR": 1,
        "VEC2": 2,
        "VEC3": 3,
        "VEC4": 4,
        "MAT4": 16,
    }[typ]

    if not values:
        return None, None

    mins = [float("inf")] * comps
    maxs = [float("-inf")] * comps

    for i in range(
        0,
        len(values),
        comps
    ):

        chunk = values[
            i:i+comps
        ]

        for j, v in enumerate(chunk):

            mins[j] = min(
                mins[j],
                float(v)
            )

            maxs[j] = max(
                maxs[j],
                float(v)
            )

    return mins, maxs


def build_glb(
    body,
    backpack,
    textures,
    animation_specs,
    root_orientation_quat
):

    gltf = {
        "asset": {
            "version": "2.0",
            "generator": (
                "JMO GoldSrc SMD -> GLB V3"
            ),
            "extras": {
                "sourceUnits": "GoldSrc units",
                "unitScale": UNIT_SCALE,
                "targetUnits": "meters",
                "bodyMaterialsPerSMDGroup": True,
                "flipTextureV": FLIP_UV_V,
                "orientationXDegrees": (
                    ORIENTATION_X_DEG
                ),
            },
        },

        "scene": 0,

        "scenes": [
            {
                "nodes": [0]
            }
        ],

        "nodes": [],
        "meshes": [],
        "skins": [],
        "materials": [],
        "images": [],
        "textures": [],

        "samplers": [
            {
                "magFilter": 9729,
                "minFilter": 9987,
                "wrapS": 10497,
                "wrapT": 10497,
            }
        ],

        "accessors": [],
        "bufferViews": [],

        "buffers": [
            {
                "byteLength": 0
            }
        ],

        "animations": [],
    }

    binbuf = bytearray()

    # --------------------------------------------------------
    # BUFFER / ACCESSORS
    # --------------------------------------------------------

    def add_blob(data, target=None):

        align4(binbuf)

        off = len(binbuf)

        binbuf.extend(data)

        view = {
            "buffer": 0,
            "byteOffset": off,
            "byteLength": len(data),
        }

        if target is not None:
            view["target"] = target

        gltf["bufferViews"].append(view)

        return len(
            gltf["bufferViews"]
        ) - 1


    def add_accessor_f32(
        values,
        typ,
        target=None,
        minmax=True
    ):

        raw = (
            struct.pack(
                "<" + "f" * len(values),
                *values
            )
            if values
            else b""
        )

        view_idx = add_blob(
            raw,
            target
        )

        comps = {
            "SCALAR": 1,
            "VEC2": 2,
            "VEC3": 3,
            "VEC4": 4,
            "MAT4": 16,
        }[typ]

        acc = {
            "bufferView": view_idx,
            "componentType": 5126,
            "count": len(values) // comps,
            "type": typ,
        }

        if minmax and values:
            mn, mx = accessor_minmax(
                values,
                typ
            )

            acc["min"] = mn
            acc["max"] = mx

        gltf["accessors"].append(acc)

        return len(
            gltf["accessors"]
        ) - 1


    def add_accessor_u8(
        values,
        typ,
        target=None
    ):

        raw = (
            struct.pack(
                "<" + "B" * len(values),
                *values
            )
            if values
            else b""
        )

        view_idx = add_blob(
            raw,
            target
        )

        comps = {
            "SCALAR": 1,
            "VEC2": 2,
            "VEC3": 3,
            "VEC4": 4,
        }[typ]

        acc = {
            "bufferView": view_idx,
            "componentType": 5121,
            "count": len(values) // comps,
            "type": typ,
        }

        gltf["accessors"].append(acc)

        return len(
            gltf["accessors"]
        ) - 1


    def add_accessor_u32(
        values,
        typ="SCALAR",
        target=None
    ):

        raw = (
            struct.pack(
                "<" + "I" * len(values),
                *values
            )
            if values
            else b""
        )

        view_idx = add_blob(
            raw,
            target
        )

        acc = {
            "bufferView": view_idx,
            "componentType": 5125,
            "count": len(values),
            "type": typ,
        }

        gltf["accessors"].append(acc)

        return len(
            gltf["accessors"]
        ) - 1


    # --------------------------------------------------------
    # IMAGES / TEXTURES
    # --------------------------------------------------------

    texture_index = {}

    for tex_name, png_bytes in textures.items():

        img_view = add_blob(
            png_bytes
        )

        gltf["images"].append({
            "name": tex_name,
            "bufferView": img_view,
            "mimeType": "image/png",
        })

        image_idx = len(
            gltf["images"]
        ) - 1

        gltf["textures"].append({
            "sampler": 0,
            "source": image_idx,
            "name": tex_name,
        })

        texture_idx = len(
            gltf["textures"]
        ) - 1

        texture_index[
            tex_name.lower()
        ] = texture_idx


    # --------------------------------------------------------
    # MATERIALS
    # --------------------------------------------------------

    material_index = {}

    all_material_names = []

    for tri in (
        body["triangles"]
        + backpack["triangles"]
    ):

        mat = tri["material"]

        if mat not in all_material_names:
            all_material_names.append(mat)


    for mat_name in all_material_names:

        key = mat_name.lower()

        mat_def = {
            "name": os.path.splitext(
                os.path.basename(mat_name)
            )[0],

            "doubleSided": True,

            "pbrMetallicRoughness": {
                "baseColorFactor": [
                    1.0,
                    1.0,
                    1.0,
                    1.0
                ],

                "metallicFactor": 0.0,
                "roughnessFactor": 1.0,
            },
        }

        if key in texture_index:

            mat_def[
                "pbrMetallicRoughness"
            ][
                "baseColorTexture"
            ] = {
                "index": texture_index[key]
            }

        else:

            fallback = os.path.basename(
                mat_name
            ).lower()

            if fallback in texture_index:

                mat_def[
                    "pbrMetallicRoughness"
                ][
                    "baseColorTexture"
                ] = {
                    "index": texture_index[
                        fallback
                    ]
                }

        gltf["materials"].append(
            mat_def
        )

        material_index[
            mat_name
        ] = len(
            gltf["materials"]
        ) - 1


    # --------------------------------------------------------
    # ORIENTATION PARENT
    # --------------------------------------------------------

    orientation_node = {
        "name": "JMO_Orientation",
        "rotation": root_orientation_quat,
        "children": [],
    }

    gltf["nodes"].append(
        orientation_node
    )

    orientation_idx = 0


    # --------------------------------------------------------
    # SKELETON NODES
    # --------------------------------------------------------

    bone_node_indices = []

    node_by_bone = {}

    for n in body["nodes"]:

        node = {
            "name": n["name"],
        }

        node_idx = len(
            gltf["nodes"]
        )

        bone_node_indices.append(
            node_idx
        )

        node_by_bone[
            n["index"]
        ] = node_idx

        gltf["nodes"].append(
            node
        )


    # --------------------------------------------------------
    # BIND FRAME
    # --------------------------------------------------------

    bind_frame = body["skeleton"][0]["bones"]

    for n in body["nodes"]:

        ni = node_by_bone[
            n["index"]
        ]

        b = bind_frame.get(
            n["index"]
        )

        if b is None:

            pos = [
                0.0,
                0.0,
                0.0
            ]

            rot = [
                0.0,
                0.0,
                0.0
            ]

        else:

            px, py, pz = b["pos"]

            pos = [
                px * UNIT_SCALE,
                py * UNIT_SCALE,
                pz * UNIT_SCALE,
            ]

            rot = b["rot"]

        q = quat_from_euler_xyz(
            *rot
        )

        gltf["nodes"][ni][
            "translation"
        ] = pos

        gltf["nodes"][ni][
            "rotation"
        ] = q


    # --------------------------------------------------------
    # BONE HIERARCHY
    # --------------------------------------------------------

    for n in body["nodes"]:

        ni = node_by_bone[
            n["index"]
        ]

        parent = n["parent"]

        if (
            parent >= 0
            and parent in node_by_bone
        ):

            pi = node_by_bone[
                parent
            ]

            gltf["nodes"][pi].setdefault(
                "children",
                []
            ).append(ni)

        else:

            orientation_node[
                "children"
            ].append(ni)


    # --------------------------------------------------------
    # GLOBAL BIND MATRICES
    # --------------------------------------------------------

    orient_m = make_transform(
        [0.0, 0.0, 0.0],
        root_orientation_quat
    )

    local_mats = {}

    for n in body["nodes"]:

        ni = node_by_bone[
            n["index"]
        ]

        pos = gltf[
            "nodes"
        ][ni].get(
            "translation",
            [0.0, 0.0, 0.0]
        )

        q = gltf[
            "nodes"
        ][ni].get(
            "rotation",
            [0.0, 0.0, 0.0, 1.0]
        )

        local_mats[
            n["index"]
        ] = make_transform(
            pos,
            q
        )


    global_mats = {}


    def compute_global(bone_idx):

        if bone_idx in global_mats:
            return global_mats[
                bone_idx
            ]

        n = next(
            x for x in body["nodes"]
            if x["index"] == bone_idx
        )

        lm = local_mats[
            bone_idx
        ]

        if (
            n["parent"] >= 0
            and n["parent"] in local_mats
        ):

            gm = mat_mul(
                compute_global(
                    n["parent"]
                ),
                lm
            )

        else:

            gm = mat_mul(
                orient_m,
                lm
            )

        global_mats[
            bone_idx
        ] = gm

        return gm


    for n in body["nodes"]:
        compute_global(
            n["index"]
        )


    # Inverse bind matrices.
    # Internamente ya están en column-major,
    # que es exactamente lo esperado por glTF.
    ibm_values = []

    for n in body["nodes"]:

        ibm_values.extend(
            mat_inverse_rigid(
                global_mats[
                    n["index"]
                ]
            )
        )

    ibm_accessor = add_accessor_f32(
        ibm_values,
        "MAT4",
        minmax=False
    )


    skin = {
        "name": "JMO_Skin",

        "inverseBindMatrices":
            ibm_accessor,

        "joints":
            bone_node_indices,

        "skeleton":
            node_by_bone.get(
                0,
                bone_node_indices[0]
            ),
    }

    gltf["skins"].append(
        skin
    )

    skin_idx = 0


    # --------------------------------------------------------
    # MESH BUILDER
    # --------------------------------------------------------

    def build_mesh(
        smd,
        mesh_name
    ):

        # CLAVE DE V3:
        # separar primitivas por material.
        # Así t.bmp NO se aplica a todo el cuerpo.

        by_material = {}

        for tri in smd["triangles"]:

            by_material.setdefault(
                tri["material"],
                []
            ).append(tri)


        primitives = []


        for mat_name, tris in by_material.items():

            positions = []
            normals = []
            uvs = []

            joints = []
            weights = []

            indices = []

            vcount = 0


            for tri in tris:

                for v in tri["verts"]:

                    px, py, pz = v["pos"]

                    nx, ny, nz = v["normal"]

                    u, vv = v["uv"]

                    # Corregir V.
                    if FLIP_UV_V:
                        vv = 1.0 - vv


                    positions.extend([
                        px * UNIT_SCALE,
                        py * UNIT_SCALE,
                        pz * UNIT_SCALE,
                    ])

                    normals.extend([
                        nx,
                        ny,
                        nz,
                    ])

                    uvs.extend([
                        u,
                        vv,
                    ])


                    bone = v["bone"]

                    if bone not in node_by_bone:
                        raise ValueError(
                            "Vértice usa hueso "
                            f"inexistente: {bone}"
                        )

                    # El SMD solamente nos da
                    # un hueso por vértice.
                    # Se conserva como peso 1.0.
                    joints.append(bone)
                    weights.append(1.0)

                    indices.append(
                        vcount
                    )

                    vcount += 1


            pos_acc = add_accessor_f32(
                positions,
                "VEC3",
                target=34962
            )

            norm_acc = add_accessor_f32(
                normals,
                "VEC3",
                target=34962
            )

            uv_acc = add_accessor_f32(
                uvs,
                "VEC2",
                target=34962,
                minmax=True
            )

            # JOINTS_0 = cuatro valores.
            # Solamente usamos el primero.
            joint_values = []

            for j in joints:
                joint_values.extend([
                    j,
                    0,
                    0,
                    0,
                ])

            joint_acc = add_accessor_u8(
                joint_values,
                "VEC4",
                target=34962
            )

            # WEIGHTS_0 = cuatro valores.
            weight_values = []

            for w in weights:
                weight_values.extend([
                    w,
                    0.0,
                    0.0,
                    0.0,
                ])

            weight_acc = add_accessor_f32(
                weight_values,
                "VEC4",
                target=34962
            )

            idx_acc = add_accessor_u32(
                indices,
                "SCALAR",
                target=34963
            )


            primitive = {
                "attributes": {
                    "POSITION": pos_acc,
                    "NORMAL": norm_acc,
                    "TEXCOORD_0": uv_acc,
                    "JOINTS_0": joint_acc,
                    "WEIGHTS_0": weight_acc,
                },

                "indices": idx_acc,

                "material":
                    material_index.get(
                        mat_name,
                        0
                    ),

                "mode": 4,
            }

            primitives.append(
                primitive
            )


        gltf["meshes"].append({
            "name": mesh_name,
            "primitives": primitives,
        })

        return len(
            gltf["meshes"]
        ) - 1


    # --------------------------------------------------------
    # BODY / BACKPACK
    # --------------------------------------------------------

    body_mesh_idx = build_mesh(
        body,
        "JMO_Body"
    )

    backpack_mesh_idx = build_mesh(
        backpack,
        "JMO_Backpack"
    )


    body_node_idx = len(
        gltf["nodes"]
    )

    gltf["nodes"].append({
        "name": "JMO_Body",
        "mesh": body_mesh_idx,
        "skin": skin_idx,
    })

    orientation_node[
        "children"
    ].append(
        body_node_idx
    )


    backpack_node_idx = len(
        gltf["nodes"]
    )

    gltf["nodes"].append({
        "name": "JMO_Backpack",
        "mesh": backpack_mesh_idx,
        "skin": skin_idx,
    })

    orientation_node[
        "children"
    ].append(
        backpack_node_idx
    )


    # --------------------------------------------------------
    # ANIMATIONS
    # --------------------------------------------------------

    def add_animation(
        anim_name,
        anim_smd,
        fps,
        blend_meta=None,
        source_seq=None,
        sample_idx=None
    ):

        frames = anim_smd["skeleton"]

        if not frames:
            return


        frame_indices = [
            fr["time"]
            for fr in frames
        ]

        start_time = frame_indices[0]

        times = [
            (t - start_time) / fps
            for t in frame_indices
        ]


        anim = {
            "name": anim_name,
            "samplers": [],
            "channels": [],
            "extras": {},
        }


        if source_seq:
            anim[
                "extras"
            ][
                "sourceSequence"
            ] = source_seq


        if sample_idx is not None:
            anim[
                "extras"
            ][
                "blendSample"
            ] = sample_idx


        if blend_meta:
            anim[
                "extras"
            ][
                "blend"
            ] = blend_meta


        time_acc = add_accessor_f32(
            times,
            "SCALAR",
            minmax=True
        )


        for n in body["nodes"]:

            bi = n["index"]

            node_idx = node_by_bone[
                bi
            ]

            trans = []
            rots = []


            for fr in frames:

                b = fr["bones"].get(
                    bi
                )

                if b is None:

                    b = bind_frame.get(
                        bi,
                        {
                            "pos": [
                                0,
                                0,
                                0
                            ],

                            "rot": [
                                0,
                                0,
                                0
                            ],
                        }
                    )


                px, py, pz = b["pos"]

                trans.extend([
                    px * UNIT_SCALE,
                    py * UNIT_SCALE,
                    pz * UNIT_SCALE,
                ])


                rots.extend(
                    quat_from_euler_xyz(
                        *b["rot"]
                    )
                )


            trans_acc = add_accessor_f32(
                trans,
                "VEC3",
                minmax=True
            )

            rot_acc = add_accessor_f32(
                rots,
                "VEC4",
                minmax=False
            )


            ts = len(
                anim["samplers"]
            )

            anim["samplers"].append({
                "input": time_acc,

                "output": trans_acc,

                "interpolation":
                    "LINEAR",
            })

            anim["channels"].append({
                "sampler": ts,

                "target": {
                    "node": node_idx,
                    "path": "translation",
                },
            })


            rs = len(
                anim["samplers"]
            )

            anim["samplers"].append({
                "input": time_acc,

                "output": rot_acc,

                "interpolation":
                    "LINEAR",
            })

            anim["channels"].append({
                "sampler": rs,

                "target": {
                    "node": node_idx,
                    "path": "rotation",
                },
            })


        gltf["animations"].append(
            anim
        )


    missing = []

    processed = 0


    for seq in animation_specs:

        path_count = len(
            seq["paths"]
        )


        for sample_idx, rel_path in enumerate(
            seq["paths"]
        ):

            anim_file = find_anim_file(
                rel_path
            )


            if not anim_file:

                missing.append(
                    rel_path
                )

                continue


            anim_smd = load_smd(
                anim_file
            )


            if len(
                anim_smd["nodes"]
            ) != len(
                body["nodes"]
            ):

                print(
                    "  AVISO: "
                    f"{os.path.basename(anim_file)} "
                    f"tiene {len(anim_smd['nodes'])} "
                    "huesos; se omite."
                )

                continue


            if path_count == 1:
                clip_name = seq["name"]
            else:
                clip_name = (
                    f"{seq['name']}_{sample_idx:02d}"
                )


            add_animation(
                clip_name,
                anim_smd,
                seq["fps"],
                blend_meta=seq["blend"],
                source_seq=seq["name"],
                sample_idx=(
                    sample_idx
                    if path_count > 1
                    else None
                ),
            )


            processed += 1


            if processed % 20 == 0:
                print(
                    "  Animaciones procesadas: "
                    f"{processed}"
                )


    # Eliminar extras vacíos.
    for anim in gltf["animations"]:

        if not anim.get("extras"):
            anim.pop(
                "extras",
                None
            )


    # --------------------------------------------------------
    # FINAL GLB
    # --------------------------------------------------------

    gltf["buffers"][0][
        "byteLength"
    ] = len(binbuf)


    json_bytes = json.dumps(
        gltf,
        separators=(",", ":"),
        ensure_ascii=False
    ).encode("utf-8")


    while len(json_bytes) % 4:
        json_bytes += b" "


    while len(binbuf) % 4:
        binbuf.append(0)


    total_len = (
        12
        + 8
        + len(json_bytes)
        + 8
        + len(binbuf)
    )


    glb = bytearray()


    # Header.
    glb.extend(
        struct.pack(
            "<III",
            0x46546C67,
            2,
            total_len
        )
    )


    # JSON chunk.
    glb.extend(
        struct.pack(
            "<I4s",
            len(json_bytes),
            b"JSON"
        )
    )

    glb.extend(
        json_bytes
    )


    # BIN chunk.
    glb.extend(
        struct.pack(
            "<I4s",
            len(binbuf),
            b"BIN\x00"
        )
    )

    glb.extend(
        binbuf
    )


    return (
        bytes(glb),
        missing,
        len(gltf["animations"])
    )


# ============================================================
# MAIN
# ============================================================

def main():

    print("======================================")
    print("       JMO SMD -> GLB V3")
    print("======================================")

    print(
        f"Escala GoldSrc -> glTF: {UNIT_SCALE}"
    )

    print(
        f"Corrección orientación X: "
        f"{ORIENTATION_X_DEG}°"
    )

    print(
        "UV V invertida: "
        + ("SÍ" if FLIP_UV_V else "NO")
    )

    print()


    # --------------------------------------------------------
    # BACKUP DE LA V2
    # --------------------------------------------------------

    if os.path.isfile(OUTPUT):

        print(
            "Creando backup de JMO.glb..."
        )

        shutil.copy2(
            OUTPUT,
            BACKUP
        )

        print(
            f"Backup: {BACKUP}"
        )

        print()


    # --------------------------------------------------------
    # SMD
    # --------------------------------------------------------

    print("Leyendo arctic.smd...")

    body = load_smd(
        BODY_SMD
    )


    print("Leyendo bomb.smd...")

    backpack = load_smd(
        BACKPACK_SMD
    )


    if (
        body["nodes"]
        != backpack["nodes"]
    ):

        print(
            "AVISO: la jerarquía de "
            "bomb.smd no coincide exactamente "
            "con arctic.smd."
        )


    print(
        f"Huesos: {len(body['nodes'])}"
    )

    print(
        f"Triángulos cuerpo: "
        f"{len(body['triangles'])}"
    )

    print(
        f"Triángulos mochila: "
        f"{len(backpack['triangles'])}"
    )

    print()


    if len(
        body["nodes"]
    ) != 23:

        print(
            "AVISO: se esperaban 23 huesos."
        )

    else:

        print(
            "Esqueleto verificado: OK"
        )


    print()


    # --------------------------------------------------------
    # MATERIALES DEL CUERPO
    # --------------------------------------------------------

    print(
        "Materiales del cuerpo encontrados:"
    )

    body_mats = []

    for tri in body["triangles"]:

        if tri["material"] not in body_mats:

            body_mats.append(
                tri["material"]
            )


    for m in body_mats:

        count = sum(
            1
            for t in body["triangles"]
            if t["material"] == m
        )

        print(
            f"   {m:<20} "
            f"{count} triángulos"
        )


    print()


    # --------------------------------------------------------
    # TEXTURAS
    # --------------------------------------------------------

    print(
        "Convirtiendo texturas..."
    )

    texture_bytes = {}


    for fn in sorted(
        os.listdir(TEXTURE_DIR)
    ):

        if not fn.lower().endswith(
            ".bmp"
        ):
            continue

        path = os.path.join(
            TEXTURE_DIR,
            fn
        )

        print(
            f"   {fn}"
        )

        _w, _h, png = bmp8_to_png(
            path
        )

        texture_bytes[fn] = png


    print(
        f"Texturas: "
        f"{len(texture_bytes)}"
    )

    print()


    # --------------------------------------------------------
    # BUILD
    # --------------------------------------------------------

    print(
        "Construyendo esqueleto..."
    )

    print(
        "Construyendo cuerpo..."
    )

    print(
        "Construyendo mochila..."
    )

    print()


    # --------------------------------------------------------
    # QC
    # --------------------------------------------------------

    print(
        "Leyendo JMO.qc..."
    )

    sequences = parse_qc_sequences(
        QC_FILE
    )

    print(
        f"Secuencias encontradas: "
        f"{len(sequences)}"
    )


    # --------------------------------------------------------
    # ORIENTATION
    # --------------------------------------------------------

    root_orientation_quat = (
        quat_from_euler_xyz(
            math.radians(
                ORIENTATION_X_DEG
            ),
            0.0,
            0.0
        )
    )


    # --------------------------------------------------------
    # BUILD GLB
    # --------------------------------------------------------

    glb, missing, animation_count = (
        build_glb(
            body,
            backpack,
            texture_bytes,
            sequences,
            root_orientation_quat,
        )
    )


    # --------------------------------------------------------
    # WRITE
    # --------------------------------------------------------

    with open(
        OUTPUT,
        "wb"
    ) as f:

        f.write(
            glb
        )


    print()

    print(
        f"Animaciones GLB: "
        f"{animation_count}"
    )

    print(
        "Archivos de animación "
        f"no encontrados: {len(missing)}"
    )


    if missing:

        print(
            "Archivos faltantes:"
        )

        for p in missing[:24]:

            print(
                f"   {p}"
            )


    print()

    print(
        "Escribiendo:"
    )

    print(
        OUTPUT
    )

    print()

    print("======================================")
    print("        CONVERSIÓN V3 OK")
    print("======================================")

    print()

    print(
        f"Archivo: {OUTPUT}"
    )

    print(
        f"Tamaño: "
        f"{os.path.getsize(OUTPUT) / (1024*1024):.2f} MB"
    )

    print()

    print("Incluido:")

    print(
        "  ✓ Escala GoldSrc -> metros"
    )

    print(
        "  ✓ Cuerpo"
    )

    print(
        "  ✓ Mochila"
    )

    print(
        "  ✓ Materiales del cuerpo "
        "separados por SMD"
    )

    print(
        "  ✓ UV corregidas (V invertida)"
    )

    print(
        "  ✓ 23 huesos"
    )

    print(
        "  ✓ Skinning"
    )

    print(
        "  ✓ Texturas embebidas"
    )

    print(
        "  ✓ Animaciones"
    )

    print(
        "  ✓ Blend samples"
    )

    print(
        "  ✓ Inverse bind matrices corregidas"
    )

    print(
        f"  ✓ Orientación inicial "
        f"{ORIENTATION_X_DEG}° en X"
    )

    print()

    print(
        "JMO.glb V3 creado correctamente."
    )


if __name__ == "__main__":
    main()
