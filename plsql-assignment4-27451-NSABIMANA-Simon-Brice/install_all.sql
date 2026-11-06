-- Owner  : NSABIMANA Simon Brice | Student ID: 27451
-- =====================================================================
-- install_all.sql  (optional helper)
-- Run from the ROOT folder of the repository, e.g. in SQL*Plus / SQLcl:
--     @install_all.sql
-- It runs the project files in dependency order:
--   schema -> sample data -> functions -> sp_log_error -> other procedures
-- (Procedures call functions and sp_log_error, so those are compiled first.)
-- =====================================================================
@00_schema/01_create_tables.sql
@00_schema/02_insert_sample_data.sql

@02_functions/fn_marks_to_grade.sql
@02_functions/fn_grade_points.sql
@02_functions/fn_calculate_gpa.sql
@02_functions/fn_available_seats.sql
@02_functions/fn_find_student_by_last_name.sql

@01_procedures/sp_log_error.sql
@01_procedures/sp_enroll_student.sql
@01_procedures/sp_record_grade.sql
@01_procedures/sp_drop_enrollment.sql
@01_procedures/sp_bulk_grade_upload.sql
@01_procedures/sp_apply_bonus_marks.sql
@01_procedures/sp_class_report.sql
@01_procedures/sp_update_student_gpa.sql
@01_procedures/sp_update_all_gpas.sql
@01_procedures/sp_department_summary.sql
@01_procedures/sp_performance_demo.sql

PROMPT
PROMPT Checking for invalid objects (should return no rows):
SELECT object_name, object_type, status
  FROM user_objects
 WHERE status <> 'VALID'
   AND (object_name LIKE 'SP\_%' ESCAPE '\' OR object_name LIKE 'FN\_%' ESCAPE '\');
