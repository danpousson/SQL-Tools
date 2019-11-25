/*
	Dan Pousson
	LinkedServer Tester
	Version 3.0

	*/

set nocount on;

declare 

/*******************************************/
  @Print_Test_Code_Only bit = 0  -- Use = 1 to Turn on to Print the Linked Server test code instead of executing it.
, @LinkedServerTimeOutValue varchar(2) = '2'
, @admin_mode_on bit = 1  --Elevated permissions required. This changes each linked servres timeout setting to the selected timeout value to speed up waiting for failed connections to error out.
/*******************************************/

, @cursor_Name nvarchar(128), @OrigLinkedServerTimeOutValue varchar(2) = 0, @Test_LinkedServer varchar(2000), @Change_LinkedServer_Timeout varchar(500)

DECLARE GetDBName CURSOR FORWARD_ONLY FAST_FORWARD READ_ONLY FOR select name, connect_timeout from sys.servers where server_id <> 0 and name <> 'repl_distributor' and is_data_access_enabled = 1;

OPEN GetDBName
FETCH GetDBName INTO @cursor_Name, @OrigLinkedServerTimeOutValue
 WHILE @@FETCH_STATUS = 0
 BEGIN

	--Create Test command with current cursor LinkedServer Name
	select @Test_LinkedServer = 'exec sp_testlinkedserver @servername =  N' + '''' + name + '''' + char(10) from sys.servers where name = @cursor_Name;
	--Set Change Timeout command with current cursor LinkedServer Timeout
	select @Change_LinkedServer_Timeout = 'EXEC master.dbo.sp_serveroption @server=' + '''' + @cursor_Name +'''' + ', @optname=N''connect timeout'', @optvalue=' + @LinkedServerTimeOutValue ;
		
		--Change LinkedServer Timeout Setting (Shorten the wait time for connectivity issues)
		if @admin_mode_on = 1
		 BEGIN 
			execute (@Change_LinkedServer_Timeout)
		 END

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

	--Revert back LinkedServer Timeout Setting. Default is zero
	if @admin_mode_on = 1
		 BEGIN 
			select @Change_LinkedServer_Timeout = 'EXEC master.dbo.sp_serveroption @server=' + '''' + @cursor_Name +'''' + ', @optname=N''connect timeout'', @optvalue=' + @OrigLinkedServerTimeOutValue ;	
			execute (@Change_LinkedServer_Timeout)
		END

	set @cursor_Name = ''

	FETCH NEXT FROM GetDBName INTO @cursor_Name, @OrigLinkedServerTimeOutValue
 END

CLOSE GetDBName
DEALLOCATE GetDBName