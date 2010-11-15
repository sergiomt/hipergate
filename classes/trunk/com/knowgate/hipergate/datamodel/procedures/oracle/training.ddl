CREATE OR REPLACE PROCEDURE k_sp_del_subject (SubjectId CHAR) IS
BEGIN
  DELETE FROM k_absentisms WHERE gu_subject=SubjectId;
  DELETE FROM k_evaluations WHERE gu_subject=SubjectId;
  DELETE FROM k_x_course_subject WHERE gu_subject=SubjectId;
  DELETE FROM k_absentisms WHERE gu_subject=SubjectId;
  DELETE FROM k_subjects WHERE gu_subject=SubjectId;
END k_sp_del_subject;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_acourse (CourseId CHAR) IS
  GuAddress CHAR(32);
BEGIN
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
  DELETE FROM k_academic_courses WHERE gu_acourse=CourseId;
END k_sp_del_acourse;
GO;

CREATE OR REPLACE PROCEDURE k_sp_del_course (CourseId CHAR) IS
  SubjectId CHAR(32);
  AcourseId CHAR(32);
  CURSOR subjects(id CHAR) IS SELECT gu_subject FROM k_x_course_subject WHERE gu_course=id;
  CURSOR acourses(id CHAR) IS SELECT gu_acourse FROM k_academic_courses WHERE gu_course=id;
BEGIN
  OPEN subjects(CourseId);
    LOOP
      FETCH subjects INTO SubjectId;
      EXIT WHEN subjects%NOTFOUND;
      k_sp_del_subject (SubjectId);
    END LOOP;
  CLOSE subjects;
  OPEN acourses(CourseId);
    LOOP
      FETCH acourses INTO AcourseId;
      EXIT WHEN acourses%NOTFOUND;
      k_sp_del_acourse (AcourseId);
    END LOOP;
  CLOSE acourses;
  DELETE FROM k_courses WHERE gu_course=CourseId;
END k_sp_del_course;
GO;

CREATE OR REPLACE TRIGGER k_tr_upd_course_booking BEFORE UPDATE ON k_x_course_bookings FOR EACH ROW
BEGIN
  IF :new.bo_confirmed=1 AND :old.bo_confirmed=0 THEN
    :new.dt_confirmed:=SYSDATE;
  END IF;
  IF :new.bo_confirmed=0 AND :old.bo_confirmed=1 THEN
    :new.dt_confirmed:=NULL;
  END IF;
  IF :new.bo_paid=1 AND :old.bo_paid=0 THEN
    :new.dt_paid:=SYSDATE;
  END IF;
  IF :new.bo_paid=0 AND :old.bo_paid=1 THEN
    :new.dt_paid:=NULL;
  END IF;
  IF :new.bo_canceled=1 AND :old.bo_canceled=0 THEN
    :new.dt_cancel:=SYSDATE;
  END IF;
  IF :new.bo_canceled=0 AND :old.bo_canceled=1 THEN
    :new.dt_cancel:=NULL;
  END IF;
  IF :new.bo_waiting=1 AND :old.bo_waiting=0 THEN
    :new.dt_waiting:=SYSDATE;
  END IF;
END k_tr_upd_course_booking;
GO;

CREATE OR REPLACE TRIGGER k_tr_ins_course_booking BEFORE INSERT ON k_x_course_bookings FOR EACH ROW
BEGIN
  IF :new.bo_confirmed=1 THEN
    :new.dt_confirmed:=SYSDATE;
  END IF;
  IF :new.bo_paid=1 THEN
    :new.dt_paid:=SYSDATE;
  END IF;
  IF :new.bo_canceled=1 THEN
    :new.dt_cancel:=SYSDATE;
  END IF;
  IF :new.bo_waiting=1 THEN
    :new.dt_waiting:=SYSDATE;
  END IF;
END k_tr_ins_course_booking;
GO;

