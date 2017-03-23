/* Update calculated values for Zoop/BOB data
Should be run every time a change is made to zoop data

September 2013

updated March 2017

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


/* No need to update these tables in the loop now*/
update specimen_main_geom set EST_NUM_PERM3 = 0;
update specimen_main_geom set EST_NUM_PERM2 = 0;
update specimen_main_geom set EST_NUM_PERM2 = ROUND(EST_NUM_PERM3*(MAX_GEAR_DEPTH -MIN_GEAR_DEPTH),4) where gear_name != 'CTDB';
update specimen_main_geom set EST_NUM_PERM3 = ROUND(EST_NUM_PERSAMPLE*(1000*(1/volume_filtered)),4) where volume_filtered > 0 and gear_name != 'CTDB';
update specimen_main_geom set EST_NUM_PERM3 = ROUND(1000*(1/sample_volume),4) where sample_volume >0 and gear_name = 'CTDB';
commit;

/* Update spceimen table with new EST_NUM_PERM3 value to link to new table*/
UPDATE specimen t1
   SET EST_NUM_PERM3 = (SELECT t2.EST_NUM_PERM3
                         FROM specimen_main_geom t2
                        WHERE t1.specimen_id = t2.specimen_id)
 WHERE EXISTS (
    SELECT 1
      FROM specimen_main_geom t2
     WHERE t1.specimen_id = t2.specimen_id );

 commit;

/* 
Create  temp volume filtered table to iterate through the "DEPTHS" for the summation of EST_NUM_PERM2

add "and EST_NUM_PERM3 IS NULL" to only do new records
*/
drop table vol_filtered_EST_NUM_PERM2;
create table vol_filtered_EST_NUM_PERM2 as(
SELECT d.depth, a.volume_filtered,a.h_id, a.MIN_GEAR_DEPTH,a.MAX_GEAR_DEPTH, a.gear_name,c.specimen_id,c.sample_volume,c.EST_NUM_PERM3, b.VOLUME_DISPLACEMENT
  FROM haul a, samples b
  left OUTER JOIN specimen c ON c.sample_id = b.sample_id
  left OUTER JOIN ctdb d ON b.h_id = d.h_id
 WHERE a.h_id = b.h_id and c.orig_db = 'BOB' and a.gear_name = 'CTDB' and c.sample_volume > 0 and d.depth >0);

/* 
update procedure
	will list out any issues with certain specimen Ids
may take a little while (up to a day)
Many values will be 0 if the volume filtered or sample volume is 0 ****
*/
DECLARE

i   NUMBER := 0;
EST_NUM_PERM2_number number;
EST_NUM_PERM3_value number;
previous_depth number;
previous_EST_NUM_PERM3 number;


/* Loop through depths to get bin values and summarize to get values */    
BEGIN
    
    /* Loop first through unique haul_ids */  
    for sampleHaul in (select distinct h_id from vol_filtered_EST_NUM_PERM2 order by h_id)
    loop
        /* This is to be updated as per David's comments EST_NUM_PERM2*/
        for depthValue in (select * from vol_filtered_EST_NUM_PERM2 order by depth where h_id = sampleHaul.h_id)
        loop
        
        i := 0;
        EST_NUM_PERM2_number := 0;
        
        /* first depth value*/
        /*don't do anything*/
        IF i = 0
        THEN
        
        EST_NUM_PERM2_number := EST_NUM_PERM2_number;

        /* all other depths  calculate the previous depths*/
        ELSE
        
        /* based on Kimberly
        EST_NUM_PERM2_number := EST_NUM_PERM2_number+ ROUND(EST_NUM_PERM3_value*(depthValue.depth -previous_depth),4);
        */
        EST_NUM_PERM2_number = (depthValue.EST_NUM_PERM3 + previous_EST_NUM_PERM3) * ((depthValue.depth - previous_depth)/2)

        END IF;
        
        i := i + 1;
        previous_depth := depthValue.depth;
        previous_EST_NUM_PERM3 = depthValue.EST_NUM_PERM3;

        /* Update both tables with the sum of the new EST_NUM_PERM2*/
        update specimen_main_geom set EST_NUM_PERM2 = EST_NUM_PERM2_number where specimen_id = depthValue.specimen_id;
        update specimen set EST_NUM_PERM2 = EST_NUM_PERM2_number where specimen_id = depthValue.specimen_id;

        END LOOP;

    END LOOP;
       
END;
/

update specimen_main_geom set DIS_PERVOLM3 = 0;
update specimen_main_geom set DIS_PERVOLM2 = 0;
update specimen_main_geom set DIS_PERVOLM3 = ROUND(VOLUME_DISPLACEMENT/volume_filtered,4) where volume_filtered > 0 and VOLUME_DISPLACEMENT > 0;
update specimen_main_geom set DIS_PERVOLM2 = ROUND(DIS_PERVOLM3*(MAX_GEAR_DEPTH - MIN_GEAR_DEPTH),4) where volume_filtered > 0 and VOLUME_DISPLACEMENT > 0;

drop table vol_filtered_EST_NUM_PERM2;
commit;
/* Done*/


update specimen_main_geom
set BIO_MASS_PERSAMPLE = 0 where CARBON_DRY_WEIGHT IS NULL;
update specimen_main_geom
set BIO_MASS_PERSAMPLE = ROUND(CARBON_DRY_WEIGHT*EST_NUM_PERSAMPLE,4) where CARBON_DRY_WEIGHT IS NOT NULL;
update specimen_main_geom
set BIO_MASS_PERM3 = 0 where volume_filtered IS NULL OR volume_filtered = 0;
update specimen_main_geom
set BIO_MASS_PERM3 = BIO_MASS_PERSAMPLE/volume_filtered where volume_filtered > 0 ;
update specimen_main_geom
set BIO_MASS_PERM2 = BIO_MASS_PERM3*(MAX_GEAR_DEPTH -MIN_GEAR_DEPTH);


commit;
