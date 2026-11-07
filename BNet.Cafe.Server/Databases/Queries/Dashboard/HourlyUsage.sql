SELECT 
    HOUR(r.DBTimeCreated) AS DBHour,
    CONCAT(LPAD(HOUR(r.DBTimeCreated), 2, '0'), ':00') AS DBHourLabel,
    COUNT(r.DBId) AS DBCount,
    COUNT(DISTINCT r.DBComputerId) AS ActiveComputersCount
FROM rentals r
WHERE 1 = 1
  AND r.DBIsDeleted = '{DBIsDeleted}'
  AND r.DBDateCreated BETWEEN '{DBDateStart}' AND '{DBDateEnd}'
GROUP BY DBHour, DBHourLabel
ORDER BY DBHour ASC;