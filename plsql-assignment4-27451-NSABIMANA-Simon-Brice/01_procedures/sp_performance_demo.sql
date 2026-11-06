
CREATE OR REPLACE PROCEDURE sp_performance_demo (
  p_rows           IN  PLS_INTEGER,
  p_rowbyrow_cs    OUT NUMBER,     -- centiseconds
  p_bulk_cs        OUT NUMBER      -- centiseconds
)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;

  TYPE t_id_tab      IS TABLE OF perf_demo.id%TYPE      INDEX BY PLS_INTEGER;
  TYPE t_payload_tab IS TABLE OF perf_demo.payload%TYPE INDEX BY PLS_INTEGER;
  l_ids      t_id_tab;
  l_payloads t_payload_tab;
  l_start    NUMBER;
BEGIN
  p_rowbyrow_cs := NULL;
  p_bulk_cs     := NULL;

  IF p_rows IS NULL OR p_rows < 1 OR p_rows > 1000000 THEN
    RAISE_APPLICATION_ERROR(-20017,
      'p_rows must be between 1 and 1000000 (received: '
      || NVL(TO_CHAR(p_rows), 'NULL') || ').');
  END IF;

  DELETE FROM perf_demo;

  -- 1) Row-by-row: p_rows context switches PL/SQL -> SQL
  l_start := DBMS_UTILITY.GET_TIME;
  FOR i IN 1 .. p_rows LOOP
    INSERT INTO perf_demo (id, payload) VALUES (i, 'row-' || i);
  END LOOP;
  p_rowbyrow_cs := DBMS_UTILITY.GET_TIME - l_start;

  DELETE FROM perf_demo;

  -- 2) Bulk: build collections first, then ONE context switch
  FOR i IN 1 .. p_rows LOOP
    l_ids(i)      := i;
    l_payloads(i) := 'row-' || i;
  END LOOP;

  l_start := DBMS_UTILITY.GET_TIME;
  FORALL i IN 1 .. p_rows
    INSERT INTO perf_demo (id, payload) VALUES (l_ids(i), l_payloads(i));
  p_bulk_cs := DBMS_UTILITY.GET_TIME - l_start;

  DELETE FROM perf_demo;      -- leave the scratch table empty
  COMMIT;                     -- an autonomous transaction must end with COMMIT/ROLLBACK

  DBMS_OUTPUT.PUT_LINE('Rows: ' || p_rows || ' | row-by-row: ' || p_rowbyrow_cs
    || ' cs | FORALL: ' || p_bulk_cs || ' cs');

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    p_rowbyrow_cs := NULL;
    p_bulk_cs     := NULL;
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    sp_log_error('sp_performance_demo', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099,
      'Unexpected error in sp_performance_demo: ' || SUBSTR(SQLERRM, 1, 1500));
END sp_performance_demo;
/
SHOW ERRORS
