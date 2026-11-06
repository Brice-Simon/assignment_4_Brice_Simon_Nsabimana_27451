
CREATE OR REPLACE PROCEDURE sp_update_student_gpa (
  p_student_id IN  students.student_id%TYPE,
  p_gpa        OUT students.gpa%TYPE
)
IS
BEGIN
  p_gpa := NULL;
  p_gpa := fn_calculate_gpa(p_student_id);

  UPDATE students
     SET gpa = p_gpa
   WHERE student_id = p_student_id;

  IF SQL%ROWCOUNT = 1 THEN
    DBMS_OUTPUT.PUT_LINE('GPA of student ' || p_student_id || ' updated to '
      || TO_CHAR(p_gpa, 'FM0.00'));
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    p_gpa := NULL;
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    sp_log_error('sp_update_student_gpa', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099,
      'Unexpected error in sp_update_student_gpa: ' || SUBSTR(SQLERRM, 1, 1500));
END sp_update_student_gpa;
/
SHOW ERRORS
