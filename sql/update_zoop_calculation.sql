/* Update calculated values for Zoop/BOB data
Should be run every time a change is made to zoop data

September 2013

updated 2016

ASA & NOAA

***This needs to be run in the order below

**Setting this will write to console on SQLPLUS
SQL> SET ECHO ON
SQL> SET SERVEROUTPUT ON
*/

/* Estimated number Per Sample*/
update specimen
set EST_NUM_PERSAMPLE = ROUND(NUMBER_MEASURED_COUNTED*(1/SUBSAMPLE_FACTOR),4)
where ORIG_DB = 'BOB';
commit;
/* Done*/

/* 
update for estimated number and volume displacement
Create temp volume filtered table first
*/
drop table vol_filtered;
create table vol_filtered as(
SELECT a.volume_filtered, a.MIN_GEAR_DEPTH,a.MAX_GEAR_DEPTH, a.gear_name,c.specimen_id,c.sample_volume,b.VOLUME_DISPLACEMENT
  FROM haul a, samples b
  left OUTER JOIN specimen c ON c.sample_id = b.sample_id
 WHERE a.h_id = b.h_id and c.orig_db = 'BOB' and EST_NUM_PERM3 IS NULL);

/* 
update procedure
	will list out any issues with certain specimen Ids
may take a little while (up to a day)
Many values will be 0 if the volume filtered or sample volume is 0 ****
*/
DECLARE
BEGIN
    FOR r_company IN (select * from vol_filtered) 
    LOOP
    	/* Estimated number update*/
        IF r_company.volume_filtered > 0 and r_company.gear_name != 'CTDB' 
            THEN 
            	update specimen set EST_NUM_PERM3 = ROUND(EST_NUM_PERSAMPLE/r_company.volume_filtered,4),EST_NUM_PERM2 = ROUND(EST_NUM_PERM3*(r_company.MAX_GEAR_DEPTH -r_company.MIN_GEAR_DEPTH),4) where specimen_id = r_company.specimen_id;
        
	ELSIF r_company.sample_volume > 0 and r_company.gear_name = 'CTDB'
            /* This is to be updated as per David's comments EST_NUM_PERM2*/
        	THEN
        		update specimen set EST_NUM_PERM3 = ROUND(1000*(1/r_company.sample_volume),4),EST_NUM_PERM2 = ROUND(EST_NUM_PERM3*(r_company.MAX_GEAR_DEPTH -r_company.MIN_GEAR_DEPTH),4) where specimen_id = r_company.specimen_id;
	
	ELSE 
		update specimen set EST_NUM_PERM3 = 0,EST_NUM_PERM2 = 0 where specimen_id = r_company.specimen_id;	
	END IF;
        /* Vol Displacement update*/
        IF r_company.volume_filtered > 0 and r_company.VOLUME_DISPLACEMENT > 0
        	THEN
        		update specimen set DIS_PERVOLM3 = ROUND(r_company.VOLUME_DISPLACEMENT/r_company.volume_filtered,4), DIS_PERVOLM2 = ROUND(DIS_PERVOLM3*(r_company.MAX_GEAR_DEPTH -r_company.MIN_GEAR_DEPTH),4) where specimen_id = r_company.specimen_id;
    	ELSE
    			update specimen set DIS_PERVOLM3 = 0,DIS_PERVOLM2 = 0 where specimen_id = r_company.specimen_id;
    	END IF;
    END LOOP;
END;
/

drop table vol_filtered;
commit;
/* Done*/



/* 
update for Bio Mass calculations
Create temp volume filtered table first
*/
drop table biomass_table;
create table biomass_table as(
SELECT a.volume_filtered, a.MIN_GEAR_DEPTH,a.MAX_GEAR_DEPTH,c.specimen_id,d.CARBON_DRY_WEIGHT, c.EST_NUM_PERSAMPLE
  FROM haul a, taxon_code d, samples b
  left OUTER JOIN specimen c ON c.sample_id = b.sample_id
 WHERE a.h_id = b.h_id and c.tc_id = d.tc_id and c.orig_db = 'BOB' and BIO_MASS_PERM2 IS NULL);
/* 
update procedure
	will list out any issues with certain specimen Ids
may take a little while 
*/
DECLARE
BEGIN
    update specimen
    set BIO_MASS_PERSAMPLE = 0 where specimen_id IN (select SPECIMEN_ID from biomass_table where CARBON_DRY_WEIGHT IS NULL);
    FOR r_company IN (select * from biomass_table where CARBON_DRY_WEIGHT IS NOT NULL) 
    LOOP
    	/* Estimated biomass update*/
        update specimen
        set BIO_MASS_PERSAMPLE = ROUND(r_company.CARBON_DRY_WEIGHT*r_company.EST_NUM_PERSAMPLE,4) where r_company.specimen_id = specimen_id;

    END LOOP;
END;
/
/* 
update procedure
	will list out any issues with certain specimen Ids
may take a little while (up to a day)
*/
DECLARE
BEGIN
    update specimen
    set BIO_MASS_PERM3 = 0 where specimen_id IN (select SPECIMEN_ID from biomass_table where volume_filtered IS NULL OR volume_filtered = 0);
    
    FOR r_company IN (select * from biomass_table where volume_filtered IS NOT NULL AND volume_filtered != 0) 
    LOOP
    	/* Estimated biomass update*/
	IF r_company.volume_filtered > 0 
             THEN
        	update specimen
        	set BIO_MASS_PERM3 = BIO_MASS_PERSAMPLE/r_company.volume_filtered where r_company.specimen_id = specimen_id;
		update specimen
		set BIO_MASS_PERM2 = BIO_MASS_PERM3*(r_company.MAX_GEAR_DEPTH -r_company.MIN_GEAR_DEPTH) where r_company.specimen_id = specimen_id;

    	END IF;

    END LOOP;
END;
/
commit;

drop table biomass_table;
commit;

