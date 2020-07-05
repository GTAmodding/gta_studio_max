fn rxmatch s pat = (
	rx = dotNetClass "System.Text.RegularExpressions.RegEx"
	(rx.match s pat).success
)

-- get base model name by stripping _L[0-2]
fn ModelName name = (
	-- be careful since imported names might have been truncated
	if rxmatch name "_[Ll][012]$" then
		substring name 1 (name.count-3)
	else if rxmatch name "_[Ll]$" then
		substring name 1 (name.count-2)
	else if rxmatch name "_$" then
		substring name 1 (name.count-1)
	else
		name
)

-- get number of model from _L[0-2] part of name
fn GetSubObjNum name = (
	if rxmatch name "_[Ll][012]$" then
		(substring name name.count -1) as integer
	else
		0
)

-- return argument if _L0 not found
fn GetNthModel obj n = (
	nname = (modelName obj.name) + "_L" + (n as string)
	node = getnodebyname nname
	if node == undefined and n == 0 then obj else node
)

fn getFlags attr = (
	flag = 0
	if attr.flg_road			do flag = bit.or flag 0x01
	if attr.flg_nofade		do flag = bit.or flag 0x02
	if attr.flg_blend		do flag = bit.or flag 0x04
	if attr.flg_additive	do flag = bit.or flag 0x08
	if attr.flg_tunnel		do flag = bit.or flag 0x10
	if attr.flg_light			do flag = bit.or flag 0x20
	if attr.flg_noz			do flag = bit.or flag 0x40
	flag as string
)

fn setFlags attr flag = (
	attr.flg_road 		= (bit.and flag 0x01) != 0
	attr.flg_nofade 	= (bit.and flag 0x02) != 0
	attr.flg_blend 		= (bit.and flag 0x04) != 0
	attr.flg_additive 	= (bit.and flag 0x08) != 0
	attr.flg_tunnel 	= (bit.and flag 0x10) != 0
	attr.flg_light 		= (bit.and flag 0x20) != 0
	attr.flg_noz 		= (bit.and flag 0x40) != 0
)

-- This object has map data associated. either in this scene or xref'ed
fn IsMapObj obj = (
	(custAttributes.get obj gtaAttrib) != undefined or
	(classof obj == XRefObject) and ((custAttributes.get (obj.getSrcItem()) gtaAttrib) != undefined)
)

-- This object is defined in this scene
fn IsObjectDefinition obj = (
	(IsMapObj obj) and not ((classof obj == XRefObject) or obj.inst)
)

-- This object is only instanced here but not defined
fn IsInstance obj = (
	(IsMapObj obj) and ((classof obj == XRefObject) or obj.inst )
)

fn IsCullZone obj = (
	(custAttributes.get obj cullAttrib) != undefined
)

fn IsZone obj = (
	(custAttributes.get obj zoneAttrib) != undefined
)

-- Xref'ed objects take their name from the xref scene
fn GetInstanceName inst = (
	if classof inst == XRefObject do
		return inst.objectname
	return inst.name
)

fn FindPathSegments obj = (
	if (classof obj) == PathSegment do
		return #(obj)
	segs = #()
	for c in obj.children do
		segs += FindPathSegments c
	segs
)

fn FirstInstance obj = (
	InstanceMgr.GetInstances obj &is
	is[1]
)

fn NumPathConnections obj = (
	num = (for c in obj.children where (classof c) == PathNode collect c).count
	if (classof obj.parent == PathNode) do num += 1
	num
)

-- PathNodes can be represented by multiple instances to simulate cycles
-- so add their connections
fn NumPathConnectionsInst obj = (
	InstanceMgr.GetInstances obj &insts
	num = 0
	for i in insts do
		num += NumPathConnections i
	num
)

tmppathnodes = #()
fn CollectPathNodes n = (
	appendIfUnique tmppathnodes (FirstInstance n)
	for c in n.children do
		CollectPathNodes c
)

fn MakePathLines seg = (
	obj = seg.parent
	-- TODO: maybe check the whole hierarchy
	if not (IsObjectDefinition obj) do
		return undefined

	global tmppathnodes
	tmppathnodes = #()
	for node in seg.children do CollectPathNodes node
	pathnodes = tmppathnodes
	tmppathnodes = undefined
	if pathnodes.count > 12 do (
		format "Error: more than 12 path nodes on %\n" obj.name
		return undefined
	)
	-- want externals at the end, so separate first
	internals = #()
	externals = #()
	for n in pathnodes do (
		if (NumPathConnectionsInst n) == 1 then
			append externals n
		else
			append internals n
	)
	pathnodes = join internals externals
	-- find what our nodes are linked to
	fn FindParent node = (
		InstanceMgr.GetInstances node &insts
		for i in insts do
			if (classof i.parent) == PathNode do
				return (FirstInstance i.parent)
		undefined
	)
	types = #("ped", "car")
	lines = #()
	ss = stringStream ""
	format "%, %, %" types[seg.type] obj.id (modelName obj.name) to:ss
	append lines (ss as string)
	for n in pathnodes do (
		p = (FindParent n)
		type = if (NumPathConnectionsInst n) == 1 then 1 else 2
		next = (finditem pathnodes (FindParent n))-1
		cross = if n.cross then 1 else 0
		-- TODO: check instance
		pos = in coordsys obj n.position
		x = integer (pos.x*16)
		y = integer (pos.y*16)
		z = integer (pos.z*16)
		width = n.width
		width = integer (width*16)
		ss = stringStream ""
		format "\t%, %, %, %, %, %, %, %, %" type next cross x y z width n.numIn n.numOut to:ss
		append lines (ss as string)
	)
	for i = lines.count to 12 do
		append lines "\t0, -1, 0, 0, 0, 0, 0, 1, 1"
	lines
)
fn PrintPathLines seg = (
	lines = MakePathLines seg
	for l in lines do
		format "%\n" l
)

fn checkIDs = (
	objs = #()
	errorobjs = #()
	for o in objects do
		if IsObjectDefinition o and (GetSubObjNum o.name) == 0 do (
			if o.id > 0 then (
				if objs[o.id] != undefined do (
					format "warning: ID % used by %, last object with this ID %\n" o.id o.name objs[o.id]
					append errorobjs o
				)
				objs[o.id] = o.name
			) else (
				format "warning: object % has ID 0\n" o.name
				append errorobjs o
			)
		)
	if errorobjs.count == 0 then
		format "all fine :)\n"
	else
		select errorobjs
)

-- return objects with ID 0
fn getUndefinedObjs = (
 	for o in objects where (IsObjectDefinition o and o.id == 0 and (GetSubObjNum o.name) == 0) collect o
)

-- assign consecutive IDs to all map objects
fn assignIDs id = (
	for o in objects where IsObjectDefinition o do
		if (GetSubObjNum o.name) == 0 then (
			o.id = id
			id += 1
		) else
			o.id = 0
	format "next ID: %\n" id
)

-- original instance is last in the array
--   removed: III doesn't use instances
-- fn getCanonical obj = (
-- 	InstanceMgr.GetInstances obj &is
-- 	is[is.count]
-- )

fn numAtomics obj = (
	p = obj
	while p.parent != undefined do p = p.parent

	if (superclassof p == GeometryClass) do
		return 1
	n = 0
	for c in p.children where (superclassof c == GeometryClass) do
		n += 1
	n
)

fn numStr num = (
	i = num as integer
	if (i as float) == num then i as string
	else num as string
)

fn makeObjLine obj = (
	ss = stringStream ""
-- 	obj = getCanonical obj
	objs = for o in (for n = 0 to 2 collect GetNthModel obj n) where o != undefined collect o
	format "%, %, %, %, " obj.id (modelname obj.name) obj.txd objs.count to:ss
	for o in objs do
		format "%, " o.dist to:ss
	format "%" (getflags obj) to:ss
	if obj.timed do
		format ", %, %" obj.timeon obj.timeoff to:ss
	ss as string
)

fn make2dfxLines obj = (
	--TODO: maybe go a bit deeper than this...
	effects = for c in obj.children where (custAttributes.get c effectAttrib) != undefined collect c
	lines = #()
	for f in effects do (
		ss = stringStream ""
		pos = in coordsys obj f.position
		format "%, %, %, %, %, %, %, %, " obj.id (numStr pos.x) (numStr pos.y) (numStr pos.z) \
			(integer f.effect_color.red) (integer f.effect_color.green) (integer f.effect_color.blue) (integer f.effect_alpha) to:ss
		case classof f of (
			Omnilight: (
				format "%, \"%\", \"%\", " 0 f.lgt_coronatex f.lgt_shadtex to:ss
				format "%, %, %, %, " (numStr f.lgt_dist) (numStr f.lgt_range) (numStr f.lgt_size) (numStr f.lgt_shadsize) to:ss
				flags = 0
				if f.lgt_LOS do flags += 1
				if f.lgt_fog do flags += 2
				if f.lgt_fogonly do flags += 4
				format "%, %, %, %, %" f.lgt_shadintens (f.lgt_type-1) (if f.lgt_refl then 1 else 0) (f.lgt_flare-1) flags to:ss
			)
			Spray: (
				dir = (in coordsys obj f.transform).row3 * f.part_speed
				format "%, %, %, %, %, %" 1 (f.part_type-1) (numStr dir.x) (numStr dir.y) (numStr dir.z) (numStr f.part_size) to:ss
			)
			CamPoint: (
				dir = (in coordsys obj f.transform).row2
				format "%, %, %, %, %, %" 2 (f.attr_type-1) (numStr dir.x) (numStr dir.y) (numStr dir.z) f.attr_prob to:ss
			)
		)
		append lines (ss as string)
	)
	lines
)

fn makeInstLine inst = (
	if classOf inst == XRefObject then (
		name = inst.objectName
		attr = custAttributes.get (inst.getSrcItem()) gtaAttrib
	) else (
		InstanceMgr.GetInstances inst &is
		name = is[is.count].name
		attr = custAttributes.get inst gtaAttrib
	)
	ss = StringStream ""
	rot = conjugate inst.rotation
	format "%, %, %, %, %, %, %, %, %, %, %, %" \
		attr.id (modelName name) \
		(numStr inst.pos.x) (numStr inst.pos.y) (numStr inst.pos.z) \
		(numStr inst.scale.x) (numStr inst.scale.y) (numStr inst.scale.z) \
		(numStr rot.x) (numStr rot.y) \
		(numStr rot.z) (numStr rot.w) to:ss
	ss as string
)

fn makeCullLine zone = (
	ss = StringStream ""
	inf = zone.min
	sup = zone.max
	pos = zone.pivot
	flags = 0
	if zone.camCloseIn do flags += 1
	if zone.stairs do flags += 2
	if zone.cam1stPerson do flags += 4
	if zone.noRain do flags += 8
	if zone.noPolice do flags += 0x10
	if zone.attribsOnly do flags += 0x20
	if zone.needCollision do flags += 0x40
	if zone.subwayVisible do flags += 0x80
	format "%, %, %, %, %, %, %, %, %, %, %" \
		(numStr pos.x) (numStr pos.y) (numStr pos.z) \
		(numStr inf.x) (numStr inf.y) (numStr inf.z) \
		(numStr sup.x) (numStr sup.y) (numStr sup.z) \
		flags zone.wantedDrop to:ss
	ss as string
)

fn makeZoneLine zone = (
	ss = StringStream ""
	inf = zone.min
	sup = zone.max
	format "%, %, %, %, %, %, %, %, %" \
		zone.name (zone.type-1) \
		inf.x inf.y inf.z \
		sup.x sup.y sup.z \
		(zone.level-1) to:ss
	ss as string
)

fn cmpid o1 o2 = (
	o1.id - o2.id
)

fn printDeflist list out = (
	format "objs\n" to:out
	for obj in list do (
		if not obj.timed do
			format "%\n" (makeObjLine obj) to:out
	)
	format "end\n" to:out
	format "tobj\n" to:out
	for obj in list do (
		if obj.timed do
			format "%\n" (makeObjLine obj) to:out
	)
	format "end\n" to:out
	format "path\n" to:out
	for obj in list do (
		ncar = 0
		nped = 0
		segs = FindPathSegments obj
		for seg in segs do (
			if seg.type == 1 then (
				if nped > 0 do (
					format "WARNING: skipping extra ped paths on object '%'\n" obj.name
					continue
				)
				nped += 1
			) else if seg.type == 2 then (
				if ncar > 0 do (
					format "WARNING: skipping extra car paths on object '%'\n" obj.name
					continue
				)
				ncar += 1
			)
			lines = MakePathLines seg
			if lines != undefined do
				for l in lines do
					format "%\n" l to:out
		)
	)
	format "end\n" to:out
	format "2dfx\n" to:out
	for obj in list do (
		lines = make2dfxLines obj
		for l in lines do
			format "%\n" l to:out
	)
	format "end\n" to:out
	OK
)

fn printDefinitions out = (
	objs = for obj in objects where (IsObjectDefinition obj) and (GetSubObjNum obj.name) == 0 collect obj
	qsort objs cmpid
	printDeflist objs out
)

fn saveIDE filename = (
	out = openFile filename mode:"w"
	if out == undefined do
		return 0
	printDefinitions out
	close out
)
-- filename = getsavefilename()
-- saveIDE filename

fn printInstances out = (
	insts = for inst in objects where (IsMapObj inst) and (GetSubObjNum inst.name) == 0 collect inst
	format "# IPL generated from Max file %\n" maxFileName to:out
	format "inst\n" to:out
	for i in insts do
		format "%\n" (makeInstLine i) to:out
	format "end\n" to:out

	cullzones = for zone in objects where IsCullZone zone collect zone
	format "cull\n" to:out
	for zone in cullzones do
		format "%\n" (makeCullLine zone) to:out
	format "end\n" to:out
	/*
	format "pick\n" to:out
	-- only used in multiplayer maps
	format "end\n" to:out
	*/
	OK
)

fn printZones out = (
	zones = for zone in objects where IsZone zone collect zone
	format "zone\n" to:out
	for zone in zones do
		format "%\n" (makeZoneLine zone) to:out
	format "end\n" to:out
	OK
)

fn saveIPL filename = (
	out = openFile filename mode:"w"
	if out == undefined do
		return 0
	printInstances out
	close out
)

fn saveZone filename = (
	out = openFile filename mode:"w"
	if out == undefined do
		return 0
	printZones out
	close out
)

fn exportScene = (
	if(custAttributes.get rootnode gtaScnAttrib) == undefined do (
		openSceneRollout()
		return 0
	)
	colpath = rootnode.exportdir + "\\col"
	if (makeDir colpath all:true) == false do (
		format "error: cannot create dir %\n" colpath
		return 0
	)
	dffpath = rootnode.exportdir + "\\dff"
	if (makeDir dffpath all:true) == false do (
		format "error: cannot create dir %\n" dffpath
		return 0
	)
	showprompt = true
	tmp = selection as array
	objs = for obj in objects where (IsObjectDefinition obj) and (GetSubObjNum obj.name) == 0 collect obj
	qsort objs cmpid
	for obj in objs do (
		name = modelName obj.name
		models = for o in (for n = 0 to 2 collect GetNthModel obj n) where o != undefined collect o
		nmodels = models.count
		format "exporting: % % %\n" obj.id name nmodels
		-- Collision
		select obj
		exportFile (colpath + "\\" + name + ".col") #noprompt using:GTA_Collision
--  		exportCOL1 (colpath + "\\" + name + ".col") name
 		-- Model
		select obj
		dff = dffpath + "\\" + name + ".dff"
		if nmodels > 1 do
			gr = group models
		if showprompt then
			exportFile dff using:RenderWare_modelExporterPlugin
		else
			exportFile dff #noprompt using:RenderWare_modelExporterPlugin
		if nmodels > 1 do
			ungroup gr
		showprompt = false
	)
	saveIDE (rootnode.exportdir + "\\" + rootnode.sceneName  + ".ide")
	saveIPL (rootnode.exportdir + "\\" + rootnode.sceneName  + ".ipl")
	clearNodeSelection()
	select tmp
)
-- exportScene()