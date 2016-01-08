update specimen_main_geom
set LARVALCATCHPERM2 =0 where VOLUME_FILTERED =0;

update specimen_main_geom
set LARVALCATCHPERM2 = (10*MAX_GEAR_DEPTH/VOLUME_FILTERED)*NUMBER_CAUGHT where VOLUME_FILTERED > 0;

update specimen_main_geom
set LARVALCATCHPERM3 =0 where VOLUME_FILTERED =0;

update specimen_main_geom
set LARVALCATCHPERM3 = (1000 / Volume_Filtered)*NUMBER_CAUGHT where VOLUME_FILTERED > 0;
