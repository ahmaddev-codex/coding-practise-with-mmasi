--  UNIVERSITY MANAGEMENT SYSTEM 

-- SETUP (Create Database if not exists)

CREATE DATABASE IF NOT EXISTS university_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE university_db;

-- Drop tables in reverse FK order; disable FK checks to avoid ordering issues

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS library_loans;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS submissions;
DROP TABLE IF EXISTS grades;
DROP TABLE IF EXISTS assignments;
DROP TABLE IF EXISTS professor_courses;
DROP TABLE IF EXISTS course_schedule;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS classrooms;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS professors;
DROP TABLE IF EXISTS departments;

SET FOREIGN_KEY_CHECKS = 1;

-- CREATE TABLES 

-- 1. departments
CREATE TABLE departments (
    dept_id        INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    dept_name      VARCHAR(100)  NOT NULL,
    building       VARCHAR(60)   NOT NULL,
    budget         DECIMAL(12,2) CHECK (budget >= 0),
    established    INT           CHECK (established BETWEEN 1800 AND 2100),
    parent_dept_id INT           DEFAULT NULL,
    UNIQUE (dept_name)
);

-- 2. professors
CREATE TABLE professors (
    prof_id    INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50)   NOT NULL,
    last_name  VARCHAR(50)   NOT NULL,
    email      VARCHAR(120)  NOT NULL,
    hire_date  DATE          NOT NULL,
    salary     DECIMAL(10,2) CHECK (salary > 0),
    prof_rank       VARCHAR(30)   CHECK (prof_rank IN ('Lecturer','Assistant Professor',
                                             'Associate Professor','Professor')),
    dept_id    INT           DEFAULT NULL,
    UNIQUE (email),
    CONSTRAINT fk_prof_dept FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id) ON DELETE SET NULL
);

-- 3. students
CREATE TABLE students (
    student_id      INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    email           VARCHAR(120) NOT NULL,
    dob             DATE         NOT NULL,
    enrollment_year INT          CHECK (enrollment_year BETWEEN 2000 AND 2100),
    major           VARCHAR(80),
    gpa             DECIMAL(3,2) CHECK (gpa BETWEEN 0.00 AND 4.00),
    UNIQUE (email)
);

-- 4. courses
CREATE TABLE courses (
    course_id    INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    course_code  VARCHAR(20)  NOT NULL,
    title        VARCHAR(150) NOT NULL,
    credit_hours INT          NOT NULL CHECK (credit_hours BETWEEN 1 AND 6),
    level        VARCHAR(20)  CHECK (level IN ('Undergraduate','Graduate','PhD')),
    dept_id      INT          DEFAULT NULL,
    UNIQUE (course_code),
    CONSTRAINT fk_course_dept FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id) ON DELETE SET NULL
);

-- 5. classrooms
CREATE TABLE classrooms (
    room_id       INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    building      VARCHAR(60) NOT NULL,
    room_number   VARCHAR(10) NOT NULL,
    capacity      INT         NOT NULL CHECK (capacity > 0),
    has_projector TINYINT(1)  DEFAULT 1,
    UNIQUE (building, room_number)
);

-- 6. enrollments
CREATE TABLE enrollments (
    enrollment_id INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    student_id    INT         NOT NULL,
    course_id     INT         NOT NULL,
    enrolled_on   DATE        NOT NULL DEFAULT (CURDATE()),
    enrollment_status        VARCHAR(20) DEFAULT 'Active'
                  CHECK (enrollment_status IN ('Active','Dropped','Completed','Waitlisted')),
    UNIQUE (student_id, course_id),
    CONSTRAINT fk_enr_student FOREIGN KEY (student_id)
        REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_enr_course FOREIGN KEY (course_id)
        REFERENCES courses(course_id) ON DELETE CASCADE
);

-- 7. professor_courses
CREATE TABLE professor_courses (
    pc_id     INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    prof_id   INT         NOT NULL,
    course_id INT         NOT NULL,
    semester  VARCHAR(20) NOT NULL,
    year      INT         NOT NULL CHECK (year BETWEEN 2000 AND 2100),
    UNIQUE (prof_id, course_id, semester, year),
    CONSTRAINT fk_pc_prof   FOREIGN KEY (prof_id)
        REFERENCES professors(prof_id) ON DELETE CASCADE,
    CONSTRAINT fk_pc_course FOREIGN KEY (course_id)
        REFERENCES courses(course_id) ON DELETE CASCADE
);

-- 8. course_schedule
CREATE TABLE course_schedule (
    schedule_id INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    course_id   INT         NOT NULL,
    room_id     INT         DEFAULT NULL,
    day_of_week VARCHAR(10) NOT NULL
                CHECK (day_of_week IN ('Monday','Tuesday','Wednesday',
                                       'Thursday','Friday','Saturday')),
    start_time  TIME NOT NULL,
    end_time    TIME NOT NULL,
    CHECK (end_time > start_time),
    CONSTRAINT fk_cs_course FOREIGN KEY (course_id)
        REFERENCES courses(course_id) ON DELETE CASCADE,
    CONSTRAINT fk_cs_room FOREIGN KEY (room_id)
        REFERENCES classrooms(room_id) ON DELETE SET NULL
);

-- 9. assignments
CREATE TABLE assignments (
    assignment_id   INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    course_id       INT          NOT NULL,
    title           VARCHAR(200) NOT NULL,
    due_date        DATE         NOT NULL,
    max_points      DECIMAL(6,2) NOT NULL CHECK (max_points > 0),
    assignment_type VARCHAR(30)  CHECK (assignment_type IN
                    ('Homework','Quiz','Midterm','Final','Project','Lab')),
    CONSTRAINT fk_asgn_course FOREIGN KEY (course_id)
        REFERENCES courses(course_id) ON DELETE CASCADE
);

-- 10. submissions
CREATE TABLE submissions (
    submission_id INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    assignment_id INT          NOT NULL,
    student_id    INT          NOT NULL,
    submitted_at  DATETIME     NOT NULL DEFAULT NOW(),
    points_earned DECIMAL(6,2) CHECK (points_earned >= 0),
    feedback      TEXT,
    UNIQUE (assignment_id, student_id),
    CONSTRAINT fk_sub_asgn    FOREIGN KEY (assignment_id)
        REFERENCES assignments(assignment_id) ON DELETE CASCADE,
    CONSTRAINT fk_sub_student FOREIGN KEY (student_id)
        REFERENCES students(student_id) ON DELETE CASCADE
);

-- 11. grades
CREATE TABLE grades (
    grade_id      INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT          NOT NULL,
    letter_grade  CHAR(2)      CHECK (letter_grade IN
                  ('A+','A','A-','B+','B','B-','C+','C','C-','D','F','W','I')),
    numeric_grade DECIMAL(5,2) CHECK (numeric_grade BETWEEN 0 AND 100),
    graded_on     DATE         NOT NULL DEFAULT (CURDATE()),
    UNIQUE (enrollment_id),
    CONSTRAINT fk_grade_enr FOREIGN KEY (enrollment_id)
        REFERENCES enrollments(enrollment_id) ON DELETE CASCADE
);

-- 12. payments
CREATE TABLE payments (
    payment_id INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    student_id INT           NOT NULL,
    amount     DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    paid_on    DATE          NOT NULL DEFAULT (CURDATE()),
    semester   VARCHAR(20)   NOT NULL,
    year       INT           NOT NULL CHECK (year BETWEEN 2000 AND 2100),
    method     VARCHAR(30)   CHECK (method IN
               ('Credit Card','Bank Transfer','Cash','Scholarship','Waiver')),
    enrollment_status     VARCHAR(20)   DEFAULT 'Paid'
               CHECK (enrollment_status IN ('Paid','Pending','Overdue','Refunded')),
    CONSTRAINT fk_pay_student FOREIGN KEY (student_id)
        REFERENCES students(student_id) ON DELETE CASCADE
);

-- 13. books
CREATE TABLE books (
    book_id        INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    isbn           VARCHAR(20)  NOT NULL,
    title          VARCHAR(200) NOT NULL,
    author         VARCHAR(150) NOT NULL,
    genre          VARCHAR(60),
    published_year INT          CHECK (published_year BETWEEN 1000 AND 2100),
    total_copies   INT          NOT NULL DEFAULT 1 CHECK (total_copies >= 0),
    UNIQUE (isbn)
);

-- 14. library_loans
CREATE TABLE library_loans (
    loan_id     INT  NOT NULL AUTO_INCREMENT PRIMARY KEY,
    student_id  INT  NOT NULL,
    book_id     INT  NOT NULL,
    loaned_on   DATE NOT NULL DEFAULT (CURDATE()),
    due_date    DATE NOT NULL,
    returned_on DATE DEFAULT NULL,
    CHECK (due_date > loaned_on),
    CONSTRAINT fk_loan_student FOREIGN KEY (student_id)
        REFERENCES students(student_id) ON DELETE CASCADE,
    CONSTRAINT fk_loan_book FOREIGN KEY (book_id)
        REFERENCES books(book_id) ON DELETE CASCADE
);

-- 15. audit_log
CREATE TABLE audit_log (
    log_id     INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(60)  NOT NULL,
    operation  VARCHAR(10)  NOT NULL CHECK (operation IN ('INSERT','UPDATE','DELETE')),
    row_id     INT          NOT NULL,
    changed_at DATETIME     NOT NULL DEFAULT NOW(),
    changed_by VARCHAR(100) DEFAULT (CURRENT_USER())
);


-- INSERT DATA

-- departments (8 rows)
INSERT INTO departments (dept_name, building, budget, established) VALUES
    ('Computer Science',    'Turing Hall',     1200000.00, 1972),
    ('Mathematics',         'Euler Building',   850000.00, 1905),
    ('Physics',             'Newton Annex',     950000.00, 1910),
    ('English Literature',  'Bronte House',     420000.00, 1898),
    ('Economics',           'Keynes Pavilion',  760000.00, 1945),
    ('Biology',             'Darwin Wing',      880000.00, 1935),
    ('Philosophy',          'Socrates Hall',    310000.00, 1892),
    ('Data Science',        'Turing Hall',      540000.00, 2018);

-- Data Science is a child of Computer Science (used in recursive CTE demo)
UPDATE departments SET parent_dept_id = 1 WHERE dept_name = 'Data Science';

-- professors (20 rows)
INSERT INTO professors (first_name, last_name, email, hire_date, salary, prof_rank, dept_id) VALUES
    ('Ada',       'Lovelace',   'a.lovelace@uni.edu',   '2005-08-15', 112000.00, 'Professor',           1),
    ('Alan',      'Turing',     'a.turing@uni.edu',     '2010-01-20',  98000.00, 'Associate Professor', 1),
    ('Grace',     'Hopper',     'g.hopper@uni.edu',     '2018-09-01',  76000.00, 'Assistant Professor', 1),
    ('Emmy',      'Noether',    'e.noether@uni.edu',    '2001-03-10', 120000.00, 'Professor',           2),
    ('Carl',      'Gauss',      'c.gauss@uni.edu',      '2008-07-22', 105000.00, 'Professor',           2),
    ('Niels',     'Bohr',       'n.bohr@uni.edu',       '2012-02-14',  97000.00, 'Associate Professor', 3),
    ('Marie',     'Curie',      'm.curie@uni.edu',      '2003-11-05', 115000.00, 'Professor',           3),
    ('Virginia',  'Woolf',      'v.woolf@uni.edu',      '2015-08-30',  82000.00, 'Associate Professor', 4),
    ('John',      'Keats',      'j.keats@uni.edu',      '2019-01-15',  68000.00, 'Lecturer',            4),
    ('Milton',    'Friedman',   'm.friedman@uni.edu',   '2007-06-01', 108000.00, 'Professor',           5),
    ('Janet',     'Yellen',     'j.yellen@uni.edu',     '2014-09-10',  94000.00, 'Associate Professor', 5),
    ('Charles',   'Darwin',     'c.darwin@uni.edu',     '2000-08-20', 125000.00, 'Professor',           6),
    ('Rosalind',  'Fprof_ranklin',   'r.fprof_ranklin@uni.edu',   '2016-03-08',  88000.00, 'Assistant Professor', 6),
    ('Simone',    'DeBeauvoir', 's.debeauvoir@uni.edu', '2011-10-01',  91000.00, 'Associate Professor', 7),
    ('Bertrand',  'Russell',    'b.russell@uni.edu',    '2004-04-12', 110000.00, 'Professor',           7),
    ('David',     'Hume',       'd.hume@uni.edu',       '2020-08-01',  65000.00, 'Lecturer',            7),
    ('Hadley',    'Wickham',    'h.wickham@uni.edu',    '2021-01-10',  92000.00, 'Assistant Professor', 8),
    ('Yann',      'LeCun',      'y.lecun@uni.edu',      '2019-07-15', 130000.00, 'Professor',           8),
    ('Fei-Fei',   'Li',         'f.li@uni.edu',         '2017-09-01', 118000.00, 'Professor',           8),
    ('Geoffrey',  'Hinton',     'g.hinton@uni.edu',     '2022-01-05', 140000.00, 'Professor',           1);

-- students (50 rows)
INSERT INTO students (first_name, last_name, email, dob, enrollment_year, major, gpa) VALUES
    ('Liam',      'Anderson',  'l.anderson@student.edu',  '2001-03-12', 2020, 'Computer Science',   3.85),
    ('Olivia',    'Thompson',  'o.thompson@student.edu',  '2000-07-25', 2019, 'Mathematics',        3.92),
    ('Noah',      'Martinez',  'n.martinez@student.edu',  '2002-01-08', 2021, 'Data Science',       3.60),
    ('Emma',      'Garcia',    'e.garcia@student.edu',    '2001-11-14', 2020, 'Physics',            3.74),
    ('Oliver',    'Wilson',    'o.wilson@student.edu',    '2000-05-30', 2019, 'Economics',          3.45),
    ('Ava',       'Moore',     'a.moore@student.edu',     '2002-09-19', 2021, 'Biology',            3.88),
    ('Elijah',    'Taylor',    'e.taylor@student.edu',    '2001-02-27', 2020, 'Computer Science',   3.50),
    ('Charlotte', 'Lee',       'c.lee@student.edu',       '2003-06-03', 2022, 'English Literature', 3.70),
    ('James',     'Harris',    'j.harris@student.edu',    '2000-12-15', 2019, 'Philosophy',         3.30),
    ('Sophia',    'Clark',     's.clark@student.edu',     '2002-04-22', 2021, 'Data Science',       3.95),
    ('Logan',     'Lewis',     'l.lewis@student.edu',     '2001-08-09', 2020, 'Mathematics',        3.67),
    ('Mia',       'Robinson',  'm.robinson@student.edu',  '2003-01-31', 2022, 'Biology',            3.80),
    ('Lucas',     'Walker',    'l.walker@student.edu',    '2000-10-17', 2019, 'Economics',          2.95),
    ('Amelia',    'Hall',      'a.hall@student.edu',      '2002-07-04', 2021, 'Computer Science',   3.55),
    ('Mason',     'Allen',     'm.allen@student.edu',     '2001-05-13', 2020, 'Physics',            3.40),
    ('Harper',    'Young',     'h.young@student.edu',     '2003-03-28', 2022, 'English Literature', 3.75),
    ('Ethan',     'Hernandez', 'e.hernandez@student.edu', '2000-09-06', 2019, 'Computer Science',   3.20),
    ('Evelyn',    'King',      'e.king@student.edu',      '2002-12-24', 2021, 'Mathematics',        3.90),
    ('Aiden',     'Wright',    'a.wright@student.edu',    '2001-06-18', 2020, 'Data Science',       3.65),
    ('Abigail',   'Scott',     'a.scott@student.edu',     '2003-08-11', 2022, 'Biology',            3.77),
    ('Jackson',   'Torres',    'j.torres@student.edu',    '2000-04-05', 2019, 'Philosophy',         3.10),
    ('Emily',     'Nguyen',    'e.nguyen@student.edu',    '2002-02-16', 2021, 'Economics',          3.55),
    ('Sebastian', 'Hill',      's.hill@student.edu',      '2001-10-29', 2020, 'Computer Science',   3.80),
    ('Elizabeth', 'Flores',    'e.flores@student.edu',    '2003-05-07', 2022, 'Data Science',       3.70),
    ('Carter',    'Green',     'c.green@student.edu',     '2000-11-23', 2019, 'Physics',            3.35),
    ('Sofia',     'Adams',     's.adams@student.edu',     '2002-03-14', 2021, 'Mathematics',        3.82),
    ('William',   'Nelson',    'w.nelson@student.edu',    '2001-07-01', 2020, 'English Literature', 3.48),
    ('Scarlett',  'Baker',     's.baker@student.edu',     '2003-09-20', 2022, 'Biology',            3.63),
    ('Michael',   'Carter',    'm.carter@student.edu',    '2000-01-30', 2019, 'Economics',          2.80),
    ('Victoria',  'Mitchell',  'v.mitchell@student.edu',  '2002-06-09', 2021, 'Computer Science',   3.91),
    ('Henry',     'Perez',     'h.perez@student.edu',     '2001-04-17', 2020, 'Data Science',       3.58),
    ('Grace',     'Roberts',   'g.roberts@student.edu',   '2003-02-02', 2022, 'Philosophy',         3.72),
    ('Alexander', 'Turner',    'a.turner@student.edu',    '2000-08-25', 2019, 'Mathematics',        3.43),
    ('Luna',      'Phillips',  'l.phillips@student.edu',  '2002-10-13', 2021, 'Physics',            3.87),
    ('Daniel',    'Campbell',  'd.campbell@student.edu',  '2001-12-31', 2020, 'Biology',            3.62),
    ('Chloe',     'Parker',    'c.parker@student.edu',    '2003-07-19', 2022, 'Computer Science',   3.33),
    ('Matthew',   'Evans',     'm.evans@student.edu',     '2000-03-08', 2019, 'Data Science',       3.79),
    ('Penelope',  'Edwards',   'p.edwards@student.edu',   '2002-05-26', 2021, 'English Literature', 3.54),
    ('Ryan',      'Collins',   'r.collins@student.edu',   '2001-09-14', 2020, 'Economics',          3.68),
    ('Layla',     'Stewart',   'l.stewart@student.edu',   '2003-11-03', 2022, 'Philosophy',         3.20),
    ('David',     'Sanchez',   'd.sanchez@student.edu',   '2000-06-21', 2019, 'Computer Science',   3.00),
    ('Zoey',      'Morris',    'z.morris@student.edu',    '2002-08-30', 2021, 'Biology',            3.85),
    ('Joseph',    'Rogers',    'j.rogers@student.edu',    '2001-01-09', 2020, 'Data Science',       3.71),
    ('Nora',      'Reed',      'n.reed@student.edu',      '2003-04-16', 2022, 'Physics',            3.94),
    ('Samuel',    'Cook',      's.cook@student.edu',      '2000-02-28', 2019, 'Mathematics',        3.42),
    ('Lillian',   'Morgan',    'l.morgan@student.edu',    '2002-11-07', 2021, 'English Literature', 3.59),
    ('Gabriel',   'Bell',      'g.bell@student.edu',      '2001-03-25', 2020, 'Economics',          3.76),
    ('Hannah',    'Murphy',    'h.murphy@student.edu',    '2003-10-14', 2022, 'Computer Science',   3.38),
    ('Leo',       'Bailey',    'l.bailey@student.edu',    '2000-07-03', 2019, 'Data Science',       3.83),
    ('Stella',    'Rivera',    's.rivera@student.edu',    '2002-01-20', 2021, 'Philosophy',         3.47);

-- courses (20 rows)
INSERT INTO courses (course_code, title, credit_hours, level, dept_id) VALUES
    ('COS101',   'Introduction to Programming',     3, 'Undergraduate', 1),
    ('COS201',   'Data Structures & Algorithms',    3, 'Undergraduate', 1),
    ('COS301',   'Database Management Systems',     3, 'Undergraduate', 1),
    ('COS401',   'Machine Learning',                3, 'Graduate',      1),
    ('COS501',   'Deep Learning',                   3, 'PhD',           1),
    ('MATH101', 'Calculus I',                      4, 'Undergraduate', 2),
    ('MATH201', 'Linear Algebra',                  3, 'Undergraduate', 2),
    ('MATH301', 'Probability & Statistics',        3, 'Undergraduate', 2),
    ('PHYS101', 'Mechanics',                       4, 'Undergraduate', 3),
    ('PHYS201', 'Electromagnetism',                3, 'Undergraduate', 3),
    ('ENG101',  'Academic Writing',                3, 'Undergraduate', 4),
    ('ENG201',  'British Literature',              3, 'Undergraduate', 4),
    ('ECON101', 'Microeconomics',                  3, 'Undergraduate', 5),
    ('ECON201', 'Macroeconomics',                  3, 'Undergraduate', 5),
    ('BIO101',  'Cell Biology',                    4, 'Undergraduate', 6),
    ('BIO201',  'Genetics',                        3, 'Undergraduate', 6),
    ('PHIL101', 'Introduction to Philosophy',      3, 'Undergraduate', 7),
    ('PHIL201', 'Ethics',                          3, 'Undergraduate', 7),
    ('DSC101',   'Data Science Fundamentals',       3, 'Undergraduate', 8),
    ('DSC301',   'Big Data Analytics',              3, 'Graduate',      8);

-- classrooms (10 rows)
INSERT INTO classrooms (building, room_number, capacity, has_projector) VALUES
    ('Turing Hall',    '101', 120, 1),
    ('Turing Hall',    '202', 60,  1),
    ('Euler Building', '101', 80,  1),
    ('Newton Annex',   '110', 100, 1),
    ('Newton Annex',   '220', 40,  0),
    ('Bronte House',   '105', 50,  1),
    ('Keynes Pavilion','201', 90,  1),
    ('Darwin Wing',    '115', 70,  1),
    ('Socrates Hall',  '101', 55,  0),
    ('Turing Hall',    '305', 30,  1);

-- enrollments (50 rows)
INSERT INTO enrollments (student_id, course_id, enrolled_on, enrollment_status) VALUES
    (1,  1, '2023-09-01', 'Completed'),
    (1,  2, '2023-09-01', 'Completed'),
    (1,  3, '2024-01-15', 'Active'),
    (2,  6, '2023-09-01', 'Completed'),
    (2,  7, '2024-01-15', 'Active'),
    (3,  19,'2023-09-01', 'Completed'),
    (3,  1, '2024-01-15', 'Active'),
    (4,  9, '2023-09-01', 'Completed'),
    (4,  10,'2024-01-15', 'Active'),
    (5,  13,'2023-09-01', 'Completed'),
    (5,  14,'2024-01-15', 'Active'),
    (6,  15,'2023-09-01', 'Completed'),
    (6,  16,'2024-01-15', 'Active'),
    (7,  1, '2023-09-01', 'Completed'),
    (7,  2, '2024-01-15', 'Active'),
    (8,  11,'2023-09-01', 'Completed'),
    (8,  12,'2024-01-15', 'Active'),
    (9,  17,'2023-09-01', 'Completed'),
    (9,  18,'2024-01-15', 'Active'),
    (10, 19,'2023-09-01', 'Completed'),
    (10, 20,'2024-01-15', 'Active'),
    (11, 6, '2023-09-01', 'Completed'),
    (11, 8, '2024-01-15', 'Active'),
    (12, 15,'2023-09-01', 'Completed'),
    (12, 16,'2024-01-15', 'Active'),
    (13, 13,'2023-09-01', 'Dropped'),
    (14, 1, '2023-09-01', 'Completed'),
    (14, 3, '2024-01-15', 'Active'),
    (15, 9, '2023-09-01', 'Completed'),
    (15, 10,'2024-01-15', 'Active'),
    (16, 11,'2023-09-01', 'Completed'),
    (17, 1, '2023-09-01', 'Completed'),
    (17, 4, '2024-01-15', 'Active'),
    (18, 6, '2023-09-01', 'Completed'),
    (18, 7, '2024-01-15', 'Active'),
    (19, 19,'2023-09-01', 'Completed'),
    (19, 20,'2024-01-15', 'Active'),
    (20, 15,'2023-09-01', 'Completed'),
    (21, 17,'2023-09-01', 'Completed'),
    (22, 13,'2023-09-01', 'Completed'),
    (23, 1, '2023-09-01', 'Completed'),
    (23, 2, '2024-01-15', 'Active'),
    (24, 19,'2023-09-01', 'Completed'),
    (25, 9, '2023-09-01', 'Completed'),
    (26, 6, '2023-09-01', 'Completed'),
    (27, 11,'2023-09-01', 'Completed'),
    (28, 15,'2023-09-01', 'Completed'),
    (29, 13,'2023-09-01', 'Dropped'),
    (30, 1, '2023-09-01', 'Completed'),
    (30, 3, '2024-01-15', 'Active');

-- professor_courses (20 rows)
INSERT INTO professor_courses (prof_id, course_id, semester, year) VALUES
    (1, 1, 'Fall', 2023), (1, 2, 'Spring', 2024),
    (2, 3, 'Fall', 2023), (2, 4, 'Spring', 2024),
    (3, 1, 'Spring', 2024),
    (4, 6, 'Fall', 2023), (4, 7, 'Spring', 2024),
    (5, 8, 'Fall', 2023),
    (6, 9, 'Fall', 2023),  (6, 10, 'Spring', 2024),
    (7, 10,'Fall', 2023),
    (8, 11,'Fall', 2023),  (8, 12,'Spring', 2024),
    (9, 12,'Fall', 2023),
    (10,13,'Fall', 2023), (10,14,'Spring', 2024),
    (12,15,'Fall', 2023), (12,16,'Spring', 2024),
    (17,19,'Fall', 2023), (18,20,'Spring', 2024);

-- course_schedule (15 rows)
INSERT INTO course_schedule (course_id, room_id, day_of_week, start_time, end_time) VALUES
    (1,  1,  'Monday',    '09:00', '10:30'),
    (1,  1,  'Wednesday', '09:00', '10:30'),
    (2,  2,  'Tuesday',   '11:00', '12:30'),
    (2,  2,  'Thursday',  '11:00', '12:30'),
    (3,  2,  'Monday',    '14:00', '15:30'),
    (6,  3,  'Tuesday',   '08:00', '09:30'),
    (6,  3,  'Thursday',  '08:00', '09:30'),
    (9,  4,  'Wednesday', '10:00', '11:30'),
    (13, 7,  'Friday',    '09:00', '10:30'),
    (15, 8,  'Monday',    '13:00', '14:30'),
    (17, 9,  'Tuesday',   '15:00', '16:30'),
    (19, 2,  'Thursday',  '14:00', '15:30'),
    (4,  1,  'Friday',    '11:00', '13:00'),
    (11, 6,  'Wednesday', '09:00', '10:30'),
    (20, 10, 'Saturday',  '10:00', '12:00');

-- assignments (30 rows)
INSERT INTO assignments (course_id, title, due_date, max_points, assignment_type) VALUES
    (1, 'Hello World & Variables',          '2023-09-15', 10,  'Homework'),
    (1, 'Control Flow Quiz',                '2023-09-29', 20,  'Quiz'),
    (1, 'Functions & Recursion HW',         '2023-10-20', 25,  'Homework'),
    (1, 'Midterm Exam - Programming Basics','2023-10-30', 100, 'Midterm'),
    (1, 'Final Project - Mini Application', '2023-12-10', 150, 'Final'),
    (2, 'Linked Lists Implementation',      '2023-10-05', 40,  'Homework'),
    (2, 'Sorting Algorithms Lab',           '2023-10-25', 30,  'Lab'),
    (2, 'Midterm - Complexity Analysis',    '2023-11-05', 100, 'Midterm'),
    (2, 'Final - Graph Algorithms Project', '2023-12-15', 150, 'Final'),
    (3, 'ER Diagram Design',                '2024-02-10', 50,  'Project'),
    (3, 'SQL Queries - Basic',              '2024-02-25', 40,  'Homework'),
    (3, 'Normalization Quiz',               '2024-03-10', 30,  'Quiz'),
    (3, 'Midterm - Schema Design',          '2024-03-20', 100, 'Midterm'),
    (6, 'Limits & Derivatives HW',          '2023-09-20', 30,  'Homework'),
    (6, 'Integration Quiz',                 '2023-10-15', 25,  'Quiz'),
    (6, 'Midterm - Calculus I',             '2023-10-30', 100, 'Midterm'),
    (6, 'Final Exam - Calculus I',          '2023-12-15', 150, 'Final'),
    (9, 'Newton Laws Lab',                  '2023-09-22', 30,  'Lab'),
    (9, 'Kinematics Problem Set',           '2023-10-10', 40,  'Homework'),
    (9, 'Midterm - Classical Mechanics',    '2023-11-01', 100, 'Midterm'),
    (13,'Demand & Supply Essay',            '2023-10-05', 30,  'Homework'),
    (13,'Market Structures Quiz',           '2023-10-28', 25,  'Quiz'),
    (13,'Midterm - Microeconomics',         '2023-11-10', 100, 'Midterm'),
    (15,'Cell Division Lab Report',         '2023-09-25', 40,  'Lab'),
    (15,'Microscopy Techniques HW',         '2023-10-12', 20,  'Homework'),
    (15,'Midterm - Cell Biology',           '2023-11-05', 100, 'Midterm'),
    (19,'Python for Data Science HW',       '2023-09-18', 30,  'Homework'),
    (19,'Pandas & Matplotlib Quiz',         '2023-10-10', 25,  'Quiz'),
    (19,'EDA Project',                      '2023-11-15', 80,  'Project'),
    (19,'Final - End-to-End Pipeline',      '2023-12-12', 150, 'Final');

-- submissions (40 rows)
INSERT INTO submissions (assignment_id, student_id, submitted_at, points_earned, feedback) VALUES
    (1,  1,  '2023-09-14 22:10:00', 9.5,  'Excellent work, clean code'),
    (2,  1,  '2023-09-28 18:30:00', 18.0, 'Minor logical error in loop'),
    (3,  1,  '2023-10-19 20:45:00', 23.5, 'Good recursion understanding'),
    (4,  1,  '2023-10-30 14:00:00', 88.0, 'Well done on the exam'),
    (5,  1,  '2023-12-09 23:50:00', 140.0,'Outstanding final project'),
    (6,  1,  '2023-10-04 21:00:00', 37.0, 'Solid linked list'),
    (7,  1,  '2023-10-24 19:00:00', 28.0, 'Good analysis'),
    (8,  1,  '2023-11-05 14:00:00', 92.0, 'Excellent'),
    (1,  7,  '2023-09-15 10:00:00', 7.5,  'Syntax errors - review notes'),
    (2,  7,  '2023-09-28 22:00:00', 14.0, 'Needs practice with conditionals'),
    (4,  7,  '2023-10-30 14:00:00', 71.0, 'Average performance'),
    (5,  7,  '2023-12-10 09:00:00', 110.0,'Good effort'),
    (14, 2,  '2023-09-19 17:00:00', 28.0, 'Strong grasp of limits'),
    (15, 2,  '2023-10-14 20:00:00', 23.0, 'Integration needs work'),
    (16, 2,  '2023-10-30 14:00:00', 91.0, 'Very good midterm'),
    (17, 2,  '2023-12-15 14:00:00', 142.0,'Top of class'),
    (18, 4,  '2023-09-21 16:00:00', 29.0, 'Thorough lab report'),
    (19, 4,  '2023-10-09 21:00:00', 36.0, 'Well solved'),
    (20, 4,  '2023-11-01 14:00:00', 85.0, 'Good performance'),
    (21, 5,  '2023-10-04 19:00:00', 26.0, 'Clear analysis'),
    (22, 5,  '2023-10-27 18:00:00', 22.0, 'Good quiz result'),
    (23, 5,  '2023-11-10 14:00:00', 82.0, 'Solid midterm'),
    (24, 6,  '2023-09-24 17:00:00', 38.0, 'Excellent lab report'),
    (25, 6,  '2023-10-11 19:00:00', 19.5, 'Good effort'),
    (26, 6,  '2023-11-05 14:00:00', 94.0, 'Outstanding'),
    (27, 3,  '2023-09-17 21:00:00', 28.0, 'Good Python code'),
    (28, 3,  '2023-10-09 20:00:00', 23.5, 'Well done'),
    (29, 3,  '2023-11-14 22:00:00', 74.0, 'Interesting EDA'),
    (30, 3,  '2023-12-11 23:00:00', 138.0,'Great pipeline'),
    (10, 14, '2024-02-09 20:00:00', 44.0, 'Excellent ER diagram'),
    (11, 14, '2024-02-24 21:00:00', 37.0, 'Good SQL queries'),
    (12, 14, '2024-03-09 18:00:00', 28.0, 'Normalization well understood'),
    (1,  14, '2024-02-08 19:00:00', 8.5,  'Good start'),
    (6,  17, '2023-10-04 20:00:00', 35.0, 'Good attempt'),
    (8,  17, '2023-11-05 14:00:00', 78.0, 'Decent performance'),
    (14, 11, '2023-09-19 19:00:00', 27.0, 'Decent limits work'),
    (16, 11, '2023-10-30 14:00:00', 86.0, 'Strong midterm'),
    (17, 11, '2023-12-15 14:00:00', 135.0,'Very strong final'),
    (27, 10, '2023-09-17 20:00:00', 30.0, 'Perfect score'),
    (30, 10, '2023-12-11 22:30:00', 148.0,'Exceptional work');

-- grades (30 rows)
INSERT INTO grades (enrollment_id, letter_grade, numeric_grade, graded_on) VALUES
    (1,  'A',  92.0, '2024-01-10'), (2,  'A',  91.0, '2024-01-10'),
    (4,  'A+', 97.0, '2024-01-10'), (6,  'A',  93.0, '2024-01-10'),
    (8,  'B+', 88.0, '2024-01-10'), (10, 'B+', 87.0, '2024-01-10'),
    (12, 'A',  94.0, '2024-01-10'), (14, 'B',  83.0, '2024-01-10'),
    (16, 'A',  90.0, '2024-01-10'), (18, 'A',  95.0, '2024-01-10'),
    (20, 'A+', 98.0, '2024-01-10'), (22, 'A',  91.0, '2024-01-10'),
    (24, 'A',  90.0, '2024-01-10'), (27, 'B',  82.0, '2024-01-10'),
    (29, 'B+', 85.0, '2024-01-10'), (31, 'B',  84.0, '2024-01-10'),
    (32, 'C+', 76.0, '2024-01-10'), (34, 'A',  93.0, '2024-01-10'),
    (36, 'A',  92.0, '2024-01-10'), (38, 'A',  94.0, '2024-01-10'),
    (39, 'B+', 86.0, '2024-01-10'), (40, 'B',  81.0, '2024-01-10'),
    (41, 'A',  90.0, '2024-01-10'), (43, 'A',  91.0, '2024-01-10'),
    (44, 'B+', 88.0, '2024-01-10'), (45, 'A',  94.0, '2024-01-10'),
    (46, 'B',  83.0, '2024-01-10'), (47, 'B+', 87.0, '2024-01-10'),
    (49, 'C',  72.0, '2024-01-10'), (50, 'A',  91.0, '2024-01-10');

-- payments (30 rows)
INSERT INTO payments (student_id, amount, paid_on, semester, year, method, enrollment_status) VALUES
    (1,  4500.00, '2023-08-20', 'Fall',   2023, 'Bank Transfer', 'Paid'),
    (1,  4500.00, '2024-01-05', 'Spring', 2024, 'Bank Transfer', 'Paid'),
    (2,  4200.00, '2023-08-18', 'Fall',   2023, 'Scholarship',   'Paid'),
    (2,  4200.00, '2024-01-03', 'Spring', 2024, 'Scholarship',   'Paid'),
    (3,  4800.00, '2023-08-25', 'Fall',   2023, 'Credit Card',   'Paid'),
    (4,  4500.00, '2023-08-22', 'Fall',   2023, 'Cash',          'Paid'),
    (5,  4800.00, '2023-08-19', 'Fall',   2023, 'Bank Transfer', 'Paid'),
    (6,  4200.00, '2023-08-20', 'Fall',   2023, 'Scholarship',   'Paid'),
    (7,  4500.00, '2023-08-21', 'Fall',   2023, 'Credit Card',   'Paid'),
    (8,  4800.00, '2023-08-17', 'Fall',   2023, 'Bank Transfer', 'Paid'),
    (9,  4200.00, '2023-08-23', 'Fall',   2023, 'Cash',          'Paid'),
    (10, 4500.00, '2023-08-20', 'Fall',   2023, 'Scholarship',   'Paid'),
    (10, 4500.00, '2024-01-08', 'Spring', 2024, 'Scholarship',   'Paid'),
    (11, 4800.00, '2023-08-22', 'Fall',   2023, 'Bank Transfer', 'Paid'),
    (12, 4200.00, '2023-08-19', 'Fall',   2023, 'Credit Card',   'Paid'),
    (13, 4500.00, '2023-08-18', 'Fall',   2023, 'Cash',          'Overdue'),
    (14, 4800.00, '2023-08-24', 'Fall',   2023, 'Bank Transfer', 'Paid'),
    (14, 4800.00, '2024-01-06', 'Spring', 2024, 'Bank Transfer', 'Paid'),
    (15, 4200.00, '2023-08-21', 'Fall',   2023, 'Scholarship',   'Paid'),
    (16, 4500.00, '2023-08-20', 'Fall',   2023, 'Credit Card',   'Paid'),
    (17, 4800.00, '2023-08-17', 'Fall',   2023, 'Bank Transfer', 'Paid'),
    (18, 4200.00, '2023-08-22', 'Fall',   2023, 'Scholarship',   'Paid'),
    (19, 4500.00, '2023-08-23', 'Fall',   2023, 'Cash',          'Paid'),
    (20, 4800.00, '2023-08-19', 'Fall',   2023, 'Credit Card',   'Paid'),
    (29, 4200.00, '2023-08-20', 'Fall',   2023, 'Cash',          'Overdue'),
    (30, 4500.00, '2023-08-21', 'Fall',   2023, 'Bank Transfer', 'Paid'),
    (30, 4500.00, '2024-01-07', 'Spring', 2024, 'Bank Transfer', 'Paid'),
    (41, 4800.00, '2023-08-18', 'Fall',   2023, 'Scholarship',   'Paid'),
    (49, 4200.00, '2023-08-24', 'Fall',   2023, 'Credit Card',   'Paid'),
    (50, 4500.00, '2023-08-20', 'Fall',   2023, 'Bank Transfer', 'Paid');

-- books (25 rows)
INSERT INTO books (isbn, title, author, genre, published_year, total_copies) VALUES
    ('978-0-13-468599-1', 'The C Programming Language',          'Kernighan & Ritchie', 'Programming',  1988, 5),
    ('978-0-13-110362-7', 'Introduction to Algorithms',          'CLRS',                'CS Theory',    2009, 8),
    ('978-0-13-235088-4', 'Database System Concepts',            'Silberschatz et al.', 'Database',     2019, 6),
    ('978-0-13-031826-4', 'Clean Code',                          'Robert Martin',       'Programming',  2008, 4),
    ('978-0-13-597316-2', 'The Pragmatic Programmer',            'Hunt & Thomas',       'Programming',  2019, 3),
    ('978-0-07-352332-0', 'Linear Algebra and Its Applications', 'Gilbert Strang',      'Mathematics',  2016, 5),
    ('978-0-13-916629-5', 'Probability and Statistics',          'DeGroot & Schervish', 'Mathematics',  2011, 4),
    ('978-0-471-64741-7', 'University Physics',                  'Young & Freedman',    'Physics',      2015, 6),
    ('978-0-521-67702-1', 'The Cambridge Companion to Darwin',   'Hodge & Radick',      'Biology',      2009, 3),
    ('978-0-13-213110-9', 'Economics',                           'Samuelson & Nordhaus','Economics',    2009, 5),
    ('978-0-19-955221-3', 'The Oxford Handbook of Philosophy',   'Various',             'Philosophy',   2014, 4),
    ('978-0-14-028329-7', 'Mrs Dalloway',                        'Virginia Woolf',      'Literature',   1925, 7),
    ('978-0-14-144020-3', 'Pride and Prejudice',                 'Jane Austen',         'Literature',   1813, 9),
    ('978-0-374-52954-6', 'Thinking Fast and Slow',              'Daniel Kahneman',     'Psychology',   2011, 6),
    ('978-0-06-093546-9', 'To Kill a Mockingbird',               'Harper Lee',          'Literature',   1960, 8),
    ('978-0-670-81302-1', 'The Brief History of Time',           'Stephen Hawking',     'Physics',      1988, 5),
    ('978-0-375-40822-0', 'The Selfish Gene',                    'Richard Dawkins',     'Biology',      1976, 4),
    ('978-0-345-53980-3', 'Cosmos',                              'Carl Sagan',          'Science',      1980, 3),
    ('978-0-06-019850-5', 'Sapiens',                             'Yuval Noah Harari',   'History',      2011, 7),
    ('978-1-4920-4823-4', 'Hands-On Machine Learning',           'Aurelien Geron',      'Data Science', 2022, 6),
    ('978-1-491-91205-8', 'Python for Data Analysis',            'Wes McKinney',        'Data Science', 2022, 5),
    ('978-0-262-53305-4', 'Deep Learning',                       'Goodfellow et al.',   'Data Science', 2016, 5),
    ('978-0-321-12521-7', 'Patterns of Enterprise Application',  'Martin Fowler',       'Programming',  2002, 3),
    ('978-0-596-51774-8', 'Learning SQL',                        'Alan Beaulieu',       'Database',     2020, 7),
    ('978-0-07-340508-0', 'Database Design for Mere Mortals',    'Michael Hernandez',   'Database',     2020, 4);

-- library_loans (30 rows)
INSERT INTO library_loans (student_id, book_id, loaned_on, due_date, returned_on) VALUES
    (1,  2,  '2023-10-01', '2023-10-15', '2023-10-13'),
    (1,  3,  '2024-02-01', '2024-02-15', NULL),
    (2,  6,  '2023-11-01', '2023-11-15', '2023-11-14'),
    (3,  20, '2023-10-05', '2023-10-19', '2023-10-18'),
    (3,  21, '2023-11-10', '2023-11-24', '2023-11-22'),
    (4,  8,  '2023-09-20', '2023-10-04', '2023-10-01'),
    (5,  10, '2023-10-12', '2023-10-26', '2023-10-25'),
    (6,  9,  '2023-09-25', '2023-10-09', '2023-10-08'),
    (7,  1,  '2023-10-08', '2023-10-22', '2023-10-20'),
    (8,  12, '2023-11-05', '2023-11-19', '2023-11-17'),
    (9,  11, '2023-10-15', '2023-10-29', '2023-10-28'),
    (10, 22, '2023-09-28', '2023-10-12', '2023-10-10'),
    (11, 7,  '2023-11-02', '2023-11-16', '2023-11-15'),
    (12, 17, '2023-10-20', '2023-11-03', NULL),
    (13, 10, '2023-10-18', '2023-11-01', '2023-11-05'),
    (14, 3,  '2024-01-20', '2024-02-03', '2024-02-01'),
    (14, 24, '2024-02-10', '2024-02-24', NULL),
    (15, 8,  '2023-10-05', '2023-10-19', '2023-10-17'),
    (16, 13, '2023-11-12', '2023-11-26', '2023-11-24'),
    (17, 4,  '2023-10-22', '2023-11-05', '2023-11-04'),
    (18, 6,  '2023-10-30', '2023-11-13', '2023-11-12'),
    (19, 21, '2023-10-02', '2023-10-16', '2023-10-14'),
    (20, 9,  '2023-09-30', '2023-10-14', '2023-10-13'),
    (23, 2,  '2024-01-25', '2024-02-08', NULL),
    (24, 20, '2023-10-07', '2023-10-21', '2023-10-19'),
    (25, 16, '2023-10-14', '2023-10-28', '2023-10-27'),
    (30, 3,  '2024-02-05', '2024-02-19', NULL),
    (37, 19, '2023-11-08', '2023-11-22', '2023-11-20'),
    (43, 5,  '2023-10-25', '2023-11-08', '2023-11-06'),
    (49, 14, '2023-11-15', '2023-11-29', '2023-11-28');


-- BASIC QUERIES 

-- Q1: All students enrolled in 2022
SELECT student_id, first_name, last_name, major, gpa
FROM   students
WHERE  enrollment_year = 2022
ORDER BY last_name;

-- Q2: Courses with 3 credit hours
SELECT course_code, title, level
FROM   courses
WHERE  credit_hours = 3
ORDER BY course_code;

-- Q3: Top 10 students by GPA
SELECT first_name, last_name, major, gpa
FROM   students
ORDER BY gpa DESC
LIMIT 10;

-- Q4: CS department professors
SELECT first_name, last_name, prof_rank, salary
FROM   professors
WHERE  dept_id = 1
ORDER BY salary DESC;

-- Q5: Unreturned library books
SELECT s.first_name, s.last_name, b.title, ll.loaned_on, ll.due_date
FROM   library_loans ll
JOIN   students s ON s.student_id = ll.student_id
JOIN   books    b ON b.book_id    = ll.book_id
WHERE  ll.returned_on IS NULL
ORDER BY ll.due_date;


-- JOINS

-- Q6: Full enrollment list with student name
SELECT CONCAT(s.first_name, ' ', s.last_name) AS student_name,
       c.course_code,
       c.title AS course_title,
       e.enrolled_on,
       e.enrollment_status
FROM   enrollments e
JOIN   students s ON s.student_id = e.student_id
JOIN   courses  c ON c.course_id  = e.course_id
ORDER BY s.last_name, c.course_code;

-- Q7: Professor assignments with department
SELECT CONCAT(p.first_name, ' ', p.last_name) AS professor,
       d.dept_name, c.course_code, c.title, pc.semester, pc.year
FROM   professor_courses pc
JOIN   professors  p ON p.prof_id   = pc.prof_id
JOIN   courses     c ON c.course_id = pc.course_id
JOIN   departments d ON d.dept_id   = p.dept_id
ORDER BY pc.year DESC, pc.semester, p.last_name;

-- Q8: Student grades with course name
SELECT CONCAT(s.first_name, ' ', s.last_name) AS student,
       c.course_code, g.letter_grade, g.numeric_grade
FROM   grades      g
JOIN   enrollments e ON e.enrollment_id = g.enrollment_id
JOIN   students    s ON s.student_id    = e.student_id
JOIN   courses     c ON c.course_id     = e.course_id
ORDER BY g.numeric_grade DESC;

-- Q9: LEFT JOIN — all students, including those not yet graded
SELECT CONCAT(s.first_name, ' ', s.last_name) AS student,
       c.course_code,
       COALESCE(g.letter_grade, 'Not graded') AS grade
FROM   enrollments e
JOIN   students    s ON s.student_id    = e.student_id
JOIN   courses     c ON c.course_id     = e.course_id
LEFT JOIN grades   g ON g.enrollment_id = e.enrollment_id
ORDER BY s.last_name;

-- Q10: Schedule with room info
SELECT c.course_code, c.title, cs.day_of_week, cs.start_time, cs.end_time,
       CONCAT(cl.building, ' ', cl.room_number) AS location,
       cl.capacity
FROM   course_schedule cs
JOIN   courses     c  ON c.course_id  = cs.course_id
LEFT JOIN classrooms cl ON cl.room_id = cs.room_id
ORDER BY cs.day_of_week, cs.start_time;


-- AGGREGATION & GROUPING

-- Q11: Students per major
SELECT major, COUNT(*) AS total_students, ROUND(AVG(gpa), 2) AS avg_gpa
FROM   students
GROUP BY major
ORDER BY total_students DESC;

-- Q12: Department budget vs headcount
SELECT d.dept_name, d.budget,
       COUNT(p.prof_id)        AS professors,
       ROUND(AVG(p.salary), 0) AS avg_salary
FROM   departments d
LEFT JOIN professors p ON p.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name, d.budget
ORDER BY d.budget DESC;

-- Q13: Enrollment count per course
SELECT c.course_code, c.title, COUNT(e.enrollment_id) AS enrolled_students
FROM   courses c
LEFT JOIN enrollments e ON e.course_id = c.course_id
GROUP BY c.course_id, c.course_code, c.title
ORDER BY enrolled_students DESC;

-- Q14: Average grade per course (HAVING filters to courses with 2+ grades)
SELECT c.course_code, c.title,
       ROUND(AVG(g.numeric_grade), 2) AS avg_grade,
       MIN(g.numeric_grade)           AS lowest,
       MAX(g.numeric_grade)           AS highest
FROM   grades g
JOIN   enrollments e ON e.enrollment_id = g.enrollment_id
JOIN   courses     c ON c.course_id     = e.course_id
GROUP BY c.course_id, c.course_code, c.title
HAVING COUNT(g.grade_id) >= 2
ORDER BY avg_grade DESC;

-- Q15: Tuition collected per semester
SELECT semester, year,
       COUNT(DISTINCT student_id)                           AS paying_students,
       SUM(amount)                                          AS total_collected,
       SUM(CASE WHEN enrollment_status = 'Overdue' THEN 1 ELSE 0 END) AS overdue_count
FROM   payments
GROUP BY semester, year
ORDER BY year, semester;

-- Q16: Students who submitted ALL COS101 assignments
SELECT s.first_name, s.last_name,
       COUNT(sub.submission_id) AS submissions_made,
       (SELECT COUNT(*) FROM assignments WHERE course_id = 1) AS total_assignments
FROM   students s
JOIN   submissions sub ON sub.student_id  = s.student_id
JOIN   assignments a   ON a.assignment_id = sub.assignment_id AND a.course_id = 1
GROUP BY s.student_id, s.first_name, s.last_name
HAVING COUNT(sub.submission_id) = (SELECT COUNT(*) FROM assignments WHERE course_id = 1);