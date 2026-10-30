SELECT 
    COUNT(kl.DBId) AS DBTotalLogs,
    SUM(CASE WHEN kl.DBIsSuccess = 1 OR UPPER(kl.DBIsSuccess) = 'TRUE' THEN 1 ELSE 0 END) AS DBSuccessfulLogs,
    SUM(CASE WHEN kl.DBIsSuccess = 0 OR UPPER(kl.DBIsSuccess) = 'FALSE' THEN 1 ELSE 0 END) AS DBFailedLogs,
    FORMAT(IFNULL(SUM(CASE WHEN kl.DBIsSuccess = 1 OR UPPER(kl.DBIsSuccess) = 'TRUE' THEN CAST(kl.DBAmount AS DECIMAL(18,2)) ELSE 0 END), 0), 2) AS DBTotalAmount
FROM kiosk_logs kl
WHERE 1 = 1 
  AND kl.DBIsDeleted = '{DBIsDeleted}'
  AND kl.DBDateCreated BETWEEN '{DBDateStart}' AND '{DBDateEnd}'
  AND (kl.DBDetails LIKE '%{DBSearch}%')