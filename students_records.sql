-- Student Records Database Management System
-- Created by: YAHYA MOHAMED

-- Create database
DROP DATABASE
IF
  EXISTS student_records_db;
  CREATE DATABASE student_records_db;
  USE student_records_db;

  -- Departments table (1-to-many with Programs, Courses, and Faculty)
  CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY
    , department_name VARCHAR(100) NOT NULL UNIQUE
    , department_code VARCHAR(10) NOT NULL UNIQUE
    , building VARCHAR(50) NOT NULL
    , office_phone VARCHAR(15)
    , email VARCHAR(100) NOT NULL UNIQUE
    , established_date DATE NOT NULL
    , description TEXT
    , CONSTRAINT chk_dept_code CHECK (department_code REGEXP '^[A-Z]{2,10}$')
  );

  -- Programs table (1-to-many with Students)
  CREATE TABLE programs (
    program_id INT AUTO_INCREMENT PRIMARY KEY
    , program_name VARCHAR(100) NOT NULL
    , program_code VARCHAR(10) NOT NULL UNIQUE
    , degree_level ENUM(
      'Certificate'
      , 'Associate'
      , 'Bachelor'
      , 'Master'
      , 'Doctorate'
    ) NOT NULL
    , total_credits INT NOT NULL
    , department_id INT NOT NULL
    , description TEXT
    , CONSTRAINT fk_program_department FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON DELETE RESTRICT
    ON
    UPDATE
      CASCADE
      , CONSTRAINT chk_program_code CHECK (program_code REGEXP '^[A-Z]{2,4}[0-9]{2,4}$')
      , CONSTRAINT chk_credits_positive CHECK (total_credits > 0)
  );

  -- Students table (1-to-many with Enrollments, Payments, etc.)
  CREATE TABLE students (
    student_id INT PRIMARY KEY AUTO_INCREMENT
    , university_id VARCHAR(20) NOT NULL UNIQUE
    , first_name VARCHAR(50) NOT NULL
    , last_name VARCHAR(50) NOT NULL
    , date_of_birth DATE NOT NULL
    , gender ENUM('Male', 'Female', 'Other', 'Prefer not to say')
    , email VARCHAR(100) NOT NULL UNIQUE
    , phone VARCHAR(15)
    , address TEXT
    , city VARCHAR(50)
    , state VARCHAR(50)
    , postal_code VARCHAR(20)
    , country VARCHAR(50) DEFAULT 'United States'
    , program_id INT
    , enrollment_date DATE NOT NULL
    , graduation_date DATE
    , status ENUM(
      'Active'
      , 'On Leave'
      , 'Suspended'
      , 'Graduated'
      , 'Withdrawn'
    ) NOT NULL DEFAULT 'Active'
    , CONSTRAINT fk_student_program FOREIGN KEY (program_id) REFERENCES programs(program_id)
    ON DELETE SET NULL
    ON
    UPDATE
      CASCADE
      , CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%')
      , CONSTRAINT chk_enrollment_before_graduation CHECK (
        graduation_date IS NULL
        OR enrollment_date <= graduation_date
      )
  );

  -- Faculty table (1-to-many with Course_Sections)
  CREATE TABLE faculty (
    faculty_id INT AUTO_INCREMENT PRIMARY KEY
    , university_id VARCHAR(20) NOT NULL UNIQUE
    , first_name VARCHAR(50) NOT NULL
    , last_name VARCHAR(50) NOT NULL
    , date_of_birth DATE NOT NULL
    , gender ENUM('Male', 'Female', 'Other', 'Prefer not to say')
    , email VARCHAR(100) NOT NULL UNIQUE
    , phone VARCHAR(15)
    , address TEXT
    , department_id INT NOT NULL
    , position VARCHAR(100) NOT NULL
    , hire_date DATE NOT NULL
    , office_location VARCHAR(50)
    , office_hours TEXT
    , status ENUM('Active', 'On Leave', 'Retired', 'Terminated') NOT NULL DEFAULT 'Active'
    , CONSTRAINT fk_faculty_department FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON DELETE RESTRICT
    ON
    UPDATE
      CASCADE
      , CONSTRAINT chk_faculty_age CHECK (YEAR(hire_date) - YEAR(date_of_birth) >= 22)
  );

  -- Courses table (1-to-many with Course_Sections, Prerequisites)
  CREATE TABLE courses (
    course_id INT AUTO_INCREMENT PRIMARY KEY
    , course_code VARCHAR(20) NOT NULL UNIQUE
    , course_name VARCHAR(100) NOT NULL
    , description TEXT
    , credits DECIMAL(3, 1) NOT NULL
    , department_id INT NOT NULL
    , level ENUM('100', '200', '300', '400', '500', '600', '700', '800') NOT NULL
    , is_core TINYINT(1) DEFAULT 0
    , is_active TINYINT(1) DEFAULT 1
    , CONSTRAINT fk_course_department FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON DELETE RESTRICT
    ON
    UPDATE
      CASCADE
      , CONSTRAINT chk_credits_range CHECK (
        credits BETWEEN 0.5 AND 6.0
      )
      , CONSTRAINT chk_course_code_format CHECK (course_code REGEXP '^[A-Z]{2,4}[0-9]{3,4}[A-Z]?$')
  );

  -- Course prerequisites (many-to-many between courses)
  CREATE TABLE course_prerequisites (
    course_id INT NOT NULL
    , prerequisite_course_id INT NOT NULL
    , minimum_grade ENUM('A', 'B', 'C', 'D') DEFAULT 'D'
    , is_mandatory TINYINT(1) DEFAULT 1
    , PRIMARY KEY (course_id, prerequisite_course_id)
    , CONSTRAINT fk_prereq_course FOREIGN KEY (course_id) REFERENCES courses(course_id)
    ON DELETE RESTRICT
    ON
    UPDATE
      RESTRICT
      , CONSTRAINT fk_prereq_prerequisite FOREIGN KEY (prerequisite_course_id) REFERENCES courses(course_id)
    ON DELETE RESTRICT
    ON
    UPDATE
      RESTRICT
      , CONSTRAINT chk_not_self_prerequisite CHECK (course_id != prerequisite_course_id)
  );

  -- Semesters table (1-to-many with Course_Sections)
  CREATE TABLE semesters (
    semester_id INT AUTO_INCREMENT PRIMARY KEY
    , semester_name VARCHAR(50) NOT NULL UNIQUE
    , semester_code VARCHAR(20) NOT NULL UNIQUE
    , start_date DATE NOT NULL
    , end_date DATE NOT NULL
    , registration_start DATE NOT NULL
    , registration_end DATE NOT NULL
    , is_current TINYINT(1) DEFAULT 0
    , CONSTRAINT chk_semester_dates CHECK (start_date < end_date)
    , CONSTRAINT chk_registration_dates CHECK (
      registration_start < registration_end
      AND registration_end <= start_date
    )
  );

  -- Course sections table (1-to-many with Enrollments)
  CREATE TABLE course_sections (
    section_id INT AUTO_INCREMENT PRIMARY KEY
    , course_id INT NOT NULL
    , semester_id INT NOT NULL
    , section_number VARCHAR(10) NOT NULL
    , faculty_id INT
    , classroom VARCHAR(20)
    , schedule VARCHAR(100) NOT NULL
    , max_capacity INT NOT NULL
    , current_enrollment INT DEFAULT 0
    , is_lab TINYINT(1) DEFAULT 0
    , CONSTRAINT fk_section_course FOREIGN KEY (course_id) REFERENCES courses(course_id)
    ON DELETE CASCADE
    ON
    UPDATE
      CASCADE
      , CONSTRAINT fk_section_semester FOREIGN KEY (semester_id) REFERENCES semesters(semester_id)
    ON DELETE CASCADE
    ON
    UPDATE
      CASCADE
      , CONSTRAINT fk_section_faculty FOREIGN KEY (faculty_id) REFERENCES faculty(faculty_id)
    ON DELETE SET NULL
    ON
    UPDATE
      CASCADE
      , CONSTRAINT chk_enrollment_capacity CHECK (current_enrollment <= max_capacity)
      , CONSTRAINT chk_positive_capacity CHECK (max_capacity > 0)
      , CONSTRAINT uk_section_unique UNIQUE (course_id, semester_id, section_number)
  );

  -- Enrollments table (many-to-many between Students and Course_Sections)
  CREATE TABLE enrollments (
    enrollment_id INT AUTO_INCREMENT PRIMARY KEY
    , student_id INT NOT NULL
    , section_id INT NOT NULL
    , enrollment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    , withdrawal_date DATETIME
    , final_grade DECIMAL(4, 2)
    , grade_letter ENUM(
      'A'
      , 'A-'
      , 'B+'
      , 'B'
      , 'B-'
      , 'C+'
      , 'C'
      , 'C-'
      , 'D+'
      , 'D'
      , 'F'
      , 'W'
      , 'I'
      , 'P'
      , 'NP'
    )
    , status ENUM('Enrolled', 'Dropped', 'Withdrawn', 'Completed') NOT NULL DEFAULT 'Enrolled'
    , credits_earned DECIMAL(3, 1)
    , CONSTRAINT fk_enrollment_student FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON DELETE CASCADE
    ON
    UPDATE
      CASCADE
      , CONSTRAINT fk_enrollment_section FOREIGN KEY (section_id) REFERENCES course_sections(section_id)
    ON DELETE CASCADE
    ON
    UPDATE
      CASCADE
      , CONSTRAINT chk_withdrawal_after_enrollment CHECK (
        withdrawal_date IS NULL
        OR withdrawal_date >= enrollment_date
      )
      , CONSTRAINT uk_student_section UNIQUE (student_id, section_id)
  );

  -- Payments table (1-to-many with Students)
  CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY
    , student_id INT NOT NULL
    , amount DECIMAL(10, 2) NOT NULL
    , payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    , payment_method ENUM(
      'Credit Card'
      , 'Debit Card'
      , 'Bank Transfer'
      , 'Check'
      , 'Cash'
      , 'Scholarship'
      , 'Financial Aid'
    ) NOT NULL
    , payment_purpose ENUM(
      'Tuition'
      , 'Housing'
      , 'Meal Plan'
      , 'Library Fine'
      , 'Other'
    ) NOT NULL
    , transaction_id VARCHAR(100) UNIQUE
    , receipt_number VARCHAR(50) UNIQUE
    , status ENUM('Pending', 'Completed', 'Failed', 'Refunded') NOT NULL DEFAULT 'Completed'
    , notes TEXT
    , CONSTRAINT fk_payment_student FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON DELETE CASCADE
    ON
    UPDATE
      CASCADE
      , CONSTRAINT chk_positive_amount CHECK (amount > 0)
  );

  -- Library books table
  CREATE TABLE library_books (
    book_id INT AUTO_INCREMENT PRIMARY KEY
    , isbn VARCHAR(20) NOT NULL UNIQUE
    , title VARCHAR(200) NOT NULL
    , author VARCHAR(100) NOT NULL
    , publisher VARCHAR(100)
    , publication_year INT
    , edition VARCHAR(20)
    , category VARCHAR(50) NOT NULL
    , total_copies INT NOT NULL DEFAULT 1
    , available_copies INT NOT NULL DEFAULT 1
    , location VARCHAR(50) NOT NULL
    , CONSTRAINT chk_copies_available CHECK (
      available_copies BETWEEN 0 AND total_copies
    )
    , CONSTRAINT chk_positive_copies CHECK (total_copies > 0)
  );


  -- Book loans table (many-to-many between Students and Library_Books)
  CREATE TABLE book_loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY
    , book_id INT NOT NULL
    , student_id INT NOT NULL
    , checkout_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    , due_date DATETIME NOT NULL
    , return_date DATETIME
    , status ENUM('Checked Out', 'Returned', 'Overdue', 'Lost') NOT NULL DEFAULT 'Checked Out'
    , fine_amount DECIMAL(10, 2) DEFAULT 0.00
    , CONSTRAINT fk_loan_book FOREIGN KEY (book_id) REFERENCES library_books(book_id)
    ON DELETE RESTRICT
    ON
    UPDATE
      CASCADE
      , CONSTRAINT fk_loan_student FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON DELETE CASCADE
    ON
    UPDATE
      CASCADE
      , CONSTRAINT chk_due_after_checkout CHECK (due_date > checkout_date)
      , CONSTRAINT chk_return_after_checkout CHECK (
        return_date IS NULL
        OR return_date >= checkout_date
      )
  );

  -- Student achievements table (1-to-many with Students)
  CREATE TABLE student_achievements (
    achievement_id INT AUTO_INCREMENT PRIMARY KEY
    , student_id INT NOT NULL
    , achievement_type ENUM(
      'Academic'
      , 'Athletic'
      , 'Artistic'
      , 'Community Service'
      , 'Leadership'
      , 'Other'
    ) NOT NULL
    , title VARCHAR(100) NOT NULL
    , description TEXT
    , date_awarded DATE NOT NULL
    , awarding_organization VARCHAR(100)
    , CONSTRAINT fk_achievement_student FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON DELETE CASCADE
    ON
    UPDATE
      CASCADE
  );

  -- Student disciplinary actions table (1-to-many with Students)
  CREATE TABLE disciplinary_actions (
    action_id INTEGER AUTO_INCREMENT PRIMARY KEY
    , student_id INTEGER NOT NULL
    , action_type ENUM(
      'Warning'
      , 'Probation'
      , 'Suspension'
      , 'Expulsion'
      , 'Other'
    ) NOT NULL
    , description TEXT NOT NULL
    , date_issued DATE NOT NULL
    , issuing_authority VARCHAR(100) NOT NULL
    , end_date DATE
    , is_active TINYINT(1) DEFAULT 1
    , CONSTRAINT fk_action_student FOREIGN KEY (student_id) REFERENCES students(student_id)
    ON DELETE CASCADE
    ON
    UPDATE
      CASCADE
      , CONSTRAINT chk_end_after_issue CHECK (
        end_date IS NULL
        OR end_date >= date_issued
      )
  );

  -- Create indexes for performance optimization
  CREATE INDEX idx_student_name
  ON students(last_name, first_name);
  CREATE INDEX idx_student_program
  ON students(program_id);
  CREATE INDEX idx_enrollment_student
  ON enrollments(student_id);
  CREATE INDEX idx_enrollment_section
  ON enrollments(section_id);
  CREATE INDEX idx_section_course
  ON course_sections(course_id);
  CREATE INDEX idx_section_semester
  ON course_sections(semester_id);
  CREATE INDEX idx_course_department
  ON courses(department_id);
  CREATE INDEX idx_faculty_department
  ON faculty(department_id);
  CREATE INDEX idx_book_loan_student
  ON book_loans(student_id);
  CREATE INDEX idx_book_loan_status
  ON book_loans(status);
  CREATE INDEX idx_payment_student
  ON payments(student_id);