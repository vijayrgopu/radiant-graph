SELECT
  zip3,
  COUNT(DISTINCT member_id_hash) AS member_count
FROM
  customer_data_by_client_date_zip
GROUP BY
  zip3
ORDER BY
  member_count DESC
LIMIT 10;
