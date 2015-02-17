	begin
	for c in (select table_name from user_tables) loop
	execute immediate ('drop table '||c.table_name||' cascade constraints');
	end loop;
	end;
	/
	begin
	for c in (select * from user_objects) loop
	execute immediate ('drop '||c.object_type||' '||c.object_name);
	end loop;
	end;
	/

	CREATE TABLE department (
	name varchar2(50),
	abbreviation CHAR(5),	
	PRIMARY KEY (name),
	UNIQUE (abbreviation)
	);	



	CREATE TABLE programme (
	name varchar2(50),
	abbreviation varchar2(5),
	PRIMARY KEY (name) 
	);	

	CREATE TABLE branch (
	name varchar2(50),
	programme varchar2(50) REFERENCES programme,
	PRIMARY KEY (name, programme) 
	);

	CREATE TABLE course (
	cid CHAR(10),
	credits numeric(3),
	department varchar2(50) REFERENCES department,
	PRIMARY KEY (cid)
	);	


	CREATE TABLE pismandatory (
	programme varchar2(50) REFERENCES programme,
	course CHAR(10) REFERENCES course,
	PRIMARY KEY (programme, course)
	);

	CREATE TABLE isrecommended (
	programme varchar2(50), 
	branch varchar2(50), 
	course CHAR(10) REFERENCES course, 
	FOREIGN KEY (branch, programme) REFERENCES branch(name, programme), 
	PRIMARY KEY (programme, branch, course) 
	);		

	CREATE TABLE bismandatory (
	programme varchar2(50), 
	branch varchar2(50), 
	course CHAR(10) REFERENCES course, 
	FOREIGN KEY (branch, programme) REFERENCES branch(name, programme), 
	PRIMARY KEY (programme, branch, course) 
	);

	CREATE TABLE prerequisites (
	course CHAR(10) REFERENCES course,
	prereq CHAR(10) REFERENCES course,
	PRIMARY KEY (course, prereq) 
	);	

	CREATE TABLE coursetype (
	name varchar2(50),
	PRIMARY KEY (name) 
	);	

	CREATE TABLE hastype (
	course CHAR(10) REFERENCES course,
	type varchar2(50) REFERENCES coursetype,
	PRIMARY KEY (course, type) 
	);	

	CREATE TABLE sizerestrictedcourse (
	course CHAR(10) REFERENCES course,
	numstudents numeric(3),
	PRIMARY KEY (course), 
	UNIQUE (numstudents)
	);		

	CREATE TABLE hosts (
	department varchar2(50) REFERENCES department,
	programme varchar2(50) REFERENCES programme,
	PRIMARY KEY (department, programme) 
	);	

	CREATE TABLE student(
	id CHAR(6),
	name varchar2(50),
	programme varchar2(50) REFERENCES programme,
	PRIMARY KEY (id),
	UNIQUE (id, programme)
	);

	CREATE TABLE choosesbranch(
	student,
	programme varchar2(50),
	branch varchar2(50),
	CONSTRAINT A FOREIGN KEY (student, programme) REFERENCES student(id, programme),
	CONSTRAINT B FOREIGN KEY (branch, programme) REFERENCES branch(name, programme),
	PRIMARY KEY (student)
	);
		

	CREATE TABLE hastaken (
	student CHAR(6) REFERENCES student,
	course CHAR(10) REFERENCES course,
	grade varchar2(2),
	PRIMARY KEY (student, course),
	CONSTRAINT ValidGrade CHECK (grade in ('U',3,4,5))
	);

	CREATE TABLE register(
	student REFERENCES student,
	course REFERENCES course,
	PRIMARY KEY (student, course)
	);

	CREATE TABLE queue(
	student REFERENCES student,
	course REFERENCES course,
	queueSpot INT,
	PRIMARY KEY (student, course),
	UNIQUE (course, queuespot)
	);

CREATE VIEW StudentsFollowing AS
    SELECT id, name, student.programme, branch
    FROM student LEFT OUTER JOIN choosesbranch
ON id = student;
 
CREATE VIEW FinishedCourses AS
     (SELECT id, name , cid, grade, credits
      FROM course RIGHT OUTER JOIN
        student RIGHT OUTER JOIN hastaken
         ON id = student
      ON course = cid);
 
CREATE VIEW Registrations AS
    (SELECT student, course, 'Registered' AS status
    FROM register)
    UNION
    (SELECT student, course, 'Waiting' AS status
    FROM queue);
 	
CREATE VIEW PassedCourses AS
	    (SELECT id, name , cid, grade, credits
	      FROM FinishedCourses
	    WHERE grade = ANY ('3','4','5'));
 
CREATE VIEW UnreadMHelper1 AS
(SELECT student.id AS id, pismandatory.course AS course FROM student NATURAL JOIN pismandatory)
UNION
(SELECT student AS id, course FROM bismandatory INNER JOIN choosesbranch ON bismandatory.branch = choosesbranch.branch);
 
CREATE VIEW UnreadMandatory AS
    SELECT id, course
    FROM UnreadMHelper1 MINUS (SELECT id, cid
 FROM PassedCourses);
 
CREATE VIEW PathToGraduation AS
WITH  
	creditsTot AS(
					SELECT id, SUM(CREDITS) AS totCredits
					FROM  PassedCourses 
					group by id),
-- count(credits) student = student
-- the number of credits they have taken.

	numUnreadMandatory AS(
					SELECT id, COUNT(course) AS numUnread
					FROM  UnreadMandatory 
					group by id),
-- count(unreadmandatory) student = student
-- the number of mandatory courses they have yet to read (branch or programme).

	mathCreditsTot AS(
					SELECT id, SUM(CREDITS) AS totMathCredits
					FROM PassedCourses JOIN hastype ON PassedCourses.cid = hastype.course
					WHERE TYPE = 'Mathematical'
					GROUP BY id),
-- count(math credits) student = student
-- the number of credits they have taken in courses that are classified as math courses.

	researchCreditsTot AS(
					SELECT id, SUM(CREDITS) AS totResearchCredits
					FROM PassedCourses JOIN hastype ON PassedCourses.cid = hastype.course
					WHERE TYPE = 'Research'
					GROUP BY id),
-- count(research credits) student = student
-- the number of credits they have taken in courses that are classified as research courses.

	numSeminar AS(
					SELECT id, count(COURSE) AS totSeminar
					FROM PassedCourses JOIN hastype ON PassedCourses.cid = hastype.course
					WHERE TYPE = 'Seminar'
					GROUP BY id),
-- count(seminar) student = student
-- the number of seminar courses they have read.
					

	graduatedStudent AS(
					SELECT PassedCourses.id, 'Graduated' AS hasGraduated
					FROM PassedCourses, numUnreadMandatory, mathCreditsTot, researchCreditsTot, numSeminar
					WHERE 	numUnreadMandatory.numUnread = 0 AND 
							mathCreditsTot.totMathCredits >= 20 AND
							researchCreditsTot.totResearchCredits >= 10 AND
							numSeminar.totSeminar >= 1 AND 
							PassedCourses.id = numUnreadMandatory.id AND
							PassedCourses.id = mathCreditsTot.id AND
							PassedCourses.id = researchCreditsTot.id AND
							PassedCourses.id = numSeminar.id)


SELECT student.id, student.name,
		NVL(creditsTot.totCredits, 0) AS totCredits,
		NVL(numUnreadMandatory.numUnread, 0) AS numUnread,
		NVL(mathCreditsTot.totMathCredits, 0) AS totMathCredits,
		NVL(researchCreditsTot.totResearchCredits, 0) AS totResearchCredits,
		NVL(numSeminar.totSeminar, 0) AS totSeminar,
		NVL(graduatedStudent.hasGraduated, ' - ') AS hasGraduated
FROM student LEFT JOIN creditsTot
                ON student.id = creditsTot.id 
            LEFT JOIN numUnreadMandatory 
                ON student.id = numUnreadMandatory.id 
            LEFT JOIN mathCreditsTot 
                ON student.id = mathCreditsTot.id
            LEFT JOIN researchCreditsTot 
                ON student.id = researchCreditsTot.id
            LEFT JOIN numSeminar 
                ON student.id = numSeminar.id
            LEFT JOIN graduatedStudent 
                ON student.id = graduatedStudent.id;
-- qualify for graduation? Y / N
-- whether or not they qualify for graduation.


CREATE VIEW CourseQueuePositions AS
		SELECT course, student, queueSpot
		FROM queue;


INSERT INTO department
	VALUES ('ComputerScienceDepartment', 'CSD');
INSERT INTO department
	VALUES ('MathematicalScienesDepartment', 'MSD');
INSERT INTO department
	VALUES ('FundamentalPhysicsDepartment', 'FFD');
INSERT INTO department
	VALUES ('ChemicalScienceDepartment', 'CeSD');

INSERT INTO programme
	VALUES ('ChemicalScience', 'CeS');
INSERT INTO programme
	VALUES ('ComputerScience', 'CS');
INSERT INTO programme
	VALUES ('MathematicalScience', 'MS');
INSERT INTO programme
	VALUES ('FundamentalPhysics', 'FP');

INSERT INTO student
	VALUES  ('STU351', 'Bert1', 'ComputerScience');
INSERT INTO student
	VALUES	('STU352', 'Bert2', 'ComputerScience');
INSERT INTO student
	VALUES	('STU353', 'Bert3', 'ComputerScience');
INSERT INTO student
	VALUES	('STU354', 'Bert4', 'ComputerScience');
INSERT INTO student
	VALUES	('STU355', 'Bert5', 'ChemicalScience');
INSERT INTO student
	VALUES	('STU356', 'Bert6', 'ChemicalScience');
INSERT INTO student
	VALUES	('STU357', 'Bert7', 'MathematicalScience');
INSERT INTO student
	VALUES	('STU358', 'Bert8', 'MathematicalScience');
INSERT INTO student
	VALUES	('STU359', 'Bert9', 'FundamentalPhysics');
INSERT INTO student
	VALUES	('STU367', 'Bert10', 'FundamentalPhysics');
INSERT INTO student
	VALUES	('STU377', 'Bert11', 'FundamentalPhysics');
INSERT INTO student
	VALUES	('STU387', 'Bert12', 'FundamentalPhysics');
INSERT INTO student
	VALUES	('STU397', 'Bert13', 'FundamentalPhysics');
INSERT INTO student
	VALUES	('STU407', 'Bert14', 'FundamentalPhysics');
INSERT INTO student
	VALUES	('STU417', 'Bert15', 'FundamentalPhysics');

INSERT INTO course
	VALUES	('CHM130', '6', 'ChemicalScienceDepartment');
INSERT INTO course
	VALUES	('CHM140', '6', 'ChemicalScienceDepartment');
INSERT INTO course
	VALUES	('CHM150', '6', 'ChemicalScienceDepartment');
INSERT INTO course
	VALUES	('CSS130', '6', 'ComputerScienceDepartment');
INSERT INTO course
	VALUES	('CSS140', '6', 'ComputerScienceDepartment');
INSERT INTO course
	VALUES	('CSS150', '6', 'ComputerScienceDepartment');
INSERT INTO course
	VALUES	('MVE130', '6', 'MathematicalScienesDepartment');
INSERT INTO course
	VALUES	('MVE140', '5', 'MathematicalScienesDepartment');
INSERT INTO course
	VALUES	('MVE150', '5', 'MathematicalScienesDepartment');
INSERT INTO course
	VALUES	('FFM130', '6', 'FundamentalPhysicsDepartment');
INSERT INTO course
	VALUES	('FFM140', '5', 'FundamentalPhysicsDepartment');
INSERT INTO course
	VALUES	('FFM150', '5', 'FundamentalPhysicsDepartment');


INSERT INTO coursetype
	VALUES	('Mathematical');
INSERT INTO coursetype
	VALUES	('Research');
INSERT INTO coursetype
	VALUES	('Seminar');

INSERT INTO hastype
	VALUES	('MVE130', 'Mathematical');
INSERT INTO hastype
	VALUES	('MVE130', 'Research');
INSERT INTO hastype
	VALUES	('MVE150', 'Seminar');


INSERT INTO branch
	VALUES	('EngingeeringMathematics', 'MathematicalScience');
INSERT INTO branch
	VALUES	('PureMathematics', 'MathematicalScience');
INSERT INTO branch
	VALUES	('PhysicsAndAstronomy', 'FundamentalPhysics');
INSERT INTO branch
	VALUES	('EngineeringPhysics', 'FundamentalPhysics');
INSERT INTO branch
	VALUES	('ITSystems', 'ComputerScience');


INSERT INTO pismandatory
	VALUES	('ChemicalScience', 'CHM130');
INSERT INTO pismandatory
	VALUES	('ComputerScience', 'CSS130');

INSERT INTO isrecommended
	VALUES	('ComputerScience', 'ITSystems', 'CSS140');
INSERT INTO isrecommended
	VALUES	('MathematicalScience', 'EngingeeringMathematics', 'MVE140');

INSERT INTO bismandatory
	VALUES	('ComputerScience', 'ITSystems', 'CSS140');
INSERT INTO bismandatory
	VALUES	('MathematicalScience', 'EngingeeringMathematics', 'MVE140');

INSERT INTO prerequisites
	VALUES	('CSS140','CSS130');
INSERT INTO prerequisites
	VALUES	('FFM140', 'FFM150');

INSERT INTO sizerestrictedcourse
	VALUES	('FFM130', 10);




INSERT INTO choosesbranch
	VALUES	('STU351', 'ComputerScience', 'ITSystems');
INSERT INTO choosesbranch
	VALUES	('STU367', 'FundamentalPhysics', 'EngineeringPhysics');
INSERT INTO choosesbranch
	VALUES	('STU357', 'MathematicalScience', 'PureMathematics');
INSERT INTO choosesbranch
	VALUES	('STU359', 'FundamentalPhysics', 'PhysicsAndAstronomy');

INSERT INTO hastaken
	VALUES	('STU351', 'FFM130', 4);
INSERT INTO hastaken
	VALUES	('STU352', 'FFM130', 3); 
INSERT INTO hastaken
	VALUES	('STU353', 'FFM130', 'U');

