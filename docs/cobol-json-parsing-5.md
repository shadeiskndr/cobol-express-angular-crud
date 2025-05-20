# Parsing JSON anonymous arrays

You can parse JSON anonymous arrays by specifying the data name of the table on the JSON PARSE statement while using the NAME IS OMITTED phrase.

Consider the following example:

```
       Identification division.
         Program-id. myprog.
       Data division.
        Working-storage section.
         1 ACT.
           2 B1 occurs 2.
             3 C1.
              4 M1 pic 9.
              4 D1 occurs 2.
                5 N1 pic 9.
         1 json-text pic u dynamic.
       Procedure division.
           move spaces to ACT
           move              '[{"C1":{"M1":1,"D1":[{"N1":3},{"N1":4}]}},
      -     '{"C1":{"M1":2,"D1":[{"N1":5},{"N1":6}]}}]"'
             to json-text
           json parse json-text into b1
             name b1 is omitted
           end-json
           display M1(1)
           display M1(2)
           display N1(1 1)
           display N1(1 2)
           display N1(2 1)
           display N1(2 2)
           goback
           .
       End program myprog.
```

Running the program will produce the following output:
```
1
2
3
4
5
6
```

Note that the JSON PARSE receiver b1 was not subscripted in order to refer to all occurrences of b1.
Consider the next example where the table b1 has two dimensions and is nested within another table like below:

```
       Identification division.
         Program-id. myprog.
       Data division.
        Working-storage section.
         1 ACT.
           2 TOPTABLE occurs 3.
             3 B1 occurs 2.
               4 C1.
                5 M1 pic 9.
                5 D1 occurs 2.
                  6 N1 pic 9.
         1 json-text pic u dynamic.
       Procedure division.
           move spaces to ACT
           move              '[{"C1":{"M1":1,"D1":[{"N1":3},{"N1":4}]}},
      -     '{"C1":{"M1":2,"D1":[{"N1":5},{"N1":6}]}}]"'
             to json-text
           json parse json-text into b1(2)
             name b1 is omitted
           end-json
           display M1(2 1)
           display M1(2 2)
           display N1(2 1 1)
           display N1(2 1 2)
           display N1(2 2 1)
           display N1(2 2 2)
           goback
           .
       End program myprog.
```

Running the program will produce the following output:
```
1
2
3
4
5
6
```

Note that b1(2) was specified with a single index subscript on the JSON PARSE statement. The value of the subscript 2 indicates that the second occurrence of table TOPTABLE shall be populated. The omission of a second index indicates to the JSON PARSE statement that the statement shall assume the input JSON text contains the entire table b1 (rather than a single occurrence of b1, which is what would have been assumed if a second index subscript was specified). This pattern applies generally to multiple nested tables, that is, an anonymous array can be parsed by the combination of the NAME IS OMITTED phrase and by specifying the receiving item with one less subscript than its dimension.