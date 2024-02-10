-- Creating Sequences
CREATE SEQUENCE  member_seq  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
CREATE SEQUENCE  staff_seq   MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
CREATE SEQUENCE  member_attendance_seq   MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
CREATE SEQUENCE  class_seq   MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
CREATE SEQUENCE  membership_type_seq   MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
CREATE SEQUENCE  membership_seq   MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
CREATE SEQUENCE  class_registration_seq   MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;
CREATE SEQUENCE  payment_seq   MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;

-- tables
CREATE TABLE member (
member_id INT DEFAULT member_seq.nextval PRIMARY KEY,
phone VARCHAR(20) UNIQUE  NOT NULL,
email VARCHAR(100) UNIQUE  NOT NULL,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50) NOT NULL,
address VARCHAR(200)
);

CREATE TABLE staff (
staff_id INT DEFAULT staff_seq.nextval PRIMARY KEY,
phone VARCHAR(20) UNIQUE NOT NULL,
email VARCHAR(100) UNIQUE NOT NULL,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50) NOT NULL,
password VARCHAR(100) NOT NULL,
username VARCHAR(50) UNIQUE NOT NULL,
role VARCHAR(20) NOT NULL
);


CREATE TABLE class (
class_id INT DEFAULT class_seq.nextval PRIMARY KEY,
class_name VARCHAR(50) NOT NULL,
maximum_capacity INT NOT NULL,
class_time DATE NOT NULL,
duration_minutes INT NOT NULL,
cost NUMBER NOT NULL,
instructor_id INT NOT NULL CONSTRAINT class_staff_id_fk REFERENCES staff(staff_id));


CREATE TABLE membership_type (
  membership_type_id INT DEFAULT membership_type_seq.nextval PRIMARY KEY,
  fees DECIMAL(8) NOT NULL,
  period VARCHAR(20) NOT NULL CHECK (period IN ('monthly', 'yearly')),
  type VARCHAR(255) NOT NULL CONSTRAINT chk_membership_type CHECK (type IN ('Gold', 'Silver', 'Bronze')),
  CONSTRAINT chk_fee CHECK (
    (type = 'Gold' AND period = 'monthly' AND fees = 40) OR
    (type = 'Gold' AND period = 'yearly' AND fees = 4000) OR
    (type = 'Silver' AND period = 'monthly' AND fees = 25) OR
    (type = 'Silver' AND period = 'yearly' AND fees = 3000) OR
    (type = 'Bronze' AND period = 'monthly' AND fees = 30) OR
    (type = 'Bronze' AND period = 'yearly' AND fees = 3500)
  )
);


CREATE TABLE membership (
membership_id INT DEFAULT membership_seq.nextval PRIMARY KEY,
member_id INT NOT NULL,
membership_type_id INT,
start_date DATE NOT NULL,
status VARCHAR(50) NOT NULL CONSTRAINT CHK_MEMBERSHIP_status CHECK (status IN (' Active', ' Expired', ' Suspended')),
payment_id INT NOT NULL CONSTRAINT payment_id_fk REFERENCES payment(payment_id),
FOREIGN KEY (member_id) REFERENCES member(member_id),
FOREIGN KEY (membership_type_id) REFERENCES membership_type(membership_type_id)
);

CREATE TABLE class_registration (
class_registration_id INT DEFAULT class_registration_seq.nextval PRIMARY KEY,
registration_date DATE NOT NULL,
member_id INT NOT NULL CONSTRAINT class_reg_memberid_fk REFERENCES member(member_id),
class_id INT NOT NULL CONSTRAINT classid_fk REFERENCES class(class_id),
payment_id INT NOT NULL CONSTRAINT paymentid_fk REFERENCES payment(payment_id)
);

CREATE TABLE attendance (
attendance_id INT DEFAULT member_attendance_seq.nextval PRIMARY KEY,
registration_date DATE NOT NULL,
member_id INT NOT NULL CONSTRAINT class_reg_member_id_fk REFERENCES member(member_id),
class_id INT NOT NULL CONSTRAINT class_id_fk REFERENCES class(class_id)
);

CREATE TABLE payment (
payment_id INT DEFAULT payment_seq.nextval PRIMARY KEY,
payment_type VARCHAR(50) NOT NULL,
payment_date DATE NOT NULL,
amount DECIMAL(8) NOT NULL,
member_id INT NOT NULL CONSTRAINT payment_member_id_fk REFERENCES member(member_id)
);


-- 1. Monthly Report

CREATE OR REPLACE PROCEDURE MonthlyReport (in_year NUMBER, in_month NUMBER) IS
BEGIN
  FOR instructor_info IN (
    SELECT s.staff_id, s.first_name, s.last_name, s.phone, s.email, s.role,
           COUNT(DISTINCT cr.member_id) AS num_members, SUM(c.cost) AS total_profits
    FROM class_registration cr
    JOIN class c ON cr.class_id = c.class_id
    JOIN staff s ON c.instructor_id = s.staff_id
    WHERE EXTRACT(YEAR FROM cr.registration_date) = in_year
      AND EXTRACT(MONTH FROM cr.registration_date) = in_month
    GROUP BY s.staff_id, s.first_name, s.last_name, s.phone, s.email, s.role
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Instructor ID: ' || instructor_info.staff_id);
    DBMS_OUTPUT.PUT_LINE('Name: ' || instructor_info.first_name || ' ' || instructor_info.last_name);
    DBMS_OUTPUT.PUT_LINE('Phone: ' || instructor_info.phone);
    DBMS_OUTPUT.PUT_LINE('Email: ' || instructor_info.email);
    DBMS_OUTPUT.PUT_LINE('Role: ' || instructor_info.role);
    DBMS_OUTPUT.PUT_LINE('Number of Members: ' || instructor_info.num_members);
    DBMS_OUTPUT.PUT_LINE('Total Profits: ' || instructor_info.total_profits);
    DBMS_OUTPUT.PUT_LINE('------------------------');
  END LOOP;
END MonthlyReport;




-- 2. Member Services
CREATE OR REPLACE PROCEDURE MemberServices (in_member_id INT) IS
BEGIN
  FOR member_info IN (
    SELECT m.*, cr.class_registration_id, cr.registration_date, c.class_name, c.class_time, c.duration_minutes, c.cost
    FROM member m
    JOIN class_registration cr ON m.member_id = cr.member_id
    JOIN class c ON cr.class_id = c.class_id
    WHERE m.member_id = in_member_id
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Member ID: ' || member_info.member_id);
    DBMS_OUTPUT.PUT_LINE('Phone: ' || member_info.phone);
    DBMS_OUTPUT.PUT_LINE('Email: ' || member_info.email);
    DBMS_OUTPUT.PUT_LINE('Address: ' || member_info.address);
    DBMS_OUTPUT.PUT_LINE('Class Registration ID: ' || member_info.class_registration_id);
    DBMS_OUTPUT.PUT_LINE('Registration Date: ' || TO_CHAR(member_info.registration_date, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('Class Name: ' || member_info.class_name);
    DBMS_OUTPUT.PUT_LINE('Class Time: ' || TO_CHAR(member_info.class_time, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Duration Minutes: ' || member_info.duration_minutes);
    DBMS_OUTPUT.PUT_LINE('Cost: ' || member_info.cost);
    DBMS_OUTPUT.PUT_LINE('------------------------');
  END LOOP;
END MemberServices;


-- 3.  Add Member
CREATE OR REPLACE PROCEDURE AddMember (
  p_phone VARCHAR2,
  p_email VARCHAR2,
  p_first_name VARCHAR2,
  p_last_name VARCHAR2,
  p_address VARCHAR2,
  p_membership_type VARCHAR2,
  p_membership_period VARCHAR2
) IS
  v_member_id INT;
  v_membership_type_id INT;
  v_payment_id_membership INT;
  v_payment_id_payment INT;
  v_membership_fee DECIMAL(8);
BEGIN
  -- Step 1: Insert into member table
  INSERT INTO member (member_id, phone, email, first_name, last_name, address)
  VALUES (member_seq.nextval, p_phone, p_email, p_first_name, p_last_name, p_address)
  RETURNING member_id INTO v_member_id;

  -- Step 2: Get membership type ID and fee
  SELECT membership_type_id, fees
  INTO v_membership_type_id, v_membership_fee
  FROM membership_type
  WHERE type = p_membership_type AND period = p_membership_period;

  -- Step 3: Insert into membership table without payment_id
  INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
  VALUES (membership_seq.nextval, v_member_id, v_membership_type_id, SYSDATE, ' Active', NULL)
  RETURNING payment_id INTO v_payment_id_membership;

  -- Step 4: Insert into payment table with payment_id
  INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
  VALUES (payment_seq.NEXTVAL, 'membership', SYSDATE, v_membership_fee, v_member_id)
  RETURNING payment_id INTO v_payment_id_payment;

  -- Step 5: Update payment_id in membership table
  UPDATE membership
  SET payment_id = v_payment_id_payment
  WHERE member_id = v_member_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Member added successfully!');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END AddMember;




-- 4. Class Status
CREATE OR REPLACE PROCEDURE ClassStatus (
    in_instructor_id INT
) IS
    v_total_members INT := 0;
    v_total_profits DECIMAL(8, 2) := 0;

BEGIN
    FOR class_info IN (
        SELECT c.class_id, c.class_name, c.maximum_capacity, c.class_time, c.duration_minutes, c.cost,
               COUNT(cr.member_id) AS enrolled_members,
               (COUNT(cr.member_id) * c.cost) AS total_profit
        FROM class c
        LEFT JOIN class_registration cr ON c.class_id = cr.class_id
        WHERE c.instructor_id = in_instructor_id
            AND c.class_time > SYSDATE
        GROUP BY c.class_id, c.class_name, c.maximum_capacity, c.class_time, c.duration_minutes, c.cost
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Class ID: ' || class_info.class_id);
        DBMS_OUTPUT.PUT_LINE('Class Name: ' || class_info.class_name);
        DBMS_OUTPUT.PUT_LINE('Maximum Capacity: ' || class_info.maximum_capacity);
        DBMS_OUTPUT.PUT_LINE('Class Time: ' || TO_CHAR(class_info.class_time, 'YYYY-MM-DD HH24:MI:SS'));
        DBMS_OUTPUT.PUT_LINE('Duration Minutes: ' || class_info.duration_minutes);
        DBMS_OUTPUT.PUT_LINE('Cost: ' || class_info.cost);
        DBMS_OUTPUT.PUT_LINE('Enrolled Members: ' || class_info.enrolled_members);
        DBMS_OUTPUT.PUT_LINE('Total Profit: ' || class_info.total_profit);
        DBMS_OUTPUT.PUT_LINE('------------------------');

        -- Update totals
        v_total_members := v_total_members + class_info.enrolled_members;
        v_total_profits := v_total_profits + class_info.total_profit;
    END LOOP;

    -- Display totals
    DBMS_OUTPUT.PUT_LINE('Total Enrolled Members: ' || v_total_members);
    DBMS_OUTPUT.PUT_LINE('Total Expected Profits: ' || v_total_profits);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Instructor not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLCODE || ' - ' || SQLERRM);
END ClassStatus;




-- 5. Class Registration
CREATE OR REPLACE PROCEDURE ClassRegistration(p_class_id INT, p_member_id INT) AS
    v_enrollment_count INT;
    v_max_capacity INT;
    v_payment_id INT;
    v_membership_start_date DATE;
    v_membership_end_date DATE;
    v_membership_type_period VARCHAR2(20);
    v_class_date DATE;
    v_class_cost NUMBER;
    v_existing_registration INT;
BEGIN
    -- Check if the provided member_id is valid
    IF NOT Check_member_id(p_member_id) THEN
        DBMS_OUTPUT.PUT_LINE('Invalid member ID. Registration failed.');
        RETURN;
    END IF;

    -- Check if the provided class_id is valid
    IF NOT Check_class_id(p_class_id) THEN
        DBMS_OUTPUT.PUT_LINE('Invalid class ID. Registration failed.');
        RETURN;
    END IF;

    -- Check if the member is already registered for the class
    SELECT COUNT(*) INTO v_existing_registration
    FROM class_registration
    WHERE class_id = p_class_id AND member_id = p_member_id;

    IF v_existing_registration > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Member is already registered for the class. Registration not allowed.');
        RETURN;
    END IF;

    BEGIN
        -- Retrieve the current enrollment count for the class
        SELECT COUNT(*) INTO v_enrollment_count FROM class_registration WHERE class_id = p_class_id;

        -- Retrieve the maximum capacity for the class
        SELECT maximum_capacity INTO v_max_capacity FROM class WHERE class_id = p_class_id;

        -- Retrieve the membership start date and type period for the member
        SELECT start_date, period INTO v_membership_start_date, v_membership_type_period
        FROM membership_type mt
        JOIN membership m ON mt.membership_type_id = m.membership_type_id
        WHERE m.member_id = p_member_id AND m.status = ' Active';

        -- Retrieve the class date and cost
        SELECT class_time, cost INTO v_class_date, v_class_cost FROM class WHERE class_id = p_class_id;

        -- Calculate the membership end date based on the type period
        IF v_membership_type_period = 'monthly' THEN
            v_membership_end_date := ADD_MONTHS(v_membership_start_date, 1);
        ELSIF v_membership_type_period = 'yearly' THEN
            v_membership_end_date := ADD_MONTHS(v_membership_start_date, 12);
        END IF;

        -- Check if there is still capacity for enrollment
        IF v_enrollment_count < v_max_capacity THEN
            -- Check if the class date is before the membership end date
            IF v_class_date < v_membership_end_date THEN
                -- Generate a new payment_id
                v_payment_id := PAYMENT_SEQ.NEXTVAL;

                -- Insert the new registration into the payment table
                INSERT INTO payment(payment_id, payment_type, payment_date, amount, member_id)
                VALUES (v_payment_id, 'class', SYSDATE, v_class_cost, p_member_id);

                -- Insert the new registration into the class_registration table
                INSERT INTO class_registration(class_registration_id, member_id, class_id, registration_date, payment_id)
                VALUES (class_registration_seq.NEXTVAL, p_member_id, p_class_id, SYSDATE, v_payment_id);

                -- Display success message
                DBMS_OUTPUT.PUT_LINE('Member successfully registered for the class.');
            ELSE
                -- Display error message if the class date is after the membership end date
                DBMS_OUTPUT.PUT_LINE('Class date is after the member''s membership end date. Registration not allowed.');
            END IF;
        ELSE
            -- Display error message if the class is already at full capacity
            DBMS_OUTPUT.PUT_LINE('Class is already at full capacity. Registration not allowed.');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: No data found during registration.');
        WHEN OTHERS THEN
            -- Display detailed error message if any error occurs during the registration process
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLCODE || ' - ' || SQLERRM);
    END;
END;





-- Update monthly memberships

CREATE OR REPLACE PROCEDURE UpdateMembershipStatus AS
BEGIN
  -- Update monthly memberships
  UPDATE membership
  SET status = ' Expired'
  WHERE status = ' Active' AND membership_type_id IN (
    SELECT membership_type_id
    FROM membership_type
    WHERE period = 'monthly'
  ) AND SYSDATE > ADD_MONTHS(start_date, 1);

  -- Update yearly memberships
  UPDATE membership
  SET status = ' Expired'
  WHERE status = ' Active' AND membership_type_id IN (
    SELECT membership_type_id
    FROM membership_type
    WHERE period = 'yearly'
  ) AND SYSDATE > ADD_MONTHS(start_date, 12);

  COMMIT;
END UpdateMembershipStatus;

-- Create a job to run the UpdateMembershipStatus procedure every day at a specific time
BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'UPDATE_MEMBERSHIP_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN UpdateMembershipStatus; END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=0; BYMINUTE=0; BYSECOND=0',
    enabled         => TRUE
  );
END;
/




--functions

--1. Check_member_id

CREATE OR REPLACE FUNCTION Check_member_id(p_member_id INT) RETURN
BOOLEAN IS
v_member_count INT;
BEGIN
SELECT COUNT(*) INTO v_member_count FROM member WHERE member_id =
p_member_id;
RETURN v_member_count > 0;
END;


--1. Check_class_id
-- Helper function to check if the class_id is valid
CREATE OR REPLACE FUNCTION Check_class_id (
    in_class_id INT
) RETURN BOOLEAN IS
    v_class_count INT;
BEGIN
    SELECT COUNT(*) INTO v_class_count
    FROM class
    WHERE class_id = in_class_id;

    RETURN v_class_count > 0;
END Check_class_id;





--data---
-- Inserting row 1
INSERT INTO member (member_id, phone, email, first_name, last_name, address)
VALUES (member_seq.nextval, '123456789', 'john@example.com', 'John', 'Doe', '123 Main Street');

-- Inserting row 2
INSERT INTO member (member_id, phone, email, first_name, last_name, address)
VALUES (member_seq.nextval, '987654321', 'jane@example.com', 'Jane', 'Smith', '456 Oak Avenue');

-- Inserting row 3
INSERT INTO member (member_id, phone, email, first_name, last_name, address)
VALUES (member_seq.nextval, '555666777', 'bob@example.com', 'Bob', 'Johnson', '789 Elm Street');

-- Inserting row 4
INSERT INTO member (member_id, phone, email, first_name, last_name, address)
VALUES (member_seq.nextval, '111222333', 'alice@example.com', 'Alice', 'Williams', '321 Pine Avenue');

-- Inserting row 5
INSERT INTO member (member_id, phone, email, first_name, last_name, address)
VALUES (member_seq.nextval, '444555666', 'sam@example.com', 'Sam', 'Davis', '654 Cedar Street');

-- Inserting row 6
INSERT INTO member (member_id, phone, email, first_name, last_name, address)
VALUES (member_seq.nextval, '888999000', 'emily@example.com', 'Emily', 'Brown', '987 Maple Avenue');

-- Inserting row 7
INSERT INTO member (member_id, phone, email, first_name, last_name, address)
VALUES (member_seq.nextval, '777888999', 'chris@example.com', 'Chris', 'Miller', '654 Birch Street');

-- Inserting row 8
INSERT INTO member (member_id, phone, email, first_name, last_name, address)
VALUES (member_seq.nextval, '666777888', 'sara@example.com', 'Sara', 'Martin', '123 Walnut Avenue');

-- Inserting row 9
INSERT INTO member (member_id, phone, email, first_name, last_name, address)
VALUES (member_seq.nextval, '333444555', 'david@example.com', 'David', 'Anderson', '456 Spruce Street');

-- Inserting row 10
INSERT INTO member (member_id, phone, email, first_name, last_name, address)
VALUES (member_seq.nextval, '999000111', 'amy@example.com', 'Amy', 'Jones', '789 Fir Avenue');




-- Insert into staff table (10 rows)
INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '111222333', 'trainer1@example.com', 'Michael', 'Johnson', 'password123', 'trainer1', 'Trainer');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '222333444', 'trainer2@example.com', 'Sophia', 'Smith', 'password123', 'trainer2', 'Trainer');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '333444555', 'trainer3@example.com', 'Daniel', 'Williams', 'password123', 'trainer3', 'Trainer');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '444555666', 'frontdesk1@example.com', 'Emma', 'Davis', 'password123', 'frontdesk1', 'Front Desk');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '555666777', 'frontdesk2@example.com', 'Oliver', 'Martin', 'password123', 'frontdesk2', 'Front Desk');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '666777888', 'manager1@example.com', 'Manager', 'One', 'password123', 'manager1', 'Manager');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '777888999', 'staff1@example.com', 'Ava', 'Miller', 'password123', 'staff1', 'Staff');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '888999000', 'staff2@example.com', 'Ethan', 'Brown', 'password123', 'staff2', 'Staff');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '999000111', 'staff3@example.com', 'Isabella', 'Anderson', 'password123', 'staff3', 'Staff');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '000111222', 'receptionist1@example.com', 'Mia', 'Johnson', 'password123', 'receptionist1', 'Receptionist');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '666777888', 'manager1@example.com', 'Manager', 'One', 'password123', 'manager1', 'Manager');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '777888999', 'manager2@example.com', 'Manager', 'Two', 'password123', 'manager2', 'Manager');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '888999000', 'admin1@example.com', 'Admin', 'One', 'password123', 'admin1', 'Admin');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '999000111', 'admin2@example.com', 'Admin', 'Two', 'password123', 'admin2', 'Admin');

INSERT INTO staff (staff_id, phone, email, first_name, last_name, password, username, role)
VALUES (staff_seq.nextval, '000111222', 'receptionist@example.com', 'Receptionist', 'One', 'password123', 'receptionist1', 'Receptionist');



-- Insert into class table (10 rows)
INSERT INTO class (class_id, class_name, maximum_capacity, class_time, duration_minutes, cost, instructor_id)
VALUES (class_seq.nextval, 'Yoga Class', 20, TO_DATE('2024-01-01 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), 60, 50.00, 1);

INSERT INTO class (class_id, class_name, maximum_capacity, class_time, duration_minutes, cost, instructor_id)
VALUES (class_seq.nextval, 'Cardio Class', 15, TO_DATE('2024-01-02 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 45, 40.00, 2);

INSERT INTO class (class_id, class_name, maximum_capacity, class_time, duration_minutes, cost, instructor_id)
VALUES (class_seq.nextval, 'Pilates Class', 18, TO_DATE('2024-01-03 16:30:00', 'YYYY-MM-DD HH24:MI:SS'), 50, 45.00, 3);

INSERT INTO class (class_id, class_name, maximum_capacity, class_time, duration_minutes, cost, instructor_id)
VALUES (class_seq.nextval, 'Zumba Class', 25, TO_DATE('2024-01-04 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 60, 55.00, 3);

INSERT INTO class (class_id, class_name, maximum_capacity, class_time, duration_minutes, cost, instructor_id)
VALUES (class_seq.nextval, 'Spinning Class', 20, TO_DATE('2024-01-05 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 55, 50.00, 6);

INSERT INTO class (class_id, class_name, maximum_capacity, class_time, duration_minutes, cost, instructor_id)
VALUES (class_seq.nextval, 'Kickboxing Class', 15, TO_DATE('2024-01-06 17:30:00', 'YYYY-MM-DD HH24:MI:SS'), 50, 60.00, 4);

INSERT INTO class (class_id, class_name, maximum_capacity, class_time, duration_minutes, cost, instructor_id)
VALUES (class_seq.nextval, 'HIIT Class', 22, TO_DATE('2024-01-07 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), 45, 45.00, 5);

INSERT INTO class (class_id, class_name, maximum_capacity, class_time, duration_minutes, cost, instructor_id)
VALUES (class_seq.nextval, 'Strength Training Class', 18, TO_DATE('2024-01-08 15:00:00', 'YYYY-MM-DD HH24:MI:SS'), 60, 50.00, 9);

INSERT INTO class (class_id, class_name, maximum_capacity, class_time, duration_minutes, cost, instructor_id)
VALUES(class_seq.nextval, 'Piloxing Class', 20, TO_DATE('2024-01-09 11:30:00', 'YYYY-MM-DD HH24:MI:SS'), 55, 55.00, 8);

INSERT INTO class (class_id, class_name, maximum_capacity, class_time, duration_minutes, cost, instructor_id)
VALUES (class_seq.nextval, 'Aerobics Class', 25, TO_DATE('2024-01-10 19:00:00', 'YYYY-MM-DD HH24:MI:SS'), 50, 40.00, 10);


  -- Insert into membership_type table (6 rows)
  INSERT INTO membership_type (membership_type_id, fees, period, type)
  VALUES (membership_type_seq.nextval, 40.00, 'monthly', 'Gold');

  INSERT INTO membership_type (membership_type_id, fees, period, type)
  VALUES (membership_type_seq.nextval, 4000.00, 'yearly', 'Gold');

  INSERT INTO membership_type (membership_type_id, fees, period, type)
  VALUES (membership_type_seq.nextval, 25.00, 'monthly', 'Silver');

  INSERT INTO membership_type (membership_type_id, fees, period, type)
  VALUES (membership_type_seq.nextval, 3000.00, 'yearly', 'Silver');

  INSERT INTO membership_type (membership_type_id, fees, period, type)
  VALUES(membership_type_seq.nextval, 30.00, 'monthly', 'Bronze');

  INSERT INTO membership_type (membership_type_id, fees, period, type)
  VALUES(membership_type_seq.nextval, 3500.00, 'yearly', 'Bronze');



    -- Insert into payment table
    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'membership', TO_DATE('2024-01-01', 'YYYY-MM-DD'), 40.00, 1);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'membership', TO_DATE('2023-02-01', 'YYYY-MM-DD'), 4000.00, 2);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'membership', TO_DATE('2024-01-01', 'YYYY-MM-DD'), 25.00, 3);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'membership', TO_DATE('2023-03-01', 'YYYY-MM-DD'), 3000.00, 4);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'membership', TO_DATE('2023-12-31', 'YYYY-MM-DD'), 40.00, 5);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'membership', TO_DATE('2023-12-22', 'YYYY-MM-DD'), 30.00, 6);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'membership', TO_DATE('2023-10-22', 'YYYY-MM-DD'), 3500.00, 7);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'membership', TO_DATE('2023-8-01', 'YYYY-MM-DD'), 4000.00, 8);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'membership', TO_DATE('2024-01-01', 'YYYY-MM-DD'), 25.00, 9);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'membership', TO_DATE('2023-05-01', 'YYYY-MM-DD'), 3000.00, 10);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'membership', TO_DATE('2023-12-05', 'YYYY-MM-DD'), 30.00, 21);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-02', 'YYYY-MM-DD'), 40.00, 1);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-06', 'YYYY-MM-DD'), 60.00, 2);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-02', 'YYYY-MM-DD'), 40.00, 3);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-02', 'YYYY-MM-DD'), 40.00, 6);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-06', 'YYYY-MM-DD'), 60.00, 8);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-08', 'YYYY-MM-DD'), 50.00, 9);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-08', 'YYYY-MM-DD'), 50.00, 10);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-03', 'YYYY-MM-DD'), 45.00, 21);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-03', 'YYYY-MM-DD'), 45.00, 5 );

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-03', 'YYYY-MM-DD'), 45.00, 9);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-05', 'YYYY-MM-DD'), 50.00, 21);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-05', 'YYYY-MM-DD'), 50.00, 5);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-05', 'YYYY-MM-DD'), 50.00, 9);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-01', 'YYYY-MM-DD'), 50.00, 6);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-01', 'YYYY-MM-DD'), 50.00, 4);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-04', 'YYYY-MM-DD'), 55.00, 4);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-07', 'YYYY-MM-DD'), 45.00, 5);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-10', 'YYYY-MM-DD'), 40.00, 7);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-10', 'YYYY-MM-DD'), 40.00, 8);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-09', 'YYYY-MM-DD'), 55.00, 4);

    INSERT INTO payment (payment_id, payment_type, payment_date, amount, member_id)
    VALUES (payment_seq.nextval, 'class', TO_DATE('2024-01-09', 'YYYY-MM-DD'), 55.00, 2);



    -- Insert into class_registration table (example data)
    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-02', 'YYYY-MM-DD'), 1, 61, 109);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-06', 'YYYY-MM-DD'), 2, 64, 111);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-02', 'YYYY-MM-DD'), 3, 61, 108);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-02', 'YYYY-MM-DD'), 6, 61, 110);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-06', 'YYYY-MM-DD'), 8, 64, 87);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-08', 'YYYY-MM-DD'), 9, 65, 88);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-08', 'YYYY-MM-DD'), 10, 65, 89);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-03', 'YYYY-MM-DD'), 21, 42, 112);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-03', 'YYYY-MM-DD'), 5, 42, 90);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-03', 'YYYY-MM-DD'), 9, 42, 113);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-05', 'YYYY-MM-DD'), 21, 63, 91);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-05', 'YYYY-MM-DD'), 5, 63, 114);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-05', 'YYYY-MM-DD'), 9, 63, 92);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-01', 'YYYY-MM-DD'), 6, 41, 115);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-01', 'YYYY-MM-DD'), 4, 41, 93);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-04', 'YYYY-MM-DD'), 4, 62, 94);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-07', 'YYYY-MM-DD'), 5, 43, 95);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-10', 'YYYY-MM-DD'), 7, 66, 116);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-10', 'YYYY-MM-DD'), 8, 66, 96);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-09', 'YYYY-MM-DD'), 4, 44, 117);

    INSERT INTO class_registration (class_registration_id, registration_date, member_id, class_id, payment_id)
    VALUES (class_registration_seq.nextval, TO_DATE('2024-01-09', 'YYYY-MM-DD'), 2, 44, 97);



    -- Insert into attendance table
    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-03', 'YYYY-MM-DD'), 9, 42);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-04', 'YYYY-MM-DD'), 4, 62);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-07', 'YYYY-MM-DD'), 5, 43);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-10', 'YYYY-MM-DD'), 7, 66);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-10', 'YYYY-MM-DD'), 8, 66);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-09', 'YYYY-MM-DD'), 4, 44);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-05', 'YYYY-MM-DD'), 21, 63);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-06', 'YYYY-MM-DD'), 2, 64);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-09', 'YYYY-MM-DD'), 2, 44);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-03', 'YYYY-MM-DD'), 21, 42);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-03', 'YYYY-MM-DD'), 5, 42);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-05', 'YYYY-MM-DD'), 9, 63);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-08', 'YYYY-MM-DD'), 9, 65);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-02', 'YYYY-MM-DD'), 6, 61);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-06', 'YYYY-MM-DD'), 8, 64);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-08', 'YYYY-MM-DD'), 10, 65);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-01', 'YYYY-MM-DD'), 4, 41);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-05', 'YYYY-MM-DD'), 5, 63);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-02', 'YYYY-MM-DD'), 3, 61);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-02', 'YYYY-MM-DD'), 1, 61);

    INSERT INTO attendance (attendance_id, registration_date, member_id, class_id)
    VALUES (member_attendance_seq.nextval, TO_DATE('2024-01-01', 'YYYY-MM-DD'), 6, 41);



  -- Insert into membership table (example data)
    INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
    VALUES (membership_seq.nextval, 1, 1, TO_DATE('2024-01-01', 'YYYY-MM-DD'), ' Active', 81);

    INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
    VALUES (membership_seq.nextval, 2, 2, TO_DATE('2023-02-01', 'YYYY-MM-DD'), ' Active', 101);

    INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
    VALUES (membership_seq.nextval, 3, 3, TO_DATE('2024-01-01', 'YYYY-MM-DD'), ' Active', 102);

    INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
    VALUES (membership_seq.nextval, 4, 4, TO_DATE('2023-03-01', 'YYYY-MM-DD'), ' Active', 103);

    INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
    VALUES (membership_seq.nextval, 5, 1, TO_DATE('2023-12-31', 'YYYY-MM-DD'), ' Active', 82);

    INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
    VALUES (membership_seq.nextval, 6, 5, TO_DATE('2023-12-22', 'YYYY-MM-DD'), ' Active', 83);

    INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
    VALUES (membership_seq.nextval, 7, 6, TO_DATE('2023-10-22', 'YYYY-MM-DD'), ' Active', 84);

    INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
    VALUES (membership_seq.nextval, 8, 2, TO_DATE('2023-08-01', 'YYYY-MM-DD'), ' Active', 104);

    INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
    VALUES (membership_seq.nextval, 9, 3, TO_DATE('2024-01-01', 'YYYY-MM-DD'), ' Active', 105);

    INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
    VALUES (membership_seq.nextval, 10, 5, TO_DATE('2023-05-01', 'YYYY-MM-DD'), ' Active', 106);

    INSERT INTO membership (membership_id, member_id, membership_type_id, start_date, status, payment_id)
    VALUES (membership_seq.nextval, 21, 5, TO_DATE('2023-12-05', 'YYYY-MM-DD'), ' Active', 107);
