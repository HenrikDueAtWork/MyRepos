--declare @t table (ParentID int, ColumnName varchar(10),ChildID int)
--insert into @t values(1,'A',1),(2,'B',1),(3,'C',2),(4,'D',2),(5,'E',3)

--Declare @ParentID int=3

--;with CTE as
--(select ParentID,ColumnName,ChildID from @t where ParentID=@ParentID
--union all
--select a.ParentID,a.ColumnName,a.ChildID from @t a
--inner join cte b on a.ParentID=b.ChildID and a.ParentID<>b.ParentID
----where b.ParentID=@ParentID



--)

--select a.ParentID,a.ColumnName,a.ChildID from @t a inner join cte b on a.ChildID=b.ParentID
----and a.ChildID<>b.ChildID
--order by a.ParentID
----select  * from CTE

declare @OrganizationalStructures table (
 BusinessUnitID smallint identity(1,1),
 BusinessUnit varchar(100) Not Null,
 ParentUnitID smallint
)
insert into @OrganizationalStructures values
('Adventure Works Cycle',NULL),
('Customer Care',1),
('Service',1),
('Channel Sales & Marketing',1),
('Customer Support',2),
('OEM Support',2),
('Central Region',3),
('Eastern Region',3),
('Western Region',3),
('OEM',4),
('Channel Marketing',4),
('National Accounts',4),
('Channel Field Sales',4),
('National Channel Marketing',11),
('Retail Channel Marketing',11),
('Central Region',13),
('Eastern Region',13),
('Western Region',13),
('Bicycles',15),
('Bicycle Parts',15)

;WITH Recursive_CTE AS (
 SELECT
  child.BusinessUnitID,
  CAST(child.BusinessUnit as varchar(100)) BusinessUnit,
  CAST(child.ParentUnitID as SmallInt) ParentUnitID,
  CAST(NULL as varchar(100)) ParentUnit,
  CAST('>> ' as varchar(100)) LVL,
  CAST(child.BusinessUnitID as varchar(100)) Hierarchy,
  1 AS RecursionLevel
 FROM @OrganizationalStructures child
 WHERE BusinessUnitID = 1

 UNION ALL

 SELECT
  child.BusinessUnitID,
  CAST(LVL + child.BusinessUnit as varchar(100)) AS BusinessUnit,
  child.ParentUnitID,
  parent.BusinessUnit ParentUnit,
  CAST('>> ' + LVL as varchar(100)) AS LVL,
  CAST(Hierarchy + ':' + CAST(child.BusinessUnitID as varchar(100)) as varchar(100)) Hierarchy,
  RecursionLevel + 1 AS RecursionLevel
 FROM Recursive_CTE parent
 INNER JOIN @OrganizationalStructures child ON child.ParentUnitID = parent.BusinessUnitID
)
SELECT * FROM Recursive_CTE ORDER BY Hierarchy