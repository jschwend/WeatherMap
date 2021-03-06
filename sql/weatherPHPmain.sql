select @rownum := @rownum + 1 Rank
     , Station
     , Name
     , Display
     , Latitude
     , Longitude
     , Elevation
     , Latest
     , Readings
     , AvgTemp
     , MaxTemp
     , MinTemp
     , NightlyAvg
     , AvgTemp - NightlyAvg DailyDiff
     , `Hot%` as HotPct
     , `Warm%` as WarmPct
     , `Cold%` as ColdPct
     , `Cool%` as CoolPct
     , `Nice%` as NicePct
     , AvgHumid
     , AvgDP
     , `Humid%` as HumidPct
     , `Rainy%` as RainyPct
FROM (select @rownum := 0) as r
   , (Select Xref.Station
     , Xref.Name
     , Xref.Display
     , Xref.Latitude
     , Xref.Longitude
     , Xref.Elevation
     , Date(max(ol.When)) Latest
     , count(*) Readings
     , Round(Avg(Temperature),1) AvgTemp
     , max(Temperature) MaxTemp
     , min(Temperature) MinTemp
     , NightlyAvg
     , coalesce(Round((ReallyHotDays / count(*))*100,1),0) `Hot%`
     , coalesce(Round((HotDays / count(*))*100,1),0) `Warm%`
     , coalesce(Round((ColdDays / count(*))*100,1),0) `Cold%`
     , coalesce(Round((CoolDays / count(*))*100,1),0) `Cool%`
     , coalesce(Round((NiceDays / count(*))*100,1),0) `Nice%`
     , Round(Avg(Humidity),1) AvgHumid
     , Round(Avg(CalcDewPoint),1) AvgDP
     , coalesce(Round((HumidDays / count(*))*100,1),0) `Humid%`
     , coalesce(Round((RainyDays / count(*))*100,1),0) `Rainy%`
  from vLog as ol
  join Xref
    on Xref.Station = ol.Station
  join (SELECT @rownum := 0) r
  left join (select Station
             , count(Distinct Date(`When`)) RainyDays
          from vLog il
         where RainRate > 0
       --    and hour(il.When) = 14
           and date(il.When) >= '2012-01-01'
         group by Station) as rd
    on rd.Station = ol.Station
  left join (select Station
             , count(*) HumidDays
          from vLog il
         where CalcDewPoint > 69
           and hour(il.When) = 14
           and date(il.When) >= '2012-01-01'
         group by Station) as sd
    on sd.Station = ol.Station
  left join (select Station
             , count(*) ReallyHotDays
          from vLog il
         where HeatIndex between 90.1 and 130
           and hour(il.When) = 14
           and date(il.When) >= '2012-01-01'
         group by Station) as rhd
    on rhd.Station = ol.Station
  left join (select Station
             , count(*) HotDays
          from vLog il
         where HeatIndex between 80.1 and 90
           and hour(il.When) = 14
           and date(il.When) >= '2012-01-01'
         group by Station) as hd
    on hd.Station = ol.Station
  left join (select Station
             , count(*) ColdDays
          from Log il
         where Temperature between -40 and 30
           and hour(il.When) = 14
           and date(il.When) >= '2012-01-01'
         group by Station) as cd
    on cd.Station = ol.Station
  left join (select Station
             , count(*) CoolDays
          from Log il
         where Temperature between 30.1 and 50
           and hour(il.When) = 14
           and date(il.When) >= '2012-01-01'
         group by Station) as coold
    on coold.Station = ol.Station
  left join (select Station
             , count(*) NiceDays
          from Log il
         where Temperature between 50.1 and 80
           and hour(il.When) = 14
           and date(il.When) >= '2012-01-01'
         group by Station) as nd
    on nd.Station = ol.Station
  left join (select Station
             , Round(avg(Temperature),1) NightlyAvg
          from Log il
         where hour(il.When) = 2
           and date(il.When) >= '2012-01-01'
         group by Station) as na
    on na.Station = ol.Station
 where Temperature between -40 and 130
   and hour(ol.When) = 14
   and date(ol.When) >= '2012-01-01'
 group by Xref.Name) as x
 WHERE DATEDIFF(NOW(),Latest) < 30
 order by `Nice%` desc, `Humid%` asc;
