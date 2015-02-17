import java.sql.*; // JDBC stuff.
import java.io.*; // Reading user input.

public class StudentPortal {
	/*
	 * This is the driving engine of the program. It parses the command-line
	 * arguments and calls the appropriate methods in the other classes.
	 * 
	 * You should edit this file in two ways: 1) Insert your database username
	 * and password (no @medic1!) in the proper places. 2) Implement the three
	 * functions getInformation, registerStudent and unregisterStudent.
	 */
	public static void main(String[] args) {
		if (args.length == 1) {
			try {
				DriverManager.registerDriver(new oracle.jdbc.OracleDriver());
				String url = "jdbc:oracle:thin:@tycho.ita.chalmers.se:1521/kingu.ita.chalmers.se";
				String userName = "vtda357_075"; // Your username goes here!
				String password = "sandw1cht1me"; // Your password goes here!
				Connection conn = DriverManager.getConnection(url, userName,
						password);

				String student = args[0]; // This is the identifier for the
											// student.
				BufferedReader input = new BufferedReader(
						new InputStreamReader(System.in));
				System.out.println("Welcome!");
				while (true) {
					System.out.println("Please choose a mode of operation:");
					System.out.print("? > ");
					String mode = input.readLine();
					if ((new String("information")).startsWith(mode
							.toLowerCase())) {
						/* Information mode */
						getInformation(conn, student);
					} else if ((new String("register")).startsWith(mode
							.toLowerCase())) {
						/* Register student mode */
						System.out.print("Register for what course? > ");
						String course = input.readLine();
						registerStudent(conn, student, course);
					} else if ((new String("unregister")).startsWith(mode
							.toLowerCase())) {
						/* Unregister student mode */
						System.out.print("Unregister from what course? > ");
						String course = input.readLine();
						unregisterStudent(conn, student, course);
					} else if ((new String("quit")).startsWith(mode
							.toLowerCase())) {
						System.out.println("Goodbye!");
						break;
					} else {
						System.out
								.println("Unknown argument, please choose either "
										+ "information, register, unregister or quit!");
						continue;
					}
				}
				conn.close();
			} catch (SQLException e) {
				System.err.println(e);
				System.exit(2);
			} catch (IOException e) {
				System.err.println(e);
				System.exit(2);
			}
		} else {
			System.err.println("Wrong number of arguments");
			System.exit(3);
		}
	}

	static void getInformation(Connection conn, String student)
			throws SQLException {

		Statement statement = conn.createStatement();
		ResultSet resultset = statement
				.executeQuery("SELECT name, programme, branch "
						+ "FROM StudentsFollowing " + "WHERE id = '" + student
						+ "'");
		System.out.println("Information for student " + student
				+ "\n----------------------------------------------");
		while (resultset.next()) {
			String name = resultset.getString("name");
			String program = resultset.getString("programme");
			String branch = resultset.getString("branch");

			System.out.println("Name: " + name + "\nLine: " + program
					+ "\nBranch: " + branch);
		}

		Statement statement2 = conn.createStatement();
		ResultSet resultset2 = statement2
				.executeQuery("SELECT cid, grade, credits "
						+ "FROM FinishedCourses " + "WHERE id = '" + student
						+ "'");

		System.out.println("\n\nRead courses (code, credits: grade):");
		while (resultset2.next()) {
			// String name = resultset.getString("name");
			String cid = resultset2.getString("cid");
			String credits = resultset2.getString("credits");
			String grade = resultset2.getString("grade");

			System.out.println(cid + " , " + credits + " : " + grade);
		}
		Statement statement3 = conn.createStatement();
		String query = "SELECT * "
				+ "FROM Registrations RIGHT INNER JOIN course ON course = course.cid "
				+ "WHERE student = '" + student + "'";
		ResultSet resultset3 = statement3
				.executeQuery(query);
		System.out.println("\n\nRegistered courses (code, credits: status):");
		while (resultset3.next()) {
			String cid = resultset3.getString("course");
			String credits = resultset3.getString("credits");
			String status = resultset3.getString("status");

			if (status.equals("Registered")) {
				System.out.println("(" + cid + "), " + credits + " : " + status);
			} else {
				Statement statement4 = conn.createStatement();
				ResultSet resultset4 = statement4
						.executeQuery("SELECT queueSpot "
								+ "FROM CourseQueuePositions " + "WHERE student = '"
								+ student + "' AND course = '" + cid + "'");
				while (resultset4.next()) {
					int queueSpot = resultset4.getInt("queueSpot");
					System.out.println("(" + cid + "), " + credits
							+ ": waiting as nr " + queueSpot);

				}
			}

			
		}

		Statement statement5 = conn.createStatement();
		ResultSet resultset5 = statement5.executeQuery("SELECT * "
				+ "FROM PathToGraduation " + "WHERE id = '" + student + "'");
		while (resultset5.next()) {
			// String name = resultset.getString("name");
			String id = resultset5.getString("id");
			String totSeminar = resultset5.getString("totSeminar");
			String totMathCredits = resultset5.getString("totMathCredits");
			String totResearchCredits = resultset5
					.getString("totResearchCredits");
			String totCredits = resultset5.getString("totCredits");
			String hasGraduated = resultset5.getString("hasGraduated");

			System.out.println("\n\nSeminar courses taken: " + totSeminar);
			System.out.println("Maths credits taken: " + totMathCredits);
			System.out
					.println("Reasearch credits taken: " + totResearchCredits);
			System.out.println("Total credits taken: " + totCredits);
			if (hasGraduated.equals("Graduated")) {
				System.out
						.println("Fulfills the requirements for graduation: Yes");
			} else
				System.out
						.println("Fulfills the requirements for graduation: No");
		}
	}

	static void registerStudent(Connection conn, String student, String course)
			throws SQLException {
		Statement stmt = conn.createStatement();
		String regQuery = "INSERT INTO Registrations VALUES	('" + student
				+ "', '" + course + "', 'Registered')";
		String checkQueueQuery = "SELECT queueSpot FROM CourseQueuePositions WHERE student = '"
				+ student + "' AND course =  '" + course + "'";
		try {
			stmt.executeUpdate(regQuery);
			ResultSet queueSet = stmt.executeQuery(checkQueueQuery);
			System.out.println(queueSet);
			if (queueSet.next()) {
				System.out.println("Course " + course
						+ "is full, you are put in the waiting list as number "
						+ queueSet.getInt("queueSpot") + ".");
			} else {
				System.out
						.println("You are now successfully registered to course "
								+ course + "!");
			}

		} catch (SQLException e) {
			int eCode = e.getErrorCode();
			if (eCode == 20001) {
				System.out
						.println("You can't register to a course you've already passed.");
			} else if (eCode == 20002) {
				System.out.println("You are already registered to " + course
						+ ".");
			} else if (eCode == 20003) {
				System.out
						.println("You are missing some prerequisites to read this course.");
			} else if (eCode == 20004) {
				System.out.println("You are already in the queue for " + course
						+ ".");
			} else {
				e.printStackTrace();
			}
		} 
	}

	static void unregisterStudent(Connection conn, String student, String course)
			throws SQLException {
		try {
			System.out.println("start");
			Statement stmt = conn.createStatement();
			System.out.println("stmt =" + stmt);
			String deleteQuery = "DELETE FROM Registrations "
					+ "WHERE student = '" + student + "' AND course = '"
					+ course + "'";
			System.out.println("deleteQuery =" + deleteQuery);
			int result = stmt.executeUpdate(deleteQuery);
			if(result != 0){
			System.out
					.println("You've succesfully been unregistered from the course: "
							+ course);

			} else {
				System.out.println("You are neither registered nor in the queue for "
							+ course
							+ " and is therefore already not enlisted on the course.");
			}
		} catch (SQLException e) {
				e.printStackTrace();
		}
	}
}