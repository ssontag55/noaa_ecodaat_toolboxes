//Update cruise

UPDATE flowmeter A SET A.cruise_name = ( SELECT B.foci_cruise_name FROM cruise B WHERE A.cruise_id= B.cruise_id );


/*update calibration factor flowmeter in haul table*/
drop table calibration_fact;

create table calibration_fact as
(SELECT b.h_id, 
(a.INTERCEPT + (a.SLOPE* (b.FLOWMETER_REVS/( (b.TOW_MINUTES*60) + b.TOW_SECONDS)))) as calc 
from flowmeter a, haul b 
where a.flowmeter_id = b.flowmeter_id 
and b.tow_minutes>0 
and b.gear_name IN ('20BON','3PSBT','60BON','BONG','CALVET','IKS','LG-CB','MANTA','MARMAP','MBT','METH','NEU','NEUTUCK','QUADNET','SLED','SM-CB','TUCK1','TUCK3','V60BON'));

alter table calibration_fact add constraint calibration_fact_un unique(h_id);

update ( select old.calibration_factor updatefield, new.calc updatorfield
           from haul old JOIN
                calibration_fact new
          on old.h_id = new.h_id )
  set updatefield = updatorfield;

drop table calibration_fact;

commit;


/*Volume filtered calculations*/

drop table volume_filt;

create table volume_filt as
(SELECT b.h_id, 
(a.MOUTH_AREA * b.FLOWMETER_REVS*b.CALIBRATION_FACTOR) as calc 
from gear a, haul b 
where a.gear_id = b.gear_id 
and b.gear_name NOT IN ('CTDB',CTD','MOC1'));

alter table volume_filt add constraint volume_filt_un unique(h_id);

update ( select old.volume_filtered updatefield, new.calc updatorfield
           from haul old JOIN
                volume_filt new
          on old.h_id = new.h_id )
  set updatefield = updatorfield;

drop table volume_filt;

commit;




