/* 
Last revised by Kimberly on Feb.07, 2017

Integrated Depth Calculations
ASA and NOAA
To Be run on the Chlorophyll table after table is updated

This is Integrated Depth Calculations for chlorophyll only. 
This was created in December 2016 by Stephen with 
 Only update for more then 4 depth values
		IF (v_count > 4)
However, after re-evaluating the depths <4  and Nissa decided that we want values for all depths. so Kimberly revised 
IF (v_count > 4) to IF (v_count > 0)
*/

set serveroutput on

/* create data type for iteration*/
CREATE OR REPLACE TYPE previous_value AS OBJECT( 
   sample_depth          NUMBER(15,5),
   PHAECONC_L            NUMBER(20,4),
   CHLOROCONC_L           NUMBER(12,4) );
/

declare
sql1 varchar2(400);
sql2 varchar2(400);
sql3 varchar2(400);
sql4 varchar2(400);
v_count number;
ph_number number;
chl_number number;
i   NUMBER := 0;

previous_value_array previous_value;

begin

/* Loop through all the hauls in the chlorophyll table*/
for haul in (select distinct haul_id,h_id from chlorophyll_data)

loop

i := 0;
ph_number := 0;
chl_number := 0;

sql2 := 'drop view t'||haul.h_id;
sql1 := 'create view t'||haul.h_id||' as (select * from chlorophyll_data where h_id = '||haul.h_id||')';

/* dbms_output.put_line(sql1);
dbms_output.put_line(sql2);

Create View for each haul
execute immediate sql1;*/

	begin

		select count(*) into v_count from chlorophyll_data where h_id = haul.h_id;

		/* Only update for more then 4 depth values 
		IF (v_count > 4)
		*/
		
		/* for all depths */
		IF (v_count > 0)
		
		THEN
		/* loop through each depth value*/
		for chlorValue in (select sample_depth,PHAECONC_L,CHLOROCONC_L from chlorophyll_data where h_id = haul.h_id order by sample_depth)
		loop
			/* first depth value*/
			IF i = 0
			THEN
			/*don't do anything*/
			ph_number := ph_number;
			chl_number := chl_number;

			ELSIF i = 1
			THEN
			ph_number := ph_number +(chlorValue.PHAECONC_L + previous_value_array.PHAECONC_L) * ((chlorValue.sample_depth - previous_value_array.sample_depth)/2);
			chl_number := chl_number +(chlorValue.CHLOROCONC_L + previous_value_array.CHLOROCONC_L) *((chlorValue.sample_depth - previous_value_array.sample_depth)/2);
			/* last depth value*/
			ELSIF i = v_count
			THEN
			
			ph_number := ph_number +(chlorValue.PHAECONC_L + previous_value_array.PHAECONC_L) * ((chlorValue.sample_depth - previous_value_array.sample_depth)/2);
			chl_number := chl_number +(chlorValue.CHLOROCONC_L + previous_value_array.CHLOROCONC_L) * ((chlorValue.sample_depth - previous_value_array.sample_depth)/2);
			
			/* 
			ph_number := ph_number + previous_value_array.PHAECONC_L * ((chlorValue.sample_depth - previous_value_array.sample_depth));
			chl_number := chl_number + previous_value_array.CHLOROCONC_L * ((chlorValue.sample_depth - previous_value_array.sample_depth));
			all other values*/
			ELSE
			ph_number := ph_number +(chlorValue.PHAECONC_L + previous_value_array.PHAECONC_L) * ((chlorValue.sample_depth - previous_value_array.sample_depth))/2;
			chl_number := chl_number +(chlorValue.CHLOROCONC_L + previous_value_array.CHLOROCONC_L) * ((chlorValue.sample_depth - previous_value_array.sample_depth)/2);

			END IF;

			i := i + 1;
			previous_value_array :=previous_value(chlorValue.sample_depth,chlorValue.PHAECONC_L,chlorValue.CHLOROCONC_L);
			
			dbms_output.put_line('Depth:'||previous_value_array.sample_depth||' Completed.');
			dbms_output.put_line('chl_number:'||chl_number||' Completed.');

		END LOOP;
		
		/* Execute the depth update*/
		sql3 :='update chlorophyll_data set INTCHL = '||chl_number||' where h_id = '||haul.h_id;
		sql4 :='update chlorophyll_data set INTPHAEO = '||ph_number||' where h_id = '||haul.h_id;

		execute immediate sql3;
		execute immediate sql4;

		dbms_output.put_line(haul.h_id||' Completed.');
		END IF;
	end;

/* Delete the view
execute immediate sql2;
*/


END LOOP;

commit;

END;
/

commit;

