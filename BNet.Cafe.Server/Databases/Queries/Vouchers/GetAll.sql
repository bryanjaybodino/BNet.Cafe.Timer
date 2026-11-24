SELECT 
    v.DBId,
    v.DBCode,
    v.DBDuration,
    CASE 
        WHEN v.DBDuration IS NULL OR v.DBDuration = 0 THEN '0 min'
        WHEN FLOOR(v.DBDuration / 60) > 0 AND (v.DBDuration % 60) > 0 THEN 
            CONCAT(FLOOR(v.DBDuration / 60), IF(FLOOR(v.DBDuration / 60) = 1, ' hr ', ' hrs '), (v.DBDuration % 60), IF((v.DBDuration % 60) = 1, ' min', ' mins'))
        WHEN FLOOR(v.DBDuration / 60) > 0 THEN 
            CONCAT(FLOOR(v.DBDuration / 60), IF(FLOOR(v.DBDuration / 60) = 1, ' hr', ' hrs'))
        ELSE 
            CONCAT((v.DBDuration % 60), IF((v.DBDuration % 60) = 1, ' min', ' mins'))
    END AS DBFormattedDuration,
    FORMAT(v.DBAmount, 2) AS DBAmount,
    v.DBIsCollected,
    v.DBDateCreated,
    v.DBTimeCreated,
    -- Creator info
    v.DBCreatedById,
    IFNULL(uc.DBName, 'System / Unknown') AS DBCreatedByName,
    -- Deleter info (if deleted)
    v.DBDeletedById,
    IFNULL(ud.DBName, '--') AS DBDeletedByName,
    v.DBDateDeleted,
    v.DBTimeDeleted
FROM vouchers v
LEFT JOIN users uc ON v.DBCreatedById = uc.DBId
LEFT JOIN users ud ON v.DBDeletedById = ud.DBId
WHERE 1 = 1 
  AND v.DBIsCollected = '{DBIsCollected}'
  AND v.DBDateCreated BETWEEN '{DBDateStart}' AND '{DBDateEnd}'
  AND (v.DBId LIKE '%{DBSearch}%' OR v.DBCode LIKE '%{DBSearch}%' OR uc.DBName LIKE '%{DBSearch}%' OR ud.DBName LIKE '%{DBSearch}%')
ORDER BY v.DBId DESC
{LIMIT}