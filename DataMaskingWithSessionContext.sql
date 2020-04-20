
/*
Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys? fees, that arise or result from the use or distribution of the Sample Code.
*/

/*

USE AdventureWorks2016 
GO

DROP TABLE IF EXISTS dbo.CustomerInfo

CREATE TABLE dbo.CustomerInfo (
    ID        INT IDENTITY PRIMARY KEY                                           ,
    FirstName VARCHAR(100) NOT NULL                                              ,
    LastName  VARCHAR(100) NOT NULL                                              ,
    Address   VARCHAR(100) MASKED WITH (FUNCTION = 'partial(1,"XXXXXXX",0)') NULL,
    City      VARCHAR(100) MASKED WITH (FUNCTION = 'default()') NULL             ,
    Salary    INT MASKED WITH (FUNCTION          = 'Random(20000,79999)') NULL   ,
    Email     VARCHAR(100) MASKED WITH (FUNCTION = 'email()') NULL
);

INSERT INTO dbo.CustomerInfo
    (
        FirstName,
        LastName ,
        Address  ,
        City     ,
        Salary   ,
        Email
    )
    VALUES
    (
        'Bob'        ,
        'West'       ,
        '123 Main St',
        'New York'   ,
        '50000'      ,
        'bwest@contoso.com'
    )
    ,
    (
        'John'      ,
        'Robbins'   ,
        '333 Elm St',
        'Dallas'    ,
        '60000'     ,
        'jrobbins@contoso.com'
    )
    ,
    (
        'Tim'       ,
        'Roberts'   ,
        '987 1st St',
        'Colorado'  ,
        '70000'     ,
        'troberts@contoso.com'
    );
GO 
-- create some demo users
CREATE USER [tim1] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO 
GRANT SELECT ON CustomerInfo TO tim1
GO 
CREATE USER [amy1] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo]
GO 
GRANT SELECT ON CustomerInfo TO amy1
GRANT UNMASK TO amy1
GO 

-- show the SESSION_CONTEXT in action
SELECT SESSION_CONTEXT(N'executingUser') AS WhoAmI

-- tim does not have unmask permission, but amy does
EXECUTE AS USER = 'tim1'
SELECT * FROM dbo.CustomerInfo
revert
EXECUTE AS USER = 'amy1'
SELECT *
FROM dbo.CustomerInforevert

-- create procedures to cache who is executing the query
CREATE PROCEDURE dbo.setExecContext
    @user nvarchar(50)
AS
BEGIN
    EXEC sys.sp_set_session_context @key = N'executingUser', @value = @user, @readonly = 0
END 
GO 

CREATE PROCEDURE dbo.revertexecContext
AS
BEGIN
    EXEC sys.sp_set_session_context @key = N'executingUser', @value = NULL, @readonly = 0;
END 
GO 

-- show the SESSION_CONTEXT in action
SELECT SESSION_CONTEXT(N'executingUser') AS WhoAmI
DECLARE @curUser nvarchar(10) = N'tim1'
EXEC dbo.setexecContext @curUser
select SESSION_CONTEXT(N'executingUser') AS WhoAmI
EXEC dbo.revertexecContext
select SESSION_CONTEXT(N'executingUser') AS WhoAmI

-- create procedure to get customer info
create procedure dbo.getCustomerInfo
as
begin
    Declare @executingUser nvarchar(50)
    
    SET @ executingUser = CONVERT(nvarchar(50),SESSION_CONTEXT(N'executingUser')) 
    
    IF (@ executingUser IS NOT NULL) BEGIN
        EXECUTE AS USER = @ executingUser
        SELECT * FROM CustomerInfo
    END
    ELSE 
    BEGIN 
        PRINT 'no executingUser context was configured. Please configure then rerun this procedure'
    END

    revert
end 

-- review the customer info using the stored SESSION_CONTEXT

-- first check who we are
select SESSION_CONTEXT(N'executingUser') as WhoAmI

-- set exec context 
exec dbo.setExecContext 'tim1'
select SESSION_CONTEXT(N' executingUser') as WhoAmI

-- this is tim1, so data should be masked
exec dbo.getCustomerInfo  

-- revert
exec dbo.revertexecContext
select SESSION_CONTEXT(N' executingUser') as WhoAmI

-- try to get customer info again, should fail as no executingUser has been configured
exec dbo.getCustomerInfo

-- set executing context to amy1
exec dbo.setExecContext 'amy1'
select SESSION_CONTEXT(N' executingUser') as WhoAmI

-- this is amy1, so data should NOT be masked
exec dbo.getCustomerInfo

-- revert
exec dbo.revertexecContext
select SESSION_CONTEXT(N' executingUser') as WhoAmI

-- to demonstrate that the mask is dynamic, lets rerun as tim and see what happens when we change the mask while tim is our execution context
exec dbo.setexecContext 'tim1'
select SESSION_CONTEXT(N' executingUser') as WhoAmI

-- this is tim1, should be masked. Pay attention to the displayed characters for the ADDRESS column
exec dbo.getCustomerInfo  

-- change the adress mask
ALTER TABLE CustomerInfo
    ALTER COLUMN Address varchar(100) 
        MASKED WITH (FUNCTION = 'partial(2,"XXXXXXX",2)') NULL
GO 

-- this is tim1, now address should show more characters
exec dbo.getCustomerInfo 

-- revert
exec dbo.revertexecContext
select SESSION_CONTEXT(N' executingUser') as WhoAmI

-- drop objects created for this demo query
drop user [amy1]
drop user [tim1]  
drop table dbo.CustomerInfo  
drop procedure dbo.setexecContext
drop procedure dbo.revertexecContext
drop procedure dbo.getCustomerInfo  

*/