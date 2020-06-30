/*
 *******************
 * Global scene settings - attached to root node
 *******************
 */
gtaScnAttrib = attributes gtaScnData
attribID:#(0x5edb9923, 0x5b889f18)
(
	parameters main rollout:params (
		exportdir type:#string ui:edt_txd default:"C:\\"
		baseID type:#integer ui:spn_id default:1000
		sceneName type:#string ui:edt_scn default:"untitled"
	)
	rollout params "GTA Scene" (
		edittext edt_scn "Scene name"
		edittext edt_txd "Export"
		button btn_browse "Browse"
		spinner spn_id "ID" type:#integer range:[0,100000,1000]
		on btn_browse pressed do (
			path = getSavePath()
			if path != undefined do
				exportdir = path
		)
	)
)

-- gta create scene if it doesn't exist yet
fn needSceneAttribs = (
	if(custAttributes.get rootnode gtaScnAttrib) == undefined do
		custAttributes.add rootnode gtaScnAttrib
)

fn openSceneRollout = (
	needSceneAttribs()
	ro = rootnode.gtaScnData.params
	createDialog ro width:400
)






/*
 *******************
 * Object definition - attached to all map objects
 *******************
 */
gtaAttrib = attributes gtaData
attribID:#(0x4ecfe9a2, 0x6db18619)
(
	parameters main rollout:params (
		id type:#integer ui:spn_type default:0
		inst type:#boolean ui:chk_instance default:false
		dist type:#integer ui:spn_dist default:100
		txd type:#string ui:edt_txd default:"CHANGEME"
		flg_road type:#boolean ui:chk_road default:false
		flg_nofade type:#boolean ui:chk_nofade default:false
		flg_blend type:#boolean ui:chk_blend default:false
		flg_additive type:#boolean ui:chk_additive default:false
		flg_tunnel type:#boolean ui:chk_tunnel default:false
		flg_light type:#boolean ui:chk_light default:false
		flg_noz type:#boolean ui:chk_noz default:false
		timed type:#boolean ui:chk_timed default:false
		timeon type:#integer ui:spn_tmon default:0
		timeoff type:#integer ui:spn_tmoff default:23
	)
	 
	rollout params "Gta Object" (
		spinner spn_type "ID" type:#integer range:[0,10000,0]
		checkbox chk_instance "Instance only"
		edittext edt_txd "TXD"
		spinner spn_dist "LOD distance" type:#integer range:[0,10000,100]
		checkbox chk_road "Normal cull"
		checkbox chk_nofade "Do not fade"
		checkbox chk_blend "Draw last"
		checkbox chk_additive "Additive"
		checkbox chk_tunnel "Is Subway"
		checkbox chk_light "Ignore Lighting"
		checkbox chk_noz "No Zbuffer write"
		checkbox chk_timed "Is time object"
		spinner spn_tmon "Time on" type:#integer range:[0,23,0] enabled:false
		spinner spn_tmoff "Time off" type:#integer range:[0,23,23] enabled:false
		
		fn updateUI = (
			edt_txd.enabled = not inst
			edt_txd.enabled = not inst
			spn_dist.enabled = not inst
			chk_road.enabled = not inst
			chk_nofade.enabled = not inst
			chk_blend.enabled = not inst
			chk_additive.enabled = not inst
			chk_tunnel.enabled = not inst
			chk_light.enabled = not inst
			chk_noz.enabled = not inst
			chk_timed.enabled = not inst
			spn_tmon.enabled = not inst and timed
			spn_tmoff.enabled = not inst and timed
		)
		on params open do updateUI()
		on chk_instance changed state do updateUI()
		on chk_timed changed state do updateUI()
		/* little test for separate dialog
		on params open do (
			removeRollout this.params
			createDialog this.params
			updateUI()
		)
		*/
	)
)

mapped fn MakeGtaObject obj = (
	if (custAttributes.get obj gtaAttrib) != undefined do
		return obj
	::RemoveGtaAttribs obj
	custAttributes.add obj gtaAttrib
)






/*
 *******************
 * Collision
 *******************
 */

ADHESIVE_RUBBER = 0
ADHESIVE_HARD = 1
ADHESIVE_ROAD = 2
ADHESIVE_LOOSE = 3
ADHESIVE_SAND = 4
ADHESIVE_WET = 5

struct GtaSurface (
	name, id, adhesion
)

SurfaceDef = #(
GtaSurface name:"DEFAULT" id:0 adhesion:ADHESIVE_ROAD,
GtaSurface name:"TARMAC" id:1 adhesion:ADHESIVE_ROAD,
GtaSurface name:"GRASS" id:2 adhesion:ADHESIVE_LOOSE,
GtaSurface name:"GRAVEL" id:3 adhesion:ADHESIVE_LOOSE,
GtaSurface name:"MUD" id:4 adhesion:ADHESIVE_HARD,
GtaSurface name:"PAVEMENT" id:5 adhesion:ADHESIVE_ROAD,
GtaSurface name:"CAR" id:6 adhesion:ADHESIVE_HARD,
GtaSurface name:"GLASS" id:7 adhesion:ADHESIVE_HARD,
GtaSurface name:"TRANSPARENT_CLOTH" id:8 adhesion:ADHESIVE_HARD,
GtaSurface name:"GARAGE_DOOR" id:9 adhesion:ADHESIVE_HARD,
GtaSurface name:"CAR_PANEL" id:10 adhesion:ADHESIVE_HARD,
GtaSurface name:"THICK_METAL_PLATE" id:11 adhesion:ADHESIVE_HARD,
GtaSurface name:"SCAFFOLD_POLE" id:12 adhesion:ADHESIVE_HARD,
GtaSurface name:"LAMP_POST" id:13 adhesion:ADHESIVE_HARD,
GtaSurface name:"FIRE_HYDRANT" id:14 adhesion:ADHESIVE_HARD,
GtaSurface name:"GIRDER" id:15 adhesion:ADHESIVE_HARD,
GtaSurface name:"METAL_CHAIN_FENCE" id:16 adhesion:ADHESIVE_HARD,
GtaSurface name:"PED" id:17 adhesion:ADHESIVE_ROAD,
GtaSurface name:"SAND" id:18 adhesion:ADHESIVE_SAND,
GtaSurface name:"WATER" id:19 adhesion:ADHESIVE_WET,
GtaSurface name:"WOOD_CRATES" id:20 adhesion:ADHESIVE_ROAD,
GtaSurface name:"WOOD_BENCH" id:21 adhesion:ADHESIVE_ROAD,
GtaSurface name:"WOOD_SOLID" id:22 adhesion:ADHESIVE_ROAD,
GtaSurface name:"RUBBER" id:23 adhesion:ADHESIVE_ROAD,
GtaSurface name:"PLASTIC" id:24 adhesion:ADHESIVE_HARD,
GtaSurface name:"HEDGE" id:25 adhesion:ADHESIVE_LOOSE,
GtaSurface name:"STEEP_CLIFF" id:26 adhesion:ADHESIVE_LOOSE,
GtaSurface name:"CONTAINER" id:27 adhesion:ADHESIVE_HARD,
GtaSurface name:"NEWS_VENDOR" id:28 adhesion:ADHESIVE_HARD,
GtaSurface name:"WHEELBASE" id:29 adhesion:ADHESIVE_ROAD,
GtaSurface name:"CARDBOARDBOX" id:30 adhesion:ADHESIVE_LOOSE,
GtaSurface name:"TRANSPARENT_STONE" id:31 adhesion:ADHESIVE_HARD,
GtaSurface name:"METAL_GATE" id:32 adhesion:ADHESIVE_HARD,
GtaSurface name:"SAND_BEACH" id:33 adhesion:ADHESIVE_SAND,
GtaSurface name:"CONCRETE_BEACH" id:34 adhesion:ADHESIVE_ROAD
)

SurfaceNames = for s in SurfaceDef collect s.name

fn GetSurfaceNum id = (
	i = 1
	for s in SurfaceDef do (
		if s.id == id do
			return i
		i += 1
	)
	0
)

fn GetSurfaceColor surf = (
	basecolor = case SurfaceDef[surf].adhesion of (
		ADHESIVE_RUBBER: (color 255 0 0 255)
		ADHESIVE_HARD: (color 255 255 128 255)
		ADHESIVE_ROAD: (color 128 128 128 255)
		ADHESIVE_LOOSE: (color 0 255 0 255)
		ADHESIVE_SAND: (color 255 128 128 255)
		ADHESIVE_WET: (color 0 0 255 255)
		default: (color 0 0 0 0)
	)
	f = (bit.and SurfaceDef[surf].id 0xF)/32.0 + 0.5
	(color (basecolor.r*f) (basecolor.g*f) (basecolor.b*f) 255)
)

PieceNames = #(
	"DEFAULT",
	"CAR_BONNET",
	"CAR_BOOT",
	"CAR_BUMP_FRONT",
	"CAR_BUMP_REAR",
	"CAR_DOOR_LF",
	"CAR_DOOR_RF",
	"CAR_DOOR_LR",
	"CAR_DOOR_RR",
	"CAR_WING_LF",
	"CAR_WING_RF",
	"CAR_WING_LR",
	"CAR_WING_RR",
	"CAR_WHEEL_LF",
	"CAR_WHEEL_RF",
	"CAR_WHEEL_LR",
	"CAR_WHEEL_RR",
	"CAR_WINDSCREEN"
)

colAttrib = attributes colData
attribID:#(0x19cb2748, 0x358e9f50)
(
	parameters main rollout:params (
		-- indices for dropdown list
		surf_sel type:#integer ui:dd_surf default:1
		piece_sel type:#integer ui:dd_piece default:1
		-- internal indices for exporting
		surf type:#integer default:0
		piece type:#integer default:0

		on surf set s do (
			surf_sel = GetSurfaceNum surf
			obj = refs.dependentnodes (custattributes.getowner this) firstonly:on
			if obj != undefined do
				obj.wirecolor = GetSurfaceColor(surf_sel)
		)
		on surf_sel set s do (
			surf = SurfaceDef[surf_sel].id
			obj = refs.dependentnodes (custattributes.getowner this) firstonly:on
			if obj != undefined do
				obj.wirecolor = GetSurfaceColor(surf_sel)
		)
		on piece set s do (
			piece_sel = piece+1
		)
		on piece_sel set s do (
			piece = piece_sel-1
		)
	)
	 
	rollout params "Gta Collision" (
		dropdownlist dd_surf "Surface Type" items:SurfaceNames
		dropdownlist dd_piece "Piece Type" items:PieceNames
	)
)

-- make an object a collision object
mapped fn MakeColObject obj = (
	obj.material = undefined
	if (custAttributes.get obj colAttrib) != undefined do
		return obj
	case classOf obj of (
	Sphere: obj.name = (uniquename "Collision_Sphere")
	Box: obj.name = (uniquename "Collision_Box")
	Editable_Poly: obj.name = (uniquename "Collision_Mesh")
	Editable_Mesh: obj.name = (uniquename "Collision_Mesh")
	default:
		if superClassOf obj == GeometryClass then
			obj.name = (uniquename "Collision_Mesh")
		else
			return obj
	)
	obj.renderable = false
	::RemoveGtaAttribs obj
	custAttributes.add obj colAttrib
	-- hack to make it update the object color
	-- (node isn't attached yet when events fire on creation)
	obj.surf = obj.surf
)






/*
 *******************
 * Paths
 *******************
 */

plugin Helper PathNode
name:"PathNode"
classID:#(0x616d924, 0x7fe16dd7)
category:"Standard"
extends:point
replaceUI:true
(
	parameters main rollout:params (
		cross type:#boolean ui:chk_cross default:false
		width type:#worldUnits default:10 ui:spn_width
		numIn type:#integer ui:spn_numin default:1
		numOut type:#integer ui:spn_numout default:1

		on cross set s do (
			delegate.box = s
		)
		on width set s do (
			delegate.size = s
		)
	)
	rollout params "Path Node" (
		checkbox chk_cross "Crosses road"
		spinner spn_width "Width" type:#worldUnits  range:[0,1000,0]
		spinner spn_numin "Num lanes in" type:#integer range:[0,10,0]
		spinner spn_numout "Num lanes out" type:#integer range:[0,10,0]
	)
)

fn UpdatePathHierarchy obj color = (
	if (classof obj) == PathNode do (
		obj.showlinks = true
		setUserProp obj "noexport" true
	)
	obj.wirecolor = color
	for c in obj.children do
		UpdatePathHierarchy c color
)

plugin Helper PathSegment
name:"PathSegment"
classID:#(0x1480e93b, 0x21ae98ca)
category:"Standard"
extends:dummy
(
	parameters main rollout:params (
		type type:#integer ui:rad_type default:1

		on type set n do (
			node = refs.dependentnodes this firstonly:on
			if node != undefined do
				case n of (
				1: UpdatePathHierarchy node (color 200 255 0)
				2: UpdatePathHierarchy node (color 255 50 50)
				3: UpdatePathHierarchy node (color 80 80 255)
				)
		)
	)
	fn FilterPathNode obj = (classof obj) == ::PathNode
	rollout Params "Path Segment" (
		--radiobuttons rad_type labels:#("Ped", "Car", "Boat")	-- VC
		radiobuttons rad_type labels:#("Ped", "Car")
		pickbutton pick_node "Add Node" width:140 filter:FilterPathNode

		on pick_node picked obj do
			if obj != undefined do
				::AddPathNodeToSegment obj (refs.dependentnodes this firstonly:on)
	)
	
	tool create (
		on start do
			delegate.boxsize = [4,4,2]
		on mouseMove clickno do
			nodeTM.translation = gridPoint
		on mousePoint clickno do (
			if clickno == 1 then
				nodeTM.translation = gridPoint
			else if clickno == 2 do
				#stop
		)
	)
)

fn AddPathNodeToSegment node seg = (
	while node.parent != undefined and ((classof node.parent) == PathNode) do node = node.parent
	if seg.children.count == 0 do
		seg.transform = node.transform
	node.parent = seg
	seg.type = seg.type	-- force color update
)






/*
 *******************
 * 2D Effects
 *******************
 */

LightTypes = #(
	"ON", "ON_NIGHT",
	"FLICKER", "FLICKER_NIGHT",
	"FLASH1", "FLASH1_NIGHT",
	"FLASH2", "FLASH2_NIGHT",
	"FLASH3", "FLASH3_NIGHT",
	"RANDOM_FLICKER", "RANDOM_FLICKER_NIGHT",
	"BRIDGE_FLASH1", "BRIDGE_FLASH2"
)

ParticleTypes = #(
	"PAVEMENT_STEAM",
	"WALL_STEAM",
	"DRY_ICE",
	"SMALL_FIRE",
	"DARK_SMOKE"
	-- VC: WATER_FOUNTAIN_VERT, WATER_FOUNTAIN_HORIZ
)

AttractorTypes = #(
	"ICECREAM",
	"STARE"
)

effectAttrib = attributes effectData
attribID:#(0xd32b42f, 0x1a9fcbf2)
(
	local updateNode
	parameters main rollout:params (
		effect_color type:#color ui:col_color
		effect_alpha type:#integer ui:spn_alpha default:200

		-- Light data
		lgt_type type:#integer ui:dd_light default: 2
		lgt_coronatex type:#string ui:edt_coronatex default:"coronastar"
		lgt_dist type:#float ui:spn_dist default:100
		lgt_size type:#float ui:spn_size default:1
		lgt_refl type:#boolean ui:chk_refl default:false
		lgt_flare type:#integer ui:dd_flare default:1
		lgt_LOS type:#boolean ui:chk_LOScheck default:false
		lgt_range type:#float ui:spn_range default:0
		lgt_fog type:#boolean ui:chk_fog default:false
		lgt_fogonly type:#boolean ui:chk_fogonly default:false
		lgt_shadtex type:#string ui:edt_shadtex default:"shad_exp"
		lgt_shadsize type:#float ui:spn_shadsize default:0
		lgt_shadintens type:#integer ui:spn_shadintens default:40

		-- Particle data
		part_type type:#integer ui:dd_particle default: 1
		part_speed type:#float ui:spn_partspeed default:0.005
		part_size type:#float ui:spn_partsize default:0.5

		-- Attractor
		attr_type type:#integer ui:dd_attractor default: 2
		attr_prob type:#integer ui:spn_attrprob default:128

		on effect_color set s do (
			updateNode()
		)
	)
	fn updateNode = (
		node = refs.dependentnodes (custattributes.getowner this) firstonly:on
		if node != undefined do (
			if (classof node) == Omnilight then
				node.rgb = effect_color
			--else
			--	node.wirecolor = effect_color
		)
	)
	rollout params "Gta Effect" (
		colorpicker col_color "Color:" color:[0,0,0] modal:false across:2
		spinner spn_alpha "Alpha" type:#integer range:[0,255,200] width:80 offset:[0,2]

		group "Light" (
		dropdownlist dd_light "Light type" items:LightTypes
		)
		group "Corona" (
			edittext edt_coronatex "Sprite"
			spinner spn_dist "Draw distance" type:#float range:[0,10000,100]
			spinner spn_size "Size" type:#float range:[0,10000,1]
			checkbox chk_refl "Road Reflection"
			dropdownlist dd_flare "Flare" items:#("None", "Sun", "Headlights")
			checkbox chk_LOScheck "Light-of-Sight check"
		)
		group "Pointlight" (
			spinner spn_range "Range" type:#float range:[0,10000,0]
			checkbox chk_fog "Fog"
			checkbox chk_fogonly "Fog Only"
		-- VC only
		--checkbox chk_hideobj "Hide Object"
		--checkbox chk_longdist "Long Dist"
		)
		group "Light on ground" (
			edittext edt_shadtex "Sprite"
			spinner spn_shadsize "Size" type:#float range:[0,10000,0]
			spinner spn_shadintens "Intensity" type:#integer range:[0,255,40]
		)
		group "Particle" (
			dropdownlist dd_particle "Particle type" items:ParticleTypes
			spinner spn_partspeed "Speed" type:#float range:[0,100,0.005]
			spinner spn_partsize "Size" type:#float range:[0,100,0.5]
		)

		group "Attractor" (
			dropdownlist dd_attractor "Attractor type" items:AttractorTypes
			spinner spn_attrprob "Probability" type:#integer range:[0,256,128]
		)

		fn updateUI = (
			effect_type = classof (custattributes.getowner this)
			visibility = #(true, effect_type == Omnilight, effect_type == Spray, effect_type == CamPoint)
			StartPos = #(5, 30, 449, 561) -- this is how we start out
			FinalPos = #(5, 30, 30, 30) -- this is how it ends, with some groups hidden
			fn FindUIGroup arr n = (
				grp = 0
				for i = 1 to arr.count do
					if arr[i] <= n do
						grp = i
				return grp
			)
			laststart = undefined
			for c in params.controls do (
				if (classof c) == GroupStartControl do
					laststart = c
				if (classof c) == GroupEndControl then (
					-- group start/end have same position so we can't catch ends with the code below
					c.visible = laststart.visible
					laststart = undefined
				) else (
					i = FindUIGroup StartPos c.pos.y
					c.pos.y += FinalPos[i] - StartPos[i]
					c.visible = visibility[i]
				)
			)
			params.height = 448
		)
		on params open do updateUI()
	)
)


fn MakeEffect obj = (
	custattributes.add obj effectAttrib
	if (classof obj) == Omnilight then
		obj.effect_color = obj.rgb
	else
		obj.effect_color = obj.wirecolor
)

fn ReplaceEffect obj newobj = (
	newobj.transform = obj.transform
	newobj.parent = obj.parent
	newattribs = (copy (custattributes.get obj effectAttrib))
	append newobj.baseobject.custattributes newattribs
	newattribs.effect_color = newattribs.effect_color
	select newobj
	delete obj
)

mapped fn MakeLight obj = (
	if (custattributes.get obj effectAttrib) == undefined then
		MakeEffect obj
	else if (classof obj) != Omnilight then
		ReplaceEffect obj (Omnilight())
)

mapped fn MakeParticle obj = (
	if (custattributes.get obj effectAttrib) == undefined then
		MakeEffect obj
	else if (classof obj) != Spray then
		ReplaceEffect obj (Spray())
)

mapped fn MakeAttractor obj = (
	if (custattributes.get obj effectAttrib) == undefined then
		MakeEffect obj
	else if (classof obj) != CamPoint then
		ReplaceEffect obj (CamPoint())
)




/*
 * Cull/Attrib zones
 */

cullAttrib = attributes cullData
attribID:#(0x3a61afe6, 0x9a8cd0a)
(
	parameters main rollout:params (
		attribsOnly type:#boolean ui:chk_attribs default:false
		stairs type:#boolean ui:chk_stairs default:false
		camCloseIn type:#boolean ui:chk_closein default:false
		cam1stPerson type:#boolean ui:chk_1stprs default:false
		noRain type:#boolean ui:chk_norain default:false
		noPolice type:#boolean ui:chk_nopolice default:false
		needCollision type:#boolean ui:chk_collision default:false
		subwayVisible type:#boolean ui:chk_subway default:false
		wantedDrop type:#integer ui:spn_wanted default:0
	)
	rollout params "Gta Cull/Attrib zone" (
		checkbox chk_attribs "Attribs only"
		checkbox chk_stairs "Stairs cam"
		checkbox chk_closein "Cam close in"
		checkbox chk_1stprs "1st person cam"
		checkbox chk_norain "No Rain"
		checkbox chk_nopolice "No Police"
		checkbox chk_collision "Need collision"
		checkbox chk_subway "Subway visible"
		spinner spn_wanted "Wanted level drop" type:#integer range:[0,100,0] width:100 offset:[55,0]
	)
)

mapped fn MakeCullZone obj = (
	if (custAttributes.get obj cullAttrib) != undefined do
		return obj
	::RemoveGtaAttribs obj
	custAttributes.add obj cullAttrib
)




/*
 * Zones
 */

ZoneTypes = #(
	"DEFAULT",
	"NAVIG",
	"INFO",
	"MAPZONE"
)

LevelNames = #(
	"None",
	"Industrial",
	"Commercial",
	"Suburban"
)

zoneAttrib = attributes zoneData
attribID:#(0x70f03c93, 0x2d6fe377)
(
	local zoneColors = #((color 255 255 64), (color 255 0 0), (color 0 255 0), (color 0 0 255))
	local UpdateColor
	parameters main rollout:params (
		type type:#integer ui:dd_type default:1
		level type:#integer ui:dd_level default:1
		
		on type set s do UpdateColor()
		on level set s do UpdateColor()
	)
	fn UpdateColor = (
		obj = refs.dependentnodes (custattributes.getowner this) firstonly:on
		f = 1.0 - level/float(LevelNames.count)*0.5
		if obj != undefined do
			obj.wirecolor = zoneColors[type]*f
	)
	rollout params "Gta Zone" (
		dropdownlist dd_type "Type" items:ZoneTypes
		dropdownlist dd_level "Level" items:LevelNames
	)
)

mapped fn MakeZone obj = (
	if (custAttributes.get obj zoneAttrib) != undefined do
		return obj
	::RemoveGtaAttribs obj
	custAttributes.add obj zoneAttrib
	-- hack to update color
	obj.type = obj.type
)



mapped fn RemoveGtaAttribs obj = (
	custAttributes.delete obj gtaAttrib
	custAttributes.delete obj colAttrib
	custAttributes.delete obj effectAttrib
	custAttributes.delete obj cullAttrib
	custAttributes.delete obj zoneAttrib
)
