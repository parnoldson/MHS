DROP PACKAGE TDCUSTOM.ENG_HL7;

CREATE OR REPLACE PACKAGE TDCUSTOM.eng_hl7
AS
   c_hl7_startblock      CONSTANT VARCHAR2 (1) := CHR (11);
   c_hl7_endblock        CONSTANT VARCHAR2 (1) := CHR (28);
   c_hl7_segment_delim   CONSTANT VARCHAR2 (1) := CHR (13);
   c_hl7_line_break      CONSTANT VARCHAR2 (1) := CHR (10);

   FUNCTION msh (sending_facx          VARCHAR2,
                 message_date_timex    DATE,
                 message_typex         VARCHAR2,
                 msg_ctrl_idx          VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION msh (eng_queue_idx NUMBER)
      RETURN VARCHAR2;

   FUNCTION evn (event_typex             VARCHAR2,
                 event_recorded_datex    DATE,
                 event_planned_datex     DATE,
                 event_occurred_datex    DATE)
      RETURN VARCHAR2;

   FUNCTION evn (eng_queue_idx NUMBER)
      RETURN VARCHAR2;

   FUNCTION pid (empix           VARCHAR2,
                 mrnx            VARCHAR2,
                 name_cmx        VARCHAR2,
                 genderx         VARCHAR2,
                 birth_datex     VARCHAR2,
                 account_numx    VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION pid (td_patient_idx NUMBER, td_institution_idx NUMBER)
      RETURN VARCHAR2;

   FUNCTION pid (eng_queue_idx NUMBER)
      RETURN VARCHAR2;

   FUNCTION pv1 (eng_queue_idx NUMBER)
      RETURN VARCHAR2;

   FUNCTION pv1 (account_numx VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION pv1 (td_patient_idx NUMBER, td_institution_idx NUMBER)
      RETURN VARCHAR2;

   FUNCTION display_hl7_non_print (pass_clobx CLOB)
      RETURN CLOB;

   FUNCTION display_hl7_non_print (pass_varcharx VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION get_ack_code (ack_strx VARCHAR2)
      RETURN VARCHAR2;
END;
/

CREATE OR REPLACE SYNONYM TDRUN.ENG_HL7 FOR TDCUSTOM.ENG_HL7;


GRANT EXECUTE, DEBUG ON TDCUSTOM.ENG_HL7 TO TDRUN WITH GRANT OPTION;
