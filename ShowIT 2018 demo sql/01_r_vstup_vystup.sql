exec sp_execute_external_script
	@language = N'R'
	, @script = N'
		x <- as.matrix(InputDataSet);
		OutputDataSet <- as.data.frame(x);'
	, @input_data_1 = N'select * from viCustomersDataSet'
with result sets undefined
go

