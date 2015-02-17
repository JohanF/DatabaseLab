CREATE OR REPLACE TRIGGER addStudent
INSTEAD OF INSERT ON Registrations
REFERENCING NEW AS newStudent
FOR EACH ROW 

		DECLARE alreadyPassed INT;
				alreadyRegistered INT;
				alreadyInQueue INT;
				emptySpotsOnCourse INT;
				lastQueueSpot INT;
				haveNotReadPrereq INT;
				isSizeRestricted INT;
				maxStudents INT;
				currentStudents INT;

BEGIN
	

	

		SELECT Count(*) into alreadyPassed
		FROM PassedCourses
		WHERE cid = :newStudent.course AND id = :newStudent.student;
		-- Check if student may register

		SELECT Count(*) into alreadyRegistered
		FROM register
		WHERE course = :newStudent.course AND student = :newStudent.student;
		-- Check if student may register

		SELECT Count(prereq) into haveNotReadPrereq
		FROM ((SELECT prereq FROM prerequisites WHERE course = :newStudent.course) MINUS (
			  SELECT cid FROM passedcourses WHERE id = :newStudent.student));
		-- Check if student may register
		
		SELECT Count(*) into alreadyInQueue
		FROM queue 
		WHERE student = :newstudent.student AND course = :newStudent.course;
		-- Check if student may register

		SELECT Count(*) into isSizeRestricted
		FROM sizerestrictedcourse
		WHERE course = :newstudent.course;
		-- Check if course is size restricted
		IF (isSizeRestricted > 0) THEN
			SELECT numstudents into maxStudents
			FROM sizerestrictedcourse
			WHERE course = :newStudent.course;
			-- Check max amount of students for the course
		END IF;

		SELECT Count(student) into currentStudents
		FROM register
		WHERE course = :newStudent.course;
		-- Check current amount of students for the course


		
		IF(alreadyPassed > 0) THEN 
			RAISE_APPLICATION_ERROR(-20001, 'You have already passed the course');
		END IF;

		
		IF(alreadyRegistered > 0) THEN
			RAISE_APPLICATION_ERROR(-20002, 'You have already registered to the course');
		END IF;

			
			
		IF(haveNotReadPrereq > 0) THEN 
			RAISE_APPLICATION_ERROR(-20003, 'You havenÂ´t read the preqrequisites for the course');
		END IF;

		
		IF(alreadyInQueue > 0) THEN
			RAISE_APPLICATION_ERROR(-20004, 'You are already in the queue for the course');
		END IF;

		IF(isSizeRestricted > 0) THEN

			IF((maxStudents - currentStudents) > 0) THEN

				INSERT INTO register
				VALUES (:newStudent.student, :newStudent.course);
				-- add to course			
			ELSE
				SELECT MAX(queueSpot) into lastQueueSpot
				FROM queue
				WHERE course = :newStudent.course;

					IF(lastQueueSpot IS NULL) THEN

						INSERT INTO queue
						VALUES (:newStudent.student, :newStudent.course, 1);

					ELSE

						INSERT INTO queue
						VALUES (:newStudent.student, :newStudent.course, (lastQueueSpot+1));
						-- if full, add to queue
					END IF;
			END IF;				
		ELSE
		INSERT INTO register VALUES (:newStudent.student, :newStudent.course);
		END IF;
END;

/

CREATE OR REPLACE TRIGGER removeStudent
INSTEAD OF DELETE ON Registrations
REFERENCING OLD AS removedStudent
FOR EACH ROW 

Declare isRegistered INT;
		queueStudents INT;		
		isSizeRestricted INT;
		isInQueue INT;
		qSpot INT;
		maxStudents INT;
		currentStudents INT;
		firstInQueueStudent CHAR(6);

BEGIN
	
	SELECT Count(*) into isRegistered
	FROM register
	WHERE course = :removedStudent.course AND student = :removedStudent.student;
	-- Checks if student is registered to the course

	SELECT Count(*) into queueStudents
	FROM queue
	WHERE course = :removedStudent.course;
	-- Checks the amount of students queueing for the course

	SELECT Count(*) into isSizeRestricted
	FROM sizerestrictedcourse
	WHERE course = :removedStudent.course;
	-- Checks if the course is size restricted

	SELECT Count(*) into isInQueue
	FROM queue
	WHERE course = :removedStudent.course AND student = :removedStudent.student;
	-- Checks if the student is in the queue for the course

	IF (isSizeRestricted > 0) THEN
			SELECT numstudents into maxStudents
			FROM sizerestrictedcourse
			WHERE course = :removedStudent.course;
			-- Check max amount of students for the course
	END IF;

	SELECT Count(student) into currentStudents
	FROM register
	WHERE course = :removedStudent.course;


	IF(isRegistered > 0) THEN 
		IF(queueStudents > 0) THEN
			IF((maxStudents - currentStudents) = 0) THEN
				DELETE FROM register
				WHERE student = :removedStudent.student AND course = :removedStudent.course;

				SELECT student into firstInQueueStudent
				FROM CourseQueuePositions
				WHERE course = :removedStudent.course AND queueSpot = 1;

				INSERT INTO register VALUES (firstInQueueStudent, :removedStudent.course);
				DELETE FROM queue WHERE student = firstInQueueStudent AND course = :removedStudent.course;

				UPDATE queue SET queueSpot = queueSpot - 1
				WHERE course = :removedStudent.course;
			ELSE 
				DELETE FROM register
				WHERE student = :removedStudent.student AND course = :removedStudent.course;
			END IF;
		ELSE 
			DELETE FROM register
			WHERE student = :removedStudent.student AND course = :removedStudent.course;
		END IF;

	ELSIF(isInQueue > 0) THEN

			SELECT queueSpot into qSpot
			FROM queue
			WHERE student = :removedStudent.student AND course = :removedStudent.course;

			DELETE FROM queue
			WHERE student = :removedStudent.student AND course = :removedStudent.course;

			UPDATE queue SET queueSpot = queueSpot - 1
			WHERE course = :removedStudent.course AND queueSpot > qSpot;
	END IF;
END;

/	