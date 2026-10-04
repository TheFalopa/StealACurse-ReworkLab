"""Fourteen reference-faithful Rare Curse sculpts, Blender Z up / front -Y.

Original geometry for the current rework-04/05/06 sheets. Functions append
closed volumetric shells to the common authoring Builder and return VFX hooks.
No source from the initial imported wave is overwritten.
"""
import math
import bpy
from mathutils import Vector, Matrix, Euler


def move_new(m, first, translation=(0, 0, 0), rotation=(0, 0, 0), scale=(1, 1, 1)):
    rotate = Euler(rotation, "XYZ").to_matrix()
    shift = Vector(translation)
    for index in range(first, len(m.vertices)):
        p = Vector(m.vertices[index])
        p = Vector((p.x * scale[0], p.y * scale[1], p.z * scale[2]))
        m.vertices[index] = tuple(rotate @ p + shift)


def ring_xy(m, center, radius, tube_radius, material, segments=20, sides=6):
    first = len(m.vertices)
    m.ring((0, 0, 0), (radius, radius), tube_radius, material, segments, sides)
    move_new(m, first, center, (math.pi / 2, 0, 0))


def pin(m, center, radius=.10, length=.15, material="gold", direction="front"):
    if direction == "side":
        m.ellipsoid(center, (length, radius, radius), material, 5, 12)
    else:
        m.ellipsoid(center, (radius, length, radius), material, 5, 12)


def swept_shell(m, centers, radii, thickness, outer="bone", inner="bone", sides=32, lobes=8, wobble=.05):
    """Curved hollow horn with actual inner wall and connected annular ends."""
    points = [Vector(p) for p in centers]
    starts = []
    for layer in range(2):
        first = len(m.vertices)
        starts.append(first)
        for level, center in enumerate(points):
            tangent = points[min(level + 1, len(points) - 1)] - points[max(0, level - 1)]
            tangent.normalize()
            guide = Vector((0, 0, 1)) if abs(tangent.z) < .9 else Vector((0, 1, 0))
            axis_a = tangent.cross(guide).normalized()
            axis_b = tangent.cross(axis_a).normalized()
            for spoke in range(sides):
                angle = spoke * math.tau / sides
                lobe = 1 + wobble * math.cos(angle * lobes) * level / max(1, len(points) - 1)
                radius = max(.018, radii[level] * lobe - layer * thickness)
                scallop = .045 * math.cos(angle * lobes) if level == len(points) - 1 else 0
                at = center + radius * (math.cos(angle) * axis_a + math.sin(angle) * axis_b) + tangent * scallop
                m.vertices.append(tuple(at))
        for level in range(len(points) - 1):
            for spoke in range(sides):
                nxt = (spoke + 1) % sides
                face = (first + level * sides + spoke, first + level * sides + nxt,
                        first + (level + 1) * sides + nxt, first + (level + 1) * sides + spoke)
                m.face(face if layer == 0 else tuple(reversed(face)), outer if layer == 0 else inner)
    for end in (0, len(points) - 1):
        for spoke in range(sides):
            nxt = (spoke + 1) % sides
            a = starts[0] + end * sides
            b = starts[1] + end * sides
            face = (a + spoke, b + spoke, b + nxt, a + nxt)
            m.face(face if end == 0 else tuple(reversed(face)), outer)


def petal_volume(m, points, widths, thickness, material, lift=.1):
    """A feather/cloth petal with convex front and concave back, closed edges."""
    first = len(m.vertices)
    for level, ((x, y, z), width) in enumerate(zip(points, widths)):
        bulge = lift * math.sin(math.pi * level / max(1, len(points) - 1))
        m.vertices.extend([(x - width / 2, y, z), (x, y - thickness - bulge, z),
                           (x + width / 2, y, z), (x, y + thickness + bulge * .2, z)])
    m.face((first, first + 3, first + 2, first + 1), material)
    for level in range(len(points) - 1):
        a, b = first + level * 4, first + (level + 1) * 4
        for u, v in ((0, 1), (1, 2), (2, 3), (3, 0)):
            m.face((a + u, a + v, b + v, b + u), material)
    a = first + (len(points) - 1) * 4
    m.face((a, a + 1, a + 2, a + 3), material)


def metadata(profile, hook, reference, design, motion, glow="cyan", **hooks):
    return {"profile": profile, "hook": hook, "reference": "assets/reference/" + reference,
            "design": design, "motion": motion, "glow": glow, "hooks": hooks}


def elliptical_ring(m, center, radii, thickness, material, rotation=(0, 0, 0), segments=24, sides=6):
    first = len(m.vertices)
    m.ring((0, 0, 0), radii, thickness, material, segments, sides)
    move_new(m, first, center, rotation)


def radial_shell(m, center, levels, thickness, material, inner_material=None, sides=24):
    # A genuinely hollow Z-up bowl or bell, both annular ends remain open.
    swept_shell(m, [(center[0], center[1], center[2] + z) for z, radius in levels],
                [radius for z, radius in levels], thickness, material,
                inner_material or material, sides, 0, 0)


def shaped_dice(m, center, size, rotation, pip_faces):
    """Beveled ivory solid with real spherical pip cavities cut into faces."""
    bpy.ops.mesh.primitive_cube_add()
    die = bpy.context.object
    die.scale = (size / 2,) * 3
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = die.modifiers.new('rounded hand worn corners', 'BEVEL')
    bevel.width = size * .085; bevel.segments = 3
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    cavities = []
    radius = size * .092
    for face, pips in pip_faces.items():
        for u, v in pips:
            if face == 'front': at = (u * size, -size * .5 + radius * .32, v * size)
            elif face == 'side': at = (size * .5 - radius * .32, u * size, v * size)
            elif face == 'top': at = (u * size, v * size, size * .5 - radius * .32)
            else: at = (u * size, size * .5 - radius * .32, v * size)
            cavities.append(Vector(at))
            bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, radius=radius, location=at)
            cutter = bpy.context.object
            boolean = die.modifiers.new('carved pip cavity', 'BOOLEAN')
            boolean.operation = 'DIFFERENCE'; boolean.solver = 'EXACT'; boolean.object = cutter
            bpy.context.view_layer.objects.active = die
            bpy.ops.object.modifier_apply(modifier=boolean.name)
            bpy.data.objects.remove(cutter, do_unlink=True)
    first = len(m.vertices)
    rotate = Euler(rotation, 'XYZ').to_matrix()
    for vertex in die.data.vertices:
        m.vertices.append(tuple(rotate @ vertex.co + Vector(center)))
    for polygon in die.data.polygons:
        midpoint = sum((die.data.vertices[i].co for i in polygon.vertices), Vector()) / len(polygon.vertices)
        carved = any(all(radius * .75 < (die.data.vertices[i].co - at).length < radius * 1.02
                         for i in polygon.vertices) for at in cavities)
        m.face(tuple(first + i for i in polygon.vertices), 'ink' if carved else 'bone')
    bpy.data.objects.remove(die, do_unlink=True)


def carve_last_surface(m, first_vertex, first_face, cavities, radius, surface='gold', inset='iron'):
    vertices = m.vertices[first_vertex:]
    faces = [tuple(v - first_vertex for v in face) for face in m.faces[first_face:]]
    del m.vertices[first_vertex:]; del m.faces[first_face:]; del m.face_materials[first_face:]
    mesh = bpy.data.meshes.new('authored curved armor')
    mesh.from_pydata(vertices, [], faces); mesh.update()
    obj = bpy.data.objects.new('authored curved armor', mesh)
    bpy.context.collection.objects.link(obj)
    for at in cavities:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=radius, location=at)
        cutter = bpy.context.object
        boolean = obj.modifiers.new('sunk sewing dimple', 'BOOLEAN')
        boolean.operation = 'DIFFERENCE'; boolean.solver = 'EXACT'; boolean.object = cutter
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=boolean.name)
        bpy.data.objects.remove(cutter, do_unlink=True)
    first = len(m.vertices)
    m.vertices.extend(tuple(vertex.co) for vertex in obj.data.vertices)
    for polygon in obj.data.polygons:
        midpoint = sum((obj.data.vertices[i].co for i in polygon.vertices), Vector()) / len(polygon.vertices)
        carved = any(all(radius * .75 < (obj.data.vertices[i].co - Vector(at)).length < radius * 1.02
                         for i in polygon.vertices) for at in cavities)
        m.face(tuple(first + i for i in polygon.vertices), inset if carved else surface)
    bpy.data.objects.remove(obj, do_unlink=True)


def marrow_dice(m):
    m.begin_part('two rounded ivory dice with carved pip cavities')
    five = [(-.25, -.25), (.25, -.25), (0, 0), (-.25, .25), (.25, .25)]
    four = [(-.24, -.24), (.24, -.24), (-.24, .24), (.24, .24)]
    shaped_dice(m, (-.71, .12, 1.49), 1.65, (.07, -.18, -.10),
                {'front': five, 'side': four, 'top': [(-.25, -.25), (.25, .25)], 'back': [(0, 0)]})
    shaped_dice(m, (.89, -.19, .87), 1.10, (-.04, .18, .09),
                {'front': [(-.21, .17), (.21, .17)], 'side': five, 'top': [(0, 0)], 'back': four})
    m.begin_part('squat articulated appendages and errant ghost pips')
    for at, side in [((-.98, .12, .65), -1), ((-.30, .12, .63), 1), ((.56, -.18, .30), -1), ((1.20, -.18, .30), 1)]:
        x, y, z = at
        m.tube([(x, y, z), (x + side * .14, y - .13, z * .45), (x + side * .19, y - .3, .09)], [.12, .12, .08], 'ink', 8)
        m.ellipsoid((x + side * .19, y - .33, .095), (.23, .21, .085), 'ink', 5, 10)
    for x, y, z, radius in [(-1.57, -.64, 2.42, .12), (-.97, -.77, 2.73, .09), (.44, -.61, 1.94, .10)]:
        m.ellipsoid((x, y, z), (radius, radius, radius), 'cyan', 6, 12)
    return metadata('wandering_dice_pips', (-.97, -.77, 2.73), 'rework-04-rare.png',
        'Paired differently scaled and tilted worn ivory dice; true carved spherical pips on four faces; squat shadow feet.',
        'Three errant cyan pips circle slowly and pause at carved sockets.', diePair=(-.1, -.55, 1.7))


def veil_mourner(m):
    m.begin_part('folded hollow black mourning cloak')
    levels = [(0.32, 1.23, .82), (.70, 1.03, .71), (1.38, .73, .57), (2.13, .51, .44), (2.81, .31, .28), (3.03, .19, .21)]
    segments = 30; starts = []
    for inner in (False, True):
        first = len(m.vertices); starts.append(first)
        for level, (z, rx, ry) in enumerate(levels):
            for spoke in range(segments + 1):
                angle = math.radians(-48 + 276 * spoke / segments)
                fold = 1 + .085 * math.cos(angle * 12 + z * .6)
                rag = .18 * math.sin(spoke * 2.1) + .10 * math.cos(spoke * 1.3) if level == 0 else 0
                m.vertices.append(((rx * fold - .065 * inner) * math.cos(angle),
                    (ry * fold - .065 * inner) * math.sin(angle) + .08, z + rag))
        for level in range(len(levels) - 1):
            for spoke in range(segments):
                a = first + level * (segments + 1) + spoke; b = a + segments + 1
                face = (a, a + 1, b + 1, b)
                m.face(tuple(reversed(face)) if inner else face, 'cloth' if spoke % 4 else 'cloth_edge')
    outer, inner = starts
    for level in (0, len(levels) - 1):
        for spoke in range(segments):
            a = outer + level * (segments + 1) + spoke; b = inner + level * (segments + 1) + spoke
            m.face((a, b, b + 1, a + 1), 'cloth_edge')
    for spoke in (0, segments):
        for level in range(len(levels) - 1):
            a = outer + level * (segments + 1) + spoke; b = inner + level * (segments + 1) + spoke
            m.face((a, a + segments + 1, b + segments + 1, b), 'cloth_edge')
    # A faceless dark presence remains tucked behind the two gathered veil edges.
    m.ellipsoid((0, .16, 2.13), (.40, .36, .54), 'ink', 8, 16)
    m.begin_part('ragged lace hems and pale hands gripping the veil')
    for side in (-1, 1):
        m.tube([(side * .17, -.20, 2.96), (side * .38, -.39, 2.20),
                (side * .66, -.54, 1.33), (side * .88, -.64, .51)], [.034, .044, .04, .047], 'cloth_edge', 6)
        m.ellipsoid((side * .59, -.56, 1.40), (.14, .10, .23), 'bone', 6, 12)
        for finger in range(3):
            x = side * (.55 + finger * .055)
            m.tube([(x, -.64, 1.51), (x + side * .025, -.66, 1.40), (x + side * .018, -.62, 1.32)], [.032] * 3, 'bone', 6)
        for scallop in range(8):
            at = .58 + scallop * .29
            x = side * (.85 - scallop * .083)
            elliptical_ring(m, (x, -.61 + scallop * .043, at), (.05, .083), .012, 'cloth_edge', segments=10, sides=4)
    m.begin_part('aged bone mourning comb')
    m.tube([(-.43, -.05, 2.95), (-.20, -.22, 3.10), (0, -.27, 3.17), (.20, -.22, 3.10), (.43, -.05, 2.95)], [.066] * 5, 'bone', 8)
    for index in range(5):
        x = (index - 2) * .14
        m.tube([(x, -.20, 3.05), (x, -.22, 3.37 + .08 * (2 - abs(index - 2)))], [.035, .022], 'bone', 7)
        m.ellipsoid((x, -.22, 3.36 + .08 * (2 - abs(index - 2))), (.055, .044, .065), 'bone', 5, 8)
    return metadata('black_veil_breath', (0, -.38, 2.19), 'rework-04-rare.png',
        'Volumetric open front cloak with twelve gathered folds, irregular torn hem, hollow dark hood and pale gripping hands; bone mourning comb.',
        'Slow low amplitude cloak breathing and pale dust settling from the bone comb.', 'bone', veilFace=(0, -.38, 2.19))


def grave_compass(m):
    m.begin_part('open verdigris pocket compass with inset dial')
    # Rotate the genuinely concave dial to face forward, keeping its stone depth.
    first = len(m.vertices)
    radial_shell(m, (0, 0, 0), [(0, .95), (.08, 1.11), (.21, 1.18), (.30, 1.10)], .11, 'gold', sides=32)
    move_new(m, first, (.36, -.06, 1.50), (math.pi / 2, .04, -.12))
    m.ellipsoid((.36, .07, 1.50), (1.01, .17, 1.01), 'stone_dark', 7, 32)
    elliptical_ring(m, (.36, -.34, 1.50), (1.11, 1.11), .058, 'gold_edge', segments=32)
    for tick in range(16):
        angle = math.tau * tick / 16
        x, z = .36 + .85 * math.cos(angle), 1.50 + .85 * math.sin(angle)
        m.tube([(x, -.14, z), (.36 + .74 * math.cos(angle), -.18, 1.50 + .74 * math.sin(angle))], [.021] * 2, 'gold', 5)
    for crack in [[(-.24, 2.23), (-.04, 1.94), (.15, 1.91), (.22, 1.73)],
                  [(.87, .82), (.73, 1.15), (.79, 1.31), (.53, 1.44)],
                  [(1.10, 1.81), (.91, 1.64), (.83, 1.67)]]:
        m.tube([(x, -.13, z) for x, z in crack], [.022] * len(crack), 'ink', 5)
    m.begin_part('inward curling needle, open hinged lid and hanging ring')
    m.ellipsoid((.36, -.17, 1.50), (.21, .045, .21), 'ink', 6, 16)
    m.tube([(.89, -.27, 2.12), (.72, -.31, 2.19), (.55, -.34, 2.05), (.52, -.37, 1.83), (.47, -.39, 1.65)],
           [.06, .064, .058, .055, .042], 'gold_edge', 8)
    m.profile([(.38, 1.57), (.62, 1.77), (.52, 1.75), (.46, 1.88)], .07, 'gold_edge', center_y=-.40)
    m.tube([(-.11, -.27, .98), (.14, -.33, 1.12), (.29, -.38, 1.41)], [.037, .042, .035], 'gold', 8)
    # Lid uses a physical shallow shell and engraved rear ornament, angled open.
    first = len(m.vertices)
    radial_shell(m, (0, 0, 0), [(0, .89), (.08, 1.0), (.18, 1.03)], .07, 'gold', sides=28)
    m.ellipsoid((0, 0, .055), (.93, .93, .052), 'green', 5, 24)
    ring_xy(m, (0, 0, .12), .76, .025, 'gold_edge', 24, 5)
    for angle in (0, math.pi / 2, math.pi, math.pi * 1.5):
        m.tube([(0, 0, .14), (.61 * math.cos(angle), .61 * math.sin(angle), .14)], [.025] * 2, 'gold', 5)
    move_new(m, first, (-1.22, .22, 1.55), (math.pi / 2, -.78, .12))
    m.tube([(-.76, -.07, .82), (-.87, -.03, 1.42), (-.76, .02, 2.13)], [.12] * 3, 'gold', 10)
    elliptical_ring(m, (.50, .0, 2.84), (.22, .27), .057, 'gold', segments=20)
    m.bevel_box((.47, .02, 2.60), (.31, .26, .21), 'gold', .045)
    # Verdigris stays on the metal edges, distinct from the cracked stone dial.
    for at in [(-.29, -.25, .87), (1.03, -.25, .96), (1.26, -.21, 1.85)]:
        m.ellipsoid(at, (.10, .025, .06), 'green', 4, 8)
    return metadata('inward_compass_wisp', (.36, -.43, 1.50), 'rework-04-rare.png',
        'Fully open aged brass pocket compass with concave rim, cracked inset stone dial, black central sink, curling inward needle and angled ornate lid.',
        'An inward curling spectral needle trace and a brief cold pulse in the dial sink.', 'cyan', dialCenter=(.36, -.43, 1.50))


def pale_gramophone(m):
    # The case is built as fitted walnut planks with depth, brass corner shoes,
    # a back winding mechanism, actual turntable and a curved hollow bone horn.
    m.begin_part("fitted walnut case and brass furniture")
    m.bevel_box((-.08, .04, 1.0), (2.13, 1.38, .84), "wood", .11)
    for y in (-.675, .755):
        for row in range(3):
            m.bevel_box((-.08 + row * .02, y, .75 + row * .22), (2.08, .09, .20), "wood", .027)
            # Grain is authored as broad asymmetric grooves, not photoreal noise.
            m.tube([(-.93, y - .05, .73 + row * .22), (-.34, y - .055, .77 + row * .22),
                    (.22, y - .04, .74 + row * .22), (.86, y - .045, .79 + row * .22)], [.012] * 4, "ink", 5)
    for x in (-1.05, .89):
        for y in (-.70, .74):
            m.bevel_box((x, y, 1.02), (.16, .18, .83), "gold", .035)
            for z in (.66, 1.38):
                m.bevel_box((x, y, z), (.32, .28, .15), "gold", .045)
                pin(m, (x, y - .09, z), .045, .023)
    for y in (-.72, .76):
        m.bevel_box((-.08, y, 1.46), (2.25, .14, .14), "gold", .03)
    for x in (-1.17, 1.01):
        m.bevel_box((x, .02, 1.46), (.14, 1.56, .14), "gold", .035)
    m.begin_part("grooved record, spindle and turntable")
    m.lathe((-.06, -.02, 1.49), [(0, .83), (.065, .88), (.11, .85)], "ink", 32)
    for radius in (.31, .47, .64, .78):
        ring_xy(m, (-.06, -.02, 1.605), radius, .012, "iron", 30, 4)
    m.lathe((-.06, -.02, 1.61), [(0, .21), (.018, .22), (.04, .20)], "gold", 20)
    m.tube([(-.06, -.02, 1.64), (-.06, -.02, 1.79)], [.045, .033], "gold", 10)
    m.begin_part("four articulated walking feet")
    for side in (-1, 1):
        for back in (-1, 1):
            x, y = side * .82, back * .48
            knee = (side * 1.18, back * .57, .34 + (back == 1) * .08)
            foot = (side * 1.37, back * .65 - .12, .12)
            m.tube([(x, y, .89), (x + side * .12, y, .65), knee, foot], [.20, .18, .17, .12], "wood", 8)
            pin(m, (x, y - .15, .81), .12, .052)
            pin(m, (knee[0], knee[1] - .13, knee[2]), .10, .055)
            m.ellipsoid((foot[0], foot[1] - .07, .115), (.32, .25, .10), "wood", 5, 12)
            m.tube([(foot[0] - .18, foot[1] - .27, .10), (foot[0], foot[1] - .31, .075),
                    (foot[0] + .18, foot[1] - .27, .10)], [.024] * 3, "gold", 5)
    m.begin_part("curved neck and hollow scalloped bone horn")
    m.tube([(-.80, .35, 1.45), (-.85, .36, 1.95), (-.65, .29, 2.34), (-.24, .08, 2.57)], [.12, .13, .15, .17], "gold", 12)
    centers = [(-.24, .08, 2.57), (.01, -.08, 2.65), (.26, -.29, 2.75), (.54, -.51, 2.89), (.87, -.79, 3.05)]
    radii = [.16, .27, .47, .72, 1.05]
    swept_shell(m, centers, radii, .055, "bone", "bone", 40, 8, .07)
    # Eight sculpted ribs follow the horn's inner petal divisions from throat to
    # irregular lip. The cavity remains geometry, never an opaque painted plane.
    mouth_tangent = (Vector(centers[-1]) - Vector(centers[-2])).normalized()
    axis_a = mouth_tangent.cross(Vector((0, 0, 1))).normalized()
    axis_b = mouth_tangent.cross(axis_a).normalized()
    for petal in range(8):
        theta = math.tau * petal / 8
        direction = math.cos(theta) * axis_a + math.sin(theta) * axis_b
        path = [tuple(Vector(at) + (radius - .02) * direction) for at, radius in zip(centers[1:], radii[1:])]
        m.tube(path, [.022, .024, .028, .038], "wax", 6)
    # A bent sound arm and rear crank read from the sides and the rear too.
    m.begin_part("sound arm and rear winding crank")
    m.tube([(.68, .41, 1.48), (.71, .35, 1.78), (.40, .10, 1.84), (.26, -.27, 1.63)], [.065] * 4, "gold", 8)
    m.ellipsoid((.27, -.28, 1.64), (.13, .10, .09), "iron", 5, 12)
    m.tube([(.35, .78, 1.01), (.35, 1.00, 1.02), (.59, 1.01, 1.07)], [.05] * 3, "gold", 8)
    m.ellipsoid((.64, 1.01, 1.07), (.13, .09, .09), "wood", 5, 10)
    return {"profile": "bone_horn_echo", "glow": "bone", "hook": (.83, -.84, 3.00),
            "hooks": {"hornMouth": (.83, -.84, 3.00), "turntable": (-.06, -.02, 1.66)},
            "motion": "restrained horn pulse and musical arc echoes", "reference": "assets/reference/rework-05-rare.png",
            "design": "Curved eight-petal hollow ivory horn; fitted walnut boards, bronze fittings, record grooves and four articulated walking legs."}


def hollow_violin(m):
    m.begin_part('carved walnut violin with genuinely open hollow waist')
    half = [(0, .59), (-.38, .63), (-.61, .78), (-.71, 1.03), (-.67, 1.22),
            (-.47, 1.43), (-.44, 1.60), (-.64, 1.78), (-.67, 2.02), (-.52, 2.20), (-.28, 2.32), (0, 2.36)]
    outline = half + [(-x, z) for x, z in reversed(half[1:-1])]
    interior = [(x * .71, 1.48 + (z - 1.48) * .79) for x, z in outline]
    count = len(outline); first = len(m.vertices)
    for loop, front in [(outline, True), (outline, False), (interior, True), (interior, False)]:
        for x, z in loop:
            y = -.28 - .06 * (1 - abs(x) / .75) if front else .25 + .035 * (1 - abs(x) / .75)
            if loop is interior and not front: y = .12
            m.vertices.append((x, y, z))
    outer_front, outer_back, inner_front, inner_back = [first + count * n for n in range(4)]
    for i in range(count):
        nxt = (i + 1) % count
        m.face((outer_front + i, outer_front + nxt, outer_back + nxt, outer_back + i), 'wood')
        m.face((outer_front + i, inner_front + i, inner_front + nxt, outer_front + nxt), 'wood')
        m.face((inner_front + i, inner_back + i, inner_back + nxt, inner_front + nxt), 'wood')
    m.face(tuple(outer_back + i for i in range(count)), 'wood')
    m.face(tuple(inner_back + i for i in reversed(range(count))), 'wood')
    for y, shape in [(-.36, outline), (.29, outline), (-.36, interior)]:
        m.tube([(x, y, z) for x, z in shape + [shape[0]]], [.025] * (count + 1), 'gold', 5)
    for side in (-1, 1):
        m.tube([(side * .62, -.315, .91), (side * .56, -.33, 1.12), (side * .39, -.34, 1.38)], [.015] * 3, 'ink', 5)
        m.tube([(side * .34, .292, .75), (side * .38, .295, 1.10), (side * .24, .30, 1.37),
                (side * .30, .29, 1.74), (side * .35, .292, 2.12)], [.018] * 5, 'ink', 5)
    m.begin_part('carved neck, curled scroll and tuning pegs')
    m.bevel_box((0, .02, 2.83), (.29, .29, 1.16), 'wood', .055)
    m.bevel_box((0, -.17, 2.78), (.24, .09, 1.13), 'ink', .023)
    scroll = [(0, .02, 3.34), (0, -.01, 3.59), (0, -.19, 3.72), (0, -.39, 3.65),
              (0, -.41, 3.48), (0, -.28, 3.42), (0, -.20, 3.50)]
    m.tube(scroll, [.12, .13, .14, .13, .105, .08, .05], 'wood', 10)
    for side in (-1, 1):
        for z in (3.15, 3.40):
            m.tube([(0, .02, z), (side * .31, .02, z)], [.055, .055], 'wood', 8)
            m.ellipsoid((side * .35, .02, z), (.085, .13, .095), 'wood', 5, 12)
    m.begin_part('three cold strings, bridge and two carved legs')
    m.profile([(-.18, .82), (.18, .82), (.10, 1.21), (-.10, 1.21)], .13, 'ink', center_y=-.42)
    m.profile([(-.27, 1.19), (-.22, 1.39), (.22, 1.39), (.27, 1.19)], .13, 'bone', center_y=-.43)
    for x in (-.095, 0, .095):
        m.tube([(x, -.45, .91), (x, -.52, 1.34), (x, -.24, 2.35), (x, -.23, 3.37)], [.015] * 4, 'cyan', 6)
    for side in (-1, 1):
        m.tube([(side * .34, .04, .72), (side * .41, -.04, .40), (side * .54, -.15, .12)], [.11, .12, .08], 'wood', 8)
        m.ellipsoid((side * .58, -.21, .10), (.25, .29, .095), 'wood', 5, 12)
    return metadata('three_spectral_strings', (0, -.46, 1.87), 'rework-04-rare.png',
        'Carved double-lobed violin body with an actual open waist cavity and intact convex back, inset purfling, curved scroll, tuning pegs and two wooden legs.',
        'Three cyan strings shimmer in turn; sparse notes emerge from the hollow body.', stringBridge=(0, -.54, 1.34))


def chime_triplets(m):
    m.begin_part('crooked blue iron suspension beam')
    beam = [(-1.82, .05, 2.68), (-1.95, .05, 2.93), (-1.79, .05, 3.09),
            (-1.23, .04, 3.06), (-.59, .02, 3.13), (.16, .04, 3.19), (.85, .04, 3.13),
            (1.46, .05, 3.05), (1.78, .05, 2.89), (1.79, .05, 2.68), (1.59, .05, 2.63)]
    m.tube(beam, [.105] * len(beam), 'blue_paint', 8)
    m.begin_part('three different hollow aged bronze bells and imprisoned faces')
    bells = [(-1.10, .81, .43, 'gold'), (0, .55, .55, 'green'), (1.13, .89, .39, 'gold')]
    for index, (x, bottom, radius, key) in enumerate(bells):
        height = 1.04 + .10 * (index == 1)
        radial_shell(m, (x, 0, bottom), [(0, radius), (.10, radius * 1.06), (.24, radius * .84),
                      (.55, radius * .65), (.85, radius * .54), (height, radius * .30)], .048, key, sides=24)
        ring_xy(m, (x, 0, bottom + .07), radius * 1.05, .04, 'gold_edge', 24, 6)
        m.ellipsoid((x, 0, bottom + height), (radius * .32, radius * .32, .09), key, 5, 12)
        elliptical_ring(m, (x, 0, bottom + height + .16), (.12, .16), .036, 'iron_edge', segments=14)
        m.tube([(x, 0, bottom + height + .32), (x + .035, 0, 2.95)], [.035] * 2, 'iron', 7)
        elliptical_ring(m, (x + .02, 0, 2.95), (.12, .13), .027, 'gold', segments=14)
        m.ellipsoid((x, -.05, bottom + .03), (radius * .66, radius * .66, radius * .46), 'ink', 6, 16)
        for side in (-1, 1):
            m.ellipsoid((x + side * radius * .23, -radius * .68, bottom - .01), (.07, .04, .092), 'white_glow', 5, 10)
        for stripe in range(5):
            angle = math.tau * stripe / 5 + index * .3
            m.tube([(x + radius * .57 * math.cos(angle), radius * .57 * math.sin(angle), bottom + .63),
                    (x + radius * .95 * math.cos(angle), radius * .95 * math.sin(angle), bottom + .15)], [.012] * 2, 'gold_edge', 5)
    return metadata('three_bell_spirits', (0, -.1, 1.24), 'rework-04-rare.png',
        'Three distinct open bronze and verdigris bells hang from curled blue iron; true concave interiors contain dark faces and pale eyes.',
        'Bells rock out of phase; small blue vapor spirals rise independently beneath each lip.',
        leftBell=(-1.10, 0, .98), middleBell=(0, 0, .74), rightBell=(1.13, 0, 1.05))


def thimble_spider(m):
    m.begin_part('domed bronze thimble and dimpled armor')
    # The cap is curved and faceted; hand sunk dark dimples follow all sides.
    first_vertex, first_face = len(m.vertices), len(m.faces)
    m.lathe((0, .10, .98), [(0, .74), (.10, .77), (.52, .66), (.91, .51), (1.11, .30), (1.17, .095)], 'gold', 24)
    cavities = []
    for row in range(4):
        z = 1.20 + row * .22
        height = z - .98
        profile = [(.10, .77), (.52, .66), (.91, .51), (1.11, .30)]
        for (lo, left), (hi, right) in zip(profile, profile[1:]):
            if lo <= height <= hi:
                radius = left + (right - left) * (height - lo) / (hi - lo) + .014
                break
        for spoke in range(14 - row * 2):
            angle = math.tau * spoke / (14 - row * 2) + row * .17
            at = (radius * math.cos(angle), .10 + radius * math.sin(angle), z)
            cavities.append(at)
    carve_last_surface(m, first_vertex, first_face, cavities, .058, 'gold', 'iron')
    ring_xy(m, (0, .10, 1.02), .75, .06, 'gold_edge', 24, 6)
    m.begin_part('rounded shadow abdomen, button eyes and needle fangs')
    m.ellipsoid((0, -.05, .91), (.84, .70, .49), 'ink', 7, 16)
    m.ellipsoid((0, -.57, .89), (.56, .34, .37), 'iron', 7, 16)
    for side in (-1, 1):
        pin(m, (side * .23, -.868, .97), .125, .037, 'gold_edge')
        for hole in (-1, 1):
            m.ellipsoid((side * .23 + hole * .037, -.912, .98), (.018, .009, .018), 'ink', 4, 8)
        m.tube([(side * .16, -.82, .74), (side * .18, -.94, .53), (side * .10, -.96, .44)], [.043, .026, .012], 'bone', 7)
    m.begin_part('eight articulated needle legs with brass knees')
    for side in (-1, 1):
        for index in range(4):
            y = -.43 + index * .33
            knee = (side * (1.00 + .11 * math.sin(index)), y - .10, 1.05 - index * .10)
            ankle = (side * (1.30 + .12 * math.sin(index)), y - .32, .18)
            foot = (side * (1.60 + .08 * math.cos(index)), y - .50, .095)
            m.tube([(side * .55, y, .94), knee, ankle, foot], [.10, .092, .056, .022], 'wood', 7)
            m.ellipsoid(knee, (.12, .10, .11), 'gold', 5, 10)
    return metadata('thimble_thread_glints', (0, .1, 1.98), 'rework-05-rare.png',
        'Curved bronze sewing thimble armor with rows of authored sunk dimples, rounded black core, button eyes, paired needle fangs and eight segmented legs.',
        'A loose spectral thread forms briefly between the needle fangs; dimples glint sparingly.', 'bone', fangs=(0, -.95, .53))


def music_box_dancer(m):
    m.begin_part('open walnut music box, fitted walls and bronze corner feet')
    m.bevel_box((0, 0, .52), (1.98, 1.30, .18), 'wood', .065)
    m.bevel_box((0, 0, .635), (1.66, 1.04, .09), 'cloth', .025)
    for y in (-.65, .65):
        m.bevel_box((0, y, .79), (2.0, .16, .53), 'wood', .055)
        m.bevel_box((0, y, 1.065), (2.05, .18, .075), 'gold', .025)
        m.bevel_box((0, y, .53), (2.06, .18, .08), 'gold', .025)
        m.tube([(-.82, y - .10, .79), (-.26, y - .105, .83), (.20, y - .10, .76), (.82, y - .105, .81)], [.012] * 4, 'ink', 5)
    for x in (-.96, .96):
        m.bevel_box((x, 0, .79), (.15, 1.25, .53), 'wood', .05)
        m.bevel_box((x, 0, 1.065), (.19, 1.30, .075), 'gold', .02)
        for y in (-.56, .56):
            m.tube([(x, y, .67), (x * 1.06, y * 1.04, .29), (x * 1.18, y * 1.11, .12)], [.09, .10, .07], 'gold', 8)
            m.ellipsoid((x * 1.18, y * 1.11, .10), (.14, .15, .07), 'gold', 5, 10)
            pin(m, (x, y - .12, .81), .067, .027, 'gold_edge')
    # Winding key is a physically open double loop on the right side.
    m.tube([(.94, .06, .79), (1.35, .06, .79)], [.052] * 2, 'gold', 8)
    elliptical_ring(m, (1.46, .06, .89), (.13, .15), .045, 'gold', (0, 0, math.pi / 2), 16)
    elliptical_ring(m, (1.46, .06, .64), (.13, .15), .045, 'gold', (0, 0, math.pi / 2), 16)
    m.begin_part('raised ornate lid with recessed lining')
    first = len(m.vertices)
    m.bevel_box((0, 0, 0), (2.05, .18, 1.38), 'wood', .085)
    m.bevel_box((0, -.115, 0), (1.74, .045, 1.07), 'cloth', .06)
    for x in (-.94, .94):
        m.bevel_box((x, -.12, 0), (.075, .06, 1.19), 'gold', .024)
    for z in (-.60, .60):
        m.bevel_box((0, -.12, z), (1.94, .06, .075), 'gold', .024)
    for side in (-1, 1):
        m.tube([(side * .77, -.153, -.40), (side * .56, -.16, -.27), (side * .71, -.16, -.05),
                (side * .49, -.16, .17), (side * .71, -.15, .37)], [.022] * 5, 'gold_edge', 5)
    move_new(m, first, (0, .82, 1.65), (-.28, 0, 0))
    m.begin_part('faceless carved wooden ballerina and pleated tutu')
    m.lathe((0, -.13, .76), [(0, .39), (.12, .40), (.17, .33)], 'gold', 20)
    m.tube([(0, -.13, .84), (.04, -.13, 1.33)], [.10, .08], 'gold', 8)
    m.ellipsoid((-.035, -.13, 1.87), (.22, .155, .20), 'wood', 7, 16)
    m.ellipsoid((0, -.13, 2.18), (.19, .14, .35), 'wood', 8, 16)
    m.tube([(0, -.13, 2.45), (0, -.13, 2.68)], [.095, .076], 'wood', 8)
    m.ellipsoid((0, -.13, 2.89), (.19, .155, .245), 'wood', 8, 16)
    m.ellipsoid((.01, .035, 3.04), (.115, .10, .11), 'wood', 6, 12)
    # Fourteen gathered, curved closed petals read as a carved tutu all round.
    for pleat in range(14):
        angle = math.tau * pleat / 14
        first = len(m.vertices)
        petal_volume(m, [(0, 0, 2.00), (0, -.14, 1.82), (0, -.38, 1.71)], [.11, .17, .23], .045,
                     'paper' if pleat % 3 == 0 else 'wood', .035)
        move_new(m, first, (0, -.13, 0), (0, 0, angle))
    arms = [[(-.14, -.13, 2.43), (-.40, -.15, 2.77), (-.29, -.18, 3.16), (-.07, -.18, 3.30)],
            [(.14, -.13, 2.43), (.41, -.16, 2.31), (.43, -.26, 2.05), (.23, -.30, 1.99)]]
    for arm in arms:
        m.tube(arm, [.073, .068, .052, .036], 'wood', 8)
        m.ellipsoid(arm[1], (.078, .075, .078), 'gold', 5, 10)
        m.ellipsoid(arm[-1], (.06, .045, .075), 'wood', 5, 10)
    m.tube([(-.08, -.13, 1.88), (-.06, -.16, 1.45), (0, -.13, 1.10)], [.085, .07, .040], 'wood', 8)
    m.tube([(.08, -.13, 1.89), (.35, -.08, 1.57), (.32, -.15, 1.89)], [.083, .073, .043], 'wood', 8)
    return metadata('wooden_music_box_refrain', (0, -.13, 2.02), 'rework-05-rare.png',
        'An actual open walnut box with raised recessed lid, winding key and four bronze feet; faceless carved wooden ballerina with curved arms, lifted knee and fourteen volumetric skirt pleats.',
        'The dancer turns subtly over the spindle while a sparse bronze musical stave curls from the box.', 'gold', musicMechanism=(0, -.13, 1.08))


def raven_quill(m):
    m.begin_part('layered curved feather body and individual sculpted barbs')
    petal_volume(m, [(-.06, .04, .57), (-.08, .06, 1.03), (0, .11, 1.83),
                    (.16, .16, 2.52), (.20, .18, 3.13), (.13, .20, 3.60)],
                 [.13, .40, .66, .71, .40, .028], .11, 'ink', .19)
    m.tube([(-.06, -.14, .49), (-.04, -.15, 1.16), (.08, -.15, 2.13), (.17, -.02, 3.02), (.13, .14, 3.59)],
           [.04, .045, .04, .03, .01], 'iron_edge', 7)
    for side in (-1, 1):
        for index in range(10):
            z = 1.00 + index * .225
            width = .59 * math.sin(math.pi * (index + 2) / 13)
            root = -.05 + index * .02
            petal_volume(m, [(root, .08, z), (root + side * width * .65, -.04, z + .19),
                            (root + side * width, -.08, z + .46)], [.08, .19, .025], .04,
                         'iron' if index % 3 == 0 else 'ink', .025)
        # Wings are deliberately feather-shaped, layered rather than thin boxes.
        for feather in range(4):
            x = side * (.25 + feather * .10)
            petal_volume(m, [(x, -.10, 2.35 - feather * .05), (side * (.75 + feather * .11), -.14, 1.96 - feather * .03),
                            (side * (.89 + feather * .11), -.22, 1.50 - feather * .035)], [.19, .24, .034], .065, 'ink', .06)
    m.begin_part('pale eye and true divided bronze fountain nib beak')
    m.ellipsoid((.20, -.25, 2.66), (.32, .24, .39), 'ink', 7, 16)
    m.ellipsoid((.32, -.471, 2.76), (.075, .035, .10), 'white_glow', 6, 12)
    # Two solid shaped nib halves preserve the visible central slit.
    m.profile([(.43, 2.61), (.61, 2.56), (.95, 2.35), (.69, 2.47), (.47, 2.48)], .20, 'gold_edge', center_y=-.31)
    m.profile([(.46, 2.45), (.67, 2.43), (.96, 2.33), (.65, 2.33), (.47, 2.36)], .20, 'gold', center_y=-.31)
    elliptical_ring(m, (.55, -.422, 2.51), (.043, .065), .017, 'gold', rotation=(0, .30, 0), segments=14, sides=4)
    m.begin_part('two orange toes and three claws per foot')
    for side in (-1, 1):
        x = side * .16
        m.tube([(x, 0, .72), (x, -.02, .37), (x + side * .06, -.12, .18)], [.055, .05, .033], 'ochre', 7)
        for toe in range(3):
            tx = x + (toe - 1) * .10
            m.tube([(x + side * .06, -.12, .18), (tx, -.37, .10), (tx + .035 * side, -.49, .105)], [.04, .025, .014], 'ochre', 6)
    return metadata('raven_ink_signature', (.84, -.35, 2.38), 'rework-05-rare.png',
        'A curved thick feather made of twenty shaped barbs and two layered wings, ivory eye, bronze fountain nib with separated slit and three-toed orange feet.',
        'One brief fading ink signature trails from the nib; feather tips sway gently.', 'bone', nibTip=(.95, -.31, 2.34))


def sorrow_chalice(m):
    m.begin_part('matte blue chalice, actual hollow bowl and bronze rim')
    m.lathe((0, .05, .10), [(0, .58), (.12, .62), (.22, .48), (.30, .28), (.43, .19)], 'blue_paint', 24)
    m.tube([(0, .05, .42), (-.055, .04, .75), (0, .04, 1.09)], [.18, .125, .17], 'blue_paint', 12)
    radial_shell(m, (0, .04, 1.00), [(0, .20), (.18, .39), (.46, .65), (.73, .82), (.82, .83)], .065, 'blue_paint', sides=32)
    ring_xy(m, (0, .04, 1.83), .83, .036, 'gold', 32, 6)
    ring_xy(m, (0, .05, .23), .56, .028, 'gold', 24, 5)
    for side in (-1, 1):
        m.tube([(side * .66, -.44, 1.72), (side * .49, -.48, 1.46), (side * .32, -.33, 1.29)], [.020] * 3, 'ink', 5)
    for angle in (-math.pi * .72, -math.pi * .50, -math.pi * .28):
        x, y = .70 * math.cos(angle), .04 + .70 * math.sin(angle)
        m.tube([(x, y, 1.75), (x * .85, .04 + (y - .04) * .88, 1.56)], [.025, .031], 'gold', 6)
        m.ellipsoid((x * .85, .04 + (y - .04) * .88, 1.52), (.045, .04, .076), 'gold', 5, 10)
    m.begin_part('curved gray tear spirit with carved dark eyes')
    centers = [(0, -.035, 1.66), (-.03, -.04, 1.91), (0, -.04, 2.19), (.09, -.01, 2.49),
               (.27, .02, 2.76), (.43, .04, 2.93)]
    m.tube(centers, [.12, .39, .42, .28, .12, .017], 'stone_light', 20)
    for side in (-1, 1):
        m.ellipsoid((side * .145, -.443, 2.15), (.050, .027, .077), 'ink', 6, 12)
    for at, radius in [((-.83, -.10, 2.10), .09), ((.80, -.1, 2.38), .07), ((.93, .03, 1.18), .065)]:
        m.ellipsoid(at, (radius, radius, radius * 1.42), 'stone_light', 6, 12)
        m.tube([(at[0], at[1], at[2] + radius), (at[0] + .025, at[1], at[2] + radius * 2.2)], [radius * .46, .012], 'stone_light', 7)
    return metadata('gray_sorrow_tears', (.11, -.07, 2.56), 'rework-05-rare.png',
        'Blue matte chalice with sculpted concave bowl, bronze tear inlays and hairline fractures; bent volumetric gray teardrop ghost with two deep eyes and drifting gray drops.',
        'Gray tears rise slowly and dissolve; blue rim breathes a low intensity cold halo.', 'blue_paint', tearFace=(0, -.45, 2.15), bowlRim=(0, .04, 1.83))


def thorn_reliquary(m):
    m.begin_part('eight sided antique bronze reliquary frame and footed base')
    m.lathe((0, .08, .21), [(0, .82), (.14, .86), (.23, .79), (.31, .73)], 'gold', 8)
    ring_xy(m, (0, .08, .38), .81, .035, 'gold_edge', 8, 5)
    for spoke in range(8):
        angle = math.tau * spoke / 8 + math.pi / 8
        x, y = .73 * math.cos(angle), .08 + .73 * math.sin(angle)
        m.tube([(x, y, .46), (x * 1.055, .08 + (y - .08) * 1.055, 1.55), (x, y, 2.55)], [.04, .038, .04], 'gold', 7)
        m.tube([(x, y, 2.55), (x * .75, .08 + (y - .08) * .75, 2.81), (x * .35, .08 + (y - .08) * .35, 2.99)],
               [.047, .042, .038], 'gold', 7)
        if spoke % 2 == 0:
            m.tube([(x * .82, .08 + (y - .08) * .82, .34), (x * 1.12, .08 + (y - .08) * 1.12, .20),
                    (x * 1.22, .08 + (y - .08) * 1.22, .075)], [.08, .075, .06], 'gold', 7)
    ring_xy(m, (0, .08, 2.56), .735, .055, 'gold', 8, 6)
    m.lathe((0, .08, 2.96), [(0, .27), (.08, .28), (.14, .19)], 'gold', 12)
    elliptical_ring(m, (0, .08, 3.32), (.21, .28), .057, 'gold', segments=20)
    # Sparse thickened glass edge reflections keep the caged thorn visible.
    # The full transparent panes are intentionally a separate Studio VFX layer,
    # since one vertex-painted FBX material cannot express reliable glass alpha.
    m.begin_part('sculpted blue glass edge reflections')
    for side in (-1, 1):
        petal_volume(m, [(side * .64, -.33, .56), (side * .67, -.34, 1.09),
                        (side * .68, -.35, 1.84), (side * .64, -.33, 2.48)], [.038, .055, .055, .025], .010, 'glass', .007)
        m.tube([(side * .65, -.34, .88), (side * .65, -.36, 1.34)], [.012, .014], 'porcelain', 5)
    m.begin_part('curved black thorn entity, forked root feet and pale eyes')
    spine = [(0, .07, .48), (-.21, .03, .83), (-.26, .04, 1.22), (.04, .05, 1.53),
             (.15, .04, 1.94), (-.02, .01, 2.21), (.04, .03, 2.44)]
    m.tube(spine, [.15, .19, .17, .23, .27, .17, .025], 'ink', 14)
    for index in range(6):
        x, y, z = spine[index]
        side = -1 if index % 2 else 1
        m.tube([(x, y, z), (x + side * .24, y - .025, z + .11), (x + side * .35, y - .04, z + .30)], [.075, .045, .013], 'ink', 7)
    for side in (-1, 1):
        m.tube([(0, .06, .55), (side * .27, -.04, .45), (side * .47, -.13, .47)], [.10, .063, .022], 'ink', 8)
        m.ellipsoid((.13 + side * .073, -.219, 1.98), (.037, .024, .055), 'white_glow', 5, 10)
    return metadata('glass_caged_thorn', (.12, -.22, 1.97), 'rework-06-rare.png',
        'Octagonal aged bronze urn with curved roof ribs, ring handle and feet; sculpted blue glass edge reflections preserve full visibility of a volumetric forked black thorn creature.',
        'Studio profile adds eight faint transparent urn panes and a trapped dark vapor curl without obscuring the creature.', 'bone',
        urnCenter=(0, .08, 1.51), thornFace=(.12, -.22, 1.97))


def anchor_crab(m):
    m.begin_part('rounded shadow crab body and upright copper green anchor carapace')
    m.ellipsoid((0, .04, .93), (.77, .52, .40), 'ink', 7, 20)
    m.tube([(0, .09, .85), (.01, .10, 1.50), (.01, .11, 2.24)], [.20, .18, .16], 'verdigris', 12)
    elliptical_ring(m, (.01, .11, 2.59), (.25, .31), .099, 'verdigris', segments=24, sides=8)
    m.tube([(-.63, .12, 2.09), (-.35, .10, 2.17), (.35, .10, 2.16), (.64, .12, 2.08)], [.10] * 4, 'gold', 8)
    for side in (-1, 1):
        m.tube([(0, .1, 1.03), (side * .49, .12, .97), (side * .95, .11, 1.17), (side * 1.12, .10, 1.50)],
               [.18, .18, .145, .075], 'verdigris', 10)
        m.profile([(side * .96, 1.29), (side * 1.12, 1.76), (side * 1.31, 1.37)], .29, 'verdigris', center_y=.10)
        m.tube([(side * 1.06, -.06, 1.45), (side * 1.11, -.07, 1.68)], [.032, .014], 'gold_edge', 6)
        m.ellipsoid((side * .21, -.424, 1.03), (.07, .046, .085), 'white_glow', 6, 12)
    m.begin_part('six articulated copper legs with bronze joints')
    for side in (-1, 1):
        for index in range(3):
            y = -.30 + index * .33
            knee = (side * (1.08 + index * .12), y + .06, .91 - index * .04)
            foot = (side * (1.61 + index * .07), y - .21, .10)
            m.tube([(side * .58, y, .95), knee, (side * (1.41 + index * .06), y - .08, .29), foot], [.11, .09, .065, .028], 'verdigris', 8)
            m.ellipsoid(knee, (.13, .11, .12), 'gold', 5, 12)
    m.begin_part('asymmetric massive right pincer and small left claw')
    for side, large in [(-1, False), (1, True)]:
        length = 1.75 if large else 1.38
        m.tube([(side * .61, -.26, .99), (side * 1.04, -.47, .74), (side * length, -.51, 1.16)], [.16, .17, .22 if large else .13], 'verdigris', 10)
        m.ellipsoid((side * length, -.51, 1.18), (.37 if large else .16, .28 if large else .19, .36 if large else .19), 'verdigris', 7, 16)
        top = [(side * length, -.51, 1.24), (side * (length + .30), -.52, 1.75 if large else 1.52), (side * (length + .58), -.52, 1.67 if large else 1.49),
               (side * (length + .67), -.52, 1.25)]
        bottom = [(side * length, -.52, 1.09), (side * (length + .23), -.52, .97), (side * (length + .51), -.52, 1.01),
                  (side * (length + .65), -.52, 1.14)]
        factor = 1 if large else .63
        m.tube(top, [radius * factor for radius in (.23, .22, .16, .039)], 'verdigris', 10)
        m.tube(bottom, [radius * factor for radius in (.19, .17, .11, .027)], 'gold', 10)
        pin(m, (side * length, -.74, 1.18), .092, .035, 'gold_edge')
    return metadata('rusted_anchor_bubbles', (0, .09, 1.15), 'rework-06-rare.png',
        'Verdigris copper anchor carapace with actual ring eyelet, forked arrow flukes and worn brass crossbar over a dark crab; six jointed legs and a distinctly oversized curved right pincer.',
        'A few cold sinking bubbles and tiny verdigris flakes drift from the anchor eyelet.', 'verdigris', anchorEyelet=(.01, .11, 2.59), largeClaw=(2.04, -.51, 1.39))


def sundial_sentinel(m):
    m.begin_part('carved round ivory stone sundial and radial hour cuts')
    first = len(m.vertices)
    m.lathe((0, 0, 0), [(0, 1.01), (.09, 1.13), (.27, 1.13), (.33, 1.03)], 'stone_light', 32)
    ring_xy(m, (0, 0, .35), 1.06, .035, 'bone', 32, 5)
    for hour in range(12):
        angle = math.tau * hour / 12
        m.tube([(.68 * math.cos(angle), .68 * math.sin(angle), .335), (.96 * math.cos(angle), .96 * math.sin(angle), .34)], [.017] * 2, 'stone_dark', 5)
        m.ellipsoid((.87 * math.cos(angle), .87 * math.sin(angle), .354), (.03, .03, .017), 'gold', 4, 8)
    # Hairline carved faults preserve a stone material rather than flat decals.
    for crack in [[(-.68, -.64), (-.44, -.42), (-.47, -.15), (-.30, .12)],
                  [(.58, .82), (.37, .56), (.48, .29)], [(.83, -.57), (.62, -.42), (.63, -.18)]]:
        m.tube([(x, y, .346) for x, y in crack], [.013] * len(crack), 'stone_dark', 5)
    move_new(m, first, (0, .10, 1.89), (math.pi / 2 - .19, -.08, -.05))
    m.begin_part('projecting bronze gnomon and independent shadow presence')
    m.profile([(.02, 1.58), (.77, 1.90), (.41, 2.60), (.10, 2.04)], .15, 'gold', center_y=-.30)
    m.tube([(.08, -.40, 1.71), (.72, -.40, 1.91), (.42, -.40, 2.53)], [.028] * 3, 'gold_edge', 6)
    # A crooked autonomous shadow volume lifts away from the dial face.
    petal_volume(m, [(-.16, -.29, 1.19), (-.37, -.32, 1.43), (-.41, -.37, 1.79),
                    (-.29, -.41, 2.04), (-.47, -.44, 2.35)], [.20, .31, .34, .21, .026], .055, 'ink', .045)
    for side in (-1, 1):
        m.ellipsoid((-.40 + side * .057, -.477, 1.85), (.027, .020, .043), 'white_glow', 5, 10)
    m.begin_part('two stone legs and brass knee collars')
    for side in (-1, 1):
        knee = (side * .40, .035, .53)
        m.tube([(side * .31, .10, 1.00), knee, (side * .56, -.12, .14)], [.16, .15, .10], 'stone_light', 8)
        ring_xy(m, knee, .154, .031, 'gold', 16, 5)
        m.ellipsoid((side * .59, -.21, .115), (.32, .32, .11), 'stone_light', 6, 12)
    return metadata('autonomous_sundial_shadow', (-.38, -.39, 1.80), 'rework-06-rare.png',
        'Tilted thick stone hour disk with rim, radial cuts, inset bronze dots and fractures; projecting bronze gnomon, an independently bent dark shadow creature and collared stone legs.',
        'The autonomous shadow slips a few degrees independently of the hour markings; a pale rim trace recedes.', 'bone', dialCenter=(0, -.26, 1.89), shadowEyes=(-.40, -.48, 1.85))


def boot_shell(m, levels, key, inner_key='ink', sides=24):
    first = len(m.vertices)
    for z, center_y, rx, ry in levels:
        for spoke in range(sides):
            angle = math.tau * spoke / sides
            m.vertices.append((rx * math.cos(angle), center_y + ry * math.sin(angle), z))
    # The inner cavity begins above the toe box and has a real closed footbed.
    inner_levels = [(levels[3][0], levels[3][1], levels[3][2] - .09, levels[3][3] - .10)] + [
        (z, cy, rx - .07, ry - .07) for z, cy, rx, ry in levels[4:]]
    inside = len(m.vertices)
    for z, center_y, rx, ry in inner_levels:
        for spoke in range(sides):
            angle = math.tau * spoke / sides
            m.vertices.append((rx * math.cos(angle), center_y + ry * math.sin(angle), z))
    for start, sections, material, reverse in [(first, len(levels), key, False), (inside, len(inner_levels), inner_key, True)]:
        for level in range(sections - 1):
            for spoke in range(sides):
                nxt = (spoke + 1) % sides
                a = start + level * sides; b = a + sides
                face = (a + spoke, a + nxt, b + nxt, b + spoke)
                m.face(tuple(reversed(face)) if reverse else face, material)
    outer_top = first + (len(levels) - 1) * sides
    inner_top = inside + (len(inner_levels) - 1) * sides
    for spoke in range(sides):
        nxt = (spoke + 1) % sides
        m.face((outer_top + spoke, inner_top + spoke, inner_top + nxt, outer_top + nxt), 'bone')
    m.face(tuple(first + i for i in reversed(range(sides))), key)
    m.face(tuple(inside + i for i in range(sides)), inner_key)


def sleepwalker_shoes(m):
    m.begin_part('two distinct empty child boots with curved toe boxes and open cuffs')
    for taller, center, rotation in [(True, (-.70, .15, .09), (.03, -.09, -.14)),
                                     (False, (.75, -.40, .25), (.18, .13, .19))]:
        key = 'blue_paint' if taller else 'wood'
        height = 1.96 if taller else 1.30
        first = len(m.vertices)
        levels = [(0, -.28, .47, .81), (.12, -.28, .51, .86), (.32, -.27, .51, .83),
                  (.56, -.01, .45, .58), (.82, .12, .40, .44), (height - .18, .13, .44, .46), (height, .13, .47, .48)]
        boot_shell(m, levels, key)
        m.ellipsoid((0, -.30, .055), (.53, .89, .075), 'iron', 6, 24)
        elliptical_ring(m, (0, -.29, .12), (.51, .86), .033, 'gold', (math.pi / 2, 0, 0), 24, 5)
        elliptical_ring(m, (0, .13, height), (.47, .48), .055, 'bone', (math.pi / 2, 0, 0), 24, 6)
        # Tongue follows the upper foot curvature; stitches wrap the curved toe.
        petal_volume(m, [(0, -.68, .37), (0, -.47, .68), (0, -.35, 1.00), (0, -.36, height - .07)], [.20, .24, .25, .27], .025, key, .026)
        for eyelet in range(4 if taller else 3):
            z = .63 + eyelet * .22
            y = -.51 if eyelet == 0 else -.365
            for side in (-1, 1):
                elliptical_ring(m, (side * .145, y, z), (.032, .036), .013, 'gold', segments=10, sides=4)
            m.tube([(-.13, y - .02, z), (.13, y - .025, z + .18)], [.022] * 2, 'bone', 6)
            m.tube([(.13, y - .02, z), (-.13, y - .025, z + .18)], [.022] * 2, 'bone', 6)
        for side in (-1, 1):
            m.bevel_box((side * .429, .05, .89), (.075, .25, .32), 'gold', .026)
            for z in (.79, .99):
                pin(m, (side * .47, .06, z), .027, .017, 'gold_edge', direction='side')
            m.tube([(side * .31, -.78, .31), (side * .39, -.59, .35), (side * .37, -.34, .45)], [.014] * 3, 'bone', 5)
        m.tube([(-.12, .58, height - .11), (-.12, .66, height + .12), (.12, .66, height + .12), (.12, .58, height - .11)], [.031] * 4, 'bone', 6)
        move_new(m, first, center, rotation)
    return metadata('out_of_step_boot_echoes', (.05, -.35, 1.39), 'rework-06-rare.png',
        'Different tall blue and shorter walnut child boots in staggered walking poses; truly empty open cuffs and footbeds, curved toes, thick soles, crisscross laces, eyelets and bronze patches.',
        'Two pale footstep arcs appear out of phase and dissipate; empty cuffs exhale faint dust.', 'bone', leftCuff=(-.70, .24, 2.08), rightCuff=(.75, -.29, 1.53))


MODELS = {
    'pale_gramophone': pale_gramophone, 'marrow_dice': marrow_dice,
    'veil_mourner': veil_mourner, 'grave_compass': grave_compass,
    'hollow_violin': hollow_violin, 'chime_triplets': chime_triplets,
    'thimble_spider': thimble_spider,
    'music_box_dancer': music_box_dancer, 'raven_quill': raven_quill,
    'sorrow_chalice': sorrow_chalice,
    'thorn_reliquary': thorn_reliquary, 'anchor_crab': anchor_crab,
    'sundial_sentinel': sundial_sentinel, 'sleepwalker_shoes': sleepwalker_shoes,
}
