       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMBINED-PROGRAM.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TODO-FILE ASSIGN TO EXTERNAL DD_TODO_FILE
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS TF-TODO-ID
           FILE STATUS IS TODO-FILE-STATUS.
           
           SELECT USER-FILE ASSIGN TO EXTERNAL DD_USER_FILE
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS UF-USER-ID
           ALTERNATE RECORD KEY IS UF-EMAIL WITH DUPLICATES
           FILE STATUS IS USER-FILE-STATUS.

           SELECT SEQUENCE-FILE ASSIGN TO EXTERNAL DD_SEQUENCE_FILE
           ORGANIZATION IS LINE SEQUENTIAL
           ACCESS MODE IS SEQUENTIAL
           FILE STATUS IS SEQUENCE-FILE-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD TODO-FILE.
       01 TODO-RECORD.
          05 TF-TODO-ID             PIC 9(5).
          05 TF-USER-ID             PIC 9(5).
          05 TF-DESCRIPTION         PIC X(100).
          05 TF-DUE-DATE            PIC X(10).
          05 TF-ESTIMATED-TIME      PIC 9(4).
          05 TF-STATUS              PIC X(20).
          05 TF-CREATION-DATE       PIC X(10).
          05 TF-LAST-UPDATE         PIC X(10).
          
       FD USER-FILE.
       01 USER-RECORD.
          05 UF-USER-ID             PIC 9(5).
          05 UF-USERNAME            PIC X(50).
          05 UF-EMAIL               PIC X(100).
          05 UF-PASSWORD            PIC X(100).
          05 UF-CREATION-DATE       PIC X(10).
          05 UF-LAST-UPDATE         PIC X(10).
       
       FD SEQUENCE-FILE.
       01 SEQUENCE-RECORD.
          05 SF-NEXT-ID             PIC 9(5). *> Matches TF-TODO-ID size
       
       WORKING-STORAGE SECTION.
       01 TODO-FILE-STATUS          PIC XX VALUE SPACES.
       01 USER-FILE-STATUS          PIC XX VALUE SPACES.
       01 SEQUENCE-FILE-STATUS      PIC XX VALUE SPACES.

       01 WS-DEBUG-MESSAGE          PIC X(1000) VALUE SPACES.
       01 WS-INPUT-BUFFER           PIC X(20000).
       01 WS-OPERATION              PIC X(15).
       01 WS-ID                     PIC 9(5).
       
       01 WS-TODO.
          05 WS-TODO-ID             PIC 9(5).
          05 WS-USER-ID             PIC 9(5).
          05 WS-DESCRIPTION         PIC X(100).
          05 WS-DUE-DATE            PIC X(10).
          05 WS-ESTIMATED-TIME      PIC 9(4).
          05 WS-STATUS              PIC X(20).
          05 WS-CREATION-DATE       PIC X(10).
          05 WS-LAST-UPDATE         PIC X(10).
       
       01 WS-USER.
          05 WS-USER-ID             PIC 9(5).
          05 WS-USERNAME            PIC X(50).
          05 WS-EMAIL               PIC X(100).
          05 WS-PASSWORD            PIC X(100).
          05 WS-CREATION-DATE       PIC X(10).
          05 WS-LAST-UPDATE         PIC X(10).
       
       01 WS-SEARCH-CRITERIA.
          05 WS-SEARCH-USER-ID      PIC 9(5) VALUE ZEROS.
          05 WS-SEARCH-DESCRIPTION  PIC X(100) VALUE SPACES.
          05 WS-SEARCH-STATUS       PIC X(20) VALUE SPACES.
          05 WS-SEARCH-MIN-TIME     PIC 9(4) VALUE ZEROS.
          05 WS-SEARCH-MAX-TIME     PIC 9(4) VALUE 9999.
       
       01 WS-RESPONSE               PIC X(20000).
       
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
       01 WS-ESTIMATED-TIME-JSON    PIC X(20).
       01 WS-FORMATTED-NUMERIC.
          05 WS-FMT-ESTIMATED-TIME  PIC ZZZ9.
          05 WS-FMT-ID              PIC Z(4)9.
          05 WS-FMT-USER-ID         PIC Z(4)9.


       01 WS-JSON-TEMP              PIC X(100).
       01 WS-USER-ID-JSON           PIC X(20).
       01 WS-TODO-ID-JSON           PIC X(20).

       01 WS-NUMERIC-RESULT           PIC 9(5) VALUE 0.
       01 WS-NUMERIC-VALID-FLAG       PIC 9 VALUE 0.
       
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
           MOVE SPACES TO WS-DEBUG-MESSAGE
           MOVE 0 TO WS-SUCCESS-FLAG
           MOVE SPACES TO WS-OPERATION
           MOVE 0 TO WS-ID
           INITIALIZE WS-TODO
           INITIALIZE WS-USER
           INITIALIZE WS-SEARCH-CRITERIA
           
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
               *> Todo operations
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
               
               *> User operations
               WHEN "GET_USER"
                   PERFORM GET-USER
               WHEN "CREATE_USER"
                   PERFORM CREATE-USER
               WHEN "UPDATE_USER"
                   PERFORM UPDATE-USER
               WHEN "DELETE_USER"
                   PERFORM DELETE-USER
               WHEN "LIST_USERS"
                   PERFORM LIST-USERS
               WHEN "LOGIN"
                   PERFORM LOGIN-USER
               WHEN OTHER
                   MOVE "Invalid operation" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
           END-EVALUATE.
       
       PARSE-JSON-REQUEST.
           
           PERFORM EXTRACT-OPERATION
           
           *> Validate operation before proceeding
           IF WS-OPERATION = SPACES
               MOVE "Missing or invalid operation" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               EXIT PARAGRAPH
           END-IF
           
           EVALUATE WS-OPERATION
               WHEN "GET"
               WHEN "DELETE"
                   PERFORM EXTRACT-ID
                   IF WS-ID = 0 OR WS-ID = SPACES
                       MOVE "Invalid ID parameter" TO WS-ERROR-MESSAGE
                       PERFORM GENERATE-ERROR-RESPONSE
                       EXIT PARAGRAPH
                   END-IF
               WHEN "CREATE"
                   *> ID is now generated, don't extract it from input
                   PERFORM EXTRACT-TODO-DATA
               WHEN "UPDATE"
                   PERFORM EXTRACT-ID *> Still need ID for update
                   IF WS-ID = 0 OR WS-ID = SPACES
                       MOVE "Invalid ID parameter" TO WS-ERROR-MESSAGE
                       PERFORM GENERATE-ERROR-RESPONSE
                       EXIT PARAGRAPH
                   END-IF
                   PERFORM EXTRACT-TODO-DATA
               WHEN "SEARCH"
               WHEN "LIST"
                   PERFORM EXTRACT-SEARCH-CRITERIA
               WHEN "GET_USER"
               WHEN "DELETE_USER"
                   PERFORM EXTRACT-ID
                   IF WS-ID = 0 OR WS-ID = SPACES
                       MOVE "Invalid ID parameter" TO WS-ERROR-MESSAGE
                       PERFORM GENERATE-ERROR-RESPONSE
                       EXIT PARAGRAPH
                   END-IF
               WHEN "CREATE_USER"
               WHEN "UPDATE_USER"
                   PERFORM EXTRACT-USER-DATA
               WHEN "LOGIN"
                   PERFORM EXTRACT-LOGIN-DATA
                   IF WS-EMAIL OF WS-USER = SPACES
                       MOVE "Missing email parameter" TO WS-ERROR-MESSAGE
                       PERFORM GENERATE-ERROR-RESPONSE
                       EXIT PARAGRAPH
                   END-IF
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
           
           MOVE 0 TO WS-NUMERIC-TEMP
           
           PERFORM VARYING WS-NUMERIC-TEMP FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF 
                   WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP
                - 1:1) = '"'
               
               IF WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP - 1 <= LENGTH OF WS-INPUT-BUFFER
                   AND WS-NUMERIC-TEMP <= LENGTH OF WS-OPERATION
                   MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + 
                       WS-NUMERIC-TEMP - 1:1)
                       TO WS-OPERATION(WS-NUMERIC-TEMP:1)
               ELSE
                   EXIT PERFORM
               END-IF
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
           
           *> Skip past the key
           IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:6) = '"id":"'
               ADD 6 TO WS-JSON-PARSING-IDX
           ELSE
               ADD 5 TO WS-JSON-PARSING-IDX
           END-IF
           
           *> Skip any spaces after the colon
           PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) NOT = SPACE
               ADD 1 TO WS-JSON-PARSING-IDX
           END-PERFORM
           
           *> Extract only numeric characters
           MOVE SPACES TO WS-TEMP
           MOVE 0 TO WS-NUMERIC-TEMP
           
           PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = ','
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '}'
               
               *> Only collect numeric characters
               IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) IS NUMERIC
                   MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                       TO WS-TEMP(WS-NUMERIC-TEMP + 1:1)
               END-IF
               
               ADD 1 TO WS-NUMERIC-TEMP
           END-PERFORM
           
           *> Convert to numeric if valid
           IF FUNCTION TRIM(WS-TEMP) IS NUMERIC AND 
              FUNCTION LENGTH(FUNCTION TRIM(WS-TEMP)) > 0
               MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-TEMP)) TO WS-ID
               *> DISPLAY "DEBUG: Valid numeric ID extracted: " WS-ID
           ELSE
               *> DISPLAY "DEBUG: Invalid or non-numeric ID"
               MOVE 0 TO WS-ID
               MOVE "Invalid ID parameter" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               EXIT PARAGRAPH
           END-IF.

       EXTRACT-TODO-DATA.
           MOVE SPACES TO WS-TODO

           MOVE SPACES TO WS-DEBUG-MESSAGE
           STRING "Raw input buffer: " WS-INPUT-BUFFER(1:100)
               DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
           PERFORM DISPLAY-DEBUG

           *> Extract user ID field with more robust approach
           MOVE 0 TO WS-USER-ID OF WS-TODO
           
           *> Improved userId extraction - check for multiple formats
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER - 8
               
               *> Check for userId in various formats (with/without quotes, with/without spaces)
               IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:9) = '"userId":' OR
                  WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:8) = '"userId"' OR
                  WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:8) = 'userId":' OR
                  WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:7) = 'userId:'
                   
                   MOVE SPACES TO WS-DEBUG-MESSAGE
                   STRING "Found userId key at position " WS-JSON-PARSING-IDX
                       DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                   PERFORM DISPLAY-DEBUG
                   
                   *> Find the colon that separates key from value
                   PERFORM VARYING WS-NUMERIC-TEMP FROM 0 BY 1
                       UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > 
                           LENGTH OF WS-INPUT-BUFFER
                       OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = ':'
                       CONTINUE
                   END-PERFORM
                   
                   IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = ':'
                       *> Found the colon, now position after it
                       COMPUTE WS-JSON-PARSING-IDX = 
                           WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP + 1
                       
                       *> Skip any spaces after the colon
                       PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                         OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) NOT = SPACE
                           ADD 1 TO WS-JSON-PARSING-IDX
                       END-PERFORM
                       
                       *> Check if the value is quoted
                       IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '"'
                           ADD 1 TO WS-JSON-PARSING-IDX *> Skip opening quote
                       END-IF
                       
                       *> Extract the numeric value directly
                       MOVE SPACES TO WS-TEMP
                       MOVE 0 TO WS-NUMERIC-TEMP *> Use as index for WS-TEMP
                       
                       PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                           *> Stop at comma, closing brace, or closing quote
                           OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = ','
                           OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '}'
                           OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '"'
                           
                           *> Only collect numeric characters
                           IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) IS NUMERIC
                               ADD 1 TO WS-NUMERIC-TEMP
                               IF WS-NUMERIC-TEMP <= LENGTH OF WS-TEMP
                                   MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1)
                                       TO WS-TEMP(WS-NUMERIC-TEMP:1)
                               END-IF
                           END-IF
                           
                           ADD 1 TO WS-JSON-PARSING-IDX *> Move to next character
                       END-PERFORM
                       
                       MOVE SPACES TO WS-DEBUG-MESSAGE
                       STRING "Extracted userId string: '" FUNCTION TRIM(WS-TEMP) "'"
                           DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                       PERFORM DISPLAY-DEBUG
                       
                       *> Validate and convert the trimmed numeric string
                       IF FUNCTION TRIM(WS-TEMP) IS NUMERIC AND
                          FUNCTION LENGTH(FUNCTION TRIM(WS-TEMP)) > 0
                           MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-TEMP))
                               TO WS-USER-ID OF WS-TODO
                           
                           MOVE SPACES TO WS-DEBUG-MESSAGE
                           STRING "Valid numeric userId extracted: "
                               WS-USER-ID OF WS-TODO
                               DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                           PERFORM DISPLAY-DEBUG
                           
                           EXIT PERFORM *> Found it, exit the search loop
                       ELSE
                           MOVE SPACES TO WS-DEBUG-MESSAGE
                           STRING "Non-numeric or empty userId found"
                               DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                           PERFORM DISPLAY-DEBUG
                       END-IF
                   END-IF
               END-IF
           END-PERFORM
           
           IF WS-USER-ID OF WS-TODO = 0
               MOVE SPACES TO WS-DEBUG-MESSAGE
               STRING "No valid userId found in input after full scan"
                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
               PERFORM DISPLAY-DEBUG
           ELSE
               MOVE SPACES TO WS-DEBUG-MESSAGE
               STRING "Final userId value before use: " WS-USER-ID OF WS-TODO
                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
               PERFORM DISPLAY-DEBUG
           END-IF

           *> Extract description field (Keep existing logic)
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:15) = '"description":"'
               CONTINUE
           END-PERFORM

           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 15 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-DESCRIPTION OF WS-TODO
               MOVE 0 TO WS-NUMERIC-TEMP

               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'

                   IF WS-NUMERIC-TEMP < LENGTH OF WS-DESCRIPTION OF WS-TODO
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-DESCRIPTION OF WS-TODO(WS-NUMERIC-TEMP + 1:1)
                   END-IF

                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF

           *> Extract dueDate field (Keep existing logic)
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:11) = '"dueDate":"'
               CONTINUE
           END-PERFORM

           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 11 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-DUE-DATE OF WS-TODO
               MOVE 0 TO WS-NUMERIC-TEMP

               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'

                   IF WS-NUMERIC-TEMP < LENGTH OF WS-DUE-DATE OF WS-TODO
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-DUE-DATE OF WS-TODO(WS-NUMERIC-TEMP + 1:1)
                   END-IF

                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF

           *> Extract estimatedTime field (Robust extraction)
           MOVE 0 TO WS-ESTIMATED-TIME OF WS-TODO *> Initialize
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:16) = '"estimatedTime":'
               CONTINUE
           END-PERFORM

           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 16 TO WS-JSON-PARSING-IDX
               *> Skip spaces before value
               PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                 OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) NOT = SPACE
                   ADD 1 TO WS-JSON-PARSING-IDX
               END-PERFORM

               MOVE SPACES TO WS-TEMP
               MOVE 0 TO WS-NUMERIC-TEMP *> Index for WS-TEMP

               PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = ','
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '}'
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '"' *> Handle if quoted

                   IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) IS NUMERIC
                       ADD 1 TO WS-NUMERIC-TEMP
                       IF WS-NUMERIC-TEMP <= LENGTH OF WS-TEMP
                           MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1)
                               TO WS-TEMP(WS-NUMERIC-TEMP:1)
                       END-IF
                   END-IF
                   ADD 1 TO WS-JSON-PARSING-IDX
               END-PERFORM

               IF FUNCTION TRIM(WS-TEMP) IS NUMERIC AND
                  FUNCTION LENGTH(FUNCTION TRIM(WS-TEMP)) > 0
                   MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-TEMP))
                       TO WS-ESTIMATED-TIME OF WS-TODO
               END-IF
           END-IF

           *> Extract status field (Keep existing logic)
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:10) = '"status":"'
               CONTINUE
           END-PERFORM

           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 10 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-STATUS OF WS-TODO
               MOVE 0 TO WS-NUMERIC-TEMP

               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'

                   IF WS-NUMERIC-TEMP < LENGTH OF WS-STATUS OF WS-TODO
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-STATUS OF WS-TODO(WS-NUMERIC-TEMP + 1:1)
                   END-IF

                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF

           MOVE WS-FORMATTED-DATE TO WS-LAST-UPDATE OF WS-TODO

           IF WS-OPERATION = "CREATE"
               MOVE WS-FORMATTED-DATE TO WS-CREATION-DATE OF WS-TODO
               IF WS-STATUS OF WS-TODO = SPACES
                   MOVE "PENDING" TO WS-STATUS OF WS-TODO
               END-IF
           END-IF.
       
       EXTRACT-USER-DATA.
           MOVE SPACES TO WS-USER
           
           *> Extract ID if provided (for update)
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:6) = '"id":"'
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:5) = '"id":'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:6) = '"id":"'
                   ADD 6 TO WS-JSON-PARSING-IDX
               ELSE
                   ADD 5 TO WS-JSON-PARSING-IDX
               END-IF
               
               MOVE SPACES TO WS-TEMP
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP - 1:1) = '"'
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP - 1:1) = ','
                   
                   IF WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP - 1 <= LENGTH OF WS-INPUT-BUFFER
                      AND WS-NUMERIC-TEMP < LENGTH OF WS-TEMP
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP - 1:1)
                           TO WS-TEMP(WS-NUMERIC-TEMP:1)
                   ELSE
                       EXIT PERFORM
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
               
               MOVE WS-TEMP TO WS-USER-ID OF WS-USER
           END-IF
           
           *> Extract username
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:12) = '"username":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 12 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-USERNAME OF WS-USER
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP <= LENGTH OF WS-INPUT-BUFFER
                      AND WS-NUMERIC-TEMP < LENGTH OF WS-USERNAME OF WS-USER
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-USERNAME OF WS-USER(WS-NUMERIC-TEMP + 1:1)
                   ELSE
                       EXIT PERFORM
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           *> Extract email
           *>*> DISPLAY  "DEBUG: Extracting email"
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:9) = '"email":"'
               CONTINUE
           END-PERFORM   
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 9 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-EMAIL OF WS-USER
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP <= LENGTH OF WS-INPUT-BUFFER
                      AND WS-NUMERIC-TEMP < LENGTH OF WS-EMAIL OF WS-USER
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-EMAIL OF WS-USER(WS-NUMERIC-TEMP + 1:1)
                   ELSE
                       EXIT PERFORM
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
               
           END-IF
           
           *> Extract password
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:12) = '"password":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 12 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-PASSWORD OF WS-USER
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP <= LENGTH OF WS-INPUT-BUFFER
                      AND WS-NUMERIC-TEMP < LENGTH OF WS-PASSWORD OF WS-USER
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-PASSWORD OF WS-USER(WS-NUMERIC-TEMP + 1:1)
                   ELSE
                       EXIT PERFORM
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           MOVE WS-FORMATTED-DATE TO WS-LAST-UPDATE OF WS-USER
           
           IF WS-OPERATION = "CREATE_USER"
               MOVE WS-FORMATTED-DATE TO WS-CREATION-DATE OF WS-USER
           END-IF.
       
       EXTRACT-LOGIN-DATA.
           MOVE SPACES TO WS-USER
           
           *> Extract email
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:9) = '"email":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 9 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-EMAIL OF WS-USER
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-EMAIL OF WS-USER
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-EMAIL OF WS-USER(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           *> Extract password
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:12) = '"password":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 12 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-PASSWORD OF WS-USER
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-PASSWORD OF WS-USER
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-PASSWORD OF WS-USER(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF.
       
        EXTRACT-SEARCH-CRITERIA.
           INITIALIZE WS-SEARCH-CRITERIA

           *> Set default values for search criteria
           MOVE ZEROS TO WS-SEARCH-USER-ID      *> Initialize new field
           MOVE SPACES TO WS-SEARCH-DESCRIPTION *> Not used currently, but good practice
           MOVE SPACES TO WS-SEARCH-STATUS
           MOVE 0 TO WS-SEARCH-MIN-TIME
           MOVE 9999 TO WS-SEARCH-MAX-TIME

           *> Extract userId field
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER - 10

               *> Check for userId with quotes or without quotes, allowing for spaces
               IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:9) = '"userId":' OR
                  WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:8) = '"userId"' OR *> Key only, no colon yet
                  WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:8) = 'userId":' OR
                  WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:7) = 'userId:'

                   *> Find the colon that separates key from value
                   MOVE WS-JSON-PARSING-IDX TO WS-NUMERIC-TEMP *> Start search from key start
                   PERFORM UNTIL WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                       OR WS-INPUT-BUFFER(WS-NUMERIC-TEMP:1) = ':'
                       ADD 1 TO WS-NUMERIC-TEMP
                   END-PERFORM

                   IF WS-INPUT-BUFFER(WS-NUMERIC-TEMP:1) = ':'
                       *> Found the colon, now position after it
                       COMPUTE WS-JSON-PARSING-IDX = WS-NUMERIC-TEMP + 1

                       *> Skip any spaces after the colon
                       PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                         OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) NOT = SPACE
                           ADD 1 TO WS-JSON-PARSING-IDX
                       END-PERFORM

                       *> Check if the value is quoted (optional)
                       IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '"'
                           ADD 1 TO WS-JSON-PARSING-IDX *> Skip opening quote
                       END-IF

                       *> Extract the numeric value directly
                       MOVE SPACES TO WS-TEMP
                       MOVE 0 TO WS-NUMERIC-TEMP *> Use as index for WS-TEMP

                       PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                           *> Stop at comma, closing brace, or closing quote
                           OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = ','
                           OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '}'
                           OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '"'

                           *> Only collect numeric characters
                           IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) IS NUMERIC
                               ADD 1 TO WS-NUMERIC-TEMP
                               IF WS-NUMERIC-TEMP <= LENGTH OF WS-TEMP
                                   MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1)
                                       TO WS-TEMP(WS-NUMERIC-TEMP:1)
                               END-IF
                           END-IF

                           ADD 1 TO WS-JSON-PARSING-IDX *> Move to next character
                       END-PERFORM

                       *> Validate and convert the trimmed numeric string
                       IF FUNCTION TRIM(WS-TEMP) IS NUMERIC AND
                          FUNCTION LENGTH(FUNCTION TRIM(WS-TEMP)) > 0
                           MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-TEMP))
                               TO WS-SEARCH-USER-ID  *> *** Target the correct variable ***
                   END-IF
               END-IF
           END-PERFORM
           *> End of userId extraction

           *> Extract status field (Keep existing logic)
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

           *> Extract minTime field (Keep existing logic, ensure robustness)
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:10) = '"minTime":'
               CONTINUE
           END-PERFORM

           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 10 TO WS-JSON-PARSING-IDX
               *> Skip spaces
               PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                 OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) NOT = SPACE
                   ADD 1 TO WS-JSON-PARSING-IDX
               END-PERFORM

               MOVE SPACES TO WS-TEMP
               MOVE 0 TO WS-NUMERIC-TEMP

               PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = ','
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '}'

                   IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) IS NUMERIC
                       ADD 1 TO WS-NUMERIC-TEMP
                       IF WS-NUMERIC-TEMP <= LENGTH OF WS-TEMP
                           MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1)
                               TO WS-TEMP(WS-NUMERIC-TEMP:1)
                       END-IF
                   END-IF
                   ADD 1 TO WS-JSON-PARSING-IDX
               END-PERFORM

               IF FUNCTION TRIM(WS-TEMP) IS NUMERIC AND
                  FUNCTION LENGTH(FUNCTION TRIM(WS-TEMP)) > 0
                   MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-TEMP)) TO WS-SEARCH-MIN-TIME
               END-IF
           END-IF

           *> Extract maxTime field (Keep existing logic, ensure robustness)
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:10) = '"maxTime":'
               CONTINUE
           END-PERFORM

           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 10 TO WS-JSON-PARSING-IDX
               *> Skip spaces
               PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                 OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) NOT = SPACE
                   ADD 1 TO WS-JSON-PARSING-IDX
               END-PERFORM

               MOVE SPACES TO WS-TEMP
               MOVE 0 TO WS-NUMERIC-TEMP

               PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = ','
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '}'

                   IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) IS NUMERIC
                       ADD 1 TO WS-NUMERIC-TEMP
                       IF WS-NUMERIC-TEMP <= LENGTH OF WS-TEMP
                           MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1)
                               TO WS-TEMP(WS-NUMERIC-TEMP:1)
                       END-IF
                   END-IF
                   ADD 1 TO WS-JSON-PARSING-IDX
               END-PERFORM

               IF FUNCTION TRIM(WS-TEMP) IS NUMERIC AND
                  FUNCTION LENGTH(FUNCTION TRIM(WS-TEMP)) > 0
                   MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-TEMP)) TO WS-SEARCH-MAX-TIME
               END-IF
           END-IF

           *> Extract estimatedTime field (if present, use it for both min and max)
           *> (Keep existing logic, but ensure robustness similar to min/max)
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:16) = '"estimatedTime":'
               CONTINUE
           END-PERFORM

           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 16 TO WS-JSON-PARSING-IDX
               *> Skip spaces
               PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                 OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) NOT = SPACE
                   ADD 1 TO WS-JSON-PARSING-IDX
               END-PERFORM

               MOVE SPACES TO WS-TEMP
               MOVE 0 TO WS-NUMERIC-TEMP

               PERFORM UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = ','
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) = '}'

                   IF WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1) IS NUMERIC
                       ADD 1 TO WS-NUMERIC-TEMP
                       IF WS-NUMERIC-TEMP <= LENGTH OF WS-TEMP
                           MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:1)
                               TO WS-TEMP(WS-NUMERIC-TEMP:1)
                       END-IF
                   END-IF
                   ADD 1 TO WS-JSON-PARSING-IDX
               END-PERFORM

               IF FUNCTION TRIM(WS-TEMP) IS NUMERIC AND
                  FUNCTION LENGTH(FUNCTION TRIM(WS-TEMP)) > 0
                   MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-TEMP)) TO WS-SEARCH-MIN-TIME
                   MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-TEMP)) TO WS-SEARCH-MAX-TIME
               END-IF
           END-IF.
       
       *> ==================== TODO OPERATIONS ====================
       
       GET-TODO.
           OPEN INPUT TODO-FILE
           
           IF TODO-FILE-STATUS NOT = "00"
               MOVE "Failed to open todo file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE TODO-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO TF-TODO-ID
           *> DISPLAY "DEBUG: Getting todo with ID: " TF-TODO-ID
           
           READ TODO-FILE
               INVALID KEY
                   MOVE "Todo item not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   *> DISPLAY "DEBUG: Found todo item, userId: " TF-USER-ID
                   MOVE 1 TO WS-SUCCESS-FLAG
                   PERFORM GENERATE-TODO-JSON
           END-READ
           
           CLOSE TODO-FILE.
       
    CREATE-TODO.
       *> --- START: Revised ID Generation for LINE SEQUENTIAL ---
       MOVE 0 TO WS-TODO-ID OF WS-TODO *> Initialize generated ID
       MOVE 0 TO SF-NEXT-ID           *> Initialize sequence record field

       *> Attempt to read the current sequence ID
       OPEN INPUT SEQUENCE-FILE

       IF SEQUENCE-FILE-STATUS = "35" *> File doesn't exist, create it
           CLOSE SEQUENCE-FILE *> Close the failed INPUT attempt
           OPEN OUTPUT SEQUENCE-FILE
           IF SEQUENCE-FILE-STATUS NOT = "00"
               MOVE "Failed to create sequence file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE SEQUENCE-FILE *> Attempt to close
               EXIT PARAGRAPH
           END-IF
           MOVE 10001 TO SF-NEXT-ID *> Start IDs from 10001
           MOVE SF-NEXT-ID TO WS-TODO-ID OF WS-TODO *> Use the first ID
           WRITE SEQUENCE-RECORD
           IF SEQUENCE-FILE-STATUS NOT = "00"
               MOVE "Failed to write initial sequence" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE SEQUENCE-FILE
               EXIT PARAGRAPH
           END-IF
           CLOSE SEQUENCE-FILE

           *> Now, immediately write the *next* sequence number for the future
           ADD 1 TO SF-NEXT-ID
           OPEN OUTPUT SEQUENCE-FILE *> Reopen for OUTPUT to overwrite
           IF SEQUENCE-FILE-STATUS NOT = "00"
               MOVE "Failed to reopen sequence file for next ID" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE SEQUENCE-FILE
               EXIT PARAGRAPH
           END-IF
           WRITE SEQUENCE-RECORD *> Write the incremented value (e.g., 10002)
           IF SEQUENCE-FILE-STATUS NOT = "00"
               MOVE "Failed to write next sequence ID" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE SEQUENCE-FILE
               EXIT PARAGRAPH
           END-IF
           CLOSE SEQUENCE-FILE

       ELSE *> File exists, read the current ID
           IF SEQUENCE-FILE-STATUS NOT = "00"
               MOVE "Failed to open sequence file for input" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE SEQUENCE-FILE
               EXIT PARAGRAPH
           END-IF

           READ SEQUENCE-FILE *> Reads the single record (e.g., 10002)
           IF SEQUENCE-FILE-STATUS NOT = "00" AND SEQUENCE-FILE-STATUS NOT = "10" *> Allow EOF just in case
               MOVE "Failed to read sequence file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE SEQUENCE-FILE
               EXIT PARAGRAPH
           END-IF
           CLOSE SEQUENCE-FILE

           *> Assign the read ID to the new Todo
           MOVE SF-NEXT-ID TO WS-TODO-ID OF WS-TODO

           *> Increment the sequence ID for the next write
           ADD 1 TO SF-NEXT-ID

           *> Rewrite the updated sequence ID back to the file
           OPEN OUTPUT SEQUENCE-FILE *> Open for OUTPUT (overwrites)
           IF SEQUENCE-FILE-STATUS NOT = "00"
               MOVE "Failed to open sequence file for rewrite" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE SEQUENCE-FILE
               EXIT PARAGRAPH
           END-IF
           WRITE SEQUENCE-RECORD *> Write the incremented value (e.g., 10003)
           IF SEQUENCE-FILE-STATUS NOT = "00"
               MOVE "Failed to rewrite sequence file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE SEQUENCE-FILE
               EXIT PARAGRAPH
           END-IF
           CLOSE SEQUENCE-FILE
       END-IF
       *> --- END: Revised ID Generation ---


       *> Now proceed with writing the TODO record using the generated ID
       OPEN I-O TODO-FILE

       *> ... (Rest of the CREATE-TODO logic remains the same) ...
       *> Check if TODO-FILE exists (Status 35), create if needed...
       *> Check TODO-FILE open status...
       *> MOVE generated WS-TODO-ID OF WS-TODO TO TF-TODO-ID
       *> MOVE other WS-TODO fields to TF fields...
       *> WRITE TODO-RECORD...
       *> Generate success response using WS-TODO-ID OF WS-TODO...
       *> CLOSE TODO-FILE...

       IF TODO-FILE-STATUS = "35"
           CLOSE TODO-FILE
           OPEN OUTPUT TODO-FILE
           IF TODO-FILE-STATUS NOT = "00"
               MOVE "Failed to create todo file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               EXIT PARAGRAPH
           END-IF
           CLOSE TODO-FILE
           OPEN I-O TODO-FILE
       END-IF

       IF TODO-FILE-STATUS NOT = "00"
           MOVE "Failed to open todo file for I-O" TO WS-ERROR-MESSAGE
           PERFORM GENERATE-ERROR-RESPONSE
           CLOSE TODO-FILE
           EXIT PARAGRAPH
       END-IF

       MOVE WS-TODO-ID OF WS-TODO TO TF-TODO-ID *> Use the GENERATED ID

       MOVE SPACES TO WS-DEBUG-MESSAGE
       STRING "Creating todo with GENERATED ID: " WS-TODO-ID OF WS-TODO
           DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
       PERFORM DISPLAY-DEBUG

       MOVE WS-USER-ID OF WS-TODO TO TF-USER-ID
       MOVE WS-DESCRIPTION OF WS-TODO TO TF-DESCRIPTION
       MOVE WS-DUE-DATE OF WS-TODO TO TF-DUE-DATE
       MOVE WS-ESTIMATED-TIME OF WS-TODO TO TF-ESTIMATED-TIME
       MOVE WS-STATUS OF WS-TODO TO TF-STATUS
       MOVE WS-CREATION-DATE OF WS-TODO TO TF-CREATION-DATE
       MOVE WS-LAST-UPDATE OF WS-TODO TO TF-LAST-UPDATE

       WRITE TODO-RECORD
           INVALID KEY
               MOVE "Failed to create new todo record (Generated ID conflict?)" TO
                   WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
           NOT INVALID KEY
               MOVE 1 TO WS-SUCCESS-FLAG
               MOVE WS-TODO-ID OF WS-TODO TO WS-FMT-ID *> Format the generated ID

               STRING '{"success":true,"message":'
                      '"Todo item created",'
                      '"id":' DELIMITED BY SIZE
                      FUNCTION TRIM(WS-FMT-ID) DELIMITED BY SIZE *> Send back generated ID
                      '}' DELIMITED BY SIZE
                   INTO WS-RESPONSE
       END-WRITE

       CLOSE TODO-FILE.


       
       UPDATE-TODO.
           OPEN I-O TODO-FILE

           IF TODO-FILE-STATUS NOT = "00"
               MOVE "Failed to open todo file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE TODO-FILE
               EXIT PARAGRAPH
           END-IF

           MOVE WS-ID TO TF-TODO-ID

           READ TODO-FILE
               INVALID KEY
                   MOVE "Todo item not found for update" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   *> Successfully read the record, now apply updates selectively

                   *> Check if description was provided in the request
                   IF WS-DESCRIPTION OF WS-TODO NOT = SPACES
                       MOVE WS-DESCRIPTION OF WS-TODO TO TF-DESCRIPTION
                   END-IF

                   *> Check if due date was provided
                   IF WS-DUE-DATE OF WS-TODO NOT = SPACES
                       MOVE WS-DUE-DATE OF WS-TODO TO TF-DUE-DATE
                   END-IF

                   *> Check if estimated time was provided (check against initial value 0)
                   *> Note: If 0 is a valid input time, this check needs adjustment
                   IF WS-ESTIMATED-TIME OF WS-TODO > 0
                       MOVE WS-ESTIMATED-TIME OF WS-TODO TO TF-ESTIMATED-TIME
                   END-IF

                   *> Check if status was provided
                   IF WS-STATUS OF WS-TODO NOT = SPACES
                       MOVE WS-STATUS OF WS-TODO TO TF-STATUS
                   END-IF

                   *> Always update the last update timestamp
                   MOVE WS-LAST-UPDATE OF WS-TODO TO TF-LAST-UPDATE

                   *> Note: We generally don't update TF-USER-ID or TF-TODO-ID here.
                   *> If TF-CREATION-DATE update is needed, add similar check.

                  REWRITE TODO-RECORD
                      INVALID KEY
                          MOVE "Failed to rewrite updated todo item" TO
                              WS-ERROR-MESSAGE
                          PERFORM GENERATE-ERROR-RESPONSE
                      NOT INVALID KEY
                          MOVE 1 TO WS-SUCCESS-FLAG
                          MOVE TF-TODO-ID TO WS-FMT-ID
                          
                          STRING '{"success":true,"message":"Todo item updated",'
                                 '"id":' DELIMITED BY SIZE
                                 FUNCTION TRIM(WS-FMT-ID) DELIMITED BY SIZE
                                 '}' DELIMITED BY SIZE
                              INTO WS-RESPONSE
                  END-REWRITE
           END-READ

           CLOSE TODO-FILE.
       
       DELETE-TODO.
           OPEN I-O TODO-FILE
           
           IF TODO-FILE-STATUS NOT = "00"
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
                          MOVE WS-ID TO WS-FMT-ID
                          
                          STRING '{"success":true,"message":"' DELIMITED BY SIZE
                                 'Todo item deleted",' DELIMITED BY SIZE
                                 '"id":' DELIMITED BY SIZE
                                 FUNCTION TRIM(WS-FMT-ID) DELIMITED BY SIZE
                                 '}' DELIMITED BY SIZE
                             INTO WS-RESPONSE
                  END-DELETE
           END-READ
           
           CLOSE TODO-FILE.
       
       LIST-TODOS.
           MOVE SPACES TO WS-DEBUG-MESSAGE
           STRING "LIST-TODOS Input Buffer(1:100): " WS-INPUT-BUFFER(1:100)
               DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
           PERFORM DISPLAY-DEBUG

           MOVE SPACES TO WS-RESPONSE

           OPEN INPUT TODO-FILE

           IF TODO-FILE-STATUS = "35" *> File Not Found
               MOVE SPACES TO WS-DEBUG-MESSAGE
               STRING "LIST-TODOS: Todo file not found (status 35), returning empty list."
                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
               PERFORM DISPLAY-DEBUG

               MOVE 1 TO WS-SUCCESS-FLAG *> Indicate success (empty list is valid)
               STRING '{"todos":[]}' DELIMITED BY SIZE INTO WS-RESPONSE
               CLOSE TODO-FILE *> Ensure file is closed even after failed open
               EXIT PARAGRAPH  *> Exit the paragraph cleanly
           END-IF

           IF TODO-FILE-STATUS NOT = "00" *> Handle other open errors
               MOVE SPACES TO WS-DEBUG-MESSAGE
               STRING "LIST-TODOS: Failed to open todo file, status: " TODO-FILE-STATUS
                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
               PERFORM DISPLAY-DEBUG

               MOVE "Failed to open todo file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE TODO-FILE
               EXIT PARAGRAPH
           END-IF

           *> Extract user ID for filtering - IMPROVED VERSION
           *> ... (User ID extraction logic remains the same) ...

           *> Reset pointer for response
           MOVE 1 TO WS-JSON-PARSING-IDX
           STRING '{"todos":[' DELIMITED BY SIZE
               INTO WS-RESPONSE
               POINTER WS-JSON-PARSING-IDX
           END-STRING

           MOVE 1 TO WS-SUCCESS-FLAG
           MOVE 0 TO WS-NUMERIC-TEMP

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

           PERFORM UNTIL TODO-FILE-STATUS NOT = "00"
               READ TODO-FILE NEXT
                   AT END
                       EXIT PERFORM
                   NOT AT END
                   *> Filter by User ID if provided in the request
                   IF WS-SEARCH-USER-ID = 0 *> If no userId sent (allow listing all - though API currently prevents this)
                      OR TF-USER-ID = WS-SEARCH-USER-ID *> If userId matches
                           IF WS-NUMERIC-TEMP > 0 *> Add comma
                               STRING ',' DELIMITED BY SIZE
                                   INTO WS-RESPONSE
                                   POINTER WS-JSON-PARSING-IDX
                               END-STRING
                           END-IF

                           ADD 1 TO WS-NUMERIC-TEMP

                           MOVE TF-TODO-ID TO WS-FMT-ID
                           MOVE TF-USER-ID TO WS-FMT-USER-ID
                           MOVE TF-ESTIMATED-TIME TO WS-FMT-ESTIMATED-TIME
                           MOVE FUNCTION TRIM(WS-FMT-ESTIMATED-TIME)
                               TO WS-ESTIMATED-TIME-JSON
                           IF WS-ESTIMATED-TIME-JSON = SPACES
                               MOVE "0" TO WS-ESTIMATED-TIME-JSON
                           END-IF

                           *> Build JSON object for the current record
                           STRING '{'                              DELIMITED BY SIZE
                                  '"id":'                          DELIMITED BY SIZE
                                  FUNCTION TRIM(WS-FMT-ID)         DELIMITED BY SIZE
                                  ',"userId":'                     DELIMITED BY SIZE
                                  FUNCTION TRIM(WS-FMT-USER-ID)    DELIMITED BY SIZE
                                  ',"description":"'               DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-DESCRIPTION)    DELIMITED BY SIZE
                                  '","dueDate":"'                  DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-DUE-DATE)       DELIMITED BY SIZE
                                  '","estimatedTime":'             DELIMITED BY SIZE
                                  WS-ESTIMATED-TIME-JSON           DELIMITED BY SIZE
                                  ',"status":"'                    DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-STATUS)         DELIMITED BY SIZE
                                  '","creationDate":"'             DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-CREATION-DATE)  DELIMITED BY SIZE
                                  '","lastUpdate":"'               DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-LAST-UPDATE)    DELIMITED BY SIZE
                                  '"}'                             DELIMITED BY SIZE
                               INTO WS-RESPONSE
                               POINTER WS-JSON-PARSING-IDX
                           END-STRING
                       END-IF
               END-READ
           END-PERFORM

           *> Close the JSON array and object
           STRING ']}' DELIMITED BY SIZE
               INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
           END-STRING

           CLOSE TODO-FILE.
       
       SEARCH-TODOS.
           MOVE SPACES TO WS-RESPONSE

           OPEN INPUT TODO-FILE

           IF TODO-FILE-STATUS = "35" *> File Not Found
               MOVE SPACES TO WS-DEBUG-MESSAGE
               STRING "SEARCH-TODOS: Todo file not found (status 35), returning empty list."
                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
               PERFORM DISPLAY-DEBUG

               MOVE 1 TO WS-SUCCESS-FLAG *> Indicate success (empty list is valid)
               STRING '{"todos":[]}' DELIMITED BY SIZE INTO WS-RESPONSE
               CLOSE TODO-FILE *> Ensure file is closed even after failed open
               EXIT PARAGRAPH  *> Exit the paragraph cleanly
           END-IF

           IF TODO-FILE-STATUS NOT = "00" *> Handle other open errors
               MOVE SPACES TO WS-DEBUG-MESSAGE
               STRING "SEARCH-TODOS: Failed to open todo file, status: " TODO-FILE-STATUS
                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
               PERFORM DISPLAY-DEBUG

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
           MOVE 0 TO WS-NUMERIC-TEMP *> Counter for matched records

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

           PERFORM UNTIL TODO-FILE-STATUS NOT = "00"
               READ TODO-FILE NEXT
                   AT END
                       EXIT PERFORM
                   NOT AT END
                       *> Call CHECK-SEARCH-MATCH to determine if this record matches criteria
                       PERFORM CHECK-SEARCH-MATCH

                       *> Only include records that match all search criteria
                       IF WS-SEARCH-MATCH-FLAG = 1
                           IF WS-NUMERIC-TEMP > 0 *> Add comma before second+ record
                               STRING ',' DELIMITED BY SIZE
                                   INTO WS-RESPONSE
                                   POINTER WS-JSON-PARSING-IDX
                               END-STRING
                           END-IF

                           ADD 1 TO WS-NUMERIC-TEMP

                           MOVE TF-TODO-ID TO WS-FMT-ID
                           MOVE TF-USER-ID TO WS-FMT-USER-ID
                           MOVE TF-ESTIMATED-TIME TO WS-FMT-ESTIMATED-TIME
                           MOVE FUNCTION TRIM(WS-FMT-ESTIMATED-TIME)
                               TO WS-ESTIMATED-TIME-JSON
                           IF WS-ESTIMATED-TIME-JSON = SPACES
                               MOVE "0" TO WS-ESTIMATED-TIME-JSON
                           END-IF

                           *> Build JSON object for the current matching record
                           STRING '{'                              DELIMITED BY SIZE
                                  '"id":'                          DELIMITED BY SIZE
                                  FUNCTION TRIM(WS-FMT-ID)         DELIMITED BY SIZE
                                  ',"userId":'                     DELIMITED BY SIZE
                                  FUNCTION TRIM(WS-FMT-USER-ID)    DELIMITED BY SIZE
                                  ',"description":"'               DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-DESCRIPTION)    DELIMITED BY SIZE
                                  '","dueDate":"'                  DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-DUE-DATE)       DELIMITED BY SIZE
                                  '","estimatedTime":'             DELIMITED BY SIZE
      *> --- Use the formatted variable ---
                                  WS-ESTIMATED-TIME-JSON           DELIMITED BY SIZE
                                  ',"status":"'                    DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-STATUS)         DELIMITED BY SIZE
                                  '","creationDate":"'             DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-CREATION-DATE)  DELIMITED BY SIZE
                                  '","lastUpdate":"'               DELIMITED BY SIZE
                                  FUNCTION TRIM(TF-LAST-UPDATE)    DELIMITED BY SIZE
                                  '"}'                             DELIMITED BY SIZE
                               INTO WS-RESPONSE
                               POINTER WS-JSON-PARSING-IDX
                           END-STRING
                       END-IF
               END-READ
           END-PERFORM

           *> Close the JSON array and object
           STRING ']}' DELIMITED BY SIZE
               INTO WS-RESPONSE(WS-JSON-PARSING-IDX:) *> Append at current position
           END-STRING

           CLOSE TODO-FILE.
       
       CHECK-SEARCH-MATCH.
           MOVE 1 TO WS-SEARCH-MATCH-FLAG
           
           MOVE SPACES TO WS-DEBUG-MESSAGE
           STRING "Checking search match for todo ID: " TF-TODO-ID
               DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
           PERFORM DISPLAY-DEBUG
           
           *> Check userId match if userId is provided in search criteria
           IF WS-SEARCH-USER-ID > 0 *> Check if a specific user was requested
               MOVE SPACES TO WS-DEBUG-MESSAGE
               STRING "Comparing userId: " TF-USER-ID " with search userId: " 
                   WS-SEARCH-USER-ID
                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
               PERFORM DISPLAY-DEBUG
               
               IF TF-USER-ID NOT = WS-SEARCH-USER-ID
                   MOVE 0 TO WS-SEARCH-MATCH-FLAG
                   MOVE SPACES TO WS-DEBUG-MESSAGE
                   STRING "userId mismatch, skipping"
                       DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                   PERFORM DISPLAY-DEBUG
               END-IF
           END-IF
        
           *> Check status match if status is provided and userId matched
           IF WS-SEARCH-MATCH-FLAG = 1 AND WS-SEARCH-STATUS NOT = SPACES
               MOVE SPACES TO WS-DEBUG-MESSAGE
               STRING "Comparing status: '" FUNCTION TRIM(TF-STATUS) 
                   "' with search status: '" FUNCTION TRIM(WS-SEARCH-STATUS) "'"
                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
               PERFORM DISPLAY-DEBUG
               
               IF FUNCTION TRIM(TF-STATUS) NOT = FUNCTION TRIM(WS-SEARCH-STATUS)
                   MOVE 0 TO WS-SEARCH-MATCH-FLAG
                   MOVE SPACES TO WS-DEBUG-MESSAGE
                   STRING "Status mismatch, skipping"
                       DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                   PERFORM DISPLAY-DEBUG
               END-IF
           END-IF
        
           *> Check time range match if previous checks passed
           IF WS-SEARCH-MATCH-FLAG = 1
               MOVE SPACES TO WS-DEBUG-MESSAGE
               STRING "Checking time range: " TF-ESTIMATED-TIME 
                   " between " WS-SEARCH-MIN-TIME " and " WS-SEARCH-MAX-TIME
                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
               PERFORM DISPLAY-DEBUG
               
               IF TF-ESTIMATED-TIME < WS-SEARCH-MIN-TIME OR
                  TF-ESTIMATED-TIME > WS-SEARCH-MAX-TIME
                   MOVE 0 TO WS-SEARCH-MATCH-FLAG
                   MOVE SPACES TO WS-DEBUG-MESSAGE
                   STRING "Time range mismatch, skipping"
                       DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                   PERFORM DISPLAY-DEBUG
               END-IF
           END-IF
          
          IF WS-SEARCH-MATCH-FLAG = 1
              MOVE SPACES TO WS-DEBUG-MESSAGE
              STRING "Todo matched all search criteria"
                  DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
              PERFORM DISPLAY-DEBUG
          END-IF.

       GENERATE-TODO-JSON.
           MOVE TF-TODO-ID TO WS-FMT-ID
           MOVE TF-USER-ID TO WS-FMT-USER-ID
           MOVE TF-ESTIMATED-TIME TO WS-FMT-ESTIMATED-TIME
           
           MOVE FUNCTION TRIM(WS-FMT-ESTIMATED-TIME) TO WS-ESTIMATED-TIME-JSON
           
           *> Ensure estimatedTime is never empty in JSON
           IF WS-ESTIMATED-TIME-JSON = SPACES
               MOVE "0" TO WS-ESTIMATED-TIME-JSON
           END-IF
           
           *> Convert user ID to properly formatted JSON number or null if empty
           IF TF-USER-ID = SPACES OR TF-USER-ID = 0
               MOVE "null" TO WS-USER-ID-JSON
           ELSE
               MOVE FUNCTION TRIM(WS-FMT-USER-ID) TO WS-USER-ID-JSON
           END-IF
           
           STRING '{"id":' DELIMITED BY SIZE
                  FUNCTION TRIM(WS-FMT-ID) DELIMITED BY SIZE
                  ',"userId":' DELIMITED BY SIZE
                  WS-USER-ID-JSON DELIMITED BY SIZE
                  ',"description":"' DELIMITED BY SIZE
                  FUNCTION TRIM(TF-DESCRIPTION) DELIMITED BY SIZE
                  '","dueDate":"' DELIMITED BY SIZE
                  FUNCTION TRIM(TF-DUE-DATE) DELIMITED BY SIZE
                  '","estimatedTime":' DELIMITED BY SIZE
                  WS-ESTIMATED-TIME-JSON DELIMITED BY SIZE
                  ',"status":"' DELIMITED BY SIZE
                  FUNCTION TRIM(TF-STATUS) DELIMITED BY SIZE
                  '","creationDate":"' DELIMITED BY SIZE
                  FUNCTION TRIM(TF-CREATION-DATE) DELIMITED BY SIZE
                  '","lastUpdate":"' DELIMITED BY SIZE
                  FUNCTION TRIM(TF-LAST-UPDATE) DELIMITED BY SIZE
                  '"}' DELIMITED BY SIZE
               INTO WS-RESPONSE.
       
       *> ==================== USER OPERATIONS ====================

       GET-USER.
           INITIALIZE WS-USER
           MOVE 0 TO WS-SUCCESS-FLAG
           
           OPEN INPUT USER-FILE
           IF USER-FILE-STATUS NOT = "00"
               MOVE "Error opening user file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO UF-USER-ID
           
           READ USER-FILE KEY IS UF-USER-ID
               INVALID KEY
                   MOVE "User not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                   CLOSE USER-FILE
                   EXIT PARAGRAPH
           END-READ
           
           IF USER-FILE-STATUS NOT = "00"
               MOVE "Error reading user record" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE USER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE UF-USER-ID TO WS-USER-ID OF WS-USER
           MOVE UF-USERNAME TO WS-USERNAME OF WS-USER
           MOVE UF-EMAIL TO WS-EMAIL OF WS-USER
           MOVE UF-PASSWORD TO WS-PASSWORD OF WS-USER
           MOVE UF-CREATION-DATE TO WS-CREATION-DATE OF WS-USER
           MOVE UF-LAST-UPDATE TO WS-LAST-UPDATE OF WS-USER
           
           MOVE 1 TO WS-SUCCESS-FLAG
           
           PERFORM GENERATE-USER-JSON
           
           CLOSE USER-FILE.
       
       CREATE-USER.
           OPEN I-O USER-FILE
               
           IF USER-FILE-STATUS = "35" *> File doesn't exist, open for OUTPUT first
               CLOSE USER-FILE *> Close attempt to open I-O
               OPEN OUTPUT USER-FILE *> Open to create it
               IF USER-FILE-STATUS NOT = "00"
                   MOVE "Failed to create user file" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                   EXIT PARAGRAPH *> Cannot proceed
               END-IF
               CLOSE USER-FILE *> Close OUTPUT
               OPEN I-O USER-FILE *> Re-open I-O now that file exists
           END-IF
           
           IF USER-FILE-STATUS NOT = "00"
               MOVE "Failed to open user file for I-O" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE USER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-USER-ID OF WS-USER TO UF-USER-ID
           
           READ USER-FILE *> Check if exists
               INVALID KEY
                   CONTINUE *> Good, doesn't exist, proceed to write
               NOT INVALID KEY
                   MOVE "User ID already exists" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                   CLOSE USER-FILE
                   EXIT PARAGRAPH
           END-READ
    
           *> Check if email already exists
           MOVE WS-EMAIL OF WS-USER TO UF-EMAIL
           
           START USER-FILE KEY = UF-EMAIL
               INVALID KEY
                   CONTINUE *> Email doesn't exist, good
               NOT INVALID KEY
                   READ USER-FILE
                       INVALID KEY
                           CONTINUE *> Somehow the START worked but READ failed
                       NOT INVALID KEY
                           MOVE "Email already registered" TO WS-ERROR-MESSAGE
                           PERFORM GENERATE-ERROR-RESPONSE
                           CLOSE USER-FILE
                           EXIT PARAGRAPH
                   END-READ
           END-START
           
           *> Create the user
           MOVE WS-USER-ID OF WS-USER TO UF-USER-ID
           MOVE WS-USERNAME OF WS-USER TO UF-USERNAME
           MOVE WS-EMAIL OF WS-USER TO UF-EMAIL
           MOVE WS-PASSWORD OF WS-USER TO UF-PASSWORD
           MOVE WS-CREATION-DATE OF WS-USER TO UF-CREATION-DATE
           MOVE WS-LAST-UPDATE OF WS-USER TO UF-LAST-UPDATE
           
           WRITE USER-RECORD
               INVALID KEY
                   MOVE "Failed to write new user record" TO 
                       WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   MOVE 1 TO WS-SUCCESS-FLAG
                   MOVE WS-USER-ID OF WS-USER TO WS-FMT-USER-ID
                   STRING '{"success":true,"message":'
                          '"User created",'
                          '"id":' DELIMITED BY SIZE
                          FUNCTION TRIM(WS-FMT-USER-ID) DELIMITED BY SIZE
                          '}' DELIMITED BY SIZE
                       INTO WS-RESPONSE
           END-WRITE
           
           CLOSE USER-FILE.
       
       UPDATE-USER.
           OPEN I-O USER-FILE
           
           IF USER-FILE-STATUS NOT = "00"
               MOVE "Failed to open user file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE USER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-USER-ID OF WS-USER TO UF-USER-ID
           
           READ USER-FILE
               INVALID KEY
                   MOVE "User not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   *> Update user fields
                   MOVE WS-USERNAME OF WS-USER TO UF-USERNAME
                   MOVE WS-EMAIL OF WS-USER TO UF-EMAIL
                   IF WS-PASSWORD OF WS-USER NOT = SPACES
                       MOVE WS-PASSWORD OF WS-USER TO UF-PASSWORD
                   END-IF
                   MOVE WS-LAST-UPDATE OF WS-USER TO UF-LAST-UPDATE
                   
                   REWRITE USER-RECORD
                      INVALID KEY
                          MOVE "Failed to rewrite user record" TO 
                              WS-ERROR-MESSAGE
                          PERFORM GENERATE-ERROR-RESPONSE
                      NOT INVALID KEY
                          MOVE 1 TO WS-SUCCESS-FLAG
                          MOVE WS-USER-ID OF WS-USER TO WS-FMT-USER-ID
                          STRING '{"success":true,"message":'
                                 '"User updated",'
                                 '"id":' DELIMITED BY SIZE
                                 FUNCTION TRIM(WS-FMT-USER-ID) DELIMITED BY SIZE
                                 '}' DELIMITED BY SIZE
                              INTO WS-RESPONSE
                   END-REWRITE
           END-READ
           
           CLOSE USER-FILE.
       
       DELETE-USER.
           OPEN I-O USER-FILE
           
           IF USER-FILE-STATUS NOT = "00"
               MOVE "Failed to open user file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE USER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-ID TO UF-USER-ID
           
           READ USER-FILE
               INVALID KEY
                   MOVE "User not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                      NOT INVALID KEY
                          DELETE USER-FILE
                      INVALID KEY
                          MOVE "Failed to delete user record" TO 
                              WS-ERROR-MESSAGE
                          PERFORM GENERATE-ERROR-RESPONSE
                      NOT INVALID KEY
                          MOVE 1 TO WS-SUCCESS-FLAG
                          MOVE WS-USER-ID OF WS-USER TO WS-FMT-USER-ID
                          STRING '{"success":true,"message":'
                                 '"User deleted",'
                                 '"id":' DELIMITED BY SIZE
                                 FUNCTION TRIM(WS-FMT-USER-ID) DELIMITED BY SIZE
                                 '}' DELIMITED BY SIZE
                              INTO WS-RESPONSE
                   END-DELETE
           END-READ
           
           CLOSE USER-FILE.
       
       LIST-USERS.
           OPEN INPUT USER-FILE
           
           IF USER-FILE-STATUS NOT = "00"
               MOVE "Failed to open user file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE USER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE 1 TO WS-JSON-PARSING-IDX *> Initialize pointer
           STRING '{"users":[' DELIMITED BY SIZE
               INTO WS-RESPONSE
               POINTER WS-JSON-PARSING-IDX *> Update pointer
           END-STRING
           
           MOVE 1 TO WS-SUCCESS-FLAG
           MOVE 0 TO WS-NUMERIC-TEMP *> Counter for records found
           
           MOVE LOW-VALUES TO UF-USER-ID
           START USER-FILE KEY >= UF-USER-ID
               INVALID KEY
                   *> No records or error starting, close the array
                   STRING ']}' DELIMITED BY SIZE
                       INTO WS-RESPONSE(WS-JSON-PARSING-IDX:)
                   END-STRING
                   CLOSE USER-FILE
                   EXIT PARAGRAPH *> Exit cleanly if no records
               NOT INVALID KEY
                   CONTINUE *> Start successful, proceed to read loop
           END-START
           
           PERFORM UNTIL USER-FILE-STATUS NOT = "00"
               READ USER-FILE NEXT
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
                       
                       MOVE UF-USER-ID TO WS-FMT-USER-ID
                      
                       STRING '{'                              DELIMITED BY SIZE
                             '"id":'                          DELIMITED BY SIZE
                             FUNCTION TRIM(WS-FMT-USER-ID)    DELIMITED BY SIZE
                             ',"username":"'                  DELIMITED BY SIZE
                             FUNCTION TRIM(UF-USERNAME)       DELIMITED BY SIZE
                             '","email":"'                    DELIMITED BY SIZE
                             FUNCTION TRIM(UF-EMAIL)          DELIMITED BY SIZE
                             '"}' DELIMITED BY SIZE
                          INTO WS-RESPONSE
                          POINTER WS-JSON-PARSING-IDX
                      END-STRING
               END-READ
           END-PERFORM
           
           *> Close the JSON array and object
           STRING ']}' DELIMITED BY SIZE
               INTO WS-RESPONSE(WS-JSON-PARSING-IDX:) *> Append at current position
           END-STRING
               
           CLOSE USER-FILE.
       
       LOGIN-USER.
           MOVE SPACES TO WS-DEBUG-MESSAGE
           STRING "Starting LOGIN-USER"
               DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
           PERFORM DISPLAY-DEBUG

           OPEN INPUT USER-FILE

           IF USER-FILE-STATUS = "35" *> File Not Found
               MOVE SPACES TO WS-DEBUG-MESSAGE
               STRING "LOGIN-USER: User file not found (status 35), login fails."
                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
               PERFORM DISPLAY-DEBUG

               MOVE "Invalid email or password" TO WS-ERROR-MESSAGE *> Standard login fail message
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE USER-FILE *> Ensure file is closed even after failed open
               EXIT PARAGRAPH  *> Exit the paragraph cleanly
           END-IF

           IF USER-FILE-STATUS NOT = "00" *> Handle OTHER open errors
               MOVE SPACES TO WS-DEBUG-MESSAGE
               STRING "Failed to open user file, status: " USER-FILE-STATUS
                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
               PERFORM DISPLAY-DEBUG

               MOVE "Failed to open user file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE USER-FILE
               EXIT PARAGRAPH
           END-IF

           *> Find user by email (Existing logic remains the same)
           MOVE WS-EMAIL OF WS-USER TO UF-EMAIL

           MOVE SPACES TO WS-DEBUG-MESSAGE
           STRING "Looking for email: '" FUNCTION TRIM(WS-EMAIL OF WS-USER) "'"
               DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
           PERFORM DISPLAY-DEBUG

           START USER-FILE KEY = UF-EMAIL
               INVALID KEY
                   MOVE SPACES TO WS-DEBUG-MESSAGE
                   STRING "Email not found in index"
                       DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                   PERFORM DISPLAY-DEBUG

                   MOVE "Invalid email or password" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                   *> CLOSE USER-FILE is handled later
               NOT INVALID KEY
                   MOVE SPACES TO WS-DEBUG-MESSAGE
                   STRING "Email found in index, reading record"
                       DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                   PERFORM DISPLAY-DEBUG

                   *> IMPORTANT CHANGE: Read using the alternate key
                   READ USER-FILE KEY IS UF-EMAIL
                       INVALID KEY
                           MOVE SPACES TO WS-DEBUG-MESSAGE
                           STRING "Failed to read user record using email key"
                               DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                           PERFORM DISPLAY-DEBUG

                           MOVE "Invalid email or password" TO WS-ERROR-MESSAGE
                           PERFORM GENERATE-ERROR-RESPONSE
                       NOT INVALID KEY
                           MOVE SPACES TO WS-DEBUG-MESSAGE
                           STRING "User record read, comparing passwords"
                               DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                           PERFORM DISPLAY-DEBUG

                           *> ... (Password comparison logic remains the same) ...
                           IF FUNCTION TRIM(UF-PASSWORD) =
                              FUNCTION TRIM(WS-PASSWORD OF WS-USER)
                               MOVE SPACES TO WS-DEBUG-MESSAGE
                               STRING "Password match"
                                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                               PERFORM DISPLAY-DEBUG

                               MOVE UF-USER-ID TO WS-FMT-USER-ID
                               MOVE 1 TO WS-SUCCESS-FLAG
                               STRING '{"success":true,'
                                      '"id":'                DELIMITED BY SIZE
                                      FUNCTION TRIM(WS-FMT-USER-ID) DELIMITED BY SIZE
                                      ',"username":"'       DELIMITED BY SIZE
                                      FUNCTION TRIM(UF-USERNAME) DELIMITED BY SIZE
                                      '","email":"'         DELIMITED BY SIZE
                                      FUNCTION TRIM(UF-EMAIL) DELIMITED BY SIZE
                                      '"}' DELIMITED BY SIZE
                                      INTO WS-RESPONSE
                           ELSE
                               MOVE SPACES TO WS-DEBUG-MESSAGE
                               STRING "Password mismatch"
                                   DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
                               PERFORM DISPLAY-DEBUG

                               MOVE "Invalid email or password" TO WS-ERROR-MESSAGE
                               PERFORM GENERATE-ERROR-RESPONSE
                           END-IF
                   END-READ
           END-START

           CLOSE USER-FILE

           MOVE SPACES TO WS-DEBUG-MESSAGE
           STRING "LOGIN-USER complete"
               DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
           PERFORM DISPLAY-DEBUG
           .
       
       GENERATE-USER-JSON.
           MOVE SPACES TO WS-RESPONSE
           MOVE WS-USER-ID OF WS-USER TO WS-FMT-USER-ID
           
           STRING '{"id":' DELIMITED BY SIZE
                  FUNCTION TRIM(WS-FMT-USER-ID) DELIMITED BY SIZE
                  ',"username":"' DELIMITED BY SIZE
                  FUNCTION TRIM(WS-USERNAME OF WS-USER) DELIMITED BY SIZE
                  '","email":"' DELIMITED BY SIZE
                  FUNCTION TRIM(WS-EMAIL OF WS-USER) DELIMITED BY SIZE
                  '"}' DELIMITED BY SIZE
               INTO WS-RESPONSE
           
           MOVE SPACES TO WS-DEBUG-MESSAGE
           STRING "User JSON generated: " WS-RESPONSE(1:100)
               DELIMITED BY SIZE INTO WS-DEBUG-MESSAGE
           PERFORM DISPLAY-DEBUG
           .

       *> ==================== COMMON OPERATIONS ====================
       
       GENERATE-ERROR-RESPONSE.
           MOVE SPACES TO WS-RESPONSE *> Initialize the response buffer first
           STRING '{"success":false,"error":"' DELIMITED BY SIZE
               FUNCTION TRIM(WS-ERROR-MESSAGE) DELIMITED BY SIZE
               '"}' DELIMITED BY SIZE
           INTO WS-RESPONSE.

       DISPLAY-DEBUG.
           DISPLAY FUNCTION TRIM(WS-DEBUG-MESSAGE) UPON SYSERR
           .
       
       CLEANUP-AND-EXIT.
           DISPLAY FUNCTION TRIM(WS-RESPONSE)
           .




