DROP TABLE IF EXISTS clubs;
CREATE TABLE clubs (
  id serial PRIMARY KEY,
  name varchar(255) NOT NULL DEFAULT ''
);
CREATE UNIQUE INDEX idx_name ON clubs (name);

DROP TABLE IF EXISTS departments;
CREATE TABLE departments (
  dept_no char(4) PRIMARY KEY,
  dept_name varchar(40) NOT NULL
);
CREATE UNIQUE INDEX idx_dept_name ON departments (dept_name);

DROP TABLE IF EXISTS dept_emp ;
CREATE TABLE dept_emp (
  emp_no int NOT NULL,
  dept_no char(4) NOT NULL,
  from_date date NOT NULL,
  to_date date NOT NULL,
  PRIMARY KEY (emp_no,dept_no)
);
CREATE INDEX idx_dept_emp_emp_no ON dept_emp (emp_no);
CREATE INDEX idx_dept_emp_dept_no ON dept_emp (dept_no);

DROP TABLE IF EXISTS dept_manager;
CREATE TABLE dept_manager (
  dept_no char(4) NOT NULL,
  emp_no int NOT NULL,
  from_date date NOT NULL,
  to_date date NOT NULL,
  PRIMARY KEY (emp_no,dept_no)
);
CREATE INDEX idx_dept_manager_emp_no ON dept_manager (emp_no);
CREATE INDEX idx_dept_manager_dept_no ON dept_manager (dept_no);

DROP TABLE IF EXISTS employee_clubs;
CREATE TABLE employee_clubs (
  id serial PRIMARY KEY,
  emp_no int NOT NULL,
  club_id int NOT NULL
);
CREATE INDEX idx_employee_clubs_emp_no_club_id ON employee_clubs (emp_no,club_id);

DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
  emp_no int PRIMARY KEY,
  birth_date date NOT NULL,
  first_name varchar(14) NOT NULL,
  last_name varchar(16) NOT NULL,
  hire_date date NOT NULL
);

DROP TABLE IF EXISTS salaries;
CREATE TABLE salaries (
  emp_no int NOT NULL,
  salary int NOT NULL,
  from_date date NOT NULL,
  to_date date NOT NULL,
  PRIMARY KEY (emp_no,from_date)
);
CREATE INDEX idx_salaries_emp_no ON salaries (emp_no);

DROP TABLE IF EXISTS titles;
CREATE TABLE titles (
  emp_no int NOT NULL,
  title varchar(50) NOT NULL,
  from_date date NOT NULL,
  to_date date DEFAULT NULL,
  PRIMARY KEY (emp_no,title,from_date)
);
CREATE INDEX idx_titles_emp_no ON titles (emp_no);

DROP TABLE IF EXISTS child;
DROP TABLE IF EXISTS parent;
