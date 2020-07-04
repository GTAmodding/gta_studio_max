--TODO: how do we handle this nicely?
-- This is where DFFs will be imported from.
dffdir = "C:/Users/aap/games/gta3/models/gta3_img/"
-- This is the gta3/data/maps directory
mapdir = "C:/Users/aap/Desktop/gta/gta3_map/"
-- These files will be searched for instances.
-- Make sure Max can find them through user paths -> xrefs
xrefFiles = #(
	"roadpart.max",
	"service.max",
	"barriers.max",
	"shops.max",
	"dynamic.max",
	"vegepart.max",
	"temppart.max",
	"making.max",
	"indroads.max",
	"comroad.max",
	"subroads.max"
)



fn GetLayer name = (
	layer = LayerManager.getLayerFromName name
	if layer == undefined do
		layer = LayerManager.newLayerFromName name
	layer
)

fn rootOf obj = (
	while obj.parent != undefined do obj = obj.parent
	obj
)

-- return the main sub-object. i.e. the single geometry or the _L0 object
fn headOf obj = (
	root = rootOf obj
	if superClassOf root == GeometryClass do
		return root
	for c in root.children do
		if matchPattern c.name pattern:"*_L0" do
			return c
	undefined
)

fn deleteDummies root = (
	for c in root.children do (
		deleteDummies c
		if classOf c == Dummy do
			delete c
	)
)

-- Just import the _L0 object
fn importMapDffSingleObject name = (
	dffImp.prepend = 1
	dffImp.autosmooth = 1
	dffImp.smoothingAngle = 10
	dffImp.convertHierarchy = 1
	clearSelection()
	importFile name #noPrompt using:RenderWare_model
	dffImp.prepend = 0
	selectImportedDff()
	for s in selection do
		s.name = substring s.name 2 -1
	if $selection[1] == undefined then
		return undefined
	x = rootOf $selection[1]
	head = headOf x
	del = for o in $selection where o != head collect o
	delete del
	head.position = [0, 0, 0]
	return head
)

-- Import DFF such that sub-objects are children of a dummy whose xform is that of the head object.
-- That way we can xform the dummy and then delete it.
fn importMapDff name = (
	dffImp.prepend = 1	-- this prepends a ! so names don't clash and are auto-renamed
	dffImp.autosmooth = 1
	dffImp.smoothingAngle = 10
	dffImp.convertHierarchy = 1
	clearSelection()
	importFile name #noPrompt using:RenderWare_model
	dffImp.prepend = 0
	selectImportedDff()
	if selection.count == 0 do (
		format "WARNING: no object '%'\n" name
		return undefined
	)
	for s in selection do
		s.name = substring s.name 2 -1	-- remove prepended !
	x = rootOf $selection[1]
	children = for c in x.children collect c
	head = headOf x
	if head == undefined do (
		-- eek, no geometry found! probably hidden or something when they exported
		-- create a fake geometry and make it so it doesn't export
		head = box length:10 height:10 width:10
		head.wirecolor = (color 255 0 0)
		head.renderable = false
		head.name = x.name
		delete x
		x = head
	)
	-- Fix possibly broken name
	-- TODO: don't force this if it doesn't end in _ or _L
	if (GetSubObjNum head.name) == 0 do
		head.name = (ModelName head.name) + "_L0"
	if classOf x == Dummy do (
		-- This is a group of sub-objects.
		-- Make a new parent dummy
		myname = x.name
		trans = x.transform
		delete x
		x = dummy name:myname
		x.transform = head.transform
		for c in children do
			attachObjects x c move:false
		x.transform = trans
-- 		g = group $selection name:myname
-- 		setGroupOpen g true
-- 		x = rootOf $selection[1]
	)
 	deleteDummies x
	return x
)

-- Place object automatically in absence of proper placement by IPL
fn PlaceObject obj = (
	global lastobj
	obj = rootOf obj
	if lastobj != undefined do (
		obj.pos.y = -obj.min.y + lastobj.max.y + 10
	)
	lastobj = obj
)

/*
 * Path stuff
 */

pathstarted = false
pathseg = undefined
fn StartPath type obj = (
	if pathstarted do
		::FinishPath()
	global pathnodes = #()
	global pathnextId = #()
	global numPathNodes = 0
	global pathseg = PathSegment()
	global pathstarted = true
	pathseg.type = type
	pathseg.Dummy.boxsize = [4,4,2]
	pathseg.parent = obj
	layer = GetLayer "Paths"
	layer.addNode pathseg
)
fn AddPathNode type next cross x y z width nIn nOut = (
	d = PathNode()
	layer = GetLayer "Paths"
	layer.addNode d
	d.cross = cross != 0
	d.width = width/16.0
	d.numIn = nIn
	d.numOut = nOut
	d.pos = [x/16.0, y/16.0, z/16.0]
	d.showlinks = true
	d.wirecolor = (color 255 0 0 255)

	global pathindex
	numPathNodes += 1
	pathnodes[numPathNodes] = d
	pathnextId[numPathNodes] = next
)
fn FinishPath = (
	if not pathstarted do
		return undefined
	for i = 1 to numPathNodes do (
		if pathnextId[i] < 0 do continue
		child = pathnodes[i]
		parent = pathnodes[pathnextId[i]+1]
		if (RootOf child) == (RootOf parent) do (
			-- can't form cycles, make an instance of the parent
			parent = instance parent
			layer = GetLayer "Paths"
			layer.addNode parent
			parent.parent = undefined
			parent.showlinks = true
			parent.wirecolor = (color 255 0 0 255)
			pathnodes[pathnextId[i]+1] = parent
		)
		child.parent = parent
	)
	for i = 1 to numPathNodes do
		if pathnodes[i].parent == undefined do
			AddPathNodeToSegment pathnodes[i] pathseg
	if pathseg.parent != undefined do
		pathseg.transform = pathseg.transform * pathseg.parent.transform
	global pathstarted = false
	global pathseg = undefined
)

fn InitInstance obj id = (
	custAttributes.add obj gtaAttrib
	attribs = custAttributes.get obj gtaAttrib
	attribs.id = id
	attribs.inst = true
)


-- import a definition model and place automatically
fn objsInstLine line = (
	dist = #()
	id = readValue line
	model = trimleft (readDelimitedString line ",")
	texdict = trimleft (readDelimitedString line ",")
	nobj = readValue line
	for i = 1 to nobj do
		dist[i] = readValue line
	flags = readValue line

	inst = importMapDff (dffdir + model + ".dff")
	if inst != undefined do (
		PlaceObject inst
		if classOf inst == Dummy then (
			for c in inst.children do (
				InitInstance c id
				global lastobj = c	-- so PlaceObject doesn't reference a deleted node
			)
			delete inst
		) else
			InitInstance inst id
	)
)

fn FindObjectsWithID id = (
	for o in objects where ((IsMapObj o) and (o.id == id)) collect o
)

fn FindDefinitionsWithID id = (
	for o in objects where ((IsObjectDefinition o) and (o.id == id) and ((GetSubObjNum o.name) == 0)) collect o
)

fn FindDefinitionsWithName name = (
	for o in objects where ((IsObjectDefinition o) and (matchPattern (ModelName o.name) pattern:name) and ((GetSubObjNum o.name) == 0)) collect o
)

fn RemoveDuplicates arr = (
	res = #()
	for e in arr do
		appendIfUnique res e
	res
)

fn DefineObject id model texdict nobj dist flags timeOn timeOff = (
	objs = FindObjectsWithID id
	if objs.count == 0 do (
		format "WARNING: couldn't find object % '%'\n" id model
		return undefined
	)
	uniquenames = RemoveDuplicates (for o in objs collect o.name)
	if nobj != uniquenames.count do (
		format "WARNING: object '%' should have % subobjects but has %. skipping\n" model nobj uniquenames.count
		return undefined
	)
	global FirstID
	if id < FirstID do
		FirstID = id
	for o in objs do (
		n = (GetSubObjNum o.name)+1
		if dist[n] < 0 then (
			-- only one object allowed. make the rest instances
			o.inst = true
		) else (
			o.inst = false
			o.txd = texdict
			o.dist = dist[n]
			setFlags o flags
			dist[n] = -1
			if timeOn < 0 then (
				o.timed = false
			) else (
				o.timed = true
				o.timeon = timeOn
				o.timeoff = timeOff
			)
		)
	)
)

fn objsLine line = (
	dist = #()
	id = readValue line
	model = trimleft (readDelimitedString line ",")
	texdict = trimleft (readDelimitedString line ",")
	nobj = readValue line
	for i = 1 to nobj do
		dist[i] = readValue line
	flags = readValue line
	
	DefineObject id model texdict nobj dist flags -1 -1
)

fn tobjLine line = (
	dist = #()
	id = readValue line
	model = trimleft (readDelimitedString line ",")
	texdict = trimleft (readDelimitedString line ",")
	nobj = readValue line
	for i = 1 to nobj do
		dist[i] = readValue line
	flags = readValue line
	timeOn = readValue line
	timeOff = readValue line

	DefineObject id model texdict nobj dist flags timeOn timeOff
)

pathtype = -1
pathobject = -1
numpathnodelines = 0
fn pathHeaderLine line = (
	type = trimleft (readDelimitedString line ",")
	id = readValue line
	model = trimleft (readDelimitedString line ",")
	if type == "ped" then
		global pathtype = 1
	else if type == "car" then
		global pathtype = 2
	global numpathnodelines = 0
	obj = FindDefinitionsWithID id
	if obj.count == 0 then (
		format "WARNING: couldn't find object % '%'\n" id model
		return undefined
	) else if obj.count > 1 then
		format "WARNING: object % '%' has multiple definitions\n" id model
	StartPath pathtype obj[1]
)
fn pathNodeLine line = (
	global numpathnodes
	type = readValue line
	next = readValue line
	cross = readValue line
	x = readValue line
	y = readValue line
	z = readValue line
	width = readValue line
	numIn = readValue line
	numOut = readValue line
	numpathnodelines += 1
	if (type != 0) and (pathseg != undefined) do (
		AddPathNode type next cross x y z width numIn numOut
	)
	if numpathnodelines == 12 do (
		global pathtype = -1
		FinishPath()
	)
)
fn pathLine line = (
	if pathtype == -1 then
		pathHeaderLine line
	else
		pathNodeLine line
)

fn twodfxLine line = (
	fn stripQuotes str = (
		substituteString str "\"" ""
	)
	id = readValue line
	obj = FindDefinitionsWithID id
	if obj.count == 0 then (
		format "WARNING: couldn't find object %\n" id
		return undefined
	) else if obj.count > 1 then (
		format "WARNING: object % has multiple definitions\n" id
	)
	obj = obj[1]

	layer = GetLayer "2dfx"

	x = readValue line
	y = readValue line
	z = readValue line
	r = readValue line
	g = readValue line
	b = readValue line
	a = readValue line
	type = readValue line
	case type of (
		0:	(-- light	Omni
			fx = omnilight pos:[x, y, z]
			MakeLight fx
			layer.addNode fx
			fx.effect_color = (color r g b)
			fx.effect_alpha = a
			fx.lgt_coronatex = stripQuotes (trimleft (readDelimitedString line ","))
			fx.lgt_shadtex = stripQuotes (trimleft (readDelimitedString line ","))
			fx.lgt_dist = readValue line
			fx.lgt_range = readValue line
			fx.lgt_size = readValue line
			fx.lgt_shadsize = readValue line
			fx.lgt_shadintens = readValue line
			fx.lgt_type = (readValue line) + 1
			fx.lgt_refl = (readValue line) != 0
			fx.lgt_flare = (readValue line) + 1
			flags = readValue line
			if (bit.and flags 1) != 0 do
				fx.lgt_LOS = true
			if (bit.and flags 2) != 0 do
				fx.lgt_fog = true
			if (bit.and flags 4) != 0 do
				fx.lgt_fogonly = true
			fx.transform = fx.transform * obj.transform
			fx.parent = obj
		)
		1:	(-- particle	Spray
			fx = spray pos:[x, y, z]
			fx.emitterwidth = 5
			fx.emitterheight = 5
			MakeParticle fx
			layer.addNode fx
			fx.effect_color = (color r g b)
			fx.effect_alpha = a
			fx.part_type = (readValue line) + 1
			dirx = readValue line
			diry = readValue line
			dirz = readValue line
			dir = [dirx, diry, dirz]
			fx.part_speed = length dir
			dir = normalize dir
			fx.part_size = readValue line
			right = normalize (cross [0,1,0] dir)
			fwd = normalize (cross dir right)
			fx.transform = (Matrix3 right fwd dir fx.pos) * obj.transform
			fx.parent = obj
		)
		2:	(-- attractor	CamPoint
			fx = campoint pos:[x, y, z]
			MakeAttractor fx
			layer.addNode fx
			fx.effect_color = (color r g b)
			fx.effect_alpha = a
			fx.attr_type = (readValue line) + 1
			dirx = readValue line
			diry = readValue line
			dirz = readValue line
			dir = normalize [dirx, diry, dirz]
			fx.attr_prob = readValue line
			right = normalize (cross dir [0,0,1])
			up = normalize (cross right dir)
			fx.transform = (Matrix3 right dir up fx.pos) * obj.transform
			fx.parent = obj
		)
	)
)

-- Attach IDE data to existing map objects
fn readIDE filename = (
	sections = #("objs", "tobj", "path", "2dfx", "end")
	if filename == undefined do
		return 0
	inf = openFile filename
	if inf == undefined do
		return 0
	sect = #end
	global lastobj = undefined
	global FirstID = 100000
	while not eof inf do (
		line = readline inf
		if line == "" or line[1] == "#" do
			continue
		i = findItem sections line
		if i > 0 do (
			sect = sections[i] as name
			global pathtype = -1
-- 			print sect
			continue
		)
--		print line
		case sect of (
		#objs: objsLine (line as stringstream)
 		#tobj: tobjLine (line as stringstream)
 		#path: pathLine (line as stringstream)
 		#2dfx: twodfxLine (line as stringstream)
		)
	)
	close inf
	OK
)

-- Import models in an IDE file for when we don't have an IPL
fn readInstIDE filename = (
	sections = #("objs", "tobj", "path", "2dfx", "end")
	if filename == undefined do
		return 0
	inf = openFile filename
	if inf == undefined do
		return 0
	sect = #end
	global lastobj = undefined
	while not eof inf do (
		line = readline inf
		if line == "" or line[1] == "#" do
			continue
		i = findItem sections line
		if i > 0 do (
			sect = sections[i] as name
-- 			print sect
			continue
		)
--		print line
		case sect of (
		#objs: objsInstLine (line as stringstream)
 		#tobj: objsInstLine (line as stringstream)
-- 		#path: pathLine (line as stringstream) inf
-- 		#2dfx: twodfxLine (line as stringstream)
		)
	)
	close inf
	OK
)



fn instLineDumb line = (
	ln = line as string
	id = readValue line
	model = trimleft (readDelimitedString line ",")
	-- not in III
	--area = readValue line
	x = readValue line
	y = readValue line
	z = readValue line
	pos =  [x, y, z]
	x = readValue line
	y = readValue line
	z = readValue line
	scl = [x, y, z]
	x = readValue line
	y = readValue line
	z = readValue line
	w = readValue line
	rot = conjugate (quat x y z w)
	inst = importMapDffSingleObject (dffdir + model + ".dff")
	if inst != undefined do (
		inst.rotation = rot
		inst.scale = scl
		inst.pos = pos
	)
)

fn instLine line = (
	ln = line as string
	id = readValue line
	model = trimleft (readDelimitedString line ",")
	-- not in III
	--area = readValue line
	x = readValue line
	y = readValue line
	z = readValue line
	pos =  [x, y, z]
	x = readValue line
	y = readValue line
	z = readValue line
	scl = [x, y, z]
	x = readValue line
	y = readValue line
	z = readValue line
	w = readValue line
	rot = (quat x y z -w)
	inst = importMapDff (dffdir + model + ".dff")
	if inst != undefined do (
		inst.rotation = rot
		inst.scale = scl
		inst.pos = pos
		if classOf inst == Dummy then (
			for c in inst.children do
				InitInstance c id
			delete inst
		) else
			InitInstance inst id
	)
)

fn cullLine line = (
	ln = line as string

	posx = readValue line
	posy = readValue line
	posz = readValue line
	minx = readValue line
	miny = readValue line
	minz = readValue line
	maxx = readValue line
	maxy = readValue line
	maxz = readValue line
	flags = readValue line
	wanted = readValue line
	
	width  = maxx-minx
	length = maxy-miny
	height = maxz-minz
	zone = box width:width length:length height:height pos:[minx+width/2, miny+length/2, minz]
	zone.pivot = [posx, posy, posz]
	MakeCullZone zone
	zone.camCloseIn = (bit.and flags 1) != 0
	zone.stairs = (bit.and flags 2) != 0
	zone.cam1stPerson = (bit.and flags 4) != 0
	zone.noRain = (bit.and flags 8) != 0
	zone.noPolice = (bit.and flags 0x10) != 0
	zone.attribsOnly = (bit.and flags 0x20) != 0
	zone.needCollision = (bit.and flags 0x40) != 0
	zone.subwayVisible = (bit.and flags 0x80) != 0
	zone.wantedDrop = wanted
)

fn zoneLine line = (
	ln = line as string

	name = trimleft (readDelimitedString line ",")
	type = readValue line
	minx = readValue line
	miny = readValue line
	minz = readValue line
	maxx = readValue line
	maxy = readValue line
	maxz = readValue line
	level = readValue line
	
	width  = maxx-minx
	length = maxy-miny
	height = maxz-minz
	zone = box width:width length:length height:height pos:[minx+width/2, miny+length/2, minz]
	MakeZone zone
	zone.name = name
	zone.type = type+1
	zone.level = level+1
)

fn readIPLdumb filename = (
	sections = #("inst", "cull", "pick", "end")
	if filename == undefined do
		return 0
	inf = openFile filename
	if inf == undefined do
		return 0
	sect = #end
	global insts = #()
	while not eof inf do (
		line = readline inf
		if line == "" or line[1] == "#" do
			continue
		i = findItem sections line
		if i > 0 do (
			sect = sections[i] as name
			continue
		)
		case sect of (
		#inst: instLineDumb (line as stringstream)
		#cull: cullLine (line as stringstream)
		-- pick ignored, only used on multiplayer maps
		)
	)
	close inf
)

fn readIPL filename = (
	sections = #("inst", "cull", "zone", "pick", "end")
	if filename == undefined do
		return 0
	inf = openFile filename
	if inf == undefined do
		return 0
	sect = #end
	global insts = #()
	while not eof inf do (
		line = readline inf
		if line == "" or line[1] == "#" do
			continue
		i = findItem sections line
		if i > 0 do (
			sect = sections[i] as name
			continue
		)
		case sect of (
		#inst: instLine (line as stringstream)
		#cull: cullLine (line as stringstream)
		#zone: zoneLine (line as stringstream)
		)
	)
	close inf
)



fn GetJunkInstances = (
	junk = #()
	for o in objects do
		if (IsInstance o) and (GetSubObjNum (GetInstanceName o)) != 0 do
			append junk o
	return junk
)

fn PrintXRefScenes = (
	for i = 1 to xrefs.getXRefFileCount() do (
		x = xrefs.getXRefFile i
		print x.filename
		print (getMAXFileObjectNames x.filename)
	)
)

/*
 * Collision
 */

struct ColSphere (
	radius,
	pos,
	surf, piece,

	fn read f = (
		radius = readFloat f
		x = readFloat f
		y = readFloat f
		z = readFloat f
		pos = [x, y, z]
		surf = readByte f
		piece = readByte f
		fseek f 2 #seek_cur
	)
)

struct ColBox (
	v0, v1,
	surf, piece,

	fn read f = (
		x = readFloat f
		y = readFloat f
		z = readFloat f
		v0 = [x, y, z]
		x = readFloat f
		y = readFloat f
		z = readFloat f
		v1 = [x, y, z]
		surf = readByte f
		piece = readByte f
		fseek f 2 #seek_cur
	)
)

struct ColTriangle (
	v0, v1, v2,
	surf,

	fn read f = (
		v0 = readLong f
		v1 = readLong f
		v2 = readLong f
		surf = readByte f
		fseek f 3 #seek_cur
	)
)

fn ReadStringN f n = (
	s = ""
	end = false
	for i = 1 to n do (
		c = readbyte f #unsigned
		if c == undefined do return undefined
		if c == 0 do end = true
		if not end do
			s += bit.intAsChar c
	)
	s
)

-- break up mesh by material id
fn BreakMesh m = (
	faces = #()
	for i = 1 to getNumFaces m do (
		id = getFaceMatID m i
		if faces[id] == undefined then
			faces[id] = #{i}
		else
			append faces[id] i
	)
	for f in faces collect (
		emesh = Editable_Mesh()
		emesh.mesh = meshop.detachFaces m f delete:false asMesh:true
		update emesh
		emesh
	)
)

fn ReadCollisionVolumes f = (
	-- bounding information
	fseek f 40 #seek_cur

	objs = #()

	numSpheres = readLong f
	for i = 1 to numSpheres do (
		sph = ColSphere()
		sph.read f

		colsph = sphere radius:sph.radius pos:sph.pos
		MakeColObject colsph
		colsph.surf = sph.surf
		colsph.piece = sph.piece
		append objs colsph
	)

	-- unused, just ignore
	numLines = readLong f
	fseek f (numLines*24) #seek_cur

	numBoxes = readLong f
	for i = 1 to numBoxes do (
		cbox = ColBox()
		cbox.read f

		w = cbox.v1.x - cbox.v0.x
		l = cbox.v1.y - cbox.v0.y
		h = cbox.v1.z - cbox.v0.z
		x = (cbox.v1.x + cbox.v0.x)/2.0
		y = (cbox.v1.y + cbox.v0.y)/2.0
		colbx = box width:w length:l height:h pos:[x,y,cbox.v0.z]
		MakeColObject colbx
		colbx.surf = cbox.surf
		colbx.piece = cbox.piece
		append objs colbx
	)

	verts = #()
	numVertices = readLong f
	for i = 1 to numVertices do (
		x = readFloat f
		y = readFloat f
		z = readFloat f
		append verts [x, y, z]
	)

	numTriangles = readLong f
	tris = #()
	matids = #()
	mats = #()
	fn getColMat mats m = (
		id = findItem mats m
		if id > 0 do return id
		append mats m
		return mats.count
	)
	for i = 1 to numTriangles do (
		tri = ColTriangle()
		tri.read f
		append tris [tri.v0+1, tri.v2+1, tri.v1+1]
		append matids (getColMat mats tri.surf)
	)
	if numTriangles != 0 do (
		colmesh = mesh vertices:verts faces:tris materialIDs:matids
		for i = 1 to numTriangles do
			setFaceSmoothGroup colmesh i 0
		m = BreakMesh colmesh
		for i = 1 to mats.count do (
			MakeColObject m[i]
			m[i].surf = mats[i]
			m[i].piece = 0
			append objs m[i]
		)
		delete colmesh
	)
	objs
)

fn ReadColFile filename = (
	if filename == undefined do
		return 0
	f = fopen filename "rb"
	while (fcc = ReadStringN f 4) == "COLL" do (
		len = readLong f
		model = ReadStringN f 24
		objs = FindDefinitionsWithName model
		if objs.count == 0 then (
			format "WARNING: couldn't find object '%'\n" model
			fseek f (len-24) #seek_cur
			continue
		) else if objs.count > 1 then (
			format "WARNING: object '%' has multiple definitions\n" model
		)
		obj = objs[1]
		col = ReadCollisionVolumes f
		layer = GetLayer "Collision"
		for c in col do (
			layer.addNode c
			c.parent = obj
			if c.parent != undefined do
				c.transform = c.transform * c.parent.transform
		)
	)
	fclose f
)

fn ReplaceInstsWithXrefs = (
	insts = for o in objects
		where (IsMapObj o) and (classof o != XRefObject) and o.inst and ((GetSubObjNum o.name) == 0)
		collect o
	instNames = for i in insts collect tolower (ModelName i.name)
--	for i = 1 to insts.count do (
--		format "% %\n" instNames[i] (classof insts[i])
--	)
	for xref in xrefFiles do (
		fullpath = xrefPaths.getFullFilePath xref
		objs = getMAXFileObjectNames fullpath
		if objs == undefined do
			continue
		objs = for o in objs where ((GetSubObjNum o) == 0) collect o
		objNames = for o in objs collect tolower (ModelName o)
		for i = 1 to insts.count do (
			-- skip objects we have replaced (deleted) already
			if not (isvalidnode insts[i]) do continue
			j = findItem objNames instNames[i]
			if j == 0 do continue
			--format "found % (%) in %\n" instNames[i] insts[i] xref

			x = xrefs.addNewXRefObject fullpath objs[j] dupMtlNameAction:#autoRename
			x.transform = insts[i].transform
			delete insts[i]
		)
	)
)

fn PopulateLODLayer = (
	layer = GetLayer "LOD"
	for o in $LOD* do
		layer.addNode o
)

fn MakeMaxSceneIPLonly filepath scenename maxpath = (
	format "\tImporting scene %\n" scenename
	gtafile = filepath + scenename
	resetMaxFile #noprompt
	readIPL (gtafile + ".ipl")
	format "\t\timport done\n"
	delete (GetJunkInstances())
	ReplaceInstsWithXrefs()
	format "\t\tXref done\n"
	-- turn off scene lights
	max default lighting toggle
	PopulateLODLayer()
	needSceneAttribs()
	rootnode.sceneName = scenename
	saveMaxFile ("$scenes/" + maxpath + scenename + ".max")
)

fn MakeMaxSceneIPL filepath scenename maxpath = (
	format "\tImporting scene %\n" scenename
	gtafile = filepath + scenename
	resetMaxFile #noprompt
	readIPL (gtafile + ".ipl")
	format "\t\timport done\n"
	readIDE (gtafile + ".ide")
	format "\t\tIDE done\n"
	delete (GetJunkInstances())
	ReadColFile (gtafile + ".col")
	format "\t\tCOL done\n"
	ReplaceInstsWithXrefs()
	format "\t\tXref done\n"
	-- turn off scene lights
	max default lighting toggle
	PopulateLODLayer()
	needSceneAttribs()
	rootnode.sceneName = scenename
	rootnode.baseID = FirstID
	saveMaxFile ("$scenes/" + maxpath + scenename + ".max")
)

fn MakeMaxSceneIDE filepath scenename colfile maxpath = (
	format "\tImporting scene %\n" scenename
	idefile = filepath + scenename + ".ide"
	resetMaxFile #noprompt
	readInstIDE idefile
	format "\t\timport done\n"
	readIDE idefile
	format "\t\tIDE done\n"
	ReadColFile (filepath + colfile + ".col")
	format "\t\tCOL done\n"
	-- turn off scene lights
	max default lighting toggle
	PopulateLODLayer()
	needSceneAttribs()
	rootnode.sceneName = scenename
	rootnode.baseID = FirstID
	saveMaxFile ("$scenes/" + maxpath + scenename + ".max")
)

fn MakeAllMaxScenes = (
	-- These have no IPL and use the same col
	-- All merged into generic.ide in the final game
	MakeMaxSceneIDE (mapdir + "generic/") "barriers" "generic" "gta3/generic/"
	MakeMaxSceneIDE (mapdir + "generic/") "dynamic" "generic" "gta3/generic/"
	MakeMaxSceneIDE (mapdir + "generic/") "roadpart" "generic" "gta3/generic/"
	MakeMaxSceneIDE (mapdir + "generic/") "service" "generic" "gta3/generic/"
	MakeMaxSceneIDE (mapdir + "generic/") "shops" "generic" "gta3/generic/"
	MakeMaxSceneIDE (mapdir + "generic/") "vegepart" "generic" "gta3/generic/"

	-- All the rest has indentically named IDE/IPL/COL
	-- Make sure to create xref'ed scenes before the other
	MakeMaxSceneIPL (mapdir + "temppart/") "temppart" "gta3/industrial/"
	MakeMaxSceneIPL (mapdir + "making/") "making" "gta3/industrial/"
	MakeMaxSceneIPL (mapdir + "indroads/") "indroads" "gta3/industrial/"
	MakeMaxSceneIPL (mapdir + "comroad/") "comroad" "gta3/commercial/"
	MakeMaxSceneIPL (mapdir + "subroads/") "subroads" "gta3/suburban/"

	MakeMaxSceneIPL (mapdir + "industsw/") "industSW" "gta3/industrial/"
	MakeMaxSceneIPL (mapdir + "industse/") "industSE" "gta3/industrial/"
	MakeMaxSceneIPL (mapdir + "industnw/") "industNW" "gta3/industrial/"
	MakeMaxSceneIPL (mapdir + "industne/") "industNE" "gta3/industrial/"

	MakeMaxSceneIPL (mapdir + "comsw/") "comsw" "gta3/commercial/"
	MakeMaxSceneIPL (mapdir + "comse/") "comse" "gta3/commercial/"
	MakeMaxSceneIPL (mapdir + "comnbtm/") "comnbtm" "gta3/commercial/"
	MakeMaxSceneIPL (mapdir + "comntop/") "comntop" "gta3/commercial/"

	MakeMaxSceneIPL (mapdir + "landsw/") "landsw" "gta3/suburban/"
	MakeMaxSceneIPL (mapdir + "landne/") "landne" "gta3/suburban/"

	-- These have no definitions at all
	MakeMaxSceneIPLonly mapdir "overview" "gta3/"
	MakeMaxSceneIPLonly mapdir "props" "gta3/"
)


utility GtaHelper "GTA map importer" (
	edittext dff "DFF path" text:dffdir
	button dffPath "Set DFF path" width:140 align:#center
	--button dumbImport "Dumb IPL import" width:140 align:#center
	button ImportIPL "IPL import" width:140 align:#center
	button ImportIDE "IDE import" width:140 align:#center
	button LoadIDE "Load IDE" width:140 align:#center
	button LoadCOL "Load COL" width:140 align:#center
	button CleanInst "Clean up Instances" width:140 align:#center
	button XrefInst "Turn Instances into Xrefs" width:140 align:#center
	on dffPath pressed do (
		path = getSavePath()
		if path != undefined do
			dff.text = path
	)
	on dumbImport pressed do (
		global dffdir
		dffdir = dff.text
		readIPLdumb (getopenfilename())
	)
	on ImportIPL pressed do (
		global dffdir
		dffdir = dff.text
		readIPL (getopenfilename())
	)
	on ImportIDE pressed do (
		global dffdir
		dffdir = dff.text
		readInstIDE (getopenfilename())
	)
	on LoadIDE pressed do (
		readIDE (getopenfilename())
	)
	on LoadCOL pressed do (
		ReadColFile (getopenfilename())
	)
	on CleanInst pressed do (
		delete (GetJunkInstances())
	)
	on XrefInst pressed do (
		ReplaceInstsWithXrefs()
	)
)

