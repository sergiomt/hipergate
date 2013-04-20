CREATE PROCEDURE k_sp_del_subject @SubjectId CHAR(32) AS
  DELETE k_absentisms WHERE gu_subject=@SubjectId
  DELETE k_evaluations WHERE gu_subject=SubjectId
  DELETE k_x_course_subject WHERE gu_subject=@SubjectId
  DELETE k_absentisms WHERE gu_subject=@SubjectId
  DELETE k_subjects WHERE gu_subject=@SubjectId
GO;

CREATE PROCEDURE k_sp_del_acourse @CourseId CHAR(32) AS
  DECLARE @GuAddress CHAR(32)
  SELECT @GuAddress=gu_address FROM k_academic_courses WHERE gu_acourse=@CourseId
  DELETE k_x_user_acourse WHERE gu_acourse=@CourseId
  DELETE k_x_course_alumni WHERE gu_acourse=@CourseId
  DELETE k_x_course_bookings WHERE gu_acourse=@CourseId
  DELETE k_evaluations WHERE gu_acourse=@CourseId
  DELETE k_absentisms WHERE gu_acourse=@CourseId
  DELETE k_academic_courses WHERE gu_acourse=@CourseId
  IF @GuAddress IS NOT NULL
    DELETE FROM k_addresses WHERE gu_address=@GuAddress
GO;

CREATE PROCEDURE k_sp_del_course @CourseId CHAR(32) AS
  DECLARE @SubjectId CHAR(32)
  DECLARE @AcourseId CHAR(32)
  DECLARE subjects CURSOR LOCAL STATIC FOR SELECT gu_subject FROM k_x_course_subject WITH (NOLOCK) WHERE gu_course=@CourseId
  DECLARE acourses CURSOR LOCAL STATIC FOR SELECT gu_acourse FROM k_academic_courses WITH (NOLOCK) WHERE gu_course=@CourseId

  OPEN subjects
    FETCH NEXT FROM subjects INTO @SubjectId
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_del_subject @SubjectId
        FETCH NEXT FROM subjects INTO @SubjectId
      END
  CLOSE subjects

  OPEN acourses
    FETCH NEXT FROM acourses INTO @AcourseId
    WHILE @@FETCH_STATUS = 0
      BEGIN
        EXECUTE k_sp_del_acourse @AcourseId
        FETCH NEXT FROM acourses INTO @AcourseId
      END
  CLOSE acourses

  DELETE k_courses WHERE gu_course=@CourseId
GO;

CREATE TRIGGER k_tr_upd_course_booking ON k_x_course_bookings FOR UPDATE AS
  DECLARE @BoConfirmed SMALLINT
  DECLARE @BoCanceled SMALLINT
  DECLARE @BoPaid SMALLINT
  DECLARE @BoWait SMALLINT

  SELECT @BoConfirmed=bo_confirmed,@BoCanceled=bo_canceled,@BoPaid=bo_paid,@BoWait=bo_waiting FROM inserted

  IF UPDATE(bo_confirmed) AND @BoConfirmed=1
    UPDATE b SET b.dt_confirmed=GETDATE() FROM k_x_course_bookings b JOIN inserted i ON b.gu_acourse=i.gu_acourse
  IF UPDATE(bo_confirmed) AND @BoConfirmed=0
    UPDATE b SET b.dt_confirmed=NULL FROM k_x_course_bookings b JOIN inserted i ON b.gu_acourse=i.gu_acourse
  IF UPDATE(bo_canceled) AND @BoCanceled=1
    UPDATE b SET b.dt_cancel=GETDATE() FROM k_x_course_bookings b JOIN inserted i ON b.gu_acourse=i.gu_acourse
  IF UPDATE(bo_canceled) AND @BoCanceled=0
    UPDATE b SET b.dt_cancel=NULL FROM k_x_course_bookings b JOIN inserted i ON b.gu_acourse=i.gu_acourse
  IF UPDATE(bo_paid) AND @BoPaid=1
    UPDATE b SET b.dt_paid=GETDATE() FROM k_x_course_bookings b JOIN inserted i ON b.gu_acourse=i.gu_acourse
  IF UPDATE(bo_paid) AND @BoPaid=0
    UPDATE b SET b.dt_paid=NULL FROM k_x_course_bookings b JOIN inserted i ON b.gu_acourse=i.gu_acourse
  IF UPDATE(bo_waiting) AND @BoWait=1
    UPDATE b SET b.dt_waiting=GETDATE() FROM k_x_course_bookings b JOIN inserted i ON b.gu_acourse=i.gu_acourse
GO;

CREATE TRIGGER k_tr_upd_course_booking ON k_x_course_bookings FOR INSERT AS
  DECLARE @BoConfirmed SMALLINT
  DECLARE @BoCanceled SMALLINT
  DECLARE @BoPaid SMALLINT
  DECLARE @BoWait SMALLINT

  SELECT @BoConfirmed=bo_confirmed,@BoCanceled=bo_canceled,@BoPaid=bo_paid,@BoWait=bo_waiting FROM inserted

  IF @BoConfirmed=1
    UPDATE b SET b.dt_confirmed=GETDATE() FROM k_x_course_bookings b JOIN inserted i ON b.gu_acourse=i.gu_acourse
  IF @BoCanceled=1
    UPDATE b SET b.dt_confirmed=GETDATE() FROM k_x_course_bookings b JOIN inserted i ON b.gu_acourse=i.gu_acourse
  IF @BoPaid=1
    UPDATE b SET b.dt_paid=GETDATE() FROM k_x_course_bookings b JOIN inserted i ON b.gu_acourse=i.gu_acourse
  IF @BoWait=1
    UPDATE b SET b.dt_waiting=GETDATE() FROM k_x_course_bookings b JOIN inserted i ON b.gu_acourse=i.gu_acourse
GO;

