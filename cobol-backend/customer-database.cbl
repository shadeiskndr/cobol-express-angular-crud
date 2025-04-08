       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTOMER-DATABASE.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUSTOMER-FILE ASSIGN TO EXTERNAL DD_CUSTOMER_FILE
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS CF-CUSTOMER-ID
           FILE STATUS IS FILE-STATUS.
           
           SELECT TRANSACTION-FILE ASSIGN TO EXTERNAL DD_TRANSACTION_FILE
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS TF-TRANSACTION-ID
           ALTERNATE RECORD KEY IS TF-CUSTOMER-ID WITH DUPLICATES
           FILE STATUS IS FILE-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD CUSTOMER-FILE.
       01 CUSTOMER-RECORD.
          05 CF-CUSTOMER-ID         PIC 9(5).
          05 CF-CUSTOMER-NAME       PIC X(30).
          05 CF-CUSTOMER-EMAIL      PIC X(50).
          05 CF-CUSTOMER-STATUS     PIC X(10).
          05 CF-LAST-UPDATE         PIC X(10).
          05 CF-ADDRESS             PIC X(100).
          05 CF-PHONE               PIC X(15).
          05 CF-CREDIT-LIMIT        PIC 9(7)V99.
          05 CF-BALANCE             PIC S9(7)V99.
          05 CF-CREATION-DATE       PIC X(10).
       
       FD TRANSACTION-FILE.
       01 TRANSACTION-RECORD.
          05 TF-TRANSACTION-ID      PIC 9(10).
          05 TF-CUSTOMER-ID         PIC 9(5).
          05 TF-DATE                PIC X(10).
          05 TF-AMOUNT              PIC S9(7)V99.
          05 TF-TYPE                PIC X(10).
          05 TF-DESCRIPTION         PIC X(100).
          05 TF-STATUS              PIC X(10).
       
       WORKING-STORAGE SECTION.
       01 FILE-STATUS               PIC XX VALUE SPACES.
       
       01 WS-INPUT-BUFFER           PIC X(1000).
       01 WS-OPERATION              PIC X(15).
       01 WS-ID                     PIC 9(5).
       
       01 WS-CUSTOMER.
          05 WS-CUSTOMER-ID         PIC 9(5).
          05 WS-CUSTOMER-NAME       PIC X(30).
          05 WS-CUSTOMER-EMAIL      PIC X(50).
          05 WS-CUSTOMER-STATUS     PIC X(10).
          05 WS-LAST-UPDATE         PIC X(10).
          05 WS-ADDRESS             PIC X(100).
          05 WS-PHONE               PIC X(15).
          05 WS-CREDIT-LIMIT        PIC 9(7)V99.
          05 WS-BALANCE             PIC S9(7)V99.
          05 WS-CREATION-DATE       PIC X(10).
       
       01 WS-SEARCH-CRITERIA.
          05 WS-SEARCH-NAME         PIC X(30) VALUE SPACES.
          05 WS-SEARCH-EMAIL        PIC X(50) VALUE SPACES.
          05 WS-SEARCH-STATUS       PIC X(10) VALUE SPACES.
          05 WS-SEARCH-MIN-BALANCE  PIC S9(7)V99 VALUE ZEROS.
          05 WS-SEARCH-MAX-BALANCE  PIC S9(7)V99 VALUE 9999999.99.
       
       01 WS-RESPONSE               PIC X(5000).
       
       01 WS-CURRENT-DATE.
          05 WS-YEAR                PIC 9(4).
          05 WS-MONTH               PIC 9(2).
          05 WS-DAY                 PIC 9(2).
          05 FILLER                 PIC X(10).
       
       01 WS-FORMATTED-DATE         PIC X(10).
       
       01 WS-JSON-PARSING-IDX       PIC 9(4) COMP.
       01 WS-TEMP                   PIC X(100).
       01 WS-NUMERIC-TEMP           PIC 9(10).
       
       01 WS-ERROR-MESSAGE          PIC X(100).
       01 WS-SUCCESS-FLAG           PIC 9 VALUE 0.
       
       01 WS-SEARCH-MATCH-FLAG      PIC 9 VALUE 0.

       01 WS-TEMP-FIELD-NAME        PIC X(25).
       01 WS-TEMP-FIELD-VALUE       PIC X(100).
       01 WS-TEMP-NUMERIC-VALUE     PIC S9(7)V99.

       01 WS-CREDIT-LIMIT-JSON       PIC X(20).
       01 WS-BALANCE-JSON            PIC X(20).

       01 WS-FORMATTED-NUMERIC.
          05 WS-FMT-CREDIT-LIMIT     PIC ZZZZZZ9.99.
          05 WS-FMT-BALANCE          PIC -ZZZZZZ9.99.
          05 WS-FMT-AMOUNT           PIC -ZZZZZZ9.99.

       01 WS-TRIMMED-FIELD-NAME   PIC X(25).
       01 WS-FIELD-NAME-LEN       PIC 9(2) COMP.
       
       PROCEDURE DIVISION.
      *> cobol-lint CL002 main-procedure
       MAIN-PROCEDURE.
           PERFORM INITIALIZE-PROGRAM
           PERFORM PROCESS-REQUEST
           PERFORM CLEANUP-AND-EXIT
           STOP RUN.
       
       INITIALIZE-PROGRAM.
           MOVE SPACES TO WS-INPUT-BUFFER
           MOVE SPACES TO WS-RESPONSE
           MOVE SPACES TO WS-ERROR-MESSAGE
           MOVE 0 TO WS-SUCCESS-FLAG
           ACCEPT WS-CURRENT-DATE FROM DATE YYYYMMDD
           
           MOVE WS-YEAR TO WS-FORMATTED-DATE(1:4)
           MOVE "-" TO WS-FORMATTED-DATE(5:1)
           MOVE WS-MONTH TO WS-FORMATTED-DATE(6:2)
           MOVE "-" TO WS-FORMATTED-DATE(8:1)
           MOVE WS-DAY TO WS-FORMATTED-DATE(9:2).
       
       PROCESS-REQUEST.
           ACCEPT WS-INPUT-BUFFER
           PERFORM PARSE-JSON-REQUEST
           
           EVALUATE WS-OPERATION
               WHEN "GET"
                   PERFORM GET-CUSTOMER
               WHEN "CREATE"
                   PERFORM CREATE-CUSTOMER
               WHEN "UPDATE"
                   PERFORM UPDATE-CUSTOMER
               WHEN "DELETE"
                   PERFORM DELETE-CUSTOMER
               WHEN "LIST"
                   PERFORM LIST-CUSTOMERS
               WHEN "SEARCH"
                   PERFORM SEARCH-CUSTOMERS
               WHEN "TRANSACTIONS"
                   PERFORM GET-CUSTOMER-TRANSACTIONS
               WHEN OTHER
                   MOVE "Invalid operation" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
           END-EVALUATE.
       
       PARSE-JSON-REQUEST.
           PERFORM EXTRACT-OPERATION
           EVALUATE WS-OPERATION
               WHEN "GET"
               WHEN "DELETE"
               WHEN "TRANSACTIONS"
                   PERFORM EXTRACT-ID
               WHEN "CREATE"
               WHEN "UPDATE"
                   PERFORM EXTRACT-ID
                   PERFORM EXTRACT-CUSTOMER-DATA
               WHEN "SEARCH"
                   PERFORM EXTRACT-SEARCH-CRITERIA
           END-EVALUATE.
       
       EXTRACT-OPERATION.
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:13) = 
                   '"operation":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               MOVE "Missing operation parameter" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               EXIT PARAGRAPH
           END-IF
           
           ADD 13 TO WS-JSON-PARSING-IDX
           MOVE SPACES TO WS-OPERATION
           
           PERFORM VARYING WS-NUMERIC-TEMP FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF 
                   WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP
                - 1:1) = '"'
               MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + 
                   WS-NUMERIC-TEMP - 1:1)
                   TO WS-OPERATION(WS-NUMERIC-TEMP:1)
           END-PERFORM.
       
       EXTRACT-ID.
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:6) = '"id":"'
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:5) = '"id":'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               MOVE "Missing id parameter" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               EXIT PARAGRAPH
           END-IF
           
           IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:6) = '"id":"'
               ADD 6 TO WS-JSON-PARSING-IDX
           ELSE
               ADD 5 TO WS-JSON-PARSING-IDX
           END-IF
           
           MOVE SPACES TO WS-TEMP
           
           PERFORM VARYING WS-NUMERIC-TEMP FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF 
                   WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP
                - 1:1) = '"'
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP 
               - 1:1) = ','
               MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + 
                   WS-NUMERIC-TEMP - 1:1)
                   TO WS-TEMP(WS-NUMERIC-TEMP:1)
           END-PERFORM
           
           MOVE WS-TEMP TO WS-ID.
       
       EXTRACT-CUSTOMER-DATA.
           MOVE SPACES TO WS-CUSTOMER
           MOVE WS-ID TO WS-CUSTOMER-ID
           
           *> Extract name field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:8) = '"name":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 8 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-CUSTOMER-NAME
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-CUSTOMER-NAME
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-CUSTOMER-NAME(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           *> Extract email field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:9) = '"email":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 9 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-CUSTOMER-EMAIL
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-CUSTOMER-EMAIL
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-CUSTOMER-EMAIL(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           *> Extract status field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:10) = '"status":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 10 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-CUSTOMER-STATUS
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-CUSTOMER-STATUS
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-CUSTOMER-STATUS(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           *> Extract address field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:11) = '"address":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 11 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-ADDRESS
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-ADDRESS
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-ADDRESS(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           *> Extract phone field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:9) = '"phone":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 9 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-PHONE
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-PHONE
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-PHONE(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           MOVE WS-FORMATTED-DATE TO WS-LAST-UPDATE
           
           IF WS-OPERATION = "CREATE"
               MOVE WS-FORMATTED-DATE TO WS-CREATION-DATE
           END-IF.

       
       EXTRACT-SEARCH-CRITERIA.
           INITIALIZE WS-SEARCH-CRITERIA
           
           MOVE '"name":' TO WS-TEMP-FIELD-NAME
           PERFORM EXTRACT-CUSTOMER-FIELD
           MOVE WS-TEMP-FIELD-VALUE TO WS-SEARCH-NAME
           
           MOVE '"email":' TO WS-TEMP-FIELD-NAME
           PERFORM EXTRACT-CUSTOMER-FIELD
           MOVE WS-TEMP-FIELD-VALUE TO WS-SEARCH-EMAIL
           
           MOVE '"status":' TO WS-TEMP-FIELD-NAME
           PERFORM EXTRACT-CUSTOMER-FIELD
           MOVE WS-TEMP-FIELD-VALUE TO WS-SEARCH-STATUS
           
           MOVE '"minBalance":' TO WS-TEMP-FIELD-NAME
           PERFORM EXTRACT-NUMERIC-FIELD
           MOVE WS-TEMP-NUMERIC-VALUE TO WS-SEARCH-MIN-BALANCE
           
           MOVE '"maxBalance":' TO WS-TEMP-FIELD-NAME
           PERFORM EXTRACT-NUMERIC-FIELD
           MOVE WS-TEMP-NUMERIC-VALUE TO WS-SEARCH-MAX-BALANCE.

       
       EXTRACT-NUMERIC-FIELD.
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:LENGTH OF 
                   WS-TEMP-FIELD-NAME) 
                   = WS-TEMP-FIELD-NAME
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD LENGTH OF WS-TEMP-FIELD-NAME TO WS-JSON-PARSING-IDX
               
               MOVE SPACES TO WS-TEMP
               
               PERFORM VARYING WS-NUMERIC-TEMP FROM 1 BY 1
                   UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP 
                         > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX 
                                     + WS-NUMERIC-TEMP - 1:1) = ','
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX 
                                     + WS-NUMERIC-TEMP - 1:1) = '}'
                   MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX 
                                       + WS-NUMERIC-TEMP - 1:1)
                       TO WS-TEMP(WS-NUMERIC-TEMP:1)
               END-PERFORM
               
               MOVE FUNCTION NUMVAL(WS-TEMP) TO WS-TEMP-NUMERIC-VALUE
           END-IF.
       
       EXTRACT-CUSTOMER-FIELD.
           MOVE SPACES TO WS-TEMP-FIELD-VALUE
           
           *> Search for the field name in the input buffer
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:LENGTH OF WS-TEMP-FIELD-NAME) 
                   = WS-TEMP-FIELD-NAME
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               *> Found the field name, now extract the value
               ADD LENGTH OF WS-TEMP-FIELD-NAME TO WS-JSON-PARSING-IDX
               
               *> Skip any whitespace after the field name
               PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) NOT = SPACE
                   ADD 1 TO WS-JSON-PARSING-IDX
               END-PERFORM
               
               *> Check if value is quoted
               IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '"'
                   *> Skip the opening quote
                   ADD 1 TO WS-JSON-PARSING-IDX
                   
                   *> Extract the value until closing quote
                   MOVE 1 TO WS-NUMERIC-TEMP
                   PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP - 1 
                         > LENGTH OF WS-INPUT-BUFFER
                       OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX 
                                         + WS-NUMERIC-TEMP - 1:1) = '"'
                       
                       IF WS-NUMERIC-TEMP <= LENGTH OF WS-TEMP-FIELD-VALUE
                           MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX 
                                              + WS-NUMERIC-TEMP - 1:1)
                               TO WS-TEMP-FIELD-VALUE(WS-NUMERIC-TEMP:1)
                       END-IF
                       
                       ADD 1 TO WS-NUMERIC-TEMP
                   END-PERFORM
               ELSE
                   *> Handle non-quoted values (numbers, booleans, etc.)
                   MOVE 1 TO WS-NUMERIC-TEMP
                   PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP - 1 
                         > LENGTH OF WS-INPUT-BUFFER
                       OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX 
                                         + WS-NUMERIC-TEMP - 1:1) = ','
                       OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX 
                                         + WS-NUMERIC-TEMP - 1:1) = '}'
                       
                       IF WS-NUMERIC-TEMP <= LENGTH OF WS-TEMP-FIELD-VALUE
                           MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX 
                                              + WS-NUMERIC-TEMP - 1:1)
                               TO WS-TEMP-FIELD-VALUE(WS-NUMERIC-TEMP:1)
                       END-IF
                       
                       ADD 1 TO WS-NUMERIC-TEMP
                   END-PERFORM
               END-IF
           END-IF.
       
       GET-CUSTOMER.
           OPEN INPUT CUSTOMER-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open customer file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE CUSTOMER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO CF-CUSTOMER-ID
           
           READ CUSTOMER-FILE
               INVALID KEY
                   MOVE "Customer not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   MOVE 1 TO WS-SUCCESS-FLAG
                   PERFORM GENERATE-CUSTOMER-JSON
           END-READ
           
           CLOSE CUSTOMER-FILE.
       
       CREATE-CUSTOMER.
           OPEN I-O CUSTOMER-FILE
               
           IF FILE-STATUS = "35" *> File doesn't exist, open for OUTPUT first
               CLOSE CUSTOMER-FILE *> Close attempt to open I-O
               OPEN OUTPUT CUSTOMER-FILE *> Open to create it
               IF FILE-STATUS NOT = "00"
                   MOVE "Failed to create customer file" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                   EXIT PARAGRAPH *> Cannot proceed
               END-IF
               CLOSE CUSTOMER-FILE *> Close OUTPUT
               OPEN I-O CUSTOMER-FILE *> Re-open I-O now that file exists
           END-IF
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open customer file for I-O" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE CUSTOMER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO CF-CUSTOMER-ID
           
           READ CUSTOMER-FILE *> Check if exists
               INVALID KEY
                   CONTINUE *> Good, doesn't exist, proceed to write
               NOT INVALID KEY
                   MOVE "Customer ID already exists" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                   CLOSE CUSTOMER-FILE
                   EXIT PARAGRAPH
           END-READ
    
           MOVE WS-CUSTOMER-ID TO CF-CUSTOMER-ID
           MOVE WS-CUSTOMER-NAME TO CF-CUSTOMER-NAME
           MOVE WS-CUSTOMER-EMAIL TO CF-CUSTOMER-EMAIL
           MOVE WS-CUSTOMER-STATUS TO CF-CUSTOMER-STATUS
           MOVE WS-LAST-UPDATE TO CF-LAST-UPDATE
           MOVE WS-ADDRESS TO CF-ADDRESS
           MOVE WS-PHONE TO CF-PHONE
           MOVE 0 TO CF-CREDIT-LIMIT *> Initialize numeric fields
           MOVE 0 TO CF-BALANCE
           MOVE WS-CREATION-DATE TO CF-CREATION-DATE
           
           WRITE CUSTOMER-RECORD
               INVALID KEY
                   MOVE "Failed to write new customer record" TO 
                       WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   MOVE 1 TO WS-SUCCESS-FLAG
                   STRING '{"success":true,"message":'
                          '"Customer created",'
                          '"id":' DELIMITED BY SIZE
                          WS-CUSTOMER-ID DELIMITED BY SIZE
                          '}' DELIMITED BY SIZE
                       INTO WS-RESPONSE
           END-WRITE
           
           CLOSE CUSTOMER-FILE.
       
       UPDATE-CUSTOMER.
           OPEN I-O CUSTOMER-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open customer file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE CUSTOMER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO CF-CUSTOMER-ID
           
           READ CUSTOMER-FILE
               INVALID KEY
                   MOVE "Customer not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   MOVE WS-CUSTOMER-NAME TO CF-CUSTOMER-NAME
                   MOVE WS-CUSTOMER-EMAIL TO CF-CUSTOMER-EMAIL
                   MOVE WS-CUSTOMER-STATUS TO CF-CUSTOMER-STATUS
                   MOVE WS-LAST-UPDATE TO CF-LAST-UPDATE
                   MOVE WS-ADDRESS TO CF-ADDRESS
                   MOVE WS-PHONE TO CF-PHONE
                   
                   REWRITE CUSTOMER-RECORD
                       INVALID KEY
                           MOVE "Failed to update customer" TO 
                               WS-ERROR-MESSAGE
                           PERFORM GENERATE-ERROR-RESPONSE
                       NOT INVALID KEY
                           MOVE 1 TO WS-SUCCESS-FLAG
                           STRING '{"success":true,"message":"Customer updated",'
                                  '"id":' DELIMITED BY SIZE
                                  WS-CUSTOMER-ID DELIMITED BY SIZE
                                  '}' DELIMITED BY SIZE
                               INTO WS-RESPONSE
                   END-REWRITE
           END-READ
           
           CLOSE CUSTOMER-FILE.
       
       DELETE-CUSTOMER.
           OPEN I-O CUSTOMER-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open customer file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE CUSTOMER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO CF-CUSTOMER-ID
           
           READ CUSTOMER-FILE
               INVALID KEY
                   MOVE "Customer not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   DELETE CUSTOMER-FILE
                       INVALID KEY
                           MOVE "Failed to delete customer" TO 
                               WS-ERROR-MESSAGE
                           PERFORM GENERATE-ERROR-RESPONSE
                       NOT INVALID KEY
                           MOVE 1 TO WS-SUCCESS-FLAG
                           STRING '{"success":true,"message":"' DELIMITED BY SIZE
                                  'Customer deleted",' DELIMITED BY SIZE
                                  '"id":"' DELIMITED BY SIZE
                                  WS-CUSTOMER-ID DELIMITED BY SIZE
                                  '"}' DELIMITED BY SIZE
                               INTO WS-RESPONSE
                   END-DELETE
           END-READ
           
           CLOSE CUSTOMER-FILE.
       
       LIST-CUSTOMERS.
           OPEN INPUT CUSTOMER-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open customer file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE CUSTOMER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE 1 TO WS-JSON-PARSING-IDX *> Initialize pointer
           STRING '{"customers":[' DELIMITED BY SIZE
               INTO WS-RESPONSE
               POINTER WS-JSON-PARSING-IDX *> Update pointer
           END-STRING
           
           MOVE 1 TO WS-SUCCESS-FLAG
           MOVE 0 TO WS-NUMERIC-TEMP *> Counter for records found
           
           MOVE LOW-VALUES TO CF-CUSTOMER-ID
           START CUSTOMER-FILE KEY >= CF-CUSTOMER-ID
               INVALID KEY
                   *> No records or error starting, close the array
                   STRING ']}' DELIMITED BY SIZE
                       INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
                   END-STRING
                   CLOSE CUSTOMER-FILE
                   EXIT PARAGRAPH *> Exit cleanly if no records
               NOT INVALID KEY
                   CONTINUE *> Start successful, proceed to read loop
           END-START
           
           PERFORM UNTIL FILE-STATUS NOT = "00"
               READ CUSTOMER-FILE NEXT
                   AT END
                       EXIT PERFORM
                   NOT AT END
                       IF WS-NUMERIC-TEMP > 0 *> Add comma before second+ record
                           STRING ',' DELIMITED BY SIZE
                               INTO WS-RESPONSE
                               POINTER WS-JSON-PARSING-IDX
                           END-STRING
                       END-IF
                       
                       ADD 1 TO WS-NUMERIC-TEMP
                       
                       STRING '{'                              DELIMITED BY SIZE
                              '"id":'                         DELIMITED BY SIZE
                              CF-CUSTOMER-ID                   DELIMITED BY SIZE
                              ',"name":"'                      DELIMITED BY SIZE
                              FUNCTION TRIM(CF-CUSTOMER-NAME)  DELIMITED BY SIZE
                              '","email":"'                    DELIMITED BY SIZE
                              FUNCTION TRIM(CF-CUSTOMER-EMAIL) DELIMITED BY SIZE
                              '","status":"'                   DELIMITED BY SIZE
                              FUNCTION TRIM(CF-CUSTOMER-STATUS) DELIMITED BY SIZE
                              '"}'                             DELIMITED BY SIZE
                           INTO WS-RESPONSE
                           POINTER WS-JSON-PARSING-IDX *> Update pointer after each record
                       END-STRING
               END-READ
           END-PERFORM
           
           *> Close the JSON array and object
           STRING ']}' DELIMITED BY SIZE
               INTO WS-RESPONSE(WS-JSON-PARSING-IDX:) *> Append at current position
           END-STRING
               
           CLOSE CUSTOMER-FILE.
       
       SEARCH-CUSTOMERS.
           OPEN INPUT CUSTOMER-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open customer file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE CUSTOMER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE '{"customers":[' TO WS-RESPONSE
           MOVE 1 TO WS-SUCCESS-FLAG
           MOVE 0 TO WS-NUMERIC-TEMP
           
           MOVE LOW-VALUES TO CF-CUSTOMER-ID
           START CUSTOMER-FILE KEY >= CF-CUSTOMER-ID
               INVALID KEY
                   MOVE "Failed to position at start of file" TO 
                       WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                   CLOSE CUSTOMER-FILE
                   EXIT PARAGRAPH
           END-START
           
           PERFORM UNTIL FILE-STATUS NOT = "00"
               READ CUSTOMER-FILE NEXT
                   AT END
                       EXIT PERFORM
                   NOT AT END
                       PERFORM CHECK-SEARCH-MATCH
                       IF WS-SEARCH-MATCH-FLAG = 1
                           IF WS-NUMERIC-TEMP > 0
                               STRING ',' DELIMITED BY SIZE
                                   INTO WS-RESPONSE(
                                       WS-JSON-PARSING-IDX:)
                               ADD 1 TO WS-JSON-PARSING-IDX
                           END-IF
                           
                           ADD 1 TO WS-NUMERIC-TEMP
                           
                           MOVE CF-BALANCE TO WS-FMT-BALANCE
                           MOVE FUNCTION TRIM(WS-FMT-BALANCE LEADING) TO
                               WS-BALANCE-JSON

                           STRING '{"id":' DELIMITED BY SIZE
                                  CF-CUSTOMER-ID DELIMITED BY SIZE
                                  ',"name":"' DELIMITED BY SIZE
                                  FUNCTION TRIM(CF-CUSTOMER-NAME) 
                                   DELIMITED BY SIZE
                                       '","email":"' DELIMITED BY SIZE
                                  FUNCTION TRIM(CF-CUSTOMER-EMAIL) 
                                   DELIMITED BY SIZE
                                       '","status":"' DELIMITED BY SIZE
                                  FUNCTION TRIM(CF-CUSTOMER-STATUS) 
                                   DELIMITED BY SIZE
                                       '","balance":' DELIMITED BY SIZE
                                  FUNCTION TRIM(WS-BALANCE-JSON) DELIMITED BY SIZE
                                  '}' DELIMITED BY SIZE
                               INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
                       END-IF
               END-READ
           END-PERFORM
           
           STRING ']}' DELIMITED BY SIZE
               INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
               
           CLOSE CUSTOMER-FILE.
       
       CHECK-SEARCH-MATCH.
           MOVE 1 TO WS-SEARCH-MATCH-FLAG
           
           IF WS-SEARCH-NAME NOT = SPACES
               PERFORM CHECK-NAME-CONTAINS
           END-IF
           
           IF WS-SEARCH-EMAIL NOT = SPACES AND WS-SEARCH-MATCH-FLAG = 1
               PERFORM CHECK-EMAIL-CONTAINS
           END-IF
           
           IF WS-SEARCH-STATUS NOT = SPACES AND WS-SEARCH-MATCH-FLAG = 1
               IF CF-CUSTOMER-STATUS NOT = WS-SEARCH-STATUS
                   MOVE 0 TO WS-SEARCH-MATCH-FLAG
               END-IF
           END-IF
           
           IF CF-BALANCE < WS-SEARCH-MIN-BALANCE OR 
              CF-BALANCE > WS-SEARCH-MAX-BALANCE
               MOVE 0 TO WS-SEARCH-MATCH-FLAG
           END-IF.
           
       CHECK-NAME-CONTAINS.
           MOVE 0 TO WS-NUMERIC-TEMP
           INSPECT CF-CUSTOMER-NAME
               TALLYING WS-NUMERIC-TEMP FOR ALL WS-SEARCH-NAME
           IF WS-NUMERIC-TEMP = 0
               MOVE 0 TO WS-SEARCH-MATCH-FLAG
           END-IF.
           
       CHECK-EMAIL-CONTAINS.
           MOVE 0 TO WS-NUMERIC-TEMP
           INSPECT CF-CUSTOMER-EMAIL
               TALLYING WS-NUMERIC-TEMP FOR ALL WS-SEARCH-EMAIL
           IF WS-NUMERIC-TEMP = 0
               MOVE 0 TO WS-SEARCH-MATCH-FLAG
           END-IF.

       
       GET-CUSTOMER-TRANSACTIONS.
           OPEN INPUT CUSTOMER-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open customer file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE CUSTOMER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO CF-CUSTOMER-ID
           
           READ CUSTOMER-FILE
               INVALID KEY
                   MOVE "Customer not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                   CLOSE CUSTOMER-FILE
                   EXIT PARAGRAPH
           END-READ
           
           CLOSE CUSTOMER-FILE
           
           OPEN INPUT TRANSACTION-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open transaction file" TO 
                   WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               EXIT PARAGRAPH
           END-IF
           
           MOVE '{"customerId":' TO WS-RESPONSE
           STRING WS-RESPONSE DELIMITED BY SIZE
                  WS-ID DELIMITED BY SIZE
                  ',"transactions":[' DELIMITED BY SIZE
               INTO WS-RESPONSE
           
           MOVE 1 TO WS-SUCCESS-FLAG
           MOVE 0 TO WS-NUMERIC-TEMP
           
           MOVE WS-ID TO TF-CUSTOMER-ID
           MOVE LOW-VALUES TO TF-TRANSACTION-ID
           
           START TRANSACTION-FILE KEY = TF-CUSTOMER-ID
               INVALID KEY
                   STRING WS-RESPONSE DELIMITED BY SIZE
                          ']}' DELIMITED BY SIZE
                       INTO WS-RESPONSE
                   CLOSE TRANSACTION-FILE
                   EXIT PARAGRAPH
           END-START
           
           PERFORM UNTIL FILE-STATUS NOT = "00"
               READ TRANSACTION-FILE NEXT
                   AT END
                       EXIT PERFORM
                   NOT AT END
                       IF TF-CUSTOMER-ID = WS-ID
                           IF WS-NUMERIC-TEMP > 0
                               STRING WS-RESPONSE DELIMITED BY SIZE
                                   ',' DELIMITED BY SIZE
                                       INTO WS-RESPONSE
                           END-IF
                           
                           ADD 1 TO WS-NUMERIC-TEMP
                           
                           MOVE TF-AMOUNT TO WS-FMT-AMOUNT
                           MOVE FUNCTION TRIM(WS-FMT-AMOUNT LEADING)
                            TO WS-BALANCE-JSON

                           STRING '{"id":' DELIMITED BY SIZE
                                  TF-TRANSACTION-ID DELIMITED BY SIZE
                                  ',"date":"' DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-DATE) 
                                   DELIMITED BY SIZE
                                       '","amount":' DELIMITED BY SIZE
                                  FUNCTION TRIM(WS-BALANCE-JSON) DELIMITED BY SIZE
                                  ',"type":"' DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-TYPE) 
                                   DELIMITED BY SIZE
                                       '","description":"'
                                            DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-DESCRIPTION) 
                                   DELIMITED BY SIZE
                                       '","status":"' DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-STATUS) 
                                   DELIMITED BY SIZE
                                  '"}' DELIMITED BY SIZE
                               INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
                       ELSE
                           EXIT PERFORM
                       END-IF
               END-READ
           END-PERFORM
           
           STRING ']}' DELIMITED BY SIZE
               INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
               
           CLOSE TRANSACTION-FILE.
       
       GENERATE-CUSTOMER-JSON.
           MOVE CF-CREDIT-LIMIT TO WS-FMT-CREDIT-LIMIT
           MOVE CF-BALANCE TO WS-FMT-BALANCE
           MOVE FUNCTION TRIM(WS-FMT-CREDIT-LIMIT) TO WS-CREDIT-LIMIT-JSON
           MOVE FUNCTION TRIM(WS-FMT-BALANCE) TO WS-BALANCE-JSON
           
           STRING '{"id":' DELIMITED BY SIZE
                  CF-CUSTOMER-ID DELIMITED BY SIZE
                  ',"name":"' DELIMITED BY SIZE
                  FUNCTION TRIM(CF-CUSTOMER-NAME) DELIMITED BY SIZE
                  '","email":"' DELIMITED BY SIZE
                  FUNCTION TRIM(CF-CUSTOMER-EMAIL) DELIMITED BY SIZE
                  '","status":"' DELIMITED BY SIZE
                  FUNCTION TRIM(CF-CUSTOMER-STATUS) DELIMITED BY SIZE
                  '","lastUpdate":"' DELIMITED BY SIZE
                  FUNCTION TRIM(CF-LAST-UPDATE) DELIMITED BY SIZE
                  '","address":"' DELIMITED BY SIZE
                  FUNCTION TRIM(CF-ADDRESS) DELIMITED BY SIZE
                  '","phone":"' DELIMITED BY SIZE
                  FUNCTION TRIM(CF-PHONE) DELIMITED BY SIZE
                  '","creditLimit":' DELIMITED BY SIZE
                  FUNCTION TRIM(WS-CREDIT-LIMIT-JSON) DELIMITED BY SIZE *> Trim here
                  ',"balance":' DELIMITED BY SIZE     
                  FUNCTION TRIM(WS-BALANCE-JSON) DELIMITED BY SIZE      *> Trim here
                  ',"creationDate":"' DELIMITED BY SIZE
                  FUNCTION TRIM(CF-CREATION-DATE) DELIMITED BY SIZE
                  '"}' DELIMITED BY SIZE
               INTO WS-RESPONSE.
       
       GENERATE-ERROR-RESPONSE.
           STRING '{"success":false,"error":"' DELIMITED BY SIZE
                  FUNCTION TRIM(WS-ERROR-MESSAGE) DELIMITED BY SIZE
                  '"}' DELIMITED BY SIZE
               INTO WS-RESPONSE.
       
       CLEANUP-AND-EXIT.
           DISPLAY WS-RESPONSE.


