SELECT stddev(
  CASE
    WHEN k = 1 THEN 10000000.2
    WHEN k % 2 = 0 THEN 10000000.1
    ELSE 10000000.3
  END :: double precision
)
FROM generate_series(1, 1001) AS k;
