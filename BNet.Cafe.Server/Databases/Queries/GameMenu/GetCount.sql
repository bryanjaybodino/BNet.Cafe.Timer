SELECT 
    COUNT(gm.DBId) AS DBTotalGames,
    COUNT(DISTINCT gm.DBCategory) AS DBTotalCategories,
    COUNT(DISTINCT gm.DBComputerId) AS DBTotalComputers
FROM game_menu gm
WHERE 1 = 1 
  AND gm.DBIsDeleted = '{DBIsDeleted}'
  AND gm.DBCategory = '{DBCategory}'
  AND gm.DBComputerId = '{DBComputerId}'
  AND gm.DBDateCreated BETWEEN '{DBDateStart}' AND '{DBDateEnd}'