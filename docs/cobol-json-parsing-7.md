# JSON PARSE example

This example shows the processing of JSON text by the JSON PARSE statement into various types of COBOL data items. The JSON text is included directly in the program source for the purpose of this example. The output of the program is shown after.
```
       Identification division.
         Program-id. jp_ex.
       Data division.
        Working-storage section.
         1 jtxt-1047-client-data.
          3 pic x(16)  value '{"client-data":{'.
          3 pic x(28)  value ' "account-num":123456789012,'.
          3 pic x(19)  value ' "balance":-125.53,'.
          3 pic x(17)  value ' "billing-info":{'.
          3 pic x(22)  value '  "name-first":"John",'.
          3 pic x(22)  value '  "name-last":"Smith",'.
          3 pic x(37)  value '  "addr-street":"12345 First Avenue",'.
          3 pic x(25)  value '  "addr-city":"New York",'.
          3 pic x(27)  value '  "addr-region":"New York",'.
          3 pic x(21)  value '  "addr-code":"10203"'.
          3 pic x(3)   value '  }'.
          3 pic x(2)   value ' }'.
          3 pic x(1)   value '}'.
        1 jtxt-1047-transactions.
          3 pic x(16)  value '{"transactions":'.
          3 pic x(14)  value ' {"tx-record":'.
          3 pic x(3)   value '  ['.
          3 pic x(4)   value '   {'.
          3 pic x(19)  value '    "tx-uid":107,'.
          3 pic x(34)  value '    "tx-item-desc":"prod a ver 1",'.
          3 pic x(30)  value '    "tx-item-uid":"ab142424",'.
          3 pic x(26)  value '    "tx-priceinUS$":12.34,'.
          3 pic x(35)  value '    "tx-comment":"express shipping"'.
          3 pic x(5)   value '   },'.
          3 pic x(4)   value '   {'.
          3 pic x(19)  value '    "tx-uid":1904,'.
          3 pic x(35)  value '    "tx-item-desc":"prod g ver 2",'.
          3 pic x(30)  value '    "tx-item-uid":"gb051533",'.
          3 pic x(27)  value '    "tx-priceinUS$":833.22,'.
          3 pic x(35)  value '    "tx-comment":"digital download"'.
          3 pic x(5)   value '   } '.
          3 pic x(3)   value '  ]'.
          3 pic x(2)   value ' }'.
          3 pic x(1)   value '}'.
         1 jtxt-1208 pic x(1000) value is all x'20'.
         77 txnum pic 999999 usage display value zero.
         1 client-data.
          3 account-num   pic 999,999,999,999.
          3 balance       pic $$$9.99CR.
          3 billing-info.
           5 name-first  pic n(20).
           5 name-last   pic n(20).
           5 addr-street pic n(20).
           5 addr-city   pic n(20).
           5 addr-region pic n(20).
           5 addr-code   pic n(10).
          3 transactions.
           5 tx-record occurs 0 to 100 depending txnum.
            7 tx-uid       pic 99999 usage display.
            7 tx-item-desc pic x(50).
            7 tx-item-uid  pic AA/9999B99.
            7 tx-price     pic $$$9.99.
            7 tx-comment   pic n(20).
       Procedure division.
           Initialize jtxt-1208 all value.
    ******************************************************************
    * In this example, input to JSON PARSE starts in EBCDIC codepage *
    * 1047 and then be converted to UTF-8 (codepage 1208).           *
    * Convert to specific codepages using the display-of function.   *
    * The first argument to display-of should be type 'national',    *
    * which the COBOL compiler represents in UTF-16.                 *
    ******************************************************************
           Move function display-of(
            function national-of( 
            jtxt-1047-client-data) 1208)    
             to jtxt-1208(1:function length(jtxt-1047-client-data)). 

           Json parse jtxt-1208 into client-data
             with detail
             suppress transactions
             not on exception
               display "Successful JSON Parse"
           end-json.

           Display "Account Number:"
           Display "  " account-num
           Display "Balance:"
           Display "  " balance
           Display "Client Information: "
           Display "  Name:"
           Display "    " function display-of(name-last)
           Display "    " function display-of(name-first)
           Display "  Address:"
           Display "    " function display-of(addr-street)
           Display "    " function display-of(addr-city)
           Display "    " function display-of(addr-region)
           Display "    " function display-of(addr-code).

           Move 2 to txnum.
           Initialize jtxt-1208 all value.
           Move function display-of(
            function national-of(
            jtxt-1047-transactions) 1208)
             to jtxt-1208(1:function length(jtxt-1047-transactions)).

           Json parse jtxt-1208 into transactions
             with detail
             name tx-price is 'tx-priceinUS$'
             not on exception
               display "Successful JSON Parse"
           end-json.

           Display "Transactions:"
           Display "  Record 1:"
           Display "    TXID:        " tx-uid(1)
           Display "    Description: " tx-item-desc(1)
           Display "    Item ID:     " tx-item-uid(1)
           Display "    Price:       " tx-price(1)
           Display "    Comment:     "
             function display-of(tx-comment(1))
           Display "  Record 2:"
           Display "    TXID:        " tx-uid(2)
           Display "    Description: " tx-item-desc(2)
           Display "    Item ID:     " tx-item-uid(2)
           Display "    Price:       " tx-price(2)
           Display "    Comment:     "
             function display-of(tx-comment(2))

           Goback.
       End program jp_ex.
```

The output of the program is:

```
Successful JSON Parse
Account Number:
  123,456,789,012
Balance:
  $125.53CR
Client Information: 
  Name:
    Smith               
    John                
  Address:
    12345 First Avenue  
    New York            
    New York            
    10203     
Successful JSON Parse
Transactions:
  Record 1:
    TXID:        00107
    Description: prod a ver 1                                      
    Item ID:     ab/1424 24
    Price:        $12.34
    Comment:     express shipping    
  Record 2:
    TXID:        01904
    Description: prod g ver 2                                      
    Item ID:     gb/0515 33
    Price:       $833.22
    Comment:     digital download   
```     
