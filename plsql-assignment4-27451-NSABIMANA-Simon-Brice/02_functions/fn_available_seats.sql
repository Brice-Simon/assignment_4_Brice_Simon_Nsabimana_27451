
CREATE OR REPLACE FUNCTION fn_available_seats (
  p_course_id IN courses.course_id%TYPE,
  p_semester  IN enrollments.semester%TYPE
) RETURN NUMBER
IS
  l_capacity courses.max_capacity%TYPE;
  l_taken    NUMBER;
BEGIN
  SELECT max_capacity
    INTO l_capacity
    FROM courses
   WHERE course_id = p_course_id;

  SELECT COUNT(*)
    INTO l_taken
    FROM enrollments
   WHERE course_id = p_course_id
     AND semester  = p_semester;

  RETURN l_capacity - l_taken;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20003,
      'Course ' || NVL(TO_CHAR(p_course_id), 'NULL') || ' does not exist.');
END fn_available_seats;
/
SHOW ERRORS
