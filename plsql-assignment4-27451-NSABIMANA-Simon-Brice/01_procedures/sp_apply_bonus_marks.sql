-- Owner  : NSABIMANA Simon Brice | Student ID: 27451
-- =====================================================================
-- Procedure: sp_apply_bonus_marks
-- Purpose  : Add bonus marks (capped at 100) to every graded student of a
--            course in a semester, and refresh their letter grades.
-- Concepts : BULK COLLECT into nested tables (collections), collection methods
--            (COUNT, EXTEND), FORALL with SAVE EXCEPTIONS,
--            SQL%ROWCOUNT after FORALL, ORA-24381 handling.
-- Errors   : -20003 course missing   -20012 bonus outside 1..20
--            -20013 no graded enrollments   -20014 some rows failed in FORALL
--            -20099 unexpected error (also written to ERROR_LOG)
-- =====================================================================
CREATE OR REPLACE PROCEDURE sp_apply_bonus_marks (
  p_course_id    IN  courses.course_id%TYPE,
  p_semester     IN  enrollments.semester%TYPE,
  p_bonus        IN  NUMBER,
  p_rows_updated OUT NUMBER
)
IS
  TYPE t_id_tab    IS TABLE OF enrollments.enrollment_id%TYPE;   -- nested tables
  TYPE t_marks_tab IS TABLE OF enrollments.marks%TYPE;
  TYPE t_grade_tab IS TABLE OF enrollments.grade%TYPE;

  l_ids    t_id_tab;
  l_marks  t_marks_tab;
  l_grades t_grade_tab := t_grade_tab();

  l_course courses%ROWTYPE;

  e_bulk_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);
  e_nothing_to_update EXCEPTION;
  l_error_total PLS_INTEGER;

  TYPE t_int_tab IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
  l_err_index t_int_tab;
  l_err_code  t_int_tab;
BEGIN
  p_rows_updated := 0;

  IF p_bonus IS NULL OR p_bonus < 1 OR p_bonus > 20 THEN
    RAISE_APPLICATION_ERROR(-20012,
      'Bonus must be between 1 and 20 marks (received: '
      || NVL(TO_CHAR(p_bonus), 'NULL') || ').');
  END IF;

  BEGIN
    SELECT * INTO l_course FROM courses WHERE course_id = p_course_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20003, 'Course ' || NVL(TO_CHAR(p_course_id), 'NULL') || ' does not exist.');
  END;

  -- One fetch for all rows
  SELECT enrollment_id, marks
    BULK COLLECT INTO l_ids, l_marks
    FROM enrollments
   WHERE course_id = p_course_id
     AND semester  = p_semester
     AND marks IS NOT NULL;

  IF l_ids.COUNT = 0 THEN
    RAISE e_nothing_to_update;
  END IF;

  -- Process in memory
  l_grades.EXTEND(l_ids.COUNT);
  FOR i IN 1 .. l_ids.COUNT LOOP
    l_marks(i)  := LEAST(l_marks(i) + p_bonus, 100);
    l_grades(i) := fn_marks_to_grade(l_marks(i));
  END LOOP;

  -- One bulk DML for all rows
  FORALL i IN 1 .. l_ids.COUNT SAVE EXCEPTIONS
    UPDATE enrollments
       SET marks = l_marks(i),
           grade = l_grades(i)
     WHERE enrollment_id = l_ids(i);

  p_rows_updated := SQL%ROWCOUNT;
  DBMS_OUTPUT.PUT_LINE('Bonus of ' || p_bonus || ' applied to ' || p_rows_updated
    || ' enrollment(s) in ' || l_course.course_code || ' (' || p_semester || ').');

EXCEPTION
  WHEN e_nothing_to_update THEN
    RAISE_APPLICATION_ERROR(-20013,
      'No graded enrollments found for course ' || p_course_id || ' in ' || p_semester || '.');
  WHEN e_bulk_errors THEN
    l_error_total  := SQL%BULK_EXCEPTIONS.COUNT;
    p_rows_updated := SQL%ROWCOUNT;
    -- copy the bulk-exception details first, then log (logging runs other SQL)
    FOR j IN 1 .. l_error_total LOOP
      l_err_index(j) := SQL%BULK_EXCEPTIONS(j).ERROR_INDEX;
      l_err_code(j)  := SQL%BULK_EXCEPTIONS(j).ERROR_CODE;
    END LOOP;
    FOR j IN 1 .. l_error_total LOOP
      sp_log_error('sp_apply_bonus_marks', -l_err_code(j),
        'Enrollment ' || l_ids(l_err_index(j)) || ': ' || SQLERRM(-l_err_code(j)));
    END LOOP;
    RAISE_APPLICATION_ERROR(-20014,
      l_error_total || ' row(s) failed during the bulk bonus update; see ERROR_LOG.');
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    sp_log_error('sp_apply_bonus_marks', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099,
      'Unexpected error in sp_apply_bonus_marks: ' || SUBSTR(SQLERRM, 1, 1500));
END sp_apply_bonus_marks;
/
SHOW ERRORS
