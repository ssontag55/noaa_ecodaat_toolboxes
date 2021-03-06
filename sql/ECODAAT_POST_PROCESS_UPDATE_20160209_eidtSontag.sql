// ecodaat_post_process_update.sql provided by ASA 2015 Mar 25.
// Revised by KYB 2015-NOV-05 to correct fished depth math equation to calculate LARVACATCHPER10M2/
/*
NOAA 2013

ECODAAT script

This is to be run anytime there is an update or data loading

This will update all corresponding tables and create linked tables
*/


/*
HAUL UPDATE
*/
update haul set geom = SDO_GEOMETRY(2001, 8307, SDO_POINT_TYPE(lon, lat , NULL), NULL, NULL)
where lon IS NOT NULL;

ALTER TABLE haul
ADD SE_ANNO_CAD_DATA BLOB;
commit;

DELETE FROM USER_SDO_GEOM_METADATA 
  WHERE TABLE_NAME = 'HAUL' AND COLUMN_NAME = 'GEOM' ;

INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID) 
  VALUES ('HAUL', 'GEOM', 
    MDSYS.SDO_DIM_ARRAY 
      (MDSYS.SDO_DIM_ELEMENT('X', -180.000000000, 180.000000000, 0.000000050), 
       MDSYS.SDO_DIM_ELEMENT('Y', -90.000000000, 90.000000000, 0.000000050)  
     ), 
     8307); 

commit;

drop index HAUL_IX_GEOM;
create index HAUL_IX_GEOM on HAUL(geom) indextype is mdsys.spatial_index;

COMMIT;


/*
SEACAT UPDATE
*/
update seacat_ctd set geom = SDO_GEOMETRY(2001, 8307, SDO_POINT_TYPE(lon, lat , NULL), NULL, NULL)
where lon IS NOT NULL;


DELETE FROM USER_SDO_GEOM_METADATA 
  WHERE TABLE_NAME = 'SEACAT_CTD' AND COLUMN_NAME = 'GEOM' ;

INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID) 
  VALUES ('SEACAT_CTD', 'GEOM', 
    MDSYS.SDO_DIM_ARRAY 
      (MDSYS.SDO_DIM_ELEMENT('X', -180.000000000, 180.000000000, 0.000000050), 
       MDSYS.SDO_DIM_ELEMENT('Y', -90.000000000, 90.000000000, 0.000000050)  
     ), 
     8307); 

drop index SEACAT_CTD_IX_GEOM;
create index SEACAT_CTD_IX_GEOM on SEACAT_CTD(geom) indextype is mdsys.spatial_index;

COMMIT;


/* haul - sample relationship Updator */
drop view haul_gear_view;
create view haul_gear_view as select a.gear_id, a.foci_gear_id, a.gear_code, a.gear_name, a.mouth_area, a.gear_abbrev,a.net_info,a.door_dimensions,a.description,a.purpose_id,b.haul_id,b.cruise,b.h_id,b.alt_station_name,b.haul_name,b.net,b.foci_grid,b.bottom_depth,b.ctd_id,b.haul_performance,b.mesh,b.lat,b.lon,b.purpose,b.primary_net,b.min_gear_depth,b.max_gear_depth,b.min_wire_out,b.max_wire_out,b.tow_minutes,b.tow_seconds,b.volume_filtered,b.wire_angle,b.orig_db,b.door,b.geom,b.door_height,b.door_width,b.diel,b.net_path,b.GEOGRAPHIC_AREA,b.netmouth_height_m,b.sea_surface_temp_c,b.trawl_deployed_lat,b.trawl_deployed_lon,b.water_temp_at_gear_depth,b.gmt_date_time,b.trawl_deployed_gmt,b.trawl_haulback_start_gmt,b.comments_haul,b.flowmeter_revs,b.flowmeter,b.polygonal_area,b.cruise_id,b.station_name,b.lon_end,b.lat_end,b.trawl_haulback_start_lat,b.trawl_haulback_start_lon from haul b, gear a where a.gear_id = b.gear_id;

drop view haul_cruise_view;
create view haul_cruise_view as select a.*,b.CRUISE_NAME,b.ship_name from cruise b, haul_gear_view a where a.cruise_id = b.cruise_id;

drop view sample_dict_view;
create view sample_dict_view as select a.sample_id,a.comments_samples,a.mouth_area_trawl,a.CPUE,a.TRAWL_CATCH,a.VOLUME_FISHED,a.DISTANCE_FISHED_0,a.DISTANCE_FISHED_1,a.EQUILIBRIUM,a.volume_displacement,a.haul_id,a.h_id,a.foci_sample_id,a.genetics_id,a.multiple_req,a.NUMBER_OF_BAGS,a.NUMBER_OF_JARS,a.NUMBER_SAMPLED,a.ORIG_DB,a.PRESERVE_ID,a.SPECIES_CODE_ID,a.SUBSAMPLE_NUMBER,a.SUBSAMPLE_WEIGHT,a.TOTAL_NUMBER,a.NON_SUBSAMPLE_WEIGHT,a.UNITS,a.VIAL_NUMBER,a.WEIGHT_UNITS,a.SAMPLE_DICT_ID,a.common_name,a.PROJECT,a.sample_type,a.PI_COMPONENT,a.PROJECT_CODE,b.sample_desc,b.sample_abbrev from samples a LEFT Join samples_dict b on b.sample_dict_id = a.sample_dict_id;

drop table sample_haul;
create table sample_haul as select a.*,b.comments_samples,b.SAMPLE_ID,b.VOLUME_DISPLACEMENT,b.FOCI_SAMPLE_ID,b.MULTIPLE_REQ,b.NUMBER_OF_BAGS,b.NUMBER_OF_JARS,b.NUMBER_SAMPLED,b.ORIG_DB sample_orig_db,b.PRESERVE_ID,b.common_name,b.SPECIES_CODE_ID,b.SUBSAMPLE_NUMBER,b.SUBSAMPLE_WEIGHT,b.TOTAL_NUMBER,b.NON_SUBSAMPLE_WEIGHT,b.VIAL_NUMBER,b.WEIGHT_UNITS,b.SAMPLE_DICT_ID,b.PROJECT,b.PI_COMPONENT,b.PROJECT_CODE,b.sample_type,b.SAMPLE_DESC,b.SAMPLE_ABBREV,b.mouth_area_trawl,b.CPUE,b.TRAWL_CATCH,b.VOLUME_FISHED,b.DISTANCE_FISHED_0,b.DISTANCE_FISHED_1,b.EQUILIBRIUM from haul_cruise_view a LEFT OUTER JOIN sample_dict_view b on a.h_id = b.h_id;
commit;

DELETE FROM USER_SDO_GEOM_METADATA 
  WHERE TABLE_NAME = 'SAMPLE_HAUL' AND COLUMN_NAME = 'GEOM' ;

INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID) 
  VALUES ('SAMPLE_HAUL', 'GEOM', 
    MDSYS.SDO_DIM_ARRAY 
      (MDSYS.SDO_DIM_ELEMENT('X', -180.000000000, 180.000000000, 0.000000050), 
       MDSYS.SDO_DIM_ELEMENT('Y', -90.000000000, 90.000000000, 0.000000050)  
     ), 
     8307); 
COMMIT;


/* TRAWL Calculations */
update sample_haul 
set trawl_catch = (subsample_weight + non_subsample_weight) *(subsample_number/subsample_weight) where subsample_weight !=0;
update samples
set trawl_catch =0 where subsample_weight = 0;
commit;

update sample_haul
set TRAWL_DEPLOYED_LON = 0 where TRAWL_DEPLOYED_LON is null;
update sample_haul
set TRAWL_DEPLOYED_LAT= 0 where TRAWL_DEPLOYED_LAT is null;

update sample_haul
set LON_END = 0 where LON_END is null;
update sample_haul
set LAT_END = 0 where LAT_END is null;

commit;

update sample_haul
set distance_fished_0 = sdo_geom.sdo_distance(sdo_geometry
(2001,4326,null,sdo_elem_info_array(1, 1, 1),
sdo_ordinate_array(LON_END, LAT_END)),
sdo_geometry
(2001,4326,null,sdo_elem_info_array(1, 1, 1),
sdo_ordinate_array(TRAWL_DEPLOYED_LON, TRAWL_DEPLOYED_LAT)
),
1,'unit=M') where ORIG_DB = 'TRAWL';

update sample_haul
set TRAWL_HAULBACK_START_LAT = 0 where TRAWL_HAULBACK_START_LAT is null;
update sample_haul
set TRAWL_HAULBACK_START_LON = 0 where TRAWL_HAULBACK_START_LON is null;
update sample_haul
set LAT = 0 where LAT is null;
update sample_haul
set LON = 0 where LON is null;

commit;

update sample_haul
set distance_fished_1 = sdo_geom.sdo_distance(sdo_geometry
(2001,4326,null,sdo_elem_info_array(1, 1, 1),
sdo_ordinate_array(TRAWL_HAULBACK_START_LON, TRAWL_HAULBACK_START_LAT)),
sdo_geometry
(2001,4326,null,sdo_elem_info_array(1, 1, 1),
sdo_ordinate_array(LON, LAT)
),
1,'unit=M') where ORIG_DB = 'TRAWL';
commit;

update sample_haul
set MOUTH_AREA_TRAWL = MAX_WIRE_OUT where MAX_WIRE_OUT > 251;

update sample_haul b
set b.MOUTH_AREA_TRAWL = (select a.AREA_SHRIMP from MOUTH_AREA_TRAWL a where a.MAXWIREOUT = b.MAX_WIRE_OUT)
where gear_name = 'SHRIMP' and net_path = 0;
update sample_haul b
set b.MOUTH_AREA_TRAWL = (select a.AREA_SHRIMP1 from MOUTH_AREA_TRAWL a where a.MAXWIREOUT = b.MAX_WIRE_OUT)
where gear_name = 'SHRIMP' and net_path = 1;

update sample_haul b
set b.MOUTH_AREA_TRAWL = (select a.AREA_ANCHOV from MOUTH_AREA_TRAWL a where a.MAXWIREOUT = b.MAX_WIRE_OUT)
where b.gear_name = 'ANCHO' and net_path = 0;
update sample_haul b
set b.MOUTH_AREA_TRAWL = (select a.AREA_ANCHOV1 from MOUTH_AREA_TRAWL a where a.MAXWIREOUT = b.MAX_WIRE_OUT)
where b.gear_name = 'ANCHO' and net_path = 1;

commit;

/* for non shrimp or ANCH catch */
update sample_haul
set volume_fished = distance_fished_1 * 1 where NET_PATH = 1 and ORIG_DB = 'TRAWL' and GEAR_NAME NOT IN ('ANCHO','SHRIMP');
update sample_haul
set volume_fished = distance_fished_0 * 1 where NET_PATH = 0 and ORIG_DB = 'TRAWL' and GEAR_NAME NOT IN ('ANCHO','SHRIMP');
commit;

/* for shrimp or ANCH catch */
update sample_haul
set volume_fished = distance_fished_1 * MOUTH_AREA_TRAWL where NET_PATH = 1 and ORIG_DB = 'TRAWL' and GEAR_NAME IN ('ANCHO','SHRIMP');
update sample_haul
set volume_fished = distance_fished_0 * MOUTH_AREA_TRAWL where NET_PATH = 0 and ORIG_DB = 'TRAWL' and GEAR_NAME IN ('ANCHO','SHRIMP');
commit;


update sample_haul
set CPUE = trawl_catch/volume_fished where volume_fished != 0;
update sample_haul
set CPUE = null where volume_fished =0;
commit;


drop index SAMPLE_HAUL_IX_GEOM;
create index SAMPLE_HAUL_IX_GEOM on SAMPLE_HAUL(geom) indextype is mdsys.spatial_index;
COMMIT;


/* sorter relationship table update */
drop view sorter_view;
create view sorter_view as select a.haul_id,a.sorter_form,a.sorter_id,a.comments_sorter,b.sorter_name,b.sorter_group,b.sorter_code from sorter a LEFT OUTER JOIN sorter_dict b on a.sorter_code = b.sorter_code;
commit;


/* specimen master relationship updator */
drop view specimen_taxon_view;
create view specimen_taxon_view as select a.*,b.taxon_name,b.size_name,b.zoop_vial_number,b.carbon_dry_weight,b.ORGANISM_TYPE,b.STAGE as stageID,b.stage_name as zoopstage,b.sex_name,b.orig_db taxon_orig_db,b.taxon_size from specimen a LEFT OUTER JOIN taxon_code b on a.tc_id = b.tc_id;

drop view specimen_main_stage_view;
create view specimen_main_stage_view as select a.*,b.stage_name,b.stage_group,b.stage_comments from specimen_taxon_view a LEFT OUTER JOIN stage b on a.stage_id = b.stage_id;

drop view specimen_main_stomach_view;
create view specimen_main_stomach_view as select a.*,b.DIGESTION,b.EXAMINER as STOMACHEXAMINER,b.FULLNESS,b.PROCESS_DATE as STOMACH_PROCESS_DATE,b.STOMACH_CONTENT_WT_G,b.STOMACH_DIGESTION_CODE,b.STOMACH_FULLNESS_CODE,b.STOMACH_INTACT_WT_G,b.STOMACH_LINING_WT_G from specimen_main_stage_view a LEFT JOIN stomach b on a.specimen_id = b.specimen_id;

drop view specimen_main_preserv_view;
create view specimen_main_preserv_view as select a.*,b.FOCI_PRESERVE_ID,b.preserve_comments,b.preservative from specimen_main_stomach_view a LEFT OUTER JOIN preservative b on b.preserve_id = a.preserve_id;

drop view specimen_main_sorter_view;
create view specimen_main_sorter_view as select a.*,b.sorter_name,b.sorter_group,b.sorter_code from specimen_main_preserv_view a LEFT OUTER JOIN sorter_view b on a.sorter_id = b.sorter_id;

drop view specimen_main_view;
create view specimen_main_view as select a.*,b.GENUS,b.SPECIES,b.SPECIES_NAME,b.SPECIES_CODE_ICHBASE,b.SPECIES_NAME_ICHBASE,b.COMMON_NAME_ICHBASE,b.ICH_ORDER_ICHBASE,b.ICH_FAMILY_ICHBASE,b.ICH_GENUS_ICHBASE,b.ICH_SPECIES_ICHBASE,b.GENUS_ICHBASE,b.SPECIES_ICHBASE,b.COMMENTS_ICHBASE,b.DATABASE_ICHBASE,b.GSID_IIS,b.PHYLOGENY_CODE_OLD_IIS,b.PHYLOGENY_CODE_IIS,b.ORDER_IIS,b.ORDER_COM_IIS,b.ORDER_CODE_IIS,b.FAMILY_IIS,b.FAMILY_COM_IIS,b.FAMILY_CODE_IIS,b.SUBFAM_IIS,b.SUBFAM_COM_IIS,b.SUBFAM_CODE_IIS,b.GENUS_IIS,b.GENUS_COM_IIS,b.GENUS_CODE_IIS,b.SPECIES_IIS,b.COMMON_NAME_IIS,b.SPECIES_CODE_IIS,b.REC_HIST_SPECIES_IIS,b.DATABASE_IIS,b.TAXON_CODE_BOB,b.SPECIES_NAME_BOB,b.DATABASE_BOB,b.OLD_PREY_CODE_TRAWL,b.PREY_CODE_TRAWL,b.SPECIES_CODE_TRAWL,b.PREY_GROUP_CODE_TRAWL,b.ALT_COMMON_NAME_TRAWL,b.GROUP_TRAWL,b.DATABASE_TRAWL,b.COMMON_NAME_RACEBASE,b.SPECIES_NAME_RACEBASE,b.SPECIES_CODE_RACEBASE,b.DATABASE_RACEBASE,b.ITIS_CODE,b.NODC_CODE,b.SPECIES_ORDER,b.GENUS_COMMON_NAME,b.FAMILY,
b.FAMILY_COMMON_NAME,b.ABBR_NAME,b.ALT_GENUS,b.COMMENTS_SPECIES_CODE from specimen_main_sorter_view a LEFT OUTER JOIN species_code b on a.SPECIES_CODE_ID = b.SPECIES_CODE_ID;

drop table specimen_main_geom;
create table specimen_main_geom as select a.*,b.FOCI_GEAR_ID,b.GEAR_CODE,b.GEAR_NAME,b.MOUTH_AREA,b.GEAR_ABBREV,b.NET_INFO,b.DOOR_DIMENSIONS,b.DESCRIPTION,b.HAUL_ID,b.CRUISE,b.H_ID,b.ALT_STATION_NAME,b.HAUL_NAME,b.NET,b.FOCI_GRID,b.BOTTOM_DEPTH,b.CTD_ID,b.HAUL_PERFORMANCE,b.MESH,b.LAT,b.LON,b.PURPOSE,b.PRIMARY_NET,b.MIN_GEAR_DEPTH,b.MAX_GEAR_DEPTH,b.MIN_WIRE_OUT,b.MAX_WIRE_OUT,b.TOW_MINUTES,b.TOW_SECONDS,b.VOLUME_FILTERED,b.WIRE_ANGLE,b.DOOR,b.GEOM,b.DOOR_HEIGHT,b.DOOR_WIDTH,b.DIEL,b.NET_PATH,b.GEOGRAPHIC_AREA,b.NETMOUTH_HEIGHT_M,b.SEA_SURFACE_TEMP_C,b.TRAWL_DEPLOYED_LAT,b.TRAWL_DEPLOYED_LON,b.WATER_TEMP_AT_GEAR_DEPTH,b.GMT_DATE_TIME,b.TRAWL_DEPLOYED_GMT,b.TRAWL_HAULBACK_START_GMT,b.lon_end,b.lat_end,b.trawl_haulback_start_lat,b.trawl_haulback_start_lon,b.COMMENTS_samples,b.FLOWMETER_REVS,b.FLOWMETER,b.POLYGONAL_AREA,b.CRUISE_NAME,b.SHIP_NAME,b.VOLUME_DISPLACEMENT,b.FOCI_SAMPLE_ID,b.MULTIPLE_REQ,b.NUMBER_OF_BAGS,b.NUMBER_OF_JARS,b.NUMBER_SAMPLED,b.SAMPLE_ORIG_DB,b.SUBSAMPLE_NUMBER,b.SUBSAMPLE_WEIGHT,b.TOTAL_NUMBER,b.NON_SUBSAMPLE_WEIGHT,b.VIAL_NUMBER,b.WEIGHT_UNITS,b.PROJECT,b.PI_COMPONENT,b.PROJECT_CODE,b.SAMPLE_TYPE,b.SAMPLE_DESC,b.SAMPLE_ABBREV,b.station_name,b.CPUE,b.TRAWL_CATCH,b.VOLUME_FISHED,b.DISTANCE_FISHED_0,b.DISTANCE_FISHED_1,b.EQUILIBRIUM from specimen_main_view a, sample_haul b where a.sample_id = b.sample_id;

ALTER TABLE specimen_main_geom
ADD SE_ANNO_CAD_DATA BLOB;
commit;

DELETE FROM USER_SDO_GEOM_METADATA 
  WHERE TABLE_NAME = 'SPECIMEN_MAIN_GEOM' AND COLUMN_NAME = 'GEOM' ;

INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID) 
  VALUES ('SPECIMEN_MAIN_GEOM', 'GEOM', 
    MDSYS.SDO_DIM_ARRAY 
      (MDSYS.SDO_DIM_ELEMENT('X', -180.000000000, 180.000000000, 0.000000050), 
       MDSYS.SDO_DIM_ELEMENT('Y', -90.000000000, 90.000000000, 0.000000050)  
     ), 
     8307); 
COMMIT;

drop index SPECIMEN_M_IX_GEOM;
create index SPECIMEN_M_IX_GEOM on SPECIMEN_MAIN_GEOM(geom) indextype is mdsys.spatial_index;
COMMIT;

/* POST PROCESS for ICH CALCULATIONS specimen table */
/* FIXED  LARVACATCHPER10M2 DEPTH FISHED MATH EQUATION. depth fished = max_gear_depth - min_gear_depth, not = max_gear_depth - KYB 2015-NOV-05*/
update specimen_main_geom
set LARVACATCHPER10M2 =0 where VOLUME_FILTERED =0;
update specimen_main_geom
set LARVACATCHPER10M2 = (10*(MAX_GEAR_DEPTH-MIN_GEAR_DEPTH)/VOLUME_FILTERED)*NUMBER_CAUGHT where VOLUME_FILTERED > 0;
update specimen_main_geom
set LARVALCATCHPER1000M3 =0 where VOLUME_FILTERED =0;
update specimen_main_geom
set LARVALCATCHPER1000M3 = (1000 / Volume_Filtered)*NUMBER_CAUGHT where VOLUME_FILTERED > 0;
commit;


/* SUB - specimen master relationship updator */
drop view subspecimen_main_stage_view;
create view subspecimen_main_stage_view as select a.*,b.stage_group,b.stage_name,b.stage_comments from specimen_subsample a LEFT OUTER JOIN stage b on b.stage_id = a.stage_id;

drop view subspecimen_main_preserv_view;
create view subspecimen_main_preserv_view as select a.*,b.FOCI_PRESERVE_ID,b.preserve_comments,b.preservative from subspecimen_main_stage_view a LEFT JOIN preservative b on b.preserve_id = a.preserve_id;

drop view subspecimen_main_species_view;
create view subspecimen_main_species_view as select a.*,b.GENUS,b.SPECIES,b.SPECIES_NAME,b.COMMON_NAME,b.SPECIES_CODE_ICHBASE,b.SPECIES_NAME_ICHBASE,b.COMMON_NAME_ICHBASE,b.ICH_ORDER_ICHBASE,b.ICH_FAMILY_ICHBASE,b.ICH_GENUS_ICHBASE,b.ICH_SPECIES_ICHBASE,b.GENUS_ICHBASE,b.SPECIES_ICHBASE,b.COMMENTS_ICHBASE,b.DATABASE_ICHBASE,b.GSID_IIS,b.PHYLOGENY_CODE_OLD_IIS,b.PHYLOGENY_CODE_IIS,b.ORDER_IIS,b.ORDER_COM_IIS,b.ORDER_CODE_IIS,b.FAMILY_IIS,b.FAMILY_COM_IIS,b.FAMILY_CODE_IIS,b.SUBFAM_IIS,b.SUBFAM_COM_IIS,b.SUBFAM_CODE_IIS,b.GENUS_IIS,b.GENUS_COM_IIS,b.GENUS_CODE_IIS,b.SPECIES_IIS,b.COMMON_NAME_IIS,b.SPECIES_CODE_IIS,b.REC_HIST_SPECIES_IIS,b.DATABASE_IIS,b.TAXON_CODE_BOB,b.SPECIES_NAME_BOB,b.DATABASE_BOB,b.OLD_PREY_CODE_TRAWL,b.PREY_CODE_TRAWL,b.SPECIES_CODE_TRAWL,b.PREY_GROUP_CODE_TRAWL,b.ALT_COMMON_NAME_TRAWL,b.GROUP_TRAWL,b.DATABASE_TRAWL,b.COMMON_NAME_RACEBASE,b.SPECIES_NAME_RACEBASE,b.SPECIES_CODE_RACEBASE,b.DATABASE_RACEBASE,b.ITIS_CODE,b.NODC_CODE,b.SPECIES_ORDER,b.GENUS_COMMON_NAME,b.FAMILY,
b.FAMILY_COMMON_NAME,b.ABBR_NAME,b.ALT_GENUS,b.COMMENTS_species_code from subspecimen_main_preserv_view a LEFT JOIN species_code b on a.SPECIES_CODE_ID = b.SPECIES_CODE_ID;

drop table subspecimen_main_geom;
create table subspecimen_main_geom as select a.preserve_id, a.subsample_id,a.SPECIES_NAME,a.specimen_id,a.LENGTH_VALUE as RAW_VALUE, a.species_code_id,a.stage_id,a.egg_diameter,a.CORRECTED_LENGTH,a.COMMENTS_SPECIMEN_SUBSAMPLE,b.GEOGRAPHIC_AREA,b.geom,b.gear_abbrev,b.gear_code,b.haul_name,b.haul_id,b.cruise,b.net,b.mesh,b.haul_performance,b.GMT_DATE_TIME,b.lat,b.lon,b.LARVACATCHPER10M2,b.LARVALCATCHPER1000M3,b.PRIMARY_NET,b.STATION_NAME,b.NUMBER_CAUGHT,b.VOLUME_FILTERED,b.MAX_GEAR_DEPTH from subspecimen_main_species_view a,specimen_main_geom b where b.specimen_id = a.specimen_id;

ALTER TABLE subspecimen_main_geom 
ADD SE_ANNO_CAD_DATA BLOB;
commit;

DELETE FROM USER_SDO_GEOM_METADATA 
  WHERE TABLE_NAME = 'SUBSPECIMEN_MAIN_GEOM' AND COLUMN_NAME = 'GEOM' ;

INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID) 
  VALUES ('SUBSPECIMEN_MAIN_GEOM', 'GEOM', 
    MDSYS.SDO_DIM_ARRAY 
      (MDSYS.SDO_DIM_ELEMENT('X', -180.000000000, 180.000000000, 0.000000050), 
       MDSYS.SDO_DIM_ELEMENT('Y', -90.000000000, 90.000000000, 0.000000050)  
     ), 
     8307); 
COMMIT;

drop index SUBSPECIMEN_M_IX_GEOM;
create index SUBSPECIMEN_M_IX_GEOM on SUBSPECIMEN_MAIN_GEOM(geom) indextype is mdsys.spatial_index;
COMMIT;

/* POST PROCESS for ICH CALCULATIONS SUBSPECIMEN table */
/* FIXED  LARVACATCHPER10M2 DEPTH FISHED MATH EQUATION. depth fished = max_gear_depth - min_gear_depth, not = max_gear_depth - KYB 2015-NOV-05*/
update SUBSPECIMEN_MAIN_GEOM
set LARVACATCHPER10M2 =0 where VOLUME_FILTERED =0;
update SUBSPECIMEN_MAIN_GEOM
set LARVACATCHPER10M2 = (10*(MAX_GEAR_DEPTH - MIN_GEAR_DEPTH) /VOLUME_FILTERED)*NUMBER_CAUGHT where VOLUME_FILTERED > 0;
update SUBSPECIMEN_MAIN_GEOM
set LARVALCATCHPER1000M3 =0 where VOLUME_FILTERED =0;
update SUBSPECIMEN_MAIN_GEOM
set LARVALCATCHPER1000M3 = (1000 / Volume_Filtered)*NUMBER_CAUGHT where VOLUME_FILTERED > 0;
commit;


/* DIET Table relationship update */
drop view diet_species_vw; 
create view diet_species_vw as select a.*,b.species_name from diet a LEFT OUTER JOIN species_code b on a.species_code_id = b.species_code_id;

drop table DIET_SPECIMEN;
create table DIET_SPECIMEN as select b.*,a.diet_id,a.PREY_COMMENTS,a.PREY_COUNT,a.PREY_WEIGHT,a.PREY_QUALITY,a.SPECIES_NAME AS DIET_SPECIES_NAME from diet_species_vw a LEFT OUTER JOIN specimen_main_geom b on a.specimen_id = b.specimen_id;
commit;

DELETE FROM USER_SDO_GEOM_METADATA 
  WHERE TABLE_NAME = 'DIET_SPECIMEN' AND COLUMN_NAME = 'GEOM' ;

INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID) 
  VALUES ('DIET_SPECIMEN', 'GEOM', 
    MDSYS.SDO_DIM_ARRAY 
      (MDSYS.SDO_DIM_ELEMENT('X', -180.000000000, 180.000000000, 0.000000050), 
       MDSYS.SDO_DIM_ELEMENT('Y', -90.000000000, 90.000000000, 0.000000050)  
     ), 
     8307); 
COMMIT;

drop index DIET_SPECIMEN_IX_GEOM;
create index DIET_SPECIMEN_IX_GEOM on DIET_SPECIMEN(geom) indextype is mdsys.spatial_index;
COMMIT;


/* CTD tables*/

/*SEACAT - just need to update geometry field*/
update seacat_ctd set geom = SDO_GEOMETRY(2001, 8307, SDO_POINT_TYPE(lon, lat , NULL), NULL, NULL)
where lon IS NOT NULL;

drop table SEACAT_DATA;
create table SEACAT_DATA as select a.*,b.CRUISE,b.GEAR_NAME,b.BOTTOM_DEPTH,b.PURPOSE,b.GEOGRAPHIC_AREA,b.GMT_DATE_TIME from seacat_ctd a LEFT OUTER JOIN haul b on a.h_id = b.h_id;

DELETE FROM USER_SDO_GEOM_METADATA 
  WHERE TABLE_NAME = 'SEACAT_DATA' AND COLUMN_NAME = 'GEOM' ;

INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID) 
  VALUES ('SEACAT_DATA', 'GEOM', 
    MDSYS.SDO_DIM_ARRAY 
      (MDSYS.SDO_DIM_ELEMENT('X', -180.000000000, 180.000000000, 0.000000050), 
       MDSYS.SDO_DIM_ELEMENT('Y', -90.000000000, 90.000000000, 0.000000050)  
     ), 
     8307); 
COMMIT;

drop index SEACAT_DATA_IX_GEOM;
create index SEACAT_DATA_IX_GEOM on SEACAT_DATA(geom) indextype is mdsys.spatial_index;
COMMIT;


/* Chlorophyll */
drop view chlorophyll_calibration_vw; 
create view chlorophyll_calibration_vw as select a.*,b.SLOPE,b.TAU,b.SCALING_FACTOR from chlorophyll a INNER JOIN FLUOROMETER_CALIBRATION b on a.FLUROCALIBID = b.FLUROCALIBID;

drop table chlorophyll_data;
create table chlorophyll_data as select a.*,b.CRUISE,b.HAUL_NAME,b.GEAR_NAME,b.BOTTOM_DEPTH,b.PURPOSE,b.GEOGRAPHIC_AREA,b.LAT,b.LON,b.GMT_DATE_TIME,b.GEOM from chlorophyll_calibration_vw a LEFT OUTER JOIN sample_haul b on a.sample_id = b.sample_id;

DELETE FROM USER_SDO_GEOM_METADATA 
  WHERE TABLE_NAME = 'CHLOROPHYLL_DATA' AND COLUMN_NAME = 'GEOM' ;

INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID) 
  VALUES ('CHLOROPHYLL_DATA', 'GEOM', 
    MDSYS.SDO_DIM_ARRAY 
      (MDSYS.SDO_DIM_ELEMENT('X', -180.000000000, 180.000000000, 0.000000050), 
       MDSYS.SDO_DIM_ELEMENT('Y', -90.000000000, 90.000000000, 0.000000050)  
     ), 
     8307); 
COMMIT;

drop index chlorophyll_IX_GEOM;
create index chlorophyll_IX_GEOM on CHLOROPHYLL_DATA(geom) indextype is mdsys.spatial_index;
COMMIT;

/* CHLOROPHYLL CALCULATION FOR BOB
CHLOROCONC_L
PHAECONC_L */

update chlorophyll_data
set CHLOROCONC_L = 0 where DILUTION_FACTOR = 0;
update chlorophyll_data
set CHLOROCONC_L = ROUND(((Slope*(Tau/(Tau-1)))*ACETONE_VOL*(F_B*SCALING_FACTOR-F_A*SCALING_FACTOR)*(1/DILUTION_FACTOR))/(VOLUME_FILTERED_CHLOR/1000),3) where DILUTION_FACTOR != 0;

update chlorophyll_data
set PHAECONC_L = 0 where DILUTION_FACTOR = 0;
update chlorophyll_data
set PHAECONC_L = ROUND(((Slope*(Tau/(Tau-1)))*ACETONE_VOL*((Tau*F_A*SCALING_FACTOR)-F_B*SCALING_FACTOR)*(1/DILUTION_FACTOR))/(VOLUME_FILTERED_CHLOR/1000),3) where DILUTION_FACTOR != 0;
COMMIT;

/* NUTRIENT */
drop table nutrient_data;
create table NUTRIENT_DATA as select a.*,b.CRUISE,b.HAUL_NAME,b.GEAR_NAME,b.BOTTOM_DEPTH,b.PURPOSE,b.GEOGRAPHIC_AREA,b.LAT,b.LON,b.GMT_DATE_TIME,b.GEOM from nutrient a LEFT OUTER JOIN sample_haul b on a.sample_id = b.sample_id;

DELETE FROM USER_SDO_GEOM_METADATA 
  WHERE TABLE_NAME = 'NUTRIENT_DATA' AND COLUMN_NAME = 'GEOM' ;

INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID) 
  VALUES ('NUTRIENT_DATA', 'GEOM', 
    MDSYS.SDO_DIM_ARRAY 
      (MDSYS.SDO_DIM_ELEMENT('X', -180.000000000, 180.000000000, 0.000000050), 
       MDSYS.SDO_DIM_ELEMENT('Y', -90.000000000, 90.000000000, 0.000000050)  
     ), 
     8307); 
COMMIT;

drop index nutrient_IX_GEOM;
create index nutrient_IX_GEOM on NUTRIENT_DATA(geom) indextype is mdsys.spatial_index;
COMMIT;

/* CTDB */
drop table ctdb_data;
create table ctdb_data as select a.*,b.CRUISE,b.HAUL_NAME,b.GEAR_NAME,b.BOTTOM_DEPTH,b.PURPOSE,b.GEOGRAPHIC_AREA,b.LAT,b.LON,b.GMT_DATE_TIME,b.GEOM,b.SE_ANNO_CAD_DATA from ctdb a LEFT OUTER JOIN haul b on a.h_id = b.h_id;
DELETE FROM USER_SDO_GEOM_METADATA 
  WHERE TABLE_NAME = 'CTDB_DATA' AND COLUMN_NAME = 'GEOM' ;

INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME, COLUMN_NAME, DIMINFO, SRID) 
  VALUES ('CTDB_DATA', 'GEOM', 
    MDSYS.SDO_DIM_ARRAY 
      (MDSYS.SDO_DIM_ELEMENT('X', -180.000000000, 180.000000000, 0.000000050), 
       MDSYS.SDO_DIM_ELEMENT('Y', -90.000000000, 90.000000000, 0.000000050)  
     ), 
     8307); 
COMMIT;

drop index ctdb_IX_GEOM;
create index ctdb_IX_GEOM on CTDB_DATA(geom) indextype is mdsys.spatial_index;
COMMIT;


/* end post processing script */




// Run the zoop calculations after the post processing script. 
//last modified version 2014Mar13.sql

/* Update calculated values for Zoop/BOB data
Should be run every time a change is made to zoop data

March 2014

ASA & NOAA

***This needs to be run in the order below

**Setting this will write to console on SQLPLUS*/
SET ECHO ON
SET SERVEROUTPUT ON


/* Estimated number Per Sample*/
update specimen_main_geom
set EST_NUM_PERSAMPLE = ROUND(NUMBER_MEASURED_COUNTED*(1/SUBSAMPLE_FACTOR),4)
where ORIG_DB = 'BOB';
commit;
/* Done*/


/* 
update procedure
	will list out any issues with certain specimen Ids
may take a little while (up to a day)
Many values will be 0 if the volume filtered or sample volume is 0 ****
*/

CREATE OR REPLACE FUNCTION is_number( p_str IN VARCHAR2 )
  RETURN VARCHAR2 DETERMINISTIC PARALLEL_ENABLE
IS
  l_num NUMBER;
BEGIN
  l_num := to_number( p_str );
  RETURN 'Y';
EXCEPTION
  WHEN value_error THEN
    RETURN 'N';
END is_number;
/


    update specimen_main_geom set EST_NUM_PERM3 = 0;
    update specimen_main_geom set EST_NUM_PERM2 = 0;

    update specimen_main_geom set EST_NUM_PERM3 = ROUND(EST_NUM_PERSAMPLE/volume_filtered,4) where volume_filtered > 0 and gear_abbrev != 'CTDB';
    update specimen_main_geom set EST_NUM_PERM2 = ROUND(EST_NUM_PERM3*(MAX_GEAR_DEPTH -MIN_GEAR_DEPTH),4) where volume_filtered > 0 and gear_abbrev != 'CTDB';
        
    update specimen_main_geom set EST_NUM_PERM3 = ROUND(1000*(1/sample_volume),4) where sample_volume > 0 and gear_abbrev = 'CTDB';
    update specimen_main_geom set EST_NUM_PERM2 = ROUND(EST_NUM_PERM3*(MAX_GEAR_DEPTH -MIN_GEAR_DEPTH),4) where sample_volume > 0 and gear_abbrev = 'CTDB';
	
    update specimen_main_geom set DIS_PERVOLM3 = 0;
    update specimen_main_geom set DIS_PERVOLM2 = 0;

	  update specimen_main_geom set DIS_PERVOLM3 = ROUND(to_number(VOLUME_DISPLACEMENT)/volume_filtered,4) where volume_filtered > 0 and to_number(VOLUME_DISPLACEMENT) > 0 and volume_filtered is not null and VOLUME_DISPLACEMENT is not null;
    update specimen_main_geom set DIS_PERVOLM2 = ROUND(DIS_PERVOLM3*(MAX_GEAR_DEPTH -MIN_GEAR_DEPTH),4) where volume_filtered > 0 and to_number(VOLUME_DISPLACEMENT) > 0;
    update specimen_main_geom set DIS_PERVOLM3 = null where volume_filtered <= 0 OR to_number(VOLUME_DISPLACEMENT) <= 0 OR volume_filtered IS NULL OR VOLUME_DISPLACEMENT IS NULL;
    update specimen_main_geom set DIS_PERVOLM2 = null where volume_filtered <= 0 OR to_number(VOLUME_DISPLACEMENT) <=0 OR volume_filtered IS NULL OR VOLUME_DISPLACEMENT IS NULL;
 
 commit;


/* 
update for Bio Mass calculations
 
update procedure
	will list out any issues with certain specimen Ids
may take a little while 
*/

    /* Estimated biomass update*/
    update specimen_main_geom set BIO_MASS_PERSAMPLE = 0 where CARBON_DRY_WEIGHT IS NULL;
    update specimen_main_geom set BIO_MASS_PERSAMPLE = ROUND(CARBON_DRY_WEIGHT*EST_NUM_PERSAMPLE,4) where CARBON_DRY_WEIGHT IS NOT NULL;

/* 
update procedure
	will list out any issues with certain specimen Ids
may take a little while 
*/

    update specimen_main_geom set BIO_MASS_PERM3 = 0 where  volume_filtered IS NULL OR volume_filtered = 0;
    update specimen_main_geom set BIO_MASS_PERM3 = BIO_MASS_PERSAMPLE/volume_filtered where volume_filtered > 0 and volume_filtered IS NOT NULL AND volume_filtered != 0;
    
    update specimen_main_geom set BIO_MASS_PERM2 = BIO_MASS_PERM3*(MAX_GEAR_DEPTH -MIN_GEAR_DEPTH) where volume_filtered > 0 and volume_filtered IS NOT NULL AND volume_filtered != 0;

commit;
