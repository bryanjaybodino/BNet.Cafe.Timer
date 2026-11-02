SELECT * FROM computers 
WHERE 1 
AND DBIsDeleted ='{DBIsDeleted}' 
AND DBComputerName LIKE '%{DBComputerName}%'
ORDER BY DBComputerName ASC 
{LIMIT}