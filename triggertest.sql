-- Trying to register students that has already taken the course 

INSERT INTO Registrations
	VALUES	('STU351', 'FFM130', 'Registered');  
INSERT INTO Registrations
	VALUES	('STU352', 'FFM130', 'Registered');  

-- Registering "fresh" students

INSERT INTO Registrations
	VALUES	('STU353', 'FFM130', 'Registered');  
INSERT INTO Registrations
	VALUES	('STU354', 'FFM130', 'Registered');
INSERT INTO Registrations
	VALUES	('STU355', 'FFM130', 'Registered');
INSERT INTO Registrations
	VALUES	('STU356', 'FFM130', 'Registered');
INSERT INTO Registrations
	VALUES	('STU357', 'FFM130', 'Registered');
INSERT INTO Registrations
	VALUES	('STU358', 'FFM130', 'Registered');
INSERT INTO Registrations
	VALUES	('STU359', 'FFM130', 'Registered');
INSERT INTO Registrations
	VALUES	('STU367', 'FFM130', 'Registered');
INSERT INTO Registrations
	VALUES	('STU377', 'FFM130', 'Registered');
INSERT INTO Registrations
	VALUES	('STU387', 'FFM130', 'Registered');

-- Trying to register students to the course when it's already full (and thus placing them in queue)

INSERT INTO Registrations
	VALUES	('STU397', 'FFM130', 'Registered');
INSERT INTO Registrations
	VALUES	('STU407', 'FFM130', 'Registered');
INSERT INTO Registrations
	VALUES	('STU417', 'FFM130', 'Registered');

-- Trying to register a student already registered to the course

INSERT INTO Registrations
	VALUES	('STU387', 'FFM130', 'Registered');

-- Removes students registered to the course, showing that the queue empties and enlists the students to the course

DELETE FROM Registrations
	WHERE student = 'STU353' AND course = 'FFM130'; 

DELETE FROM Registrations
	WHERE student = 'STU354' AND course = 'FFM130'; 

DELETE FROM Registrations
	WHERE student = 'STU355' AND course = 'FFM130'; 










