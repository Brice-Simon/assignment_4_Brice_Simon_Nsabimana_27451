
CREATE OR REPLACE FUNCTION fn_calculate_gpa (
  p_student_id IN students.student_id%TYPE
) RETURN NUMBER
IS
  CURSOR c_graded (cp_student_id students.student_id%TYPE) IS
    SELECT e.grade, c.credits
      FROM enrollments e
      JOIN courses c ON c.course_id = e.course_id
     WHERE e.student_id = cp_student_id
       AND e.grade IS NOT NULL;

  l_dummy    students.student_id%TYPE;
  l_points   NUMBER := 0;
  l_credits  NUMBER := 0;
  e_no_graded_courses EXCEPTION;
BEGIN
  -- Does the student exist? (predefined exception NO_DATA_FOUND)
  BEGIN
    SELECT student_id INTO l_dummy
      FROM students
     WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001,
        'Student ' || NVL(TO_CHAR(p_student_id), 'NULL') || ' does not exist.');
  END;

  -- Explicit cursor FOR loop
  FOR r IN c_graded(p_student_id) LOOP
    l_points  := l_points  + fn_grade_points(r.grade) * r.credits;
    l_credits := l_credits + r.credits;
  END LOOP;

  IF l_credits = 0 THEN
    RAISE e_no_graded_courses;
  END IF;

  RETURN ROUND(l_points / l_credits, 2);

EXCEPTION
  WHEN e_no_graded_courses THEN
    RAISE_APPLICATION_ERROR(-20020,
      'Student ' || p_student_id || ' has no graded courses; GPA cannot be calculated.');
END fn_calculate_gpa;
/
SHOW ERRORS
