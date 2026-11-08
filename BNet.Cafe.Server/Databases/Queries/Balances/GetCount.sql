SELECT 
    COUNT(b.DBId) AS DBTotalTransactions,
    COUNT(DISTINCT b.DBUserId) AS DBTotalUsers,
    CASE 
        WHEN MAX(u.DBRole) = 'ADMIN' THEN '0.00'
        ELSE FORMAT(IFNULL(SUM(b.DBAmount), 0), 2) 
    END AS DBTotalIncome,
    CASE 
        WHEN MAX(u.DBRole) = 'ADMIN' THEN '0 min'
        WHEN IFNULL(SUM(b.DBDuration), 0) = 0 THEN '0 min'
        ELSE CONCAT(
            IF(SUM(b.DBDuration) < 0, '-', ''),
            CASE 
                WHEN FLOOR(ABS(SUM(b.DBDuration)) / 60) > 0 AND (ABS(SUM(b.DBDuration)) % 60) > 0 THEN 
                    CONCAT(
                        FLOOR(ABS(SUM(b.DBDuration)) / 60), IF(FLOOR(ABS(SUM(b.DBDuration)) / 60) = 1, ' hr ', ' hrs '), 
                        (ABS(SUM(b.DBDuration)) % 60), IF((ABS(SUM(b.DBDuration)) % 60) = 1, ' min', ' mins')
                    )
                WHEN FLOOR(ABS(SUM(b.DBDuration)) / 60) > 0 THEN 
                    CONCAT(FLOOR(ABS(SUM(b.DBDuration)) / 60), IF(FLOOR(ABS(SUM(b.DBDuration)) / 60) = 1, ' hr', ' hrs'))
                ELSE 
                    CONCAT((ABS(SUM(b.DBDuration)) % 60), IF((ABS(SUM(b.DBDuration)) % 60) = 1, ' min', ' mins'))
            END
        )
    END AS DBTotalFormattedDuration
FROM balances b
LEFT JOIN users u ON b.DBUserId = u.DBId
WHERE 1 = 1 
  AND b.DBIsDeleted = '{DBIsDeleted}'
  AND b.DBUserId = '{DBUserId}'
  AND b.DBDateCreated BETWEEN '{DBDateStart}' AND '{DBDateEnd}'