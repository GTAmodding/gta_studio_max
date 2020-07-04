GTA III map tools for 3ds max
=============================

With these scripts you can import a GTA map into 3ds max
and export it again.

How to install
==============

Install my rwio plugin.

`gta_types.ms` defines the basic plugins and custom attributes needed
for the map. Since everything else depends on this, it has to be loaded early
and hence goes into the `plugins` directory.
`gtamap_import.ms` and `gtamap_export.ms` have to be loaded after that
and hence go into `scripts/startup`.

Some commands for exporting are defined in `GTA.mcr`. That file goes
into `AppData/Local/Autodesk/YOURVERSION/enu/UI/usermacros`.
The commands appear in the 'GTA' group and can be put on custom toolbars or
quad menus.


How to import
=============

Before you do anything it is a good idea to set the variables `dffdir` and `mapdir`
at the top of `gtamap_import.ms` to whatever is appropriate on your system (TODO: this could use an improvement)

The basic strategy to import a scene is like this:

  - import all the models from the IPL
  - load the IDE to attach: object definitions, paths, 2dfx
  - delete junk instances (i.e. L1/2 subobjects that are only instances in the scene)
  - load the COL to attach collision
  optional:
  - replace explicit instances with xrefs to the objects in the defining scene

If the scene is a pure xref scene (i.e. it has no instances) and has no IPL,
the models can be imported from the IDE and placed automatically.

If the scene defines no objects (has no IDE) the IDE and COL steps are skipped.

These three cases are encoded in the functions `MakeMaxSceneIPL`, `MakeMaxSceneIDE` and `MakeMaxSceneIPLonly`

If you want to do this manually you can do so in the "GTA map tools" max script utility rollout

Note that for the xref step to work the xref scenes have to be created first and known to the script
by putting them into the `xrefFiles` array at the top of `gtamap_import.ms`. (TODO: this could use an improvement)
The files also have to be findable by max through the xrefs user paths.

The whole procedure of importing the gta3 map is encoded in `MakeAllMaxScenes`.
It will automatically create all necessary max files for the whole map.

How to export
=============

Use the `SceneProperties` macro to set where to export to and the name of the scene.
It will put all dffs and cols into their respective directories and
generate an IDE and IPL pair.

TODO: i should probably put something for that in the maxscript utility rollout.

How to edit the map
===================

TODO: i should probably describe how the thing works in the first place

Supported games
===============

Right now only GTA III is supported.
VC would not require a huge effort to support,
but one would have to think about how to handle
different games in the code.

additional VC features are:

  - boat paths (easy)
  - more pathnode data (easy)
  - detached paths (easy)
  - ped attractor 2dfx (not quite clear to me yet, probably easy)
  - flare 2dfx (easy)
  - instance areas (perhaps with layers?)
  - occluders (easy)

SA support is not really planned, as it would require quite a lot more:

  - lots of 2dfx types
  - binary path compiler
  - DFF chunks: breakables, 2dfx
  - more coll versions
  - ...
  - ...

