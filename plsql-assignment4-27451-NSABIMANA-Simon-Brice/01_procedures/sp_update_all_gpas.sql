
CREATE OR REPLACE PROCEDURE sp_update_all_gpas (
  p_updated OUT NUMBER,
  p_skipped OUT NUMBER
)
IS
  TYPE t_id_tab  IS TABLE OF students.student_id%TYPE;                  -- nested table
  TYPE t_gpa_tab IS TABLE OF students.gpa%TYPE INDEX BY PLS_INTEGER;    -- associative array

  l_all_ids t_id_tab;
  l_ids     t_id_tab := t_id_tab();
  l_gpas    t_gpa_tab;
  l_gpa     students.gpa%TYPE;
  l_pos     PLS_INTEGER;

  e_no_graded_courses EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_no_graded_courses, -20020);

  e_bulk_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);
  l_error_total PLS_INTEGER;

  TYPE t_int_tab IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
  l_err_index t_int_tab;
  l_err_code  t_int_tab;
BEGIN
  p_updated := 0;
  p_skipped := 0;

  -- One fetch for all students
  SELECT student_id
    BULK COLLECT INTO l_all_ids
    FROM students
   ORDER BY student_id;

  -- Compute in memory; skip students that have no graded courses
  FOR i IN 1 .. l_all_ids.COUNT LOOP
    BEGIN
      l_gpa := fn_calculate_gpa(l_all_ids(i));
      l_ids.EXTEND;
      l_pos := l_ids.LAST;
      l_ids(l_pos)  := l_all_ids(i);
      l_gpas(l_pos) := l_gpa;
    EXCEPTION
      WHEN e_no_graded_courses THEN
        p_skipped := p_skipped + 1;
    END;
  END LOOP;

  -- One bulk DML for all computed GPAs
  IF l_ids.COUNT > 0 THEN
    FORALL i IN 1 .. l_ids.COUNT SAVE EXCEPTIONS
      UPDATE students
         SET gpa = l_gpas(i)
       WHERE student_id = l_ids(i);

    p_updated := SQL%ROWCOUNT;
  END IF;

  DBMS_OUTPUT.PUT_LINE('GPA refresh: ' || p_updated || ' updated, '
    || p_skipped || ' skipped (no graded courses).');

EXCEPTION
  WHEN e_bulk_errors THEN
    l_error_total := SQL%BULK_EXCEPTIONS.COUNT;
    -- copy the bulk-exception details first, then log (logging runs other SQL)
    FOR j IN 1 .. l_error_total LOOP
      l_err_index(j) := SQL%BULK_EXCEPTIONS(j).ERROR_INDEX;
      l_err_code(j)  := SQL%BULK_EXCEPTIONS(j).ERROR_CODE;
    END LOOP;
    FOR j IN 1 .. l_error_total LOOP
      sp_log_error('sp_update_all_gpas', -l_err_code(j),
        'Student ' || l_ids(l_err_index(j)) || ': ' || SQLERRM(-l_err_code(j)));
    END LOOP;
    RAISE_APPLICATION_ERROR(-20014,
      l_error_total || ' row(s) failed during the bulk GPA update; see ERROR_LOG.');
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    sp_log_error('sp_update_all_gpas', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099,
      'Unexpected error in sp_update_all_gpas: ' || SUBSTR(SQLERRM, 1, 1500));
END sp_update_all_gpas;
/
SHOW ERRORS
