SELECT 
    COUNT(v.DBId) AS DBTotalTransactions,
    
    -- Financial Summary
    FORMAT(IFNULL(SUM(v.DBAmount), 0), 2) AS DBTotalIncome,
    
    -- Total Combined Duration
    IFNULL(SUM(v.DBDuration), 0) AS DBTotalDuration,
    CASE 
        WHEN SUM(v.DBDuration) IS NULL OR SUM(v.DBDuration) = 0 THEN '0 mins'
        WHEN FLOOR(SUM(v.DBDuration) / 60) > 0 AND (SUM(v.DBDuration) % 60) > 0 THEN 
            CONCAT(FLOOR(SUM(v.DBDuration) / 60), IF(FLOOR(SUM(v.DBDuration) / 60) = 1, ' hr ', ' hrs '), (SUM(v.DBDuration) % 60), IF((SUM(v.DBDuration) % 60) = 1, ' min', ' mins'))
        WHEN FLOOR(SUM(v.DBDuration) / 60) > 0 THEN 
            CONCAT(FLOOR(SUM(v.DBDuration) / 60), IF(FLOOR(SUM(v.DBDuration) / 60) = 1, ' hr', ' hrs'))
        ELSE 
            CONCAT((SUM(v.DBDuration) % 60), IF((SUM(v.DBDuration) % 60) = 1, ' min', ' mins'))
    END AS DBTotalFormattedDuration

FROM vouchers v
LEFT JOIN users uc ON v.DBCreatedById = uc.DBId
LEFT JOIN users ud ON v.DBDeletedById = ud.DBId
WHERE 1 = 1 
    AND v.DBIsCollected = '{DBIsCollected}'
    AND v.DBDateCreated BETWEEN '{DBDateStart}' AND '{DBDateEnd}'
    AND (v.DBId LIKE '%{DBSearch}%' OR v.DBCode LIKE '%{DBSearch}%' OR uc.DBName LIKE '%{DBSearch}%');