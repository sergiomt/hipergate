CREATE PROCEDURE k_sp_del_subject (SubjectId CHAR(32))
BEGIN
  DELETE FROM k_absentisms WHERE gu_subject=SubjectId;
  DELETE FROM k_evaluations WHERE gu_subject=SubjectId;
  DELETE FROM k_x_course_subject WHERE gu_subject=SubjectId;
  DELETE FROM k_absentisms WHERE gu_subject=SubjectId;
  DELETE FROM k_subjects WHERE gu_subject=SubjectId;
END
GO;

CREATE PROCEDURE k_sp_del_acourse (CourseId CHAR(32))
BEGIN
  DECLARE GuAddress CHAR(32);
  SELECT gu_address INTO GuAddress FROM k_academic_courses WHERE gu_acourse=CourseId;
  DELETE FROM k_x_user_acourse WHERE gu_acourse=CourseId;
  DELETE FROM k_x_course_alumni WHERE gu_acourse=CourseId;
  DELETE FROM k_x_course_bookings WHERE gu_acourse=CourseId;
  DELETE FROM k_evaluations WHERE gu_acourse=CourseId;
  DELETE FROM k_absentisms WHERE gu_acourse=CourseId;
  DELETE FROM k_academic_courses WHERE gu_acourse=CourseId;
  IF GuAddress IS NOT NULL THEN
    DELETE FROM k_addresses WHERE gu_address=GuAddress;
  END IF;  
END
GO;

CREATE PROCEDURE k_sp_del_course (CourseId CHAR(32))
BEGIN
  DECLARE SubjectId CHAR(32);
  DECLARE AcourseId CHAR(32);
  DECLARE Done INT DEFAULT 0;
  DECLARE subjects CURSOR FOR SELECT gu_subject FROM k_x_course_subject WHERE gu_course=CourseId;
  DECLARE acourses CURSOR FOR SELECT gu_acourse FROM k_academic_courses WHERE gu_course=CourseId;
  DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET Done=1;

  OPEN subjects;
    REPEAT
      FETCH subjects INTO SubjectId;
      IF Done=0 THEN
        CALL k_sp_del_subject (SubjectId);
      END IF;
    UNTIL Done=1 END REPEAT;
  CLOSE subjects;
  SET Done=0;
  OPEN acourses;
    REPEAT
      FETCH acourses INTO AcourseId;
      IF Done=0 THEN
        CALL k_sp_del_acourse (AcourseId);
      END IF;
    UNTIL Done=1 END REPEAT;
  CLOSE acourses;
  DELETE FROM k_courses WHERE gu_course=CourseId;
END
GO;

CREATE TRIGGER k_tr_upd_course_booking BEFORE UPDATE ON k_x_course_bookings FOR EACH ROW
BEGIN
  IF NEW.bo_confirmed=1 AND OLD.bo_confirmed=0 THEN
    SET NEW.dt_confirmed=NOW();
  END IF;
  IF NEW.bo_confirmed=0 AND OLD.bo_confirmed=1 THEN
    SET NEW.dt_confirmed=NULL;
  END IF;
  IF NEW.bo_paid=1 AND OLD.bo_paid=0 THEN
    SET NEW.dt_paid=NOW();
  END IF;
  IF NEW.bo_paid=0 AND OLD.bo_paid=1 THEN
    SET NEW.dt_paid=NULL;
  END IF;
  IF NEW.bo_canceled=1 AND OLD.bo_canceled=0 THEN
    SET NEW.dt_cancel=NOW();
  END IF;
  IF NEW.bo_canceled=0 AND OLD.bo_canceled=1 THEN
    SET NEW.dt_cancel=NULL;
  END IF;
  IF NEW.bo_waiting=1 AND OLD.bo_waiting=0 THEN
    SET NEW.dt_waiting=NOW();
  END IF;
END
GO;

CREATE TRIGGER k_tr_ins_course_booking BEFORE INSERT ON k_x_course_bookings FOR EACH ROW
BEGIN
  IF NEW.bo_confirmed=1 THEN
    SET NEW.dt_confirmed=NOW();
  END IF;
  IF NEW.bo_paid=1 THEN
    SET NEW.dt_paid=NOW();
  END IF;
  IF NEW.bo_waiting=1 THEN
    SET NEW.dt_waiting=NOW();
  END IF;
END
GO;
