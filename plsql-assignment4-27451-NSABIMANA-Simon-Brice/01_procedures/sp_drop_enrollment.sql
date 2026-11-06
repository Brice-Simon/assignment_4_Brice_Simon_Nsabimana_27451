
CREATE OR REPLACE PROCEDURE sp_drop_enrollment (
  p_enrollment_id IN  enrollments.enrollment_id%TYPE,
  p_rows_deleted  OUT NUMBER
)
IS
  l_enrollment enrollments%ROWTYPE;
  e_already_graded EXCEPTION;
BEGIN
  p_rows_deleted := 0;

  BEGIN
    SELECT * INTO l_enrollment
      FROM enrollments
     WHERE enrollment_id = p_enrollment_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20006,
        'Enrollment ' || NVL(TO_CHAR(p_enrollment_id), 'NULL') || ' does not exist.');
  END;

  IF l_enrollment.marks IS NOT NULL THEN
    RAISE e_already_graded;
  END IF;

  -- Implicit cursor: DELETE
  DELETE FROM enrollments
   WHERE enrollment_id = p_enrollment_id;

  p_rows_deleted := SQL%ROWCOUNT;

  IF SQL%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Enrollment ' || p_enrollment_id || ' dropped ('
      || p_rows_deleted || ' row deleted).');
  ELSIF SQL%NOTFOUND THEN
    DBMS_OUTPUT.PUT_LINE('Nothing was deleted for enrollment ' || p_enrollment_id);
  END IF;

EXCEPTION
  WHEN e_already_graded THEN
    RAISE_APPLICATION_ERROR(-20007,
      'Enrollment ' || p_enrollment_id || ' is already graded and cannot be dropped.');
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    sp_log_error('sp_drop_enrollment', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099,
      'Unexpected error in sp_drop_enrollment: ' || SUBSTR(SQLERRM, 1, 1500));
END sp_drop_enrollment;
/
SHOW ERRORS
