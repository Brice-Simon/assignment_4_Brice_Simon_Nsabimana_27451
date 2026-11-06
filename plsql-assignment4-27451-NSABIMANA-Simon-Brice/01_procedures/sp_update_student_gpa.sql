-- Owner  : NSABIMANA Simon Brice | Student ID: 27451
-- =====================================================================
-- Procedure: sp_update_student_gpa
-- Purpose  : Calculate one student's GPA and store it in STUDENTS.GPA.
-- Concepts : function call, implicit cursor UPDATE (SQL%ROWCOUNT),
--            OUT parameter, error pass-through.
-- Errors   : -20001 student missing  -20020 no graded courses
--            (both raised by fn_calculate_gpa and passed through)
--            -20099 unexpected error (also written to ERROR_LOG)
-- =====================================================================
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
