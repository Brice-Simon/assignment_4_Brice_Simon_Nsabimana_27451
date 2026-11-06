-- Owner  : NSABIMANA Simon Brice | Student ID: 27451
-- =====================================================================
-- Procedure: sp_enroll_student
-- Purpose  : Enrol an ACTIVE student in a course for a semester,
--            respecting the course capacity.
-- Concepts : %ROWTYPE records, user-defined record, implicit cursor (INSERT
--            with SQL%ROWCOUNT), user-defined exceptions, predefined
--            exceptions (NO_DATA_FOUND, DUP_VAL_ON_INDEX), RAISE_APPLICATION_ERROR,
--            OUT parameter, error logging for unexpected errors.
-- Errors   : -20001 student missing   -20002 student not ACTIVE
--            -20003 course missing    -20004 course full
--            -20005 already enrolled  -20009 missing input
--            -20099 unexpected error (also written to ERROR_LOG)
-- =====================================================================
CREATE OR REPLACE PROCEDURE sp_enroll_student (
  p_student_id    IN  students.student_id%TYPE,
  p_course_id     IN  courses.course_id%TYPE,
  p_semester      IN  enrollments.semester%TYPE,
  p_enrollment_id OUT enrollments.enrollment_id%TYPE
)
IS
  -- user-defined record
  TYPE t_enroll_summary IS RECORD (
    student_name VARCHAR2(201),
    course_code  courses.course_code%TYPE,
    seats_left   NUMBER
  );
  l_summary t_enroll_summary;

  -- %ROWTYPE records
  l_student students%ROWTYPE;
  l_course  courses%ROWTYPE;
  l_seats   NUMBER;

  -- user-defined exceptions
  e_student_inactive EXCEPTION;
  e_course_full      EXCEPTION;
BEGIN
  p_enrollment_id := NULL;

  IF p_student_id IS NULL OR p_course_id IS NULL OR p_semester IS NULL THEN
    RAISE_APPLICATION_ERROR(-20009,
      'Student id, course id and semester are all required.');
  END IF;

  -- Student must exist
  BEGIN
    SELECT * INTO l_student FROM students WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Student ' || p_student_id || ' does not exist.');
  END;

  IF l_student.status <> 'ACTIVE' THEN
    RAISE e_student_inactive;
  END IF;

  -- Course must exist
  BEGIN
    SELECT * INTO l_course FROM courses WHERE course_id = p_course_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20003, 'Course ' || p_course_id || ' does not exist.');
  END;

  -- Capacity check (function)
  l_seats := fn_available_seats(p_course_id, p_semester);
  IF l_seats <= 0 THEN
    RAISE e_course_full;
  END IF;

  -- Implicit cursor: INSERT
  INSERT INTO enrollments (enrollment_id, student_id, course_id, semester)
  VALUES (seq_enrollment.NEXTVAL, p_student_id, p_course_id, p_semester)
  RETURNING enrollment_id INTO p_enrollment_id;

  IF SQL%ROWCOUNT = 1 THEN
    l_summary.student_name := l_student.first_name || ' ' || l_student.last_name;
    l_summary.course_code  := l_course.course_code;
    l_summary.seats_left   := l_seats - 1;
    DBMS_OUTPUT.PUT_LINE('Enrolled ' || l_summary.student_name || ' in '
      || l_summary.course_code || ' (' || p_semester || '). Enrollment id = '
      || p_enrollment_id || ', seats left = ' || l_summary.seats_left);
  END IF;

EXCEPTION
  WHEN e_student_inactive THEN
    RAISE_APPLICATION_ERROR(-20002,
      'Student ' || p_student_id || ' is ' || l_student.status || ' and cannot enrol.');
  WHEN e_course_full THEN
    RAISE_APPLICATION_ERROR(-20004,
      'Course ' || l_course.course_code || ' is full for ' || p_semester || '.');
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20005,
      'Student ' || p_student_id || ' is already enrolled in course '
      || p_course_id || ' for ' || p_semester || '.');
  WHEN OTHERS THEN
    IF SQLCODE BETWEEN -20999 AND -20000 THEN
      RAISE;                              -- business-rule errors pass through unchanged
    END IF;
    sp_log_error('sp_enroll_student', SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20099,
      'Unexpected error in sp_enroll_student: ' || SUBSTR(SQLERRM, 1, 1500));
END sp_enroll_student;
/
SHOW ERRORS
