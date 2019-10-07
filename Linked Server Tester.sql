/*
	Dan Pousson
	LinkedServer Tester
	Version 1.1

	*/

set nocount on;

declare 

/*******************************************/
  @Print_Test_Code_Only bit = 0 --Turn on to Print the Linked Server test code instead of executing it.
, @LinkedServerTimeOutValue varchar(2) = '2'
/*******************************************/

, @cursor_Name nvarchar(128), @Test_LinkedServer varchar(2000) , @Change_LinkedServer_Timeout varchar(500)

DECLARE GetDBName CURSOR FORWARD_ONLY FAST_FORWARD READ_ONLY FOR select name from sys.servers where server_id <> 0 and name <> 'repl_distributor';

OPEN GetDBName
FETCH GetDBName INTO @cursor_Name
 WHILE @@FETCH_STATUS = 0
 BEGIN

	--Get LinkedServer Names
	select @Test_LinkedServer = 'exec sp_testlinkedserver @servername =  N' + '''' + name + '''' + char(10) from sys.servers where server_id <> 0 and name = @cursor_Name;
	--Get LinkedServer Timeout for current individual target
	select @Change_LinkedServer_Timeout = 'EXEC master.dbo.sp_serveroption @server=' + '''' + @cursor_Name +'''' + ', @optname=N''connect timeout'', @optvalue=' + @LinkedServerTimeOutValue ;
		
		--Change LinkedServer Timeout Setting (Shorten the wait time for connectivity issues)
		 execute (@Change_LinkedServer_Timeout)

	BEGIN TRY
	declare @error varchar(2000)

		--Test LinkedServer
		IF @Print_Test_Code_Only = 1  print (@Test_LinkedServer) + 'GO' 
		ELSE execute (@Test_LinkedServer)

		set @error = ERROR_MESSAGE()

	END TRY
	BEGIN CATCH
		
		DECLARE @msg varchar(500) = @cursor_Name + ' Failed on: ' + @@servername
		--RAISERROR (@msg,16,1)
		 PRINT @msg + ': ' + ERROR_MESSAGE()

	END CATCH

	--Revert back LinkedServer Timeout Setting what is usually 0
	select @Change_LinkedServer_Timeout = 'EXEC master.dbo.sp_serveroption @server=' + '''' + @cursor_Name +'''' + ', @optname=N''connect timeout'', @optvalue=N''0'' ';
	
		execute (@Change_LinkedServer_Timeout)

	set @cursor_Name = ''

	FETCH NEXT FROM GetDBName INTO @cursor_Name
 END

CLOSE GetDBName
DEALLOCATE GetDBName