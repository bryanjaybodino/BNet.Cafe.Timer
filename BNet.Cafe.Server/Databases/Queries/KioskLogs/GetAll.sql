SELECT 
    kl.DBId,
    kl.DBDetails,
    FORMAT(CAST(kl.DBAmount AS DECIMAL(18,2)), 2) AS DBAmount,
    kl.DBIsSuccess,
    kl.DBType,
    kl.DBDateCreated,
    kl.DBTimeCreated,
    kl.DBIsDeleted
FROM kiosk_logs kl
WHERE 1 = 1 
  AND kl.DBIsDeleted = '{DBIsDeleted}'
  AND kl.DBDateCreated BETWEEN '{DBDateStart}' AND '{DBDateEnd}'
  AND (kl.DBDetails LIKE '%{DBSearch}%')
ORDER BY kl.DBId DESC
{LIMIT}