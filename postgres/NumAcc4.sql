SELECT stddev(
  CASE
    WHEN i = 0 THEN 10000000.2
    WHEN i % 2 = 1 THEN 10000000.1
    ELSE 10000000.3
  END :: double precision
)
FROM generate_series(0, 1000) AS i;
