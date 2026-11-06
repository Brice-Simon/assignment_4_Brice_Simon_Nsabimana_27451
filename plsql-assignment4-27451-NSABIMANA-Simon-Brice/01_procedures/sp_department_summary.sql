
CREATE OR REPLACE PROCEDURE sp_department_summary (
  p_dept_id       IN  departments.dept_id%TYPE,
  p_student_count OUT NUMBER
)
IS
  l_dept departments%ROWTYPE;

  CURSOR c_dept_students (cp_dept_id departments.dept_id%TYPE) IS
    SELECT s.student_id,
           s.first_name || ' ' || s.last_name AS full_name,
           s.status,
           s.gpa
      FROM students s
     WHERE s.dept_id = cp_dept_id
     ORDER BY s.gpa DESC NULLS LAST, s.last_name;
BEGIN
  p_student_count := 0;

  BEGIN
    SELECT * INTO l_dept FROM departments WHERE dept_id = p_dept_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20016,
        'Department ' || NVL(TO_CHAR(p_dept_id), 'NULL') || ' does not exist.');
  END;

  DBMS_OUTPUT.PUT_LINE('=== Department: ' || l_dept.dept_name || ' ===');

  -- Cursor FOR loop: OPEN / FETCH / CLOSE are implicit
  FOR r IN c_dept_students(p_dept_id) LOOP
    p_student_count := p_student_count + 1;
    DBMS_OUTPUT.PUT_LINE(RPAD(TO_CHAR(r.student_id), 7) || RPAD(r.full_name, 26)
      || RPAD(r.status, 11) || 'GPA: ' || NVL(TO_CHAR(r.gpa, 'FM0.00'), 'n/a'));
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Students in department: ' || p_student_count);

EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    sp_log_error('sp_department_summary', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099,
      'Unexpected error in sp_department_summary: ' || SUBSTR(SQLERRM, 1, 1500));
END sp_department_summary;
/
SHOW ERRORS
