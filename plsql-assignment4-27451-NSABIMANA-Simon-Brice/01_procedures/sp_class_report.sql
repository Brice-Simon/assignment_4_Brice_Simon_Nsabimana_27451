
CREATE OR REPLACE PROCEDURE sp_class_report (
  p_course_id IN courses.course_id%TYPE,
  p_semester  IN enrollments.semester%TYPE
)
IS
  CURSOR c_roster (cp_course_id courses.course_id%TYPE,
                   cp_semester  enrollments.semester%TYPE) IS
    SELECT s.student_id,
           s.first_name || ' ' || s.last_name AS full_name,
           e.marks,
           e.grade
      FROM enrollments e
      JOIN students s ON s.student_id = e.student_id
     WHERE e.course_id = cp_course_id
       AND e.semester  = cp_semester
     ORDER BY e.marks DESC NULLS LAST, s.last_name;

  -- user-defined record that receives one fetched row
  TYPE t_roster_rec IS RECORD (
    student_id students.student_id%TYPE,
    full_name  VARCHAR2(201),
    marks      enrollments.marks%TYPE,
    grade      enrollments.grade%TYPE
  );
  l_row t_roster_rec;

  -- associative array: grade -> number of students
  TYPE t_grade_count_tab IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(2);
  l_counts t_grade_count_tab;
  l_key    VARCHAR2(2);

  l_course courses%ROWTYPE;
  l_total  PLS_INTEGER := 0;
  l_graded PLS_INTEGER := 0;
  l_sum    NUMBER      := 0;

  e_empty_roster EXCEPTION;
BEGIN
  BEGIN
    SELECT * INTO l_course FROM courses WHERE course_id = p_course_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20003, 'Course ' || NVL(TO_CHAR(p_course_id), 'NULL') || ' does not exist.');
  END;

  DBMS_OUTPUT.PUT_LINE('=== ' || l_course.course_code || ' - ' || l_course.course_name
    || ' (' || p_semester || ') ===');
  DBMS_OUTPUT.PUT_LINE(RPAD('ID', 7) || RPAD('Student', 26) || LPAD('Marks', 7) || LPAD('Grade', 7));

  OPEN c_roster(p_course_id, p_semester);
  LOOP
    FETCH c_roster INTO l_row;
    EXIT WHEN c_roster%NOTFOUND;

    l_total := l_total + 1;
    DBMS_OUTPUT.PUT_LINE(RPAD(TO_CHAR(l_row.student_id), 7) || RPAD(l_row.full_name, 26)
      || LPAD(NVL(TO_CHAR(l_row.marks), '-'), 7) || LPAD(NVL(l_row.grade, '-'), 7));

    IF l_row.marks IS NOT NULL THEN
      l_graded := l_graded + 1;
      l_sum    := l_sum + l_row.marks;
      IF l_counts.EXISTS(l_row.grade) THEN
        l_counts(l_row.grade) := l_counts(l_row.grade) + 1;
      ELSE
        l_counts(l_row.grade) := 1;
      END IF;
    END IF;
  END LOOP;
  CLOSE c_roster;

  IF l_total = 0 THEN
    RAISE e_empty_roster;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Enrolled: ' || l_total || ' | Graded: ' || l_graded
    || ' | Seats left: ' || (l_course.max_capacity - l_total));
  IF l_graded > 0 THEN
    DBMS_OUTPUT.PUT_LINE('Class average: ' || ROUND(l_sum / l_graded, 2));
    l_key := l_counts.FIRST;
    WHILE l_key IS NOT NULL LOOP
      DBMS_OUTPUT.PUT_LINE('  Grade ' || RPAD(l_key, 2) || ': ' || l_counts(l_key));
      l_key := l_counts.NEXT(l_key);
    END LOOP;
  ELSE
    DBMS_OUTPUT.PUT_LINE('No marks recorded yet.');
  END IF;

EXCEPTION
  WHEN e_empty_roster THEN
    RAISE_APPLICATION_ERROR(-20015,
      'No enrollments found for course ' || p_course_id || ' in ' || p_semester || '.');
  WHEN OTHERS THEN
    IF c_roster%ISOPEN THEN
      CLOSE c_roster;
    END IF;
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;
    END IF;
    sp_log_error('sp_class_report', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099,
      'Unexpected error in sp_class_report: ' || SUBSTR(SQLERRM, 1, 1500));
END sp_class_report;
/
SHOW ERRORS
