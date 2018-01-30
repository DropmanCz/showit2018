-- funkce "balici" parametry do vysledkove sady
create or alter function ds.fnModelSchema(
	@CustomerKey int
	, @MaritalStatus nchar(1)
	, @Gender nchar(1)
	, @NumberCarsOwned int
	, @NumberChildrenAtHome int
	, @DaysFromLastOrder int
	, @AgeInYears int
	, @SalesAmount int
	, @SalesCount int
	, @YearlyIncome int
	, @AgeInYearsCategory int
	, @SmallAmount bit
)
returns table
as
return
select @CustomerKey as CustomerKey, @MaritalStatus as MaritalStatus, @Gender as Gender
	, @NumberCarsOwned as NumberCarsOwned, @NumberChildrenAtHome as NumberChildrenAtHome
	, @DaysFromLastOrder as DaysFromLastOrder, @AgeInYears as AgeInYears
	, @SalesAmount as SalesAmount, @SalesCount as SalesCount, @YearlyIncome as YearlyIncome
	, @AgeInYearsCategory as AgeInYearsCategory, @SmallAmount as SmallAmount
go

-- predikcni procedura
create or alter proc ds.procPredictSmallAmount
	@CustomerKey int
	, @MaritalStatus nchar(1)
	, @Gender nchar(1)
	, @NumberCarsOwned int
	, @NumberChildrenAtHome int
	, @DaysFromLastOrder int
	, @AgeInYears int
	, @SalesAmount int
	, @SalesCount int
	, @YearlyIncome int
	, @AgeInYearsCategory int
	, @SmallAmount bit
as

declare @q nvarchar(max) = N'SELECT * FROM ds.fnModelSchema(@CustomerKey
	, @MaritalStatus
	, @Gender
	, @NumberCarsOwned
	, @NumberChildrenAtHome
	, @DaysFromLastOrder
	, @AgeInYears
	, @SalesAmount
	, @SalesCount
	, @YearlyIncome
	, @AgeInYearsCategory
	, @SmallAmount)'
declare @m varbinary(max) = (select top 1 Model from ds.Models)

exec sp_execute_external_script  
	@language = N'R'
	, @script = N'  
	library("ROCR");
	library("gplots");
	mod <- unserialize(as.raw(model));  
	OutputDataSet <- predict(mod, newdata = InputDataSet, type = "response");
	OutputDataSet <- data.frame(OutputDataSet);'
	, @input_data_1 = @q
	, @params = N'@model varbinary(max)
	,@CustomerKey int
	, @MaritalStatus nchar(1)
	, @Gender nchar(1)
	, @NumberCarsOwned int
	, @NumberChildrenAtHome int
	, @DaysFromLastOrder int
	, @AgeInYears int
	, @SalesAmount int
	, @SalesCount int
	, @YearlyIncome int
	, @AgeInYearsCategory int
	, @SmallAmount bit
	', @model = @m
	, @CustomerKey = @CustomerKey
	, @MaritalStatus = @MaritalStatus
	, @Gender =  @Gender
	, @NumberCarsOwned = @NumberCarsOwned
	, @NumberChildrenAtHome = @NumberChildrenAtHome
	, @DaysFromLastOrder = @DaysFromLastOrder
	, @AgeInYears = @AgeInYears
	, @SalesAmount = @SalesAmount
	, @SalesCount = @SalesCount
	, @YearlyIncome = @YearlyIncome
	, @AgeInYearsCategory = @AgeInYearsCategory
	, @SmallAmount = @SmallAmount
	with result sets undefined
go

-- test vysledku

exec ds.procPredictSmallAmount
	@CustomerKey = 0
	, @MaritalStatus = 'S'
	, @Gender = 'M'
	, @NumberCarsOwned = 1
	, @NumberChildrenAtHome = 3
	, @DaysFromLastOrder = 1500
	, @AgeInYears = 45
	, @SalesAmount = 0
	, @SalesCount = 0
	, @YearlyIncome = 350000
	, @AgeInYearsCategory = 40
	, @SmallAmount = 0
go

--exec sp_execute_external_script @language = N'R', @script = N'OutputDataSet <- data.frame(installed.packages())'
--exec sp_execute_external_script @language = N'R', @script = N'find.package("ROCR")'

--EXECUTE sp_execute_external_script  @language = N'R'
--, @script = N'OutputDataSet <- data.frame(.libPaths());'
--WITH RESULT SETS (([DefaultLibraryName] VARCHAR(MAX) NOT NULL));
--GO

--exec sp_execute_external_script @language = N'R'
--, @script = N'
--if (!(''ROCR'' %in% rownames(installed.packages()))){ 
--  install.packages(''ROCR'') ;
--}'