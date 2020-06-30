macroScript DefObj
	category:"GTA"
	toolTip:"Define map object"
(
	for o in $selection do
		custAttributes.add o gtaAttrib
)

macroScript UndefObj
	category:"GTA"
	toolTip:"Undefine map object"
(
	for o in $selection do
		custAttributes.delete o gtaAttrib
)

macroScript PrintIDE
	category:"GTA"
	toolTip:"Print item defintions"
(
	out = StringStream ""
	printDefinitions out
	format "%" (out as string)
)

macroScript PrintIPL
	category:"GTA"
	toolTip:"Print item placement"
(
	out = StringStream ""
	printInstances out
	format "%" (out as string)
)

macroScript DefColl
	category:"GTA"
	toolTip:"Define collision object"
(
	for o in $selection do
		makeColObject o
)

macroScript UndefColl
	category:"GTA"
	toolTip:"Undefine collision object"
(
	for o in $selection do
		custAttributes.delete o colAttrib
)

macroScript SelectInvalid
	category:"GTA"
	toolTip:"Select invalid map objects"
(
	select (getUndefinedObjs())
)

macroScript CheckIDs
	category:"GTA"
	toolTip:"Check assigned IDs"
(
	checkIDs()
)

macroScript AssignIDs
	category:"GTA"
	toolTip:"Auto-assign IDs"
(
	needSceneAttribs()
	assignIDs rootnode.baseID
)

macroScript SceneProperties
	category:"GTA"
	toolTip:"Show Scene properties"
(
	openSceneRollout()
)

macroScript ExportScene
	category:"GTA"
	toolTip:"Export Scene"
(
	exportScene()
)
