
CREATE OR REPLACE FUNCTION fn_grade_points (
  p_grade IN VARCHAR2
) RETURN NUMBER
DETERMINISTIC
IS
  l_points NUMBER;
BEGIN
  l_points := CASE p_grade
                WHEN 'A'  THEN 4.0
                WHEN 'B+' THEN 3.5
                WHEN 'B'  THEN 3.0
                WHEN 'C+' THEN 2.5
                WHEN 'C'  THEN 2.0
                WHEN 'D'  THEN 1.0
                WHEN 'F'  THEN 0.0
                ELSE NULL
              END;

  IF l_points IS NULL THEN
    RAISE_APPLICATION_ERROR(-20011,
      'Unknown grade: ' || NVL(p_grade, 'NULL'));
  END IF;

  RETURN l_points;
END fn_grade_points;
/
SHOW ERRORS
