       IDENTIFICATION DIVISION.
       PROGRAM-ID. USER-MANAGEMENT.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT USER-FILE ASSIGN TO EXTERNAL DD_USER_FILE
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS UF-USER-ID
           ALTERNATE RECORD KEY IS UF-EMAIL WITH DUPLICATES
           FILE STATUS IS FILE-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD USER-FILE.
       01 USER-RECORD.
          05 UF-USER-ID             PIC 9(5).
          05 UF-USERNAME            PIC X(50).
          05 UF-EMAIL               PIC X(100).
          05 UF-PASSWORD            PIC X(100).  *> In production, store hashed passwords
          05 UF-CREATION-DATE       PIC X(10).
          05 UF-LAST-UPDATE         PIC X(10).
       
       WORKING-STORAGE SECTION.
       01 FILE-STATUS               PIC XX VALUE SPACES.
       
       01 WS-INPUT-BUFFER           PIC X(1000).
       01 WS-OPERATION              PIC X(15).
       01 WS-ID                     PIC 9(5).
       
       01 WS-USER.
          05 WS-USER-ID             PIC 9(5).
          05 WS-USERNAME            PIC X(50).
          05 WS-EMAIL               PIC X(100).
          05 WS-PASSWORD            PIC X(100).
          05 WS-CREATION-DATE       PIC X(10).
          05 WS-LAST-UPDATE         PIC X(10).
       
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
           EVALUATE WS-OPERATION
               WHEN "GET_USER"
               WHEN "DELETE_USER"
                   PERFORM EXTRACT-ID
               WHEN "CREATE_USER"
               WHEN "UPDATE_USER"
                   PERFORM EXTRACT-USER-DATA
               WHEN "LOGIN"
                   PERFORM EXTRACT-LOGIN-DATA
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
                   
                   MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP - 1:1)
                       TO WS-TEMP(WS-NUMERIC-TEMP:1)
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
               
               MOVE WS-TEMP TO WS-USER-ID
           END-IF
           
           *> Extract username
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:12) = '"username":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 12 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-USERNAME
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-USERNAME
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-USERNAME(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           *> Extract email
           PERFORM VARYING WS-JSON-PARSING-IDX FROM 1 BY 1
               UNTIL WS-JSON-PARSING-IDX > LENGTH OF WS-INPUT-BUFFER
               OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX:9) = '"email":"'
               CONTINUE
           END-PERFORM
           
           IF WS-JSON-PARSING-IDX <= LENGTH OF WS-INPUT-BUFFER
               ADD 9 TO WS-JSON-PARSING-IDX
               MOVE SPACES TO WS-EMAIL
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-EMAIL
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-EMAIL(WS-NUMERIC-TEMP + 1:1)
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
               MOVE SPACES TO WS-PASSWORD
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-PASSWORD
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-PASSWORD(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF
           
           MOVE WS-FORMATTED-DATE TO WS-LAST-UPDATE
           
           IF WS-OPERATION = "CREATE_USER"
               MOVE WS-FORMATTED-DATE TO WS-CREATION-DATE
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
               MOVE SPACES TO WS-EMAIL
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-EMAIL
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-EMAIL(WS-NUMERIC-TEMP + 1:1)
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
               MOVE SPACES TO WS-PASSWORD
               MOVE 0 TO WS-NUMERIC-TEMP
               
               PERFORM UNTIL WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP > LENGTH OF WS-INPUT-BUFFER
                   OR WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1) = '"'
                   
                   IF WS-NUMERIC-TEMP < LENGTH OF WS-PASSWORD
                       MOVE WS-INPUT-BUFFER(WS-JSON-PARSING-IDX + WS-NUMERIC-TEMP:1)
                           TO WS-PASSWORD(WS-NUMERIC-TEMP + 1:1)
                   END-IF
                   
                   ADD 1 TO WS-NUMERIC-TEMP
               END-PERFORM
           END-IF.
       
       GET-USER.
           OPEN INPUT USER-FILE
           
           IF FILE-STATUS NOT = "00"
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
                   MOVE 1 TO WS-SUCCESS-FLAG
                   PERFORM GENERATE-USER-JSON
           END-READ
           
           CLOSE USER-FILE.
       
       CREATE-USER.
           OPEN I-O USER-FILE
               
           IF FILE-STATUS = "35" *> File doesn't exist, open for OUTPUT first
               CLOSE USER-FILE *> Close attempt to open I-O
               OPEN OUTPUT USER-FILE *> Open to create it
               IF FILE-STATUS NOT = "00"
                   MOVE "Failed to create user file" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
                   EXIT PARAGRAPH *> Cannot proceed
               END-IF
               CLOSE USER-FILE *> Close OUTPUT
               OPEN I-O USER-FILE *> Re-open I-O now that file exists
           END-IF
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open user file for I-O" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE USER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-USER-ID TO UF-USER-ID
           
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
           MOVE WS-EMAIL TO UF-EMAIL
           
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
           MOVE WS-USER-ID TO UF-USER-ID
           MOVE WS-USERNAME TO UF-USERNAME
           MOVE WS-EMAIL TO UF-EMAIL
           MOVE WS-PASSWORD TO UF-PASSWORD
           MOVE WS-CREATION-DATE TO UF-CREATION-DATE
           MOVE WS-LAST-UPDATE TO UF-LAST-UPDATE
           
           WRITE USER-RECORD
               INVALID KEY
                   MOVE "Failed to write new user record" TO 
                       WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   MOVE 1 TO WS-SUCCESS-FLAG
                   STRING '{"success":true,"message":'
                          '"User created",'
                          '"id":' DELIMITED BY SIZE
                          WS-USER-ID DELIMITED BY SIZE
                          '}' DELIMITED BY SIZE
                       INTO WS-RESPONSE
           END-WRITE
           
           CLOSE USER-FILE.
       
       UPDATE-USER.
           OPEN I-O USER-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open user file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE USER-FILE
               EXIT PARAGRAPH
           END-IF
           
           MOVE WS-USER-ID TO UF-USER-ID
           
           READ USER-FILE
               INVALID KEY
                   MOVE "User not found" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   *> Update user fields
                   MOVE WS-USERNAME TO UF-USERNAME
                   MOVE WS-EMAIL TO UF-EMAIL
                   IF WS-PASSWORD NOT = SPACES
                       MOVE WS-PASSWORD TO UF-PASSWORD
                   END-IF
                   MOVE WS-LAST-UPDATE TO UF-LAST-UPDATE
                   
                   REWRITE USER-RECORD
                       INVALID KEY
                           MOVE "Failed to update user" TO 
                               WS-ERROR-MESSAGE
                           PERFORM GENERATE-ERROR-RESPONSE
                       NOT INVALID KEY
                           MOVE 1 TO WS-SUCCESS-FLAG
                           STRING '{"success":true,"message":"User updated",'
                                  '"id":' DELIMITED BY SIZE
                                  WS-USER-ID DELIMITED BY SIZE
                                  '}' DELIMITED BY SIZE
                               INTO WS-RESPONSE
                   END-REWRITE
           END-READ
           
           CLOSE USER-FILE.
       
       DELETE-USER.
           OPEN I-O USER-FILE
           
           IF FILE-STATUS NOT = "00"
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
                           MOVE "Failed to delete user" TO 
                               WS-ERROR-MESSAGE
                           PERFORM GENERATE-ERROR-RESPONSE
                       NOT INVALID KEY
                           MOVE 1 TO WS-SUCCESS-FLAG
                           STRING '{"success":true,"message":"' DELIMITED BY SIZE
                                  'User deleted",' DELIMITED BY SIZE
                                  '"id":"' DELIMITED BY SIZE
                                  WS-ID DELIMITED BY SIZE
                                  '"}' DELIMITED BY SIZE
                               INTO WS-RESPONSE
                   END-DELETE
           END-READ
           
           CLOSE USER-FILE.
       
       LIST-USERS.
           OPEN INPUT USER-FILE
           
           IF FILE-STATUS NOT = "00"
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
           
           PERFORM UNTIL FILE-STATUS NOT = "00"
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
                       
                       STRING '{'                              DELIMITED BY SIZE
                              '"id":'                          DELIMITED BY SIZE
                              UF-USER-ID                       DELIMITED BY SIZE
                              ',"username":"'                  DELIMITED BY SIZE
                              FUNCTION TRIM(UF-USERNAME)       DELIMITED BY SIZE
                              '","email":"'                    DELIMITED BY SIZE
                              FUNCTION TRIM(UF-EMAIL)          DELIMITED BY SIZE
                              '"}' DELIMITED BY SIZE
                           INTO WS-RESPONSE
                           POINTER WS-JSON-PARSING-IDX *> Update pointer after each record
                       END-STRING
               END-READ
           END-PERFORM
           
           *> Close the JSON array and object
           STRING ']}' DELIMITED BY SIZE
               INTO WS-RESPONSE(WS-JSON-PARSING-IDX:) *> Append at current position
           END-STRING
               
           CLOSE USER-FILE.
       
       LOGIN-USER.
           OPEN INPUT USER-FILE
           
           IF FILE-STATUS NOT = "00"
               MOVE "Failed to open user file" TO WS-ERROR-MESSAGE
               PERFORM GENERATE-ERROR-RESPONSE
               CLOSE USER-FILE
               EXIT PARAGRAPH
           END-IF
           
           *> Find user by email
           MOVE WS-EMAIL TO UF-EMAIL
           
           START USER-FILE KEY = UF-EMAIL
               INVALID KEY
                   MOVE "Invalid email or password" TO WS-ERROR-MESSAGE
                   PERFORM GENERATE-ERROR-RESPONSE
               NOT INVALID KEY
                   READ USER-FILE
                       INVALID KEY
                           MOVE "Invalid email or password" TO WS-ERROR-MESSAGE
                           PERFORM GENERATE-ERROR-RESPONSE
                       NOT INVALID KEY
                           *> Check password
                           IF UF-PASSWORD = WS-PASSWORD
                               MOVE 1 TO WS-SUCCESS-FLAG
                               STRING '{"success":true,'
                                      '"id":'                DELIMITED BY SIZE
                                      UF-USER-ID            DELIMITED BY SIZE
                                      ',"username":"'       DELIMITED BY SIZE
                                      FUNCTION TRIM(UF-USERNAME) DELIMITED BY SIZE
                                      '","email":"'         DELIMITED BY SIZE
                                      FUNCTION TRIM(UF-EMAIL) DELIMITED BY SIZE
                                      '"}' DELIMITED BY SIZE
                                   INTO WS-RESPONSE
                           ELSE
                               MOVE "Invalid email or password" TO WS-ERROR-MESSAGE
                               PERFORM GENERATE-ERROR-RESPONSE
                           END-IF
                   END-READ
           END-START
           
           CLOSE USER-FILE.
       
       GENERATE-USER-JSON.
           STRING '{"id":' DELIMITED BY SIZE
                  UF-USER-ID DELIMITED BY SIZE
                  ',"username":"' DELIMITED BY SIZE
                  FUNCTION TRIM(UF-USERNAME) DELIMITED BY SIZE
                  '","email":"' DELIMITED BY SIZE
                  FUNCTION TRIM(UF-EMAIL) DELIMITED BY SIZE
                  '","creationDate":"' DELIMITED BY SIZE
                  FUNCTION TRIM(UF-CREATION-DATE) DELIMITED BY SIZE
                  '","lastUpdate":"' DELIMITED BY SIZE
                  FUNCTION TRIM(UF-LAST-UPDATE) DELIMITED BY SIZE
                  '"}' DELIMITED BY SIZE
               INTO WS-RESPONSE.
       
       GENERATE-ERROR-RESPONSE.
           STRING '{"success":false,"error":"' DELIMITED BY SIZE
                  FUNCTION TRIM(WS-ERROR-MESSAGE) DELIMITED BY SIZE
                  '"}' DELIMITED BY SIZE
               INTO WS-RESPONSE.
       
       CLEANUP-AND-EXIT.
           DISPLAY WS-RESPONSE.

