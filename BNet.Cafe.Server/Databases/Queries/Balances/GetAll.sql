SELECT 
    b.DBId,
    b.DBUserId,
    IFNULL(u.DBEmail, '--') AS DBEmail,
    IFNULL(u.DBName, 'Guest / Walk-in') AS DBName,
    IFNULL(b.DBDescription, 'TopUp') AS DBDescription,
    CASE 
        WHEN u.DBRole = 'ADMIN' THEN 0 
        ELSE b.DBDuration 
    END AS DBDuration,
    CASE 
        WHEN u.DBRole = 'ADMIN' THEN '0 min'
        WHEN b.DBDuration IS NULL OR b.DBDuration = 0 THEN '0 min'
        ELSE CONCAT(
            IF(b.DBDuration < 0, '-', ''),
            CASE 
                WHEN FLOOR(ABS(b.DBDuration) / 60) > 0 AND (ABS(b.DBDuration) % 60) > 0 THEN 
                    CONCAT(
                        FLOOR(ABS(b.DBDuration) / 60), IF(FLOOR(ABS(b.DBDuration) / 60) = 1, ' hr ', ' hrs '), 
                        (ABS(b.DBDuration) % 60), IF((ABS(b.DBDuration) % 60) = 1, ' min', ' mins')
                    )
                WHEN FLOOR(ABS(b.DBDuration) / 60) > 0 THEN 
                    CONCAT(FLOOR(ABS(b.DBDuration) / 60), IF(FLOOR(ABS(b.DBDuration) / 60) = 1, ' hr', ' hrs'))
                ELSE 
                    CONCAT((ABS(b.DBDuration) % 60), IF((ABS(b.DBDuration) % 60) = 1, ' min', ' mins'))
            END
        )
    END AS DBFormattedDuration,
    CASE 
        WHEN u.DBRole = 'ADMIN' THEN '0.00'
        ELSE FORMAT(b.DBAmount, 2) 
    END AS DBAmount,
    b.DBCreatedById,
    IFNULL(uc.DBName, 'System / Unknown') AS DBCreatedByName,
    b.DBDateCreated,
    b.DBTimeCreated,
    b.DBIsDeleted
FROM balances b
LEFT JOIN users u ON b.DBUserId = u.DBId
LEFT JOIN users uc ON b.DBCreatedById = uc.DBId
WHERE 1 = 1 
  AND b.DBIsDeleted = '{DBIsDeleted}'
  AND b.DBUserId = '{DBUserId}'
  AND b.DBDateCreated BETWEEN '{DBDateStart}' AND '{DBDateEnd}'
  AND (u.DBEmail LIKE '%{DBSearch}%' OR u.DBName LIKE '%{DBSearch}%' OR b.DBDescription LIKE '%{DBSearch}%')
ORDER BY b.DBId DESC
{LIMIT}