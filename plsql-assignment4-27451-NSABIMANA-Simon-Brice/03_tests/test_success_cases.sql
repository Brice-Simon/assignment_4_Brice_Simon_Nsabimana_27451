
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 150
SET PAGESIZE 100
COL student_name FORMAT A22
COL course_code  FORMAT A10

PROMPT
PROMPT ===== S1: fn_marks_to_grade called from SQL =====
SELECT m AS marks, fn_marks_to_grade(m) AS grade
  FROM (SELECT 100 m FROM dual UNION ALL SELECT 80 FROM dual UNION ALL SELECT 77 FROM dual
        UNION ALL SELECT 70 FROM dual UNION ALL SELECT 66 FROM dual UNION ALL SELECT 60 FROM dual
        UNION ALL SELECT 50 FROM dual UNION ALL SELECT 49 FROM dual UNION ALL SELECT 0 FROM dual);

PROMPT
PROMPT ===== S2: fn_calculate_gpa and fn_available_seats called from SQL =====
SELECT s.student_id,
       s.first_name || ' ' || s.last_name AS student_name,
       fn_calculate_gpa(s.student_id)     AS calculated_gpa
  FROM students s
 WHERE s.student_id IN (2001, 2002, 2003);

SELECT course_code, max_capacity, fn_available_seats(course_id, '2026-B') AS seats_left
  FROM courses
 ORDER BY course_id;

PROMPT
PROMPT ===== S3: sp_enroll_student (records + implicit INSERT) =====
DECLARE
  l_enrollment_id enrollments.enrollment_id%TYPE;
BEGIN
  sp_enroll_student(2011, 206, '2026-B', l_enrollment_id);
  DBMS_OUTPUT.PUT_LINE('OUT parameter -> new enrollment id: ' || l_enrollment_id);
END;
/

PROMPT
PROMPT ===== S4: sp_record_grade (implicit UPDATE, SQL%FOUND / SQL%ROWCOUNT) =====
DECLARE
  l_grade enrollments.grade%TYPE;
BEGIN
  -- Student 2011 was just enrolled in S3; grade that enrollment.
  FOR r IN (SELECT enrollment_id FROM enrollments
             WHERE student_id = 2011 AND course_id = 206 AND semester = '2026-B') LOOP
    sp_record_grade(r.enrollment_id, 77, l_grade);
    DBMS_OUTPUT.PUT_LINE('OUT parameter -> grade: ' || l_grade);
  END LOOP;
END;
/

PROMPT
PROMPT ===== S5: sp_bulk_grade_upload (FORALL, all rows valid) =====
DECLARE
  l_ids     t_number_tab := t_number_tab(6013, 6014, 6016);
  l_marks   t_number_tab := t_number_tab(70,   88,   59);
  l_success NUMBER;
  l_errors  NUMBER;
BEGIN
  sp_bulk_grade_upload(l_ids, l_marks, l_success, l_errors);
  DBMS_OUTPUT.PUT_LINE('success=' || l_success || ', errors=' || l_errors);
END;
/
SELECT enrollment_id, student_id, course_id, marks, grade
  FROM enrollments WHERE enrollment_id IN (6013, 6014, 6016) ORDER BY enrollment_id;

PROMPT
PROMPT ===== S6: sp_apply_bonus_marks (BULK COLLECT + FORALL) - course 201 =====
SELECT enrollment_id, marks, grade FROM enrollments
 WHERE course_id = 201 AND semester = '2026-B' ORDER BY enrollment_id;
DECLARE
  l_rows NUMBER;
BEGIN
  sp_apply_bonus_marks(201, '2026-B', 5, l_rows);
  DBMS_OUTPUT.PUT_LINE('rows updated: ' || l_rows);
END;
/
SELECT enrollment_id, marks, grade FROM enrollments
 WHERE course_id = 201 AND semester = '2026-B' ORDER BY enrollment_id;

PROMPT
PROMPT ===== S7: sp_class_report (explicit cursor OPEN/FETCH/CLOSE) =====
BEGIN
  sp_class_report(201, '2026-B');
  DBMS_OUTPUT.PUT_LINE(' ');
  sp_class_report(205, '2026-B');
END;
/

PROMPT
PROMPT ===== S8: sp_update_student_gpa =====
DECLARE
  l_gpa students.gpa%TYPE;
BEGIN
  sp_update_student_gpa(2001, l_gpa);
  DBMS_OUTPUT.PUT_LINE('OUT parameter -> gpa: ' || TO_CHAR(l_gpa, 'FM0.00'));
END;
/

PROMPT
PROMPT ===== S9: sp_update_all_gpas (BULK COLLECT + FORALL) =====
DECLARE
  l_updated NUMBER;
  l_skipped NUMBER;
BEGIN
  sp_update_all_gpas(l_updated, l_skipped);
END;
/
SELECT student_id, first_name, last_name, status, gpa FROM students ORDER BY student_id;

PROMPT
PROMPT ===== S10: sp_department_summary (cursor FOR loop) =====
DECLARE
  l_count NUMBER;
BEGIN
  sp_department_summary(10, l_count);
  DBMS_OUTPUT.PUT_LINE(' ');
  sp_department_summary(20, l_count);
END;
/

PROMPT
PROMPT ===== S11: sp_drop_enrollment (implicit DELETE, SQL%FOUND) =====
DECLARE
  l_enrollment_id enrollments.enrollment_id%TYPE;
  l_deleted       NUMBER;
BEGIN
  sp_enroll_student(2012, 206, '2026-B', l_enrollment_id);   -- ungraded enrollment
  sp_drop_enrollment(l_enrollment_id, l_deleted);
  DBMS_OUTPUT.PUT_LINE('rows deleted: ' || l_deleted);
END;
/

PROMPT
PROMPT ===== S12: fn_find_student_by_last_name (unique name) =====
SELECT fn_find_student_by_last_name('Rukundo') AS student_id FROM dual;

PROMPT
PROMPT ===== S13: sp_performance_demo (row-by-row vs FORALL, 20000 rows) =====
DECLARE
  l_rowbyrow NUMBER;
  l_bulk     NUMBER;
BEGIN
  sp_performance_demo(20000, l_rowbyrow, l_bulk);
  DBMS_OUTPUT.PUT_LINE('Row-by-row: ' || l_rowbyrow || ' cs | FORALL: ' || l_bulk || ' cs');
END;
/

COMMIT;
PROMPT
PROMPT ===== All success cases finished =====
