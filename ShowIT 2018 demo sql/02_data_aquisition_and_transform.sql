-- denormalizace star schema; vyber zakazniku a koupenych produktu
create or alter view viCustomersDataSet
as
select 
	EnglishProductName
	, BirthDate
	, MaritalStatus
	, Gender
	, YearlyIncome
	, NumberChildrenAtHome
	, SalesAmount
	, OrderDate
	, HouseOwnerFlag
	, NumberCarsOwned
	, DimCustomer.CustomerKey
from FactInternetSales
	join DimProduct on DimProduct.ProductKey = FactInternetSales.ProductKey
	join DimCustomer on DimCustomer.CustomerKey = FactInternetSales.CustomerKey
go

select * from viCustomersDataSet

-- "hrani si" se zdrojovymi daty (forma transformace)
;with completeData as
(
select
CustomerKey
, MaritalStatus
, Gender
, NumberCarsOwned
, NumberChildrenAtHome
, datediff(dd, max(OrderDate), getdate()) as DaysFromLastOrder
, DATEDIFF(yyyy, BirthDate, getdate()) as AgeInYears
, SUM(cast(SalesAmount as numeric(8,2))) as SalesAmount
, count(*) as SalesCount
, cast(YearlyIncome as int) as YearlyIncome
from viCustomersDataSet
group by CustomerKey
, MaritalStatus
, Gender
, NumberCarsOwned
, NumberChildrenAtHome
, BirthDate
, YearlyIncome
)
select * 
, FLOOR(AgeInYears / 10) * 10 as AgeInYearsCategory
, iif(SalesAmount <= 1155.48, 0, 1) as SmallAmount
from completeData 
where SalesCount between 2 and 7
and SalesAmount > 500