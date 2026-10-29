SELECT 
    gm.DBAppName AS GameName,
    gm.DBCategory AS Category,
    COUNT(gm.DBId) AS PlayCount
FROM game_menu gm
WHERE 1 = 1
  AND gm.DBIsDeleted = '{DBIsDeleted}'
  AND gm.DBDateCreated BETWEEN '{DBDateStart}' AND '{DBDateEnd}'
GROUP BY gm.DBAppName, gm.DBCategory
ORDER BY PlayCount DESC
LIMIT 10