DROP PACKAGE BODY TDCUSTOM.ENG_HL7;

CREATE OR REPLACE PACKAGE BODY TDCUSTOM.eng_hl7
AS
   FUNCTION msh (sending_facx          VARCHAR2,
                 message_date_timex    DATE,
                 message_typex         VARCHAR2,
                 msg_ctrl_idx          VARCHAR2)
      RETURN VARCHAR2
   AS
      msh_segz   VARCHAR2 (4000);
   BEGIN
      msh_segz :=
            'MSH|^~\&|THERADOC|'
         || sending_facx
         || '|||'
         || util.date_to_hl7 (message_date_timex)
         || '||'
         || message_typex
         || '|'
         || msg_ctrl_idx
         || c_hl7_segment_delim;
      RETURN msh_segz;
   END msh;

   FUNCTION msh (eng_queue_idx NUMBER)
      RETURN VARCHAR2
   AS
      qrecz                eng_queue%ROWTYPE;
      sending_facz         VARCHAR2 (20);
      message_date_timez   DATE;
      message_typez        VARCHAR2 (20);
      msg_ctrl_idz         VARCHAR2 (100);
   BEGIN
      -- Retrieve the record
      SELECT *
        INTO qrecz
        FROM eng_queue
       WHERE eng_queue_id = eng_queue_idx;

      -- Get sending facility based on td_institution_id
      SELECT abbreviation
        INTO sending_facz
        FROM td_institution
       WHERE td_institution_id = qrecz.td_institution_id;

      -- Set message_date_time based on eng_queue.nq_time
      message_date_timez := qrecz.nq_time;
      -- message_typez = eng_queue.event_type
      message_typez := qrecz.event_type;
      -- msg_ctrl_idz = eng_queue_idx
      msg_ctrl_idz := eng_queue_idx;
      RETURN msh (sending_facz,
                  message_date_timez,
                  message_typez,
                  msg_ctrl_idz);
   END msh;

   FUNCTION evn (event_typex             VARCHAR2,
                 event_recorded_datex    DATE,
                 event_planned_datex     DATE,
                 event_occurred_datex    DATE)
      RETURN VARCHAR2
   AS
      evn_segz   VARCHAR2 (4000);
   BEGIN
      evn_segz :=
            'EVN|'
         || event_typex
         || '|'
         || util.date_to_hl7 (event_recorded_datex)
         || '|'
         || util.date_to_hl7 (event_planned_datex)
         || '|||'
         || util.date_to_hl7 (event_occurred_datex)
         || c_hl7_segment_delim;
      RETURN evn_segz;
   END;

   FUNCTION evn (eng_queue_idx NUMBER)
      RETURN VARCHAR2
   AS
      qrecz   eng_queue%ROWTYPE;
   BEGIN
      -- Get this record from the queue
      SELECT *
        INTO qrecz
        FROM eng_queue
       WHERE eng_queue_id = eng_queue_idx;

      -- Call raw evn segment function
      RETURN evn (qrecz.event_type,
                  qrecz.event_recorded_date,
                  qrecz.event_planned_date,
                  qrecz.event_occurred_date);
   END;

   FUNCTION pid (empix           VARCHAR2,
                 mrnx            VARCHAR2,
                 name_cmx        VARCHAR2,
                 genderx         VARCHAR2,
                 birth_datex     VARCHAR2,
                 account_numx    VARCHAR2)
      RETURN VARCHAR2
   AS
      pid_segz   VARCHAR2 (4000);
   BEGIN
      pid_segz :=
            'PID||'
         || empix
         || '|'
         || LPAD (LTRIM (mrnx, '0'), 7, '0')
         || '||'
         || name_cmx
         || '||'
         || birth_datex
         || '|'
         || genderx
         || '||||||||||'
         || '||'
         || c_hl7_segment_delim;
      RETURN pid_segz;
   END pid;

   FUNCTION pid (td_patient_idx NUMBER, td_institution_idx NUMBER)
      RETURN VARCHAR2
   AS
      empiz          VARCHAR2 (100);
      mrnz           VARCHAR2 (100);
      name_cmz       VARCHAR2 (100);
      genderz        VARCHAR2 (50);
      birth_datez    VARCHAR2 (50);
      account_numz   VARCHAR2 (50);
   BEGIN
      -- Get empiz
      SELECT pat_id_empi
        INTO empiz
        FROM td_master_patient
       WHERE td_patient_id = td_patient_idx;

      -- Get the appropriate td_patient entry
      SELECT pat_id,
             name_cm,
             sex,
             TO_CHAR (birth_date, 'yyyymmdd')
        INTO mrnz,
             name_cmz,
             genderz,
             birth_datez
        FROM td_patient
       WHERE     td_patient_id = td_patient_idx
             AND td_institution_id = td_institution_idx
             AND td_status_id = 1
             AND ROWNUM = 1;

      BEGIN
         SELECT visit_num
           INTO account_numz
           FROM td_inpatient_location
          WHERE     td_patient_id = td_patient_idx
                AND td_institution_id = td_institution_idx;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT visit_num
                 INTO account_numz
                 FROM td_inpatient_location
                WHERE td_encounter_id =
                         (SELECT MAX (td_encounter_id)
                            FROM td_inpatient_tracker
                           WHERE     td_patient_id = td_patient_idx
                                 AND td_institution_id = td_institution_idx);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     SELECT visit_num
                       INTO account_numz
                       FROM td_ENCOUNTER
                      WHERE td_encounter_id =
                               (SELECT MAX (td_encounter_id)
                                  FROM td_ENCOUNTER
                                 WHERE     td_patient_id = td_patient_idx
                                       AND td_institution_id =
                                              td_institution_idx
                                       AND HL7_EVENT_CODE LIKE 'ADT%');
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        NULL;
                  END;
            END;
      END;

      RETURN pid (empiz,
                  mrnz,
                  name_cmz,
                  genderz,
                  birth_datez,
                  account_numz);
   END pid;

   FUNCTION pid (eng_queue_idx NUMBER)
      RETURN VARCHAR2
   AS
      qrecz   eng_queue%ROWTYPE;
   BEGIN
      SELECT *
        INTO qrecz
        FROM eng_queue
       WHERE eng_queue_id = eng_queue_idx;

      RETURN pid (qrecz.td_patient_id, qrecz.td_institution_id);
   END pid;


   FUNCTION pv1 (account_numx VARCHAR2)
      RETURN VARCHAR2
   AS
      pid_segz   VARCHAR2 (4000);
   BEGIN
      pid_segz :=
            'PV1|||||||||||||||||||'
         || account_numx
         || '|'
         || c_hl7_segment_delim;
      RETURN pid_segz;
   END pv1;

   FUNCTION pv1 (td_patient_idx NUMBER, td_institution_idx NUMBER)
      RETURN VARCHAR2
   AS
      account_numz   VARCHAR2 (50);
   BEGIN
      BEGIN
         SELECT visit_num
           INTO account_numz
           FROM td_inpatient_location
          WHERE     td_patient_id = td_patient_idx
                AND td_institution_id = td_institution_idx;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT visit_num
                 INTO account_numz
                 FROM td_inpatient_location
                WHERE td_encounter_id =
                         (SELECT MAX (td_encounter_id)
                            FROM td_inpatient_tracker
                           WHERE     td_patient_id = td_patient_idx
                                 AND td_institution_id = td_institution_idx
                                 AND visit_num NOT LIKE '4%');
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  BEGIN
                     SELECT visit_num
                       INTO account_numz
                       FROM td_ENCOUNTER
                      WHERE td_encounter_id =
                               (SELECT MAX (td_encounter_id)
                                  FROM td_ENCOUNTER
                                 WHERE     td_patient_id = td_patient_idx
                                       AND td_institution_id =
                                              td_institution_idx
                                       AND HL7_EVENT_CODE LIKE 'ADT%'
                                       AND visit_num NOT LIKE '4%');
                  EXCEPTION
                     WHEN NO_DATA_FOUND
                     THEN
                        BEGIN
                           SELECT visit_num
                             INTO account_numz
                             FROM td_ENCOUNTER
                            WHERE td_encounter_id =
                                     (SELECT MAX (td_encounter_id)
                                        FROM td_ENCOUNTER
                                       WHERE     td_patient_id =
                                                    td_patient_idx
                                             AND HL7_EVENT_CODE LIKE 'ADT%'
                                             AND visit_num NOT LIKE '4%');
                        EXCEPTION
                           WHEN NO_DATA_FOUND
                           THEN
                              NULL;
                        END;
                  END;
            END;
      END;

      RETURN pv1 (account_numz);
   END pv1;


   FUNCTION pv1 (eng_queue_idx NUMBER)
      RETURN VARCHAR2
   AS
      qrecz   eng_queue%ROWTYPE;
   BEGIN
      SELECT *
        INTO qrecz
        FROM eng_queue
       WHERE eng_queue_id = eng_queue_idx;

      RETURN pv1 (qrecz.td_patient_id, qrecz.td_institution_id);
   END pv1;

   FUNCTION display_hl7_non_print (pass_clobx CLOB)
      RETURN CLOB
   IS
      ret_clobz   CLOB := pass_clobx;
   BEGIN
      ret_clobz := REPLACE (ret_clobz, eng_hl7.c_hl7_startblock, '\\x0b');
      ret_clobz := REPLACE (ret_clobz, eng_hl7.c_hl7_endblock, '\\x1c');
      ret_clobz := REPLACE (ret_clobz, eng_hl7.c_hl7_line_break, '\\x0a');
      ret_clobz :=
         REPLACE (ret_clobz,
                  eng_hl7.c_hl7_segment_delim,
                  '\\x0d' || CHR (10));
      RETURN ret_clobz;
   END display_hl7_non_print;

   FUNCTION display_hl7_non_print (pass_varcharx VARCHAR2)
      RETURN VARCHAR2
   IS
      ret_varcharz   VARCHAR2 (32767) := pass_varcharx;
   BEGIN
      ret_varcharz :=
         REPLACE (ret_varcharz, eng_hl7.c_hl7_startblock, '\\x0b');
      ret_varcharz := REPLACE (ret_varcharz, eng_hl7.c_hl7_endblock, '\\x1c');
      ret_varcharz := REPLACE (ret_varcharz, CHR (10), '\\x0a');
      ret_varcharz :=
         REPLACE (ret_varcharz,
                  eng_hl7.c_hl7_segment_delim,
                  '\\x0d' || CHR (10));
      RETURN ret_varcharz;
   END display_hl7_non_print;

   FUNCTION get_ack_code (ack_strx VARCHAR2)
      RETURN VARCHAR2
   IS
      ack_strz   VARCHAR2 (32767) := ack_strx;
   BEGIN
      ack_strz := REPLACE (ack_strz, eng_hl7.c_hl7_startblock);
      ack_strz := REPLACE (ack_strz, eng_hl7.c_hl7_endblock);
      RETURN util.get_msg_tok (ack_strz, 'MSA-1');
   END get_ack_code;
END;
/

CREATE OR REPLACE SYNONYM TDRUN.ENG_HL7 FOR TDCUSTOM.ENG_HL7;


GRANT EXECUTE, DEBUG ON TDCUSTOM.ENG_HL7 TO TDRUN WITH GRANT OPTION;
