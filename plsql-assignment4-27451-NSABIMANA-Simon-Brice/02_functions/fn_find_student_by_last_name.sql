
CREATE OR REPLACE FUNCTION fn_find_student_by_last_name (
  p_last_name IN students.last_name%TYPE
) RETURN students.student_id%TYPE
IS
  l_student_id students.student_id%TYPE;
BEGIN
  SELECT student_id
    INTO l_student_id
    FROM students
   WHERE UPPER(last_name) = UPPER(p_last_name);

  RETURN l_student_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20041,
      'No student found with last name ''' || p_last_name || '''.');
  WHEN TOO_MANY_ROWS THEN
    RAISE_APPLICATION_ERROR(-20040,
      'Several students have last name ''' || p_last_name
      || '''. Search by student_id instead.');
END fn_find_student_by_last_name;
/
SHOW ERRORS
