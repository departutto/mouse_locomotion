<h4>Example of using script 'generate_trials.m'.</h4><br>
<b>Step #1. Open Matlab Editor by typing in 'edit' in the Matlab command line.</b><br>
<b>Step #2. Open script 'generate_trials.m' in the Matlab Editor.</b><br>
<b>Step #3. Make block no. 1 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).</b><br>
<b>Step #4. Make block no. 2 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).</b><br>
Script output: Events file: C:\Users\u0062274\Desktop\recordings\08-may-2018\datafiles\Events.nev<br>
Script output: Block no. 2 was complete.<br>
<b>Step #5. Make block no. 3 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).</b><br>
Script output: Situation #1: Header start and stop indices = 5690 x 5697<br>
<b>Step #6. Remove one record from the data structure 'consolidated' by typing in the following instruction.</b><br>
>> consolidated = [consolidated(1:5690, :); consolidated(5692:end, :)];<br>
<b>Step #7. Make block no. 3 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).</b><br>
Script output: Situation #1: Header start and stop indices = 32229 x 32236<br>
<b>Step #8. Remove one record from the data structure 'consolidated' by typing in the following instruction.</b><br>
>> consolidated = [consolidated(1:32229, :); consolidated(32231:end, :)];<br>
<b>Step #9. Make block no. 3 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).</b><br>
Script output: N(Header start and stop entries) = 1923 x 1923<br>
Block no. 3 was complete.<br>
<b>Step #10. Make block no. 4 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).</b><br>
Block no. 4 was complete.<br>
<b>Step #11. Make block no. 5 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).</b><br>
Unique conditions = [1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36]<br>
Block no. 5 was complete.<br>
<b>Step #12. Make block no. 6 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).</b><br>
Block no. 6 was complete.<br>
<b>Step #13. Make block no. 7 active and execute it (Cell -> Evaluate Current Cell or Ctrl + Enter).</b><br>
Block no. 7 was complete.<br>
<b>Step #14. Save the variables 'consolidated', 'time0', and 'trials' in a file (e.g., >> save '2018-05-08-mouse-68865-run-01-stimrep.mat').<br>
<b>Step #15. Clear the Matlab workspace by typing in 'clear all' in the Matlab command line.<br>