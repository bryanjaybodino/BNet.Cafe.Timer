SELECT 
    COUNT(gm.DBId) AS TotalGames,
    COUNT(DISTINCT gm.DBCategory) AS TotalCategories,
    COUNT(DISTINCT gm.DBComputerId) AS TotalComputers
FROM game_menu gm
WHERE 1 = 1
  AND gm.DBIsDeleted = '{DBIsDeleted}'
  AND gm.DBDateCreated BETWEEN '{DBDateStart}' AND '{DBDateEnd}'