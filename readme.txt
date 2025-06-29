============================================================
                    ED-IT for the Model 4
                         README/TXT
============================================================

This README/TXT file describes any additions, corrections,
or changes to the ED-IT instruction manual.  See page 1 of
the ED-IT manual for details about how to print this file...
or follow the procedure described below, under "Additions,
Changes, and Corrections."

============ ADDITIONS, CHANGES, and CORRECTIONS ===========

Version 1.1 of ED-IT contains a new menu option, "Print."
To use this option, press <BREAK>.  The bottom screen line
will clear and ED-IT will display its main menu:

           File  Block  Search  Print  Other  Quit

Press <P> to select "Print."  The bottom line will now
display a second menu:

            Print  Margins  Titles  Number  Other

To make a choice, press the first letter of the choice.  For
example, to choose "Titles," press <T>.

1.  The Print/Print option starts printing the current file,
    using the tab interval, line length, margins, titles,
    and so on that you have already set.  (Tab interval and
    line length are set using the Other menu, described in
    the ED-IT instruction manual on pages 8 and 9.  Margins,
    titles, and other printing options are set using other
    Print menu options, described below.)  To cancel
    printing at any time, press <BREAK>.

2.  The Print/Margins option prompts you to enter values for
    left margin, top margin, number of printed lines, and
    page length.  Each prompt will display a current value.
    To leave the current value unchanged, press <ENTER>
    without typing anything else.  To change a value, press
    <SHIFT><CLEAR>, type a new value, and press <ENTER>.  To
    exit the Margins option without answering all of the
    prompts, press <BREAK>.

3.  The Print/Titles option prompts you to enter a header
    and footer.  The header and footer are separated from
    the rest of the text by one blank line.  To print the
    current page number in a header or footer, include a
    number sign (#) at an appropriate position on the header
    or footer line.  To turn off a header or footer, answer
    the prompt by pressing <SHIFT><CLEAR>, followed by
    <ENTER>.  To exit the Titles option without entering a
    header and footer, press <BREAK>.

4.  The Print/Number option prompts you for a starting page
    number.  Enter any number from 0 (zero) to 255.  This
    number will be used to compute current page numbers,
    which can be printed on header and footer lines (see
    above).  To exit the Number option without changing the
    starting page number, press <BREAK>.

5.  The Print/Other option asks you three questions.  The
    first question is "Pause after each page?"  Press <Y> if
    you are using single sheets of paper, or <N> if you are
    using continuous fanfold paper or a cut sheet feeder.
    The second question is "Add line-feeds?"  Press <Y> if
    your printer requires line-feeds after carriage returns,
    <N> if it does not.  (Experiment if you're not sure, but
    on TRS-80 computers, the answer is usually <N>.)  The
    final question is "Print slashed zeroes?"  Press <Y> if
    you want slashed zeroes in your print-out; otherwise,
    press <N>.  (Note: this feature will not work on all
    printers.)  To exit the Print/Other option without
    answering all three questions, press <BREAK>.

Suppose you want to use ED-IT's PRINT option to print out
this README/TXT file.  You want a left margin of 12, a top
margin of 0, a line length of 60, and you want to print 54
lines on a 66-line page.  (These are suitable values for
most dot matrix printers if you position the paper about one
inch below the top of the first page.  However, if these
values are inappropriate for your printer, substitute your
own numbers below.)  You want a header of "ED-IT for the
Model 4: README/TXT" and a footer of "Page " followed by the
page number.  Follow this procedure:

1.  Load README/TXT into ED-IT.  (Press <BREAK>, <F>, and
    <L>.  Press <SHIFT><CLEAR> and enter "README/TXT"
    without quotation marks.)

2.  Set a line length of 60.  (Press <BREAK>, <O>, and <L>.
    Press <SHIFT><CLEAR> and enter the number 61.  This
    means that ED-IT will wrap words around to the next line
    when they reach the sixty-first character on-screen.)

3.  Set the margins to your desired values.  (Press <BREAK>,
    <P>, and <M>.  ED-IT will prompt you for each margin
    value.  Press <SHIFT><CLEAR> to erase the default value
    (if necessary) and enter the appropriate number.  In
    this example, the numbers were 12 for left margin, 0 for
    top margin, 54 for number of printed lines, and 66 for
    page length.

4.  Set the header and footer.  (Press <BREAK>, <P>, and
    <T>.  Press <SHIFT><CLEAR> and enter "ED-IT for the
    Model 4: README/TXT" as the header.  Press
    <SHIFT><CLEAR> and enter "Page #" as the footer.  Don't
    include the quotation marks in either case.

5.  Make sure the printer is ready, then print the file.
    (Press <BREAK>, <P>, and <P>.)

That's all there is to it.  As you can see, ED-IT's Print
option is fast, easy, and powerful.

===================== RELEASE HISTORY ======================

06/17/91:  First release of ED-IT (version 1.0).

07/22/91:  Minor revision of ED-IT (version 1.1).  Adds a
           PRINT option to ED-IT's main menu and corrects a
           few minor bugs.

11/18/92:  Patch to ED-IT (E411A/FIX, raises ED-IT's version
           number to 1.1a).  Corrects information line
           problem when switching from programming to text
           mode.

09/30/93:  Patches to ED-IT (E411B/FIX and E411C/FIX, raise
           ED-IT's version number to 1.1c).  Corrects
           miscellaneous loading and saving problems.

==================== End of README/TXT =====================
