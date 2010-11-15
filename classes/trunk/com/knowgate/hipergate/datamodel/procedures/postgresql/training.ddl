CREATE FUNCTION k_sp_del_subject (CHAR) RETURNS INTEGER AS '
BEGIN
  DELETE FROM k_absentisms WHERE gu_subject=$1;
  DELETE FROM k_evaluations WHERE gu_subject=$1;
  DELETE FROM k_x_course_subject WHERE gu_subject=$1;
  DELETE FROM k_absentisms WHERE gu_subject=$1;
  DELETE FROM k_subjects WHERE gu_subject=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_acourse (CHAR) RETURNS INTEGER AS '
DECLARE
  GuAddress CHAR(32);
BEGIN
  SELECT gu_address INTO GuAddress FROM k_academic_courses WHERE gu_acourse=$1;
  DELETE FROM k_x_user_acourse WHERE gu_acourse=$1;
  DELETE FROM k_x_course_alumni WHERE gu_acourse=$1;
  DELETE FROM k_x_course_bookings WHERE gu_acourse=$1;
  DELETE FROM k_evaluations WHERE gu_acourse=$1;
  DELETE FROM k_absentisms WHERE gu_acourse=$1;
  DELETE FROM k_academic_courses WHERE gu_acourse=$1;
  IF GuAddress IS NOT NULL THEN
    DELETE FROM k_addresses WHERE gu_address=GuAddress;
  END IF;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_sp_del_course (CHAR) RETURNS INTEGER AS '
DECLARE
  asubs k_x_course_subject%ROWTYPE;
  acurs k_academic_courses%ROWTYPE;
BEGIN
  FOR asubs IN SELECT * FROM k_x_course_subject WHERE gu_course=$1 LOOP
    PERFORM k_sp_del_subject (asubs.gu_subject);
  END LOOP;
  FOR acurs IN SELECT * FROM k_academic_courses WHERE gu_course=$1 LOOP
    PERFORM k_sp_del_acourse (acurs.gu_acourse);
  END LOOP;

  DELETE FROM k_courses WHERE gu_course=$1;
  RETURN 0;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_fn_upd_course_booking () RETURNS OPAQUE AS '
BEGIN
  IF NEW.bo_confirmed=1 AND OLD.bo_confirmed=0 THEN
    NEW.dt_confirmed:=CURRENT_TIMESTAMP;
  END IF;
  IF NEW.bo_confirmed=0 AND OLD.bo_confirmed=1 THEN
    NEW.dt_confirmed:=NULL;
  END IF;
  IF NEW.bo_paid=1 AND OLD.bo_paid=0 THEN
    NEW.dt_paid:=CURRENT_TIMESTAMP;
  END IF;
  IF NEW.bo_paid=0 AND OLD.bo_paid=1 THEN
    NEW.dt_paid:=NULL;
  END IF;
  IF NEW.bo_canceled=1 AND OLD.bo_canceled=0 THEN
    NEW.dt_cancel:=CURRENT_TIMESTAMP;
  END IF;
  IF NEW.bo_canceled=0 AND OLD.bo_canceled=1 THEN
    NEW.dt_cancel:=NULL;
  END IF;
  IF NEW.bo_waiting=1 AND OLD.bo_waiting=0 THEN
    NEW.dt_waiting:=CURRENT_TIMESTAMP;
  END IF;
  RETURN NEW;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE FUNCTION k_fn_ins_course_booking () RETURNS OPAQUE AS '
BEGIN
  IF NEW.bo_confirmed=1 THEN
    NEW.dt_confirmed:=CURRENT_TIMESTAMP;
  END IF;
  IF NEW.bo_paid=1 THEN
    NEW.dt_paid:=CURRENT_TIMESTAMP;
  END IF;
  IF NEW.bo_canceled=1 THEN
    NEW.dt_cancel:=CURRENT_TIMESTAMP;
  END IF;
  IF NEW.bo_waiting=1 THEN
    NEW.dt_waiting:=CURRENT_TIMESTAMP;
  END IF;    
  RETURN NEW;
END;
' LANGUAGE 'plpgsql';
GO;

CREATE TRIGGER k_tr_ins_course_booking BEFORE INSERT ON k_x_course_bookings FOR EACH ROW EXECUTE PROCEDURE k_fn_ins_course_booking();
GO;

CREATE TRIGGER k_tr_upd_course_booking BEFORE UPDATE ON k_x_course_bookings FOR EACH ROW EXECUTE PROCEDURE k_fn_upd_course_booking();
GO;
