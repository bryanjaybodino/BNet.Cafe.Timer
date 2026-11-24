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
    v.DBCreatedById,
    IFNULL(uc.DBName, 'System / Unknown') AS DBCreatedByName
FROM vouchers v
LEFT JOIN users uc ON v.DBCreatedById = uc.DBId
ORDER BY v.DBId DESC
{LIMIT}