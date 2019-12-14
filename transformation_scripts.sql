insert ignore into mdm_DataElement( deName )
(
    select distinct element_name
    from import_measures
);

insert ignore into mdm_Unit( unique_name )
(
    select distinct lower(trim(metric_unit))
    from import_measures
);

insert ignore into mdm_Metric( unique_name, unit_id )
(
    select distinct a.metric_name, b.unit_id
    from import_measures a,
         mdm_Unit b
    where b.unique_name = lower(trim( a.metric_unit ))     
);

insert ignore into mdm_OrganizationType( unique_name )
(
     select distinct lower(trim(org_type))
     from   import_measures a            
);

insert ignore into mdm_Organization( unique_name, type_id )
(
     select a.org_code, b.type_id
                from import_measures a,
          mdm_OrganizationType b
     where b.unique_name = lower(trim(a.org_type))     
);

insert ignore into mdm_OrganizationHierarchy( parent_org_id, child_org_id )
(
     select distinct b.org_id, e.org_id
     from import_measures a,
          mdm_Organization b,
          mdm_OrganizationType c,
          import_measures d,
          mdm_Organization e,
          mdm_OrganizationType f 
                where b.unique_name = a.org_parent_code
    and   c.type_id = b.type_id
    and   e.unique_name = d.org_code
    and   f.type_id = e.type_id
);

insert ignore into mdm_Measure( metric_id, measure, measure_datetime, hash, org_id)
(
select met.metric_id, 
       mvp.measure_value,
       str_to_date(mvp.measure_datetime,'%d/%m/%Y %h:%s'), 
       md5(concat_ws(lower(trim(mvp.metric_name)),str_to_date(mvp.measure_datetime,'%d/%m/%Y %h:%s'),mvp.org_code)),
       org.org_id
from   import_measures mvp,
       mdm_Metric met,
       mdm_Organization org
where  mvp.metric_name = met.unique_name
and    org.unique_name = mvp.org_code
);

insert ignore into mdm_DataValue( distinct_value )
(
     select distinct data_value
     from   import_measures
);

insert ignore into mdm_DataElementMeasure( element_id, measure_id )
(
select de.element_id, m.measure_id
from   mdm_Measure m,
       import_measures imp,
       mdm_DataElement de
where  de.deName = lower(trim(imp.element_name))       
and    m.hash in ( 
                 select md5(concat_ws(lower(trim(mvp.metric_name)),str_to_date(mvp.measure_datetime,'%d/%m/%Y %h:%s'),mvp.org_code))
                 from   import_measures mvp,
                               mdm_Metric met,
                            mdm_Organization org
                   where  mvp.metric_name = met.unique_name
                 and    org.unique_name = mvp.org_code )
);

create view view_metadataV2 as
  select mea.measure, mea.measure_datetime, ot.unique_name, met.unique_name, uni.unique_name, de.deName 
  from   mdm_Organization org,
         mdm_Measure mea,
         mdm_OrganizationType ot,
         mdm_Metric met,
         mdm_Unit uni,
         mdm_DataElementMeasure dem,
         mdm_DataElement de
  where  mea.org_id = org.org_id
  and    ot.type_id = org.type_id
  and    met.metric_id = mea.metric_id
  and    uni.unit_id = met.unit_id
  and    dem.measure_id = mea.measure_id
  and    de.element_id = dem.element_id;       
