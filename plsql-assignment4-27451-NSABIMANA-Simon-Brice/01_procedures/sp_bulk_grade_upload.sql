CREATE OR REPLACE PROCEDURE sp_bulk_grade_upload (
  p_enrollment_ids IN  t_number_tab,
  p_marks          IN  t_number_tab,
  p_success_count  OUT NUMBER,
  p_error_count    OUT NUMBER
)
IS
  TYPE t_grade_tab IS TABLE OF enrollments.grade%TYPE INDEX BY PLS_INTEGER;
  TYPE t_int_tab   IS TABLE OF PLS_INTEGER            INDEX BY PLS_INTEGER;

  l_grades t_grade_tab;   -- derived letter grades (same index as the inputs)
  l_failed t_int_tab;     -- index -> Oracle error code of rows rejected by FORALL
  l_rows   t_int_tab;     -- index -> rows touched by that UPDATE (SQL%BULK_ROWCOUNT)

  e_bulk_errors  EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);

  e_invalid_marks EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_invalid_marks, -20010);
BEGIN
  p_success_count := 0;
  p_error_count   := 0;

  -- ---- Validate the two lists ----
  IF p_enrollment_ids IS NULL OR p_marks IS NULL
     OR p_enrollment_ids.COUNT = 0
     OR p_enrollment_ids.COUNT <> p_marks.COUNT THEN
    RAISE_APPLICATION_ERROR(-20009,
      'Enrollment ids and marks must be non-empty lists of the same size.');
  END IF;

  FOR i IN 1 .. p_enrollment_ids.COUNT LOOP
    IF p_enrollment_ids(i) IS NULL OR p_marks(i) IS NULL THEN
      RAISE_APPLICATION_ERROR(-20009, 'NULL value found at position ' || i || '.');
    END IF;
  END LOOP;

  -- ---- Derive the grades in PL/SQL ----
  -- Out-of-range marks get a NULL grade; the table CHECK constraints then
  -- reject the row inside FORALL, which demonstrates SAVE EXCEPTIONS.
  FOR i IN 1 .. p_enrollment_ids.COUNT LOOP
    BEGIN
      l_grades(i) := fn_marks_to_grade(p_marks(i));
    EXCEPTION
      WHEN e_invalid_marks THEN
        l_grades(i) := NULL;
    END;
  END LOOP;

  -- ---- One round trip to the SQL engine for ALL rows ----
  BEGIN
    FORALL i IN 1 .. p_enrollment_ids.COUNT SAVE EXCEPTIONS
      UPDATE enrollments
         SET marks = p_marks(i),
             grade = l_grades(i)
       WHERE enrollment_id = p_enrollment_ids(i);

    -- no errors: remember rows touched per statement
    FOR i IN 1 .. p_enrollment_ids.COUNT LOOP
      l_rows(i) := SQL%BULK_ROWCOUNT(i);
    END LOOP;
  EXCEPTION
    WHEN e_bulk_errors THEN
      -- copy the information first, before any other SQL is executed
      FOR i IN 1 .. p_enrollment_ids.COUNT LOOP
        l_rows(i) := SQL%BULK_ROWCOUNT(i);
      END LOOP;
      FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
        l_failed(SQL%BULK_EXCEPTIONS(j).ERROR_INDEX) := SQL%BULK_EXCEPTIONS(j).ERROR_CODE;
      END LOOP;
  END;

  -- ---- Classify every row ----
  FOR i IN 1 .. p_enrollment_ids.COUNT LOOP
    IF l_failed.EXISTS(i) THEN
      p_error_count := p_error_count + 1;
      sp_log_error('sp_bulk_grade_upload', -l_failed(i),
        'Row ' || i || ' (enrollment ' || p_enrollment_ids(i) || ', marks '
        || p_marks(i) || '): ' || SQLERRM(-l_failed(i)));
      DBMS_OUTPUT.PUT_LINE('  REJECTED row ' || i || ' (enrollment ' || p_enrollment_ids(i)
        || '): ' || SQLERRM(-l_failed(i)));
    ELSIF l_rows(i) = 0 THEN
      p_error_count := p_error_count + 1;
      sp_log_error('sp_bulk_grade_upload', -20006,
        'Row ' || i || ': enrollment ' || p_enrollment_ids(i) || ' does not exist.');
      DBMS_OUTPUT.PUT_LINE('  REJECTED row ' || i || ': enrollment '
        || p_enrollment_ids(i) || ' does not exist.');
    ELSE
      p_success_count := p_success_count + 1;
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Bulk upload finished: ' || p_success_count || ' updated, '
    || p_error_count || ' rejected.');

EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    sp_log_error('sp_bulk_grade_upload', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099,
      'Unexpected error in sp_bulk_grade_upload: ' || SUBSTR(SQLERRM, 1, 1500));
END sp_bulk_grade_upload;
/
SHOW ERRORS
