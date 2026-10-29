SELECT 
    gm.DBId,
    gm.DBAppName,
    gm.DBCategory,
    gm.DBComputerId,
    c.DBComputerName,
    gm.DBDateCreated,
    gm.DBTimeCreated,
    gm.DBIsDeleted
FROM game_menu gm
JOIN computers c ON gm.DBComputerId = c.DBId
WHERE 1 = 1 
  AND gm.DBIsDeleted = '{DBIsDeleted}'
  AND gm.DBCategory = '{DBCategory}'
  AND gm.DBComputerId = '{DBComputerId}'
  AND gm.DBDateCreated BETWEEN '{DBDateStart}' AND '{DBDateEnd}'
  AND (gm.DBAppName LIKE '%{DBSearch}%' OR gm.DBCategory LIKE '%{DBSearch}%' OR gm.DBComputerId LIKE '%{DBSearch}%')
ORDER BY gm.DBId DESC
{LIMIT}