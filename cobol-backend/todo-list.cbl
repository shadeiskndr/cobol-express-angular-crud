       IDENTIFICATION DIVISION.
       PROGRAM-ID. TODO-LIST.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TODO-FILE ASSIGN TO EXTERNAL DD_TODO_FILE
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS TF-TODO-ID
           FILE STATUS IS FILE-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD TODO-FILE.
       01 TODO-RECORD.
          05 TF-TODO-ID             PIC 9(5).
          05 TF-DESCRIPTION         PIC X(100).
          05 TF-DUE-DATE            PIC X(10).
          05 TF-ESTIMATED-TIME      PIC 9(4).
          05 TF-STATUS              PIC X(10).
          05 TF-CREATION-DATE       PIC X(10).
          05 TF-LAST-UPDATE         PIC X(10).
       
       WORKING-STORAGE SECTION.
       01 FILE-STATUS               PIC XX VALUE SPACES.
       
       01 WS-INPUT-BUFFER           PIC X(1000).
       01 WS-OPERATION              PIC X(15).
       01 WS-ID                     PIC 9(5).
       
       01 WS-TODO.
          05 WS-TODO-ID             PIC 9(5).
          05 WS-DESCRIPTION         PIC X(100).
          05 WS-DUE-DATE            PIC X(10).
          05 WS-ESTIMATED-TIME      PIC 9(4).
          05 WS-STATUS              PIC X(10).
          05 WS-CREATION-DATE       PIC X(10).
          05 WS-LAST-UPDATE         PIC X(10).
       
       01 WS-SEARCH-CRITERIA.
          05 WS-SEARCH-DESCRIPTION  PIC X(100) VALUE SPACES.
          05 WS-SEARCH-STATUS       PIC X(10) VALUE SPACES.
          05 WS-SEARCH-MIN-TIME     PIC 9(4) VALUE ZEROS.
          05 WS-SEARCH-MAX-TIME     PIC 9(4) VALUE 9999.
       
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
       01 WS-TEMP-NUMERIC-VALUE     PIC 9(4).

       01 WS-ESTIMATED-TIME-JSON    PIC X(20).

       01 WS-FORMATTED-NUMERIC.
          05 WS-FMT-ESTIMATED-TIME  PIC ZZZ9.

       01 WS-TRIMMED-FIELD-NAME     PIC X(25).
       01 WS-FIELD-NAME-LEN         PIC 9(2) COMP.
       
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
                   PERFORM GET-TODO
               WHEN "CREATE"
                   PERFORM CREATE-TODO
               WHEN "UPDATE"
                   PERFORM UPDATE-TODO
               WHEN "DELETE"
                   PERFORM DELETE-TODO
               WHEN "LIST"
                   PERFORM LIST-TODOS
               WHEN "SEARCH"
                   PERFORM SEARCH-TODOS
               WHEN OTHER
                   MOVE "Invalid operation" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
           END-EVALUATE.
       
       PARSE-JSON-REQUEST.
           PERFORM EXTRACT-OPERATION
           EVALUATE WS-OPERATION
               WHEN "GET"
               WHEN "DELETE"
                   PERFORM EXTRACT-ID
               WHEN "CREATE"
               WHEN "UPDATE"
                   PERFORM EXTRACT-ID
                   PERFORM EXTRACT-TODO-DATA
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
       
       EXTRACT-TODO-DATA.
           MOVE SPACES TO WS-TODO
           MOVE WS-ID TO WS-TODO-ID
           
           *> Extract description field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:15) = '"description":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 15 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-DESCRIPTION
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-DESCRIPTION
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-DESCRIPTION(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           *> Extract dueDate field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:11) = '"dueDate":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 11 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-DUE-DATE
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-DUE-DATE
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-DUE-DATE(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           *> Extract estimatedTime field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:16) = '"estimatedTime":'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 16 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-TEMP
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = ','
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '}'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-TEMP
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-TEMP(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
               
               MOVE FUNCTION NUMVAL(WS-TEMP) TO WS-ESTIMATED-TIME
           END-IF
           
           *> Extract status field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:10) = '"status":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 10 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-STATUS
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-STATUS
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-STATUS(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           MOVE WS-FORMATTED-DATE TO WS-LAST-UPDATE
           
           IF WS-OPERATION = "CREATE"
               MOVE WS-FORMATTED-DATE TO WS-CREATION-DATE
               IF WS-STATUS = SPACES
                   MOVE "PENDING" TO WS-STATUS
               END-IF
           END-IF.
       
       EXTRACT-SEARCH-CRITERIA.
           INITIALIZE WS-SEARCH-CRITERIA
           
           *> Set default values for search criteria
           MOVE SPACES TO WS-SEARCH-DESCRIPTION
           MOVE SPACES TO WS-SEARCH-STATUS
           MOVE 0 TO WS-SEARCH-MIN-TIME
           MOVE 9999 TO WS-SEARCH-MAX-TIME
           
           *> Extract status field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:10) = '"status":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 10 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-SEARCH-STATUS
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-SEARCH-STATUS
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-SEARCH-STATUS(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           *> Extract minTime field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:10) = '"minTime":'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 10 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-TEMP
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = ','
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '}'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-TEMP
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-TEMP(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
               
               IF WS-TEMP NOT = SPACES
                   MOVE FUNCTION NUMVAL(WS-TEMP) TO WS-SEARCH-MIN-TIME
               END-IF
           END-IF
           
           *> Extract maxTime field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:10) = '"maxTime":'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 10 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-TEMP
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = ','
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '}'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-TEMP
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-TEMP(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
               
               IF WS-TEMP NOT = SPACES
                   MOVE FUNCTION NUMVAL(WS-TEMP) TO WS-SEARCH-MAX-TIME
               END-IF
           END-IF
           
           *> Extract estimatedTime field (if present, use it for both min and max)
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:16) = '"estimatedTime":'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 16 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-TEMP
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = ','
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '}'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-TEMP
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-TEMP(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
               
               IF WS-TEMP NOT = SPACES
                   MOVE FUNCTION NUMVAL(WS-TEMP) TO WS-SEARCH-MIN-TIME
                   MOVE FUNCTION NUMVAL(WS-TEMP) TO WS-SEARCH-MAX-TIME
               END-IF
           END-IF.
           
       GET-TODO.
           OPEN INPUT TODO-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open todo file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE TODO-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO TF-TODO-ID
           
           READ TODO-FILE
               INVALID KEY
                   MOVE "Todo item not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   MOVE 1 TO WS-SUCCESS-FLAG
                   PERFORM GENERATE-TODO-JSON
           END-READ
           
           CLOSE TODO-FILE.
       
       CREATE-TODO.
           OPEN I-O TODO-FILE
               
           IF FILE-STATUS = "35" *> File doesn't exist, open for OUTPUT first
               CLOSE TODO-FILE *> Close attempt to open I-O
               OPEN OUTPUT TODO-FILE *> Open to create it
               IF FILE-STATUS NOT = "00"
                   MOVE "Failed to create todo file" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                   EXIT PARAGRAPH *> Cannot proceed
               END-IF
               CLOSE TODO-FILE *> Close OUTPUT
               OPEN I-O TODO-FILE *> Re-open I-O now that file exists
           END-IF
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open todo file for I-O" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE TODO-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO TF-TODO-ID
           
           READ TODO-FILE *> Check if exists
               INVALID KEY
                   CONTINUE *> Good, doesn't exist, proceed to write
               NOT INVALID KEY
                   MOVE "Todo ID already exists" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                   CLOSE TODO-FILE
                   EXIT PARAGRAPH
           END-READ
    
           MOVE WS-TODO-ID TO TF-TODO-ID
           MOVE WS-DESCRIPTION TO TF-DESCRIPTION
           MOVE WS-DUE-DATE TO TF-DUE-DATE
           MOVE WS-ESTIMATED-TIME TO TF-ESTIMATED-TIME
           MOVE WS-STATUS TO TF-STATUS
           MOVE WS-CREATION-DATE TO TF-CREATION-DATE
           MOVE WS-LAST-UPDATE TO TF-LAST-UPDATE
           
           WRITE TODO-RECORD
               INVALID KEY
                   MOVE "Failed to write new todo record" TO 
                       WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   MOVE 1 TO WS-SUCCESS-FLAG
                   STRING '{"success":true,"message":'
                          '"Todo item created",'
                          '"id":' DELIMITED BY SIZE
                          WS-TODO-ID DELIMITED BY SIZE
                          '}' DELIMITED BY SIZE
                       INTO WS-RESPONSE
           END-WRITE
           
           CLOSE TODO-FILE.
       
       UPDATE-TODO.
           OPEN I-O TODO-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open todo file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE TODO-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO TF-TODO-ID
           
           READ TODO-FILE
               INVALID KEY
                   MOVE "Todo item not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   MOVE WS-DESCRIPTION TO TF-DESCRIPTION
                   MOVE WS-DUE-DATE TO TF-DUE-DATE
                   MOVE WS-ESTIMATED-TIME TO TF-ESTIMATED-TIME
                   MOVE WS-STATUS TO TF-STATUS
                   MOVE WS-LAST-UPDATE TO TF-LAST-UPDATE
                   
                   REWRITE TODO-RECORD
                       INVALID KEY
                           MOVE "Failed to update todo item" TO 
                               WS-ERROR-MESSAGE
                           PERFORM GENERATE-ERROR-RESPONSE
                       NOT INVALID KEY
                           MOVE 1 TO WS-SUCCESS-FLAG
                           STRING '{"success":true,"message":"Todo item updated",'
                                  '"id":' DELIMITED BY SIZE
                                  WS-TODO-ID DELIMITED BY SIZE
                                  '}' DELIMITED BY SIZE
                               INTO WS-RESPONSE
                   END-REWRITE
           END-READ
           
           CLOSE TODO-FILE.
       
       DELETE-TODO.
           OPEN I-O TODO-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open todo file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE TODO-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO TF-TODO-ID
           
           READ TODO-FILE
               INVALID KEY
                   MOVE "Todo item not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   DELETE TODO-FILE
                       INVALID KEY
                           MOVE "Failed to delete todo item" TO 
                               WS-ERROR-MESSAGE
                           PERFORM GENERATE-ERROR-RESPONSE
                       NOT INVALID KEY
                           MOVE 1 TO WS-SUCCESS-FLAG
                           STRING '{"success":true,"message":"' DELIMITED BY SIZE
                                  'Todo item deleted",' DELIMITED BY SIZE
                                  '"id":"' DELIMITED BY SIZE
                                  WS-TODO-ID DELIMITED BY SIZE
                                  '"}' DELIMITED BY SIZE
                               INTO WS-RESPONSE
                   END-DELETE
           END-READ
           
           CLOSE TODO-FILE.
       
       LIST-TODOS.
           OPEN INPUT TODO-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open todo file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE TODO-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE 1 TO WS-JSON-PARSING-IDX *> Initialize pointer
           STRING '{"todos":[' DELIMITED BY SIZE
               INTO WS-RESPONSE
               POINTER WS-JSON-PARSING-IDX *> Update pointer
           END-STRING
           
           MOVE 1 TO WS-SUCCESS-FLAG
           MOVE 0 TO WS-NUMERIC-TEMP *> Counter for records found
           
           MOVE LOW-VALUES TO TF-TODO-ID
           START TODO-FILE KEY >= TF-TODO-ID
               INVALID KEY
                   *> No records or error starting, close the array
                   STRING ']}' DELIMITED BY SIZE
                       INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
                   END-STRING
                   CLOSE TODO-FILE
                   EXIT PARAGRAPH *> Exit cleanly if no records
               NOT INVALID KEY
                   CONTINUE *> Start successful, proceed to read loop
           END-START
           
           PERFORM UNTIL FILE-STATUS NOT = "00"
               READ TODO-FILE NEXT
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
                       
                       MOVE TF-ESTIMATED-TIME TO WS-FMT-ESTIMATED-TIME
                       MOVE FUNCTION TRIM(WS-FMT-ESTIMATED-TIME) 
                           TO WS-ESTIMATED-TIME-JSON
                       
                       STRING '{'                              DELIMITED BY SIZE
                              '"id":'                          DELIMITED BY SIZE
                              TF-TODO-ID                       DELIMITED BY SIZE
                              ',"description":"'               DELIMITED BY SIZE
                              FUNCTION TRIM(TF-DESCRIPTION)    DELIMITED BY SIZE
                              '","dueDate":"'                  DELIMITED BY SIZE
                              FUNCTION TRIM(TF-DUE-DATE)       DELIMITED BY SIZE
                              '","estimatedTime":'             DELIMITED BY SIZE
                              FUNCTION TRIM(WS-ESTIMATED-TIME-JSON) DELIMITED BY SIZE
                              ',"status":"'                    DELIMITED BY SIZE
                              FUNCTION TRIM(TF-STATUS)         DELIMITED BY SIZE
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
               
           CLOSE TODO-FILE.
       
       SEARCH-TODOS.
           OPEN INPUT TODO-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open todo file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE TODO-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE '{"todos":[' TO WS-RESPONSE
           MOVE 11 TO WS-JSON-PARSING-IDX
           MOVE 1 TO WS-SUCCESS-FLAG
           MOVE 0 TO WS-NUMERIC-TEMP
           
           MOVE LOW-VALUES TO TF-TODO-ID
           START TODO-FILE KEY >= TF-TODO-ID
               INVALID KEY
                   STRING ']}' DELIMITED BY SIZE
                       INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
                   CLOSE TODO-FILE
                   EXIT PARAGRAPH
           END-START
           
           PERFORM UNTIL FILE-STATUS NOT = "00"
               READ TODO-FILE NEXT
                   AT END
                       EXIT PERFORM
                   NOT AT END
                       PERFORM CHECK-SEARCH-MATCH
                       IF WS-SEARCH-MATCH-FLAG = 1
                           IF WS-NUMERIC-TEMP > 0
                               STRING ',' DELIMITED BY SIZE
                                   INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
                               ADD 1 TO WS-JSON-PARSING-IDX
                           END-IF
                           
                           ADD 1 TO WS-NUMERIC-TEMP
                           
                           MOVE TF-ESTIMATED-TIME TO WS-FMT-ESTIMATED-TIME
                           MOVE FUNCTION TRIM(WS-FMT-ESTIMATED-TIME) 
                               TO WS-ESTIMATED-TIME-JSON
                           
                           STRING '{"id":' DELIMITED BY SIZE
                                  TF-TODO-ID DELIMITED BY SIZE
                                  ',"description":"' DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-DESCRIPTION) DELIMITED BY SIZE
                                  '","dueDate":"' DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-DUE-DATE) DELIMITED BY SIZE
                                  '","estimatedTime":' DELIMITED BY SIZE
                                  FUNCTION TRIM(WS-ESTIMATED-TIME-JSON) DELIMITED BY SIZE
                                  ',"status":"' DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-STATUS) DELIMITED BY SIZE
                                  '"}' DELIMITED BY SIZE
                               INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
                           
                           COMPUTE WS-JSON-PARSING-IDX = 
                               WS-JSON-PARSING-IDX + 
                               FUNCTION LENGTH(FUNCTION TRIM(WS-RESPONSE(WS-JSON-PARSING-IDX:)))
                       END-IF
               END-READ
           END-PERFORM
           
           STRING ']}' DELIMITED BY SIZE
               INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
               
           CLOSE TODO-FILE.
       
       CHECK-SEARCH-MATCH.
           MOVE 1 TO WS-SEARCH-MATCH-FLAG
           
           *> Check status match if status is provided
           IF WS-SEARCH-STATUS NOT = SPACES
               IF FUNCTION TRIM(TF-STATUS) NOT = FUNCTION TRIM(WS-SEARCH-STATUS)
                   MOVE 0 TO WS-SEARCH-MATCH-FLAG
               END-IF
           END-IF
           
           *> Check time range match
           IF WS-SEARCH-MATCH-FLAG = 1
               IF TF-ESTIMATED-TIME < WS-SEARCH-MIN-TIME OR 
                  TF-ESTIMATED-TIME > WS-SEARCH-MAX-TIME
                   MOVE 0 TO WS-SEARCH-MATCH-FLAG
               END-IF
           END-IF.
       
       GENERATE-TODO-JSON.
           MOVE TF-ESTIMATED-TIME TO WS-FMT-ESTIMATED-TIME
           MOVE FUNCTION TRIM(WS-FMT-ESTIMATED-TIME) TO WS-ESTIMATED-TIME-JSON
           
           STRING '{"id":' DELIMITED BY SIZE
                  TF-TODO-ID DELIMITED BY SIZE
                  ',"description":"' DELIMITED BY SIZE
                  FUNCTION TRIM(TF-DESCRIPTION) DELIMITED BY SIZE
                  '","dueDate":"' DELIMITED BY SIZE
                  FUNCTION TRIM(TF-DUE-DATE) DELIMITED BY SIZE
                  '","estimatedTime":' DELIMITED BY SIZE
                  FUNCTION TRIM(WS-ESTIMATED-TIME-JSON) DELIMITED BY SIZE
                  ',"status":"' DELIMITED BY SIZE
                  FUNCTION TRIM(TF-STATUS) DELIMITED BY SIZE
                  '","creationDate":"' DELIMITED BY SIZE
                  FUNCTION TRIM(TF-CREATION-DATE) DELIMITED BY SIZE
                  '","lastUpdate":"' DELIMITED BY SIZE
                  FUNCTION TRIM(TF-LAST-UPDATE) DELIMITED BY SIZE
                  '"}' DELIMITED BY SIZE
               INTO WS-RESPONSE.
       
       GENERATE-ERROR-RESPONSE.
           STRING '{"success":false,"error":"' DELIMITED BY SIZE
                  FUNCTION TRIM(WS-ERROR-MESSAGE) DELIMITED BY SIZE
                  '"}' DELIMITED BY SIZE
               INTO WS-RESPONSE.
       
       CLEANUP-AND-EXIT.
           DISPLAY WS-RESPONSE.

