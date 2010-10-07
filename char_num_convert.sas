/*
Converting variable types from character to numeric
Numeric data are sometimes imported into variables of type character and it may be desirable to convert these to variables of type numeric. Note that it is not possible to directly change the type of a variable. It is only possible to write the variable to a new variable containing the same data, although with a different type. By renaming and dropping variables, it is possible to produce a new variable with the same name as the original, although with a different type.

A naive approach is to multiply the character variable by 1, causing SAS to perform an implicit type conversion. For example, if charvar is a character variable then the code

numvar=charvar*1;

will result in the creation of a new variable, numvar, which will be of type numeric. SAS performs an implicit character to numeric conversion and gives a note to this effect in the log. This method is considered poor programming practice and should be avoided. A preferable method is to use the INPUT function. For example:

numvar=input(charvar,4.0);

The following SAS code demonstrates character to numeric and numeric to character conversion.
*/
data temp;
length char4 $ 4;
input numeric char4;

/* convert character to numeric */
new_num=input(char4,best4.);

/* convert numeric to character */
new_char=put(numeric,4.0);

cards;
789 1234
009 0009
1 9999
;;

proc print;
run;
/*
If the character variable char4 in the above example contains missing values of non-numeric data then the value of new_num will be missing. When char4 contains non-numeric data, an 'invalid argument' note will be written to the log. This note can be suppressed using the ?? format modifier as in the code below

new_num=input(char4, ?? best4.);

Click here to download some sample code illustrating this.

The INPUT statement is also the best method for converting a character string representing a date (e.g. '990719') to a SAS date variable (see the example here).

The INPUT statement is also more efficient than the implicit conversion method with respect to CPU time.
*/