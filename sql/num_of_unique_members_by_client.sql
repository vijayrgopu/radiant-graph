SELECT
  client_name,
  COUNT(DISTINCT member_id_hash) AS unique_member_count
FROM
  customer_data_by_client_date_zip
GROUP BY
  client_name;
