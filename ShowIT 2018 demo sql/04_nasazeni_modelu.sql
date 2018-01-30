create schema ds
	authorization dbo
go

create table ds.Models
(
Id int not null identity constraint pk_Models primary key
, ModelTime datetime2 not null constraint df_ModelTime default (sysdatetime())
, Model varbinary(max) not null
)
go

create or alter proc ds.procTrainModel
as
create table #model (model varbinary(max))
insert #model
exec sp_execute_external_script
	@language = N'R'
	, @script = N'
vzorek <- as.data.frame(InputDataSet);

training <- vzorek[1:1000,];
test <- vzorek[1001:5000,];	

model <- glm(SmallAmount ~ ., family = binomial(link = "logit"), data = training);
trained_model <- data.frame(model=as.raw(serialize(model, NULL)));
'
, @input_data_1 = N'
with completeData as
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
'
, @output_data_1_name = N'trained_model'

insert ds.Models (Model) select model from #model
go

-- zavolani a kontrola
exec ds.procTrainModel
select * from ds.Models

truncate table ds.models