-- Owner  : NSABIMANA Simon Brice | Student ID: 27451
-- =====================================================================
-- File : 03_tests/test_error_cases.sql
-- Run  : AFTER the success tests. Every block is EXPECTED to fail and the
--        output shows the expected code next to the actual one.
-- Tip  : Take one screenshot per test (E1 ... E19) into /screenshots.
-- =====================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 170
SET PAGESIZE 100
COL error_message FORMAT A90
COL source_name   FORMAT A24

PROMPT
PROMPT ===== E1: Student does not exist (expect -20001) =====
DECLARE l_id enrollments.enrollment_id%TYPE;
BEGIN
  sp_enroll_student(9999, 201, '2026-B', l_id);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20001, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E2: Suspended student (user-defined exception, expect -20002) =====
DECLARE l_id enrollments.enrollment_id%TYPE;
BEGIN
  sp_enroll_student(2009, 201, '2026-B', l_id);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20002, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E3: Course does not exist (expect -20003) =====
DECLARE l_id enrollments.enrollment_id%TYPE;
BEGIN
  sp_enroll_student(2001, 999, '2026-B', l_id);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20003, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E4: Course full - capacity 2 (expect -20004) =====
DECLARE l_id enrollments.enrollment_id%TYPE;
BEGIN
  sp_enroll_student(2012, 205, '2026-B', l_id);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20004, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E5: Duplicate enrollment - DUP_VAL_ON_INDEX (expect -20005) =====
DECLARE l_id enrollments.enrollment_id%TYPE;
BEGIN
  sp_enroll_student(2001, 201, '2026-B', l_id);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20005, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E6: Missing input (expect -20009) =====
DECLARE l_id enrollments.enrollment_id%TYPE;
BEGIN
  sp_enroll_student(NULL, 201, '2026-B', l_id);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20009, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E7: Unexpected error - value too large, logged (expect -20099) =====
DECLARE l_id enrollments.enrollment_id%TYPE;
BEGIN
  sp_enroll_student(2001, 201, 'THIS-SEMESTER-NAME-IS-TOO-LONG', l_id);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20099, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/
SELECT log_id, source_name, error_code, SUBSTR(error_message, 1, 90) AS error_message
  FROM error_log ORDER BY log_id DESC FETCH FIRST 3 ROWS ONLY;

PROMPT
PROMPT ===== E8: sp_record_grade - enrollment missing, SQL%NOTFOUND (expect -20006) =====
DECLARE l_grade enrollments.grade%TYPE;
BEGIN
  sp_record_grade(99999, 70, l_grade);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20006, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E9: sp_record_grade - marks above 100 (expect -20008) =====
DECLARE l_grade enrollments.grade%TYPE;
BEGIN
  sp_record_grade(6001, 150, l_grade);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20008, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E10: sp_drop_enrollment - already graded (expect -20007) =====
DECLARE l_deleted NUMBER;
BEGIN
  sp_drop_enrollment(6001, l_deleted);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20007, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E11: sp_drop_enrollment - enrollment missing (expect -20006) =====
DECLARE l_deleted NUMBER;
BEGIN
  sp_drop_enrollment(99999, l_deleted);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20006, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E12: sp_bulk_grade_upload - FORALL SAVE EXCEPTIONS =====
PROMPT Row 1 valid | Row 2 marks 150 (CHECK constraint) | Row 3 enrollment 99999 missing
DECLARE
  l_ids     t_number_tab := t_number_tab(6016, 6014, 99999);
  l_marks   t_number_tab := t_number_tab(61,   150,  70);
  l_success NUMBER;
  l_errors  NUMBER;
BEGIN
  sp_bulk_grade_upload(l_ids, l_marks, l_success, l_errors);
  DBMS_OUTPUT.PUT_LINE('expected success=1, errors=2 -> got success=' || l_success
    || ', errors=' || l_errors);
  ROLLBACK;   -- undo the one valid update; the error log rows are kept (autonomous)
END;
/
SELECT log_id, source_name, error_code, SUBSTR(error_message, 1, 90) AS error_message
  FROM error_log WHERE source_name = 'sp_bulk_grade_upload' ORDER BY log_id;

PROMPT
PROMPT ===== E13: sp_bulk_grade_upload - lists of different size (expect -20009) =====
DECLARE
  l_success NUMBER;
  l_errors  NUMBER;
BEGIN
  sp_bulk_grade_upload(t_number_tab(6016, 6014), t_number_tab(61), l_success, l_errors);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20009, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E14: sp_apply_bonus_marks - bonus too large (expect -20012) =====
DECLARE l_rows NUMBER;
BEGIN
  sp_apply_bonus_marks(201, '2026-B', 50, l_rows);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20012, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E15: sp_apply_bonus_marks - nothing graded in course 205 (expect -20013) =====
DECLARE l_rows NUMBER;
BEGIN
  sp_apply_bonus_marks(205, '2026-B', 5, l_rows);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20013, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E16: sp_class_report - course missing / empty roster (expect -20003, -20015) =====
BEGIN
  sp_class_report(999, '2026-B');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20003, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/
BEGIN
  sp_class_report(201, '2099-Z');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20015, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E17: Functions - TOO_MANY_ROWS / NO_DATA_FOUND translated (expect -20040, -20041) =====
DECLARE l_id students.student_id%TYPE;
BEGIN
  l_id := fn_find_student_by_last_name('Ndayisaba');
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20040, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/
DECLARE l_id students.student_id%TYPE;
BEGIN
  l_id := fn_find_student_by_last_name('Nobody');
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20041, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E18: Functions - GPA errors and invalid marks (expect -20001, -20020, -20010) =====
DECLARE l_gpa NUMBER;
BEGIN
  l_gpa := fn_calculate_gpa(9999);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20001, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/
DECLARE l_gpa students.gpa%TYPE;
BEGIN
  sp_update_student_gpa(2009, l_gpa);     -- suspended student without grades
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20020, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/
DECLARE l_grade VARCHAR2(2);
BEGIN
  l_grade := fn_marks_to_grade(201);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20010, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== E19: Predefined exceptions directly + department / performance errors =====
DECLARE l_id students.student_id%TYPE;
BEGIN
  SELECT student_id INTO l_id FROM students WHERE last_name = 'Ndayisaba';   -- 2 rows
EXCEPTION
  WHEN TOO_MANY_ROWS THEN DBMS_OUTPUT.PUT_LINE('TOO_MANY_ROWS caught: query returned several rows');
END;
/
DECLARE l_id students.student_id%TYPE;
BEGIN
  SELECT student_id INTO l_id FROM students WHERE last_name = 'Nobody';    -- 0 rows
EXCEPTION
  WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('NO_DATA_FOUND caught: query returned no row');
END;
/
DECLARE l_count NUMBER;
BEGIN
  sp_department_summary(99, l_count);
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20016, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/
DECLARE l_a NUMBER; l_b NUMBER;
BEGIN
  sp_performance_demo(0, l_a, l_b);
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('expected -20017, got ' || SQLCODE || ' : ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== Error log content =====
SELECT log_id, source_name, error_code, SUBSTR(error_message, 1, 90) AS error_message
  FROM error_log ORDER BY log_id;

PROMPT ===== All error cases finished =====
