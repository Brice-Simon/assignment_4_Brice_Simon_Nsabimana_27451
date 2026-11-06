-- Owner  : NSABIMANA Simon Brice | Student ID: 27451
-- =====================================================================
-- Function: fn_marks_to_grade
-- Purpose : Convert numeric marks (0-100) into a letter grade.
-- Errors  : ORA-20010 when marks are NULL or outside 0..100
--           (an invalid mark is never silently turned into a grade).
-- =====================================================================
CREATE OR REPLACE FUNCTION fn_marks_to_grade (
  p_marks IN NUMBER
) RETURN VARCHAR2
DETERMINISTIC
IS
  l_grade VARCHAR2(2);
BEGIN
  IF p_marks IS NULL OR p_marks < 0 OR p_marks > 100 THEN
    RAISE_APPLICATION_ERROR(-20010,
      'Marks must be between 0 and 100 (received: '
      || NVL(TO_CHAR(p_marks), 'NULL') || ').');
  END IF;

  IF    p_marks >= 80 THEN l_grade := 'A';
  ELSIF p_marks >= 75 THEN l_grade := 'B+';
  ELSIF p_marks >= 70 THEN l_grade := 'B';
  ELSIF p_marks >= 65 THEN l_grade := 'C+';
  ELSIF p_marks >= 60 THEN l_grade := 'C';
  ELSIF p_marks >= 50 THEN l_grade := 'D';
  ELSE                     l_grade := 'F';
  END IF;

  RETURN l_grade;
END fn_marks_to_grade;
/
SHOW ERRORS
