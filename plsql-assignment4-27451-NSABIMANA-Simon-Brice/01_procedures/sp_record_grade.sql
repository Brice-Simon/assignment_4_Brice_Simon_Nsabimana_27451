
CREATE OR REPLACE PROCEDURE sp_record_grade (
  p_enrollment_id IN  enrollments.enrollment_id%TYPE,
  p_marks         IN  enrollments.marks%TYPE,
  p_grade         OUT enrollments.grade%TYPE
)
IS
  e_enrollment_missing EXCEPTION;
BEGIN
  p_grade := NULL;

  IF p_marks IS NULL OR p_marks < 0 OR p_marks > 100 THEN
    RAISE_APPLICATION_ERROR(-20008,
      'Marks must be between 0 and 100 (received: '
      || NVL(TO_CHAR(p_marks), 'NULL') || ').');
  END IF;

  p_grade := fn_marks_to_grade(p_marks);

  -- Implicit cursor: UPDATE
  UPDATE enrollments
     SET marks = p_marks,
         grade = p_grade
   WHERE enrollment_id = p_enrollment_id;

  IF SQL%NOTFOUND THEN
    RAISE e_enrollment_missing;
  END IF;

  IF SQL%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Enrollment ' || p_enrollment_id || ' graded: '
      || p_marks || ' -> ' || p_grade || ' (rows updated: ' || SQL%ROWCOUNT || ')');
  END IF;

EXCEPTION
  WHEN e_enrollment_missing THEN
    p_grade := NULL;
    RAISE_APPLICATION_ERROR(-20006,
      'Enrollment ' || NVL(TO_CHAR(p_enrollment_id), 'NULL') || ' does not exist.');
  WHEN OTHERS THEN
    p_grade := NULL;
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    sp_log_error('sp_record_grade', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099,
      'Unexpected error in sp_record_grade: ' || SUBSTR(SQLERRM, 1, 1500));
END sp_record_grade;
/
SHOW ERRORS
