macroScript DefObj
	category:"GTA"
	toolTip:"Define map object"
(
	::MakeGtaObject $selection
)

macroScript DefColl
	category:"GTA"
	toolTip:"Define collision object"
(
	::MakeColObject $selection
)

macroScript MakeLight
	category:"GTA"
	toolTip:"Define 2dfx light"
(
	::MakeLight $selection
)

macroScript MakeParticle
	category:"GTA"
	toolTip:"Define 2dfx particle"
(
	::MakeParticle $selection
)

macroScript MakeAttractor
	category:"GTA"
	toolTip:"Define 2dfx attractor"
(
	::MakeAttractor $selection
)

macroScript UndefGTA
	category:"GTA"
	toolTip:"Undefine gta object"
(
	::RemoveGtaAttribs $selection
)

macroScript PrintIDE
	category:"GTA"
	toolTip:"Print item defintions"
(
	out = StringStream ""
	::printDefinitions out
	format "%" (out as string)
)

macroScript PrintIPL
	category:"GTA"
	toolTip:"Print item placement"
(
	out = StringStream ""
	::printInstances out
	format "%" (out as string)
)

macroScript PrintZone
	category:"GTA"
	toolTip:"Print zones"
(
	out = StringStream ""
	::printZones out
	format "%" (out as string)
)

macroScript SelectInvalid
	category:"GTA"
	toolTip:"Select invalid map objects"
(
	select (::getUndefinedObjs())
)

macroScript CheckIDs
	category:"GTA"
	toolTip:"Check assigned IDs"
(
	::checkIDs()
)

macroScript AssignIDs
	category:"GTA"
	toolTip:"Auto-assign IDs"
(
	::needSceneAttribs()
	::assignIDs rootnode.baseID
)

macroScript SceneProperties
	category:"GTA"
	toolTip:"Show Scene properties"
(
	::openSceneRollout()
)

macroScript ExportScene
	category:"GTA"
	toolTip:"Export Scene"
(
	::exportScene()
)

macroScript ExportZones
	category:"GTA"
	toolTip:"Export Zones"
(
	filename = getSaveFilename()
	if filename != undefined do
		::saveZone filename
)

macroScript ToggleDefaultLights
	category:"GTA"
	toolTip:"Toggle Default Lights"
(
	max default lighting toggle 
)
