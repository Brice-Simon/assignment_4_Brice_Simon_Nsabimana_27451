-- =====================================================================
-- File   : 00_schema/02_insert_sample_data.sql
-- Purpose: Sample data. Grades below follow the grading scale:
--          80-100 A | 75-79 B+ | 70-74 B | 65-69 C+ | 60-64 C | 50-59 D | <50 F
-- Notes  : * Two students share the last name 'Ndayisaba' (TOO_MANY_ROWS demo).
--          * Student 1009 is SUSPENDED and 1011 has no enrollments.
--          * Course 105 has capacity 2 and is already full for '2026-A'.
-- =====================================================================

-- Departments
INSERT INTO departments (dept_id, dept_name) VALUES (10, 'Computer Science');
INSERT INTO departments (dept_id, dept_name) VALUES (20, 'Information Technology');
INSERT INTO departments (dept_id, dept_name) VALUES (30, 'Business Administration');

-- Students
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1001, 'Simon Brice',     'Nsabimana',   'jean.uwimana@auca.ac.rw',     10, 'ACTIVE',    DATE '2025-09-01');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1002, 'Irene',    'Ndayisaba',   'marie.uwimana@auca.ac.rw',    10, 'ACTIVE',    DATE '2025-09-01');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1003, 'Samuel',     'Ndayisaba',   'eric.mugisha@auca.ac.rw',     10, 'ACTIVE',    DATE '2025-09-01');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1004, 'Alice',    'Rukundo',   'aline.ishimwe@auca.ac.rw',    20, 'ACTIVE',    DATE '2025-09-01');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1005, 'Emmanuel',  'Munyaneza',  'patrick.habimana@auca.ac.rw', 20, 'ACTIVE',    DATE '2025-09-01');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1006, 'Chantal',    'Ingabire',  'diane.mukamana@auca.ac.rw',   30, 'ACTIVE',    DATE '2025-09-01');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1007, 'Fabrice',    'Nsengiyumva', 'kevin.niyonzima@auca.ac.rw',  30, 'ACTIVE',    DATE '2025-09-01');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1008, 'Olive',    'Uwera',   'grace.umutoni@auca.ac.rw',    10, 'ACTIVE',    DATE '2026-01-15');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1009, 'Patrick',    'Mutesi',    'david.nshuti@auca.ac.rw',     20, 'SUSPENDED', DATE '2025-09-01');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1010, 'Doreen',   'Karemera',   'sandra.kamanzi@auca.ac.rw',   30, 'ACTIVE',    DATE '2025-09-01');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1011, 'Claude',   'Nkurunziza',  'samuel.bizimana@auca.ac.rw',  10, 'ACTIVE',    DATE '2026-01-15');
INSERT INTO students (student_id, first_name, last_name, email, dept_id, status, enrolled_on)
VALUES (1012, 'Beatrice',   'Munyakazi',     'claire.uwase@auca.ac.rw',     20, 'ACTIVE',    DATE '2026-01-15');

-- Courses
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, max_capacity)
VALUES (101, 'CS101', 'Introduction to Programming', 3, 10, 40);
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, max_capacity)
VALUES (102, 'CS201', 'Database Systems',            4, 10, 40);
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, max_capacity)
VALUES (103, 'IT201', 'Networking Fundamentals',     3, 20, 40);
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, max_capacity)
VALUES (104, 'BA101', 'Principles of Management',    3, 30, 40);
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, max_capacity)
VALUES (105, 'CS399', 'Capstone Seminar',            2, 10, 2);
INSERT INTO courses (course_id, course_code, course_name, credits, dept_id, max_capacity)
VALUES (106, 'IT301', 'Web Development',             3, 20, 40);

-- Enrollments for semester 2026-A (marks/grade NULL = not graded yet)
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5001, 1001, 101, '2026-A', 85,   'A');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5002, 1001, 102, '2026-A', 72,   'B');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5003, 1002, 101, '2026-A', 78,   'B+');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5004, 1002, 102, '2026-A', 66,   'C+');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5005, 1003, 101, '2026-A', 91,   'A');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5006, 1003, 102, '2026-A', 55,   'D');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5007, 1004, 103, '2026-A', 88,   'A');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5008, 1004, 106, '2026-A', 62,   'C');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5009, 1005, 103, '2026-A', 45,   'F');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5010, 1005, 106, '2026-A', 74,   'B');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5011, 1006, 104, '2026-A', 69,   'C+');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5012, 1007, 104, '2026-A', 81,   'A');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5013, 1008, 101, '2026-A', NULL, NULL);
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5014, 1008, 102, '2026-A', NULL, NULL);
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5015, 1010, 104, '2026-A', 58,   'D');
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5016, 1012, 103, '2026-A', NULL, NULL);
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5017, 1003, 105, '2026-A', NULL, NULL);
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, marks, grade) VALUES (5018, 1001, 105, '2026-A', NULL, NULL);

COMMIT;

PROMPT Sample data inserted.
