SELECT 
    r.DBId,
    r.DBComputerId,
    c.DBComputerName,
    r.DBUserId,
    IFNULL(u.DBEmail, '--') AS DBEmail,
    IFNULL(u.DBName, 'Guest / Walk-in') AS DBName,
    r.DBDuration,
    CASE 
        WHEN r.DBDuration IS NULL OR r.DBDuration = 0 THEN '0 min'
        WHEN FLOOR(r.DBDuration / 60) > 0 AND (r.DBDuration % 60) > 0 THEN 
            CONCAT(FLOOR(r.DBDuration / 60), IF(FLOOR(r.DBDuration / 60) = 1, ' hr ', ' hrs '), (r.DBDuration % 60), IF((r.DBDuration % 60) = 1, ' min', ' mins'))
        WHEN FLOOR(r.DBDuration / 60) > 0 THEN 
            CONCAT(FLOOR(r.DBDuration / 60), IF(FLOOR(r.DBDuration / 60) = 1, ' hr', ' hrs'))
        ELSE 
            CONCAT((r.DBDuration % 60), IF((r.DBDuration % 60) = 1, ' min', ' mins'))
    END AS DBFormattedDuration,
    FORMAT(r.DBAmount, 2) AS DBAmount,
    r.DBDateCreated,
    r.DBTimeCreated,
    -- Creator info
    r.DBCreatedById,
    IFNULL(uc.DBName, 'System / Unknown') AS DBCreatedByName,
    -- Deleter info (if deleted)
    r.DBDeletedById,
    IFNULL(ud.DBName, '--') AS DBDeletedByName,
    r.DBDateDeleted,
    r.DBTimeDeleted,
    r.DBIsDeleted
FROM rentals r
LEFT JOIN computers c ON r.DBComputerId = c.DBId
LEFT JOIN users u ON r.DBUserId = u.DBId
LEFT JOIN users uc ON r.DBCreatedById = uc.DBId
LEFT JOIN users ud ON r.DBDeletedById = ud.DBId
WHERE 1 = 1 
  AND r.DBDuration = '{DBDuration}'
  AND r.DBUserId = '{DBUserId}'
  AND r.DBDateCreated = '{DBDateCreated}'
ORDER BY r.DBId DESC
{LIMIT}